/datum/clue
	/// Who created this clue?
	var/clue_owner = null

	/// An optional description to accompany the clue.
	var/description = null

	/// This clue has been marked for cleanup.
	/// Do what you need to do before calling the parent process method.
	var/cleanup = FALSE
	var/created_time = 0

/datum/clue/New(/mob/living/carbon/human/owner, desc = "")
	clue_owner = owner

	if (desc != "")
		description = desc

	SSclues.clues_list += src

/datum/clue/process()
	// Safety check to delete clues after an hour of gametime
	if (world.timeofday - created_time > 1 HOURS)
		return PROCESS_KILL

	if (cleanup)
		return PROCESS_KILL

/datum/clue/prints
	/// A description of the finger that was used to make this fingerprint.
	///
	/// Ex: "this fingerprint was made by **a gloved finger**"
	var/glove_desc = null

	/// The level to which a glove obscures the traces of a fingerprint.
	var/glove_obfuscation = FINGERPRINT_GLOVES_NONE

	/// The quality of the actual traces of the fingerprint that were left behind.
	/// Firmly gripping items (like when attacking) increases the quality of the traces.
	var/imprint_quality = FINGERPRINT_QUALITY_FULL_PRINT

	/// How smudged the fingerprint is from further interactions with an item.
	/// Can be decreased if the print is oily in nature and sprayed with forensic spray.
	var/smudge_amount = FINGERPRINT_SMUDGE_NONE

	/// How much the fingerprint's quality has been affected by age
	var/print_age = FINGERPRINT_TIME_FRESH

	/// If these fingerprints were made by something oily.
	/// Determines if forensic spray increases the chance of them being found.
	var/oily = FALSE

	/// If these fingerprints were made by a left hand
	var/left_handed = FALSE

/datum/clue/prints/New(/mob/living/carbon/human/owner, desc = "", left_hand = FALSE)
	. = ..(owner, desc)

	var/obj/item/clothing/gloves/gloves = owner.gloves
	if (!gloves)
		glove_desc = "a bare finger"
		oily = TRUE
	else
		glove_desc = gloves.fingerprint_desc
		glove_obfuscation = gloves.fingerprint_obfuscation
		oily = gloves.fingerprint_obfuscation == FINGERPRINT_GLOVES_NONE

	src.left_handed = left_hand

	// Fingerprint sets with more than one fingerprint can only be made by "upgrading" existing prints
	switch(rand(1, 100))
		if (1 to 40)
			imprint_quality = FINGERPRINT_QUALITY_FULL_PRINT
		if (41 to 70)
			// Fingerprints made when the user was angry are more likely to be clearer
			if (owner.a_intent == INTENT_HARM)
				imprint_quality = FINGERPRINT_QUALITY_FULL_PRINT
			else
				imprint_quality = FINGERPRINT_QUALITY_HALF_FACED
		if (71 to 90)
			if (owner.a_intent == INTENT_HARM)
				imprint_quality = FINGERPRINT_QUALITY_HALF_FACED
			else
				imprint_quality = FINGERPRINT_QUALITY_SLIVER
		if (91 to 100)
			imprint_quality = FINGERPRINT_QUALITY_SLIVER

	if (prob(20))
		smudge_amount = FINGERPRINT_SMUDGE_CLEAR
	else
		smudge_amount = FINGERPRINT_SMUDGE_NONE

/datum/clue/prints/process()
	var/age = world.timeofday - created_time

	switch (age)
		if (0 to 1 MINUTES)
			print_age = FINGERPRINT_TIME_FRESH
		if (1 MINUTES to 10 MINUTES)
			print_age = FINGERPRINT_TIME_NORMAL
		if (10 MINUTES to 30 MINUTES)
			print_age = FINGERPRINT_TIME_FADED
		else
			print_age = FINGERPRINT_TIME_OLD

	. = ..()

/datum/clue/hair
	/// The length of this hair.
	/// Humans with longer hairstyles are more likely to leave longer hairs on objects.
	var/hair_length = 0

	/// The approximate color of the hair.
	var/hair_color = null

/datum/clue/fiber
	/// The type of clothing that was worn when this clue was created.
	/// CAN include glove fibers. Should not be null.
	var/clothing_type = null

/datum/clue/footprint
	/// The type of footwear that was worn when this footprint was made.
	/// Is null if these are barefoot prints (ew).
	var/boot_type = null

	/// Was this footprint made after stepping in a pool of blood?
	var/is_bloody = FALSE

	/// Was this footprint made after stepping in a pool of oil?
	var/is_oily = FALSE

/datum/clue/blood_splatter
	/// Was this splatter made by a blunt object?
	var/is_blunt = FALSE

	/// Was this splatter made by a sharp object?
	var/is_sharp = FALSE

	/// Was this splatter caused by a bullet?
	var/is_bullet = FALSE

	/// How many people were nearby when this blood spatter was made?
	/// In real life, this is found by seeing where the blood spray is NOT.
	var/nearby_assailants = 0

	/// Does this blood splatter need to be sprayed with forensic spray to be found?
	var/is_subtle = FALSE
