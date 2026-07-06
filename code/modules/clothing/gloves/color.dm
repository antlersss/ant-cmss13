/obj/item/clothing/gloves/yellow
	desc = "These gloves will protect the wearer from electric shock."
	name = "insulated gloves"
	icon_state = "insulated"
	item_state = "insulated"
	siemens_coefficient = 0

	flags_cold_protection = BODY_FLAG_HANDS
	min_cold_protection_temperature = GLOVES_MIN_COLD_PROT
	flags_heat_protection = BODY_FLAG_HANDS
	max_heat_protection_temperature = GLOVES_MAX_HEAT_PROT
	fingerprint_desc = "a gloved finger, covered in yellow insulative material"
	fingerprint_obfuscation = FINGERPRINT_GLOVES_HEAVY

/obj/item/clothing/gloves/fyellow  //Cheap Chinese Crap
	desc = "These gloves are cheap copies of the coveted gloves, no way this can end badly."
	name = "budget insulated gloves"
	icon_state = "insulated"
	item_state = "insulated"
	siemens_coefficient = 1 //Set to a default of 1, gets overridden in New()
	fingerprint_desc = "a gloved finger, covered in cheap yellow insulative material"
	fingerprint_obfuscation = FINGERPRINT_GLOVES_HEAVY

/obj/item/clothing/gloves/fyellow/New()
	siemens_coefficient = pick(0,0.5,0.5,0.5,0.5,0.75,1.5)
	..()

/obj/item/clothing/gloves/black
	desc = "These gloves are fire-resistant."
	name = "black gloves"
	icon_state = "black"
	item_state = "bgloves"
	flags_cold_protection = BODY_FLAG_HANDS
	min_cold_protection_temperature = GLOVES_MIN_COLD_PROT
	flags_heat_protection = BODY_FLAG_HANDS
	max_heat_protection_temperature = GLOVES_MAX_HEAT_PROT
	fingerprint_desc = "a gloved finger, covered in black, fire-resistant material"
	fingerprint_obfuscation = FINGERPRINT_GLOVES_HEAVY

/obj/item/clothing/gloves/orange
	name = "orange gloves"
	desc = "A pair of gloves, they don't look special in any way."
	icon_state = "orange"
	item_state = "orangegloves"
	fingerprint_desc = "a gloved finger, dyed with orange pigment"

/obj/item/clothing/gloves/red
	name = "red gloves"
	desc = "A pair of gloves, they don't look special in any way."
	icon_state = "red"
	item_state = "redgloves"
	fingerprint_desc = "a gloved finger, dyed with red pigment"

/obj/item/clothing/gloves/rainbow
	name = "rainbow gloves"
	desc = "A pair of gloves, they don't look special in any way."
	icon_state = "rainbow"
	item_state = "rainbowgloves"
	fingerprint_desc = "a gloved finger, dyed with rainbow pigment"

/obj/item/clothing/gloves/blue
	name = "blue gloves"
	desc = "A pair of gloves, they don't look special in any way."
	icon_state = "blue"
	item_state = "bluegloves"
	fingerprint_desc = "a gloved finger, dyed with blue pigment"

/obj/item/clothing/gloves/purple
	name = "purple gloves"
	desc = "A pair of gloves, they don't look special in any way."
	icon_state = "purple"
	item_state = "purplegloves"
	fingerprint_desc = "a gloved finger, dyed with purple pigment"

/obj/item/clothing/gloves/green
	name = "green gloves"
	desc = "A pair of gloves, they don't look special in any way."
	icon_state = "green"
	item_state = "greengloves"
	fingerprint_desc = "a gloved finger, dyed with green pigment"

/obj/item/clothing/gloves/grey
	name = "grey gloves"
	desc = "A pair of gloves, they don't look special in any way."
	icon_state = "gray"
	item_state = "graygloves"
	fingerprint_desc = "a gloved finger, dyed with grey pigment"

/obj/item/clothing/gloves/light_brown
	name = "light brown gloves"
	desc = "A pair of gloves, they don't look special in any way."
	icon_state = "lightbrown"
	item_state = "lightbrowngloves"
	fingerprint_desc = "a gloved finger, dyed with light brown pigment"

/obj/item/clothing/gloves/brown
	name = "brown gloves"
	desc = "A pair of gloves, they don't look special in any way."
	icon_state = "brown"
	item_state = "browngloves"
	fingerprint_desc = "a gloved finger, dyed with brown pigment"
