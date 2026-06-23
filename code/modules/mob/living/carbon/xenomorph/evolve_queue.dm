/// Parent datum for the evolve queue and evolve queue entries
/// Provides no procs on its own, and is for better type-pathing
/datum/evolve_queue

/datum/evolve_queue/queue
	/// The hive this evolve queue belongs to
	var/datum/hive_status/linked_hive

	var/list/entries = list()

	var/seniority_score_multiplier = 1
	var/weeding_score_multiplier = 1
	var/building_score_multiplier = 1
	var/damage_score_multiplier = 1
	var/pheromone_score_multiplier = 1

/datum/evolve_queue/queue/New(/datum/hive_status/linked_hive)
	. = ..()
	src.linked_hive = linked_hive

/// Creates a new entry in the evolve queue with the assigned xenomorph and a timestamp
/datum/evolve_queue/queue/proc/AddEntry(/mob/living/carbon/xenomorph/xeno, evolve_to)
	var/datum/evolve_queue/entry/entry = new(xeno, evolve_to)
	entries += entry

/// Updates the position of an entry in the queue based off of a descending ordering of score
/// This MUST be called after modifying an entry's score
/datum/evolve_queue/queue/proc/UpdateEntry(/mob/living/carbon/xenomorph/entry_owner)
	var/datum/evolve_queue/entry/subject = null
	for (var/datum/evolve_queue/entry/potential_subject in entries)
		if (potential_subject.owner == entry_owner)
			subject = potential_subject
			break

	if (subject == null)
		return

	// Remove the entry
	entries.Remove(subject);

	// Do a binary insertion
	var/idx = length(entries) - 1
	var/bit_idx = 0
	while (idx > 0)
		idx >>= 1
		bit_idx++

	while (bit_idx > 0)
		idx |= 1 << bit_idx
		var/datum/evolve_queue/entry/sample = entries[idx + 1]

		if (sample.score() < subject.score())
			idx ^= 1 << bit_idx
		bit_idx--

	entries.Insert(idx + 1, subject)

/datum/evolve_queue/entry
	/// The owner of this entry in the evolve queue
	var/mob/living/carbon/xenomorph/owner
	/// The caste that the owner wants to evolve to
	var/evolving_to
	/// The game time that the owner initially queued
	var/queue_time

	// ==== Priority Queue Score Vars ====
	/// Score earned by planting and spreading weeds
	var/weeding_score = 0
	/// Score earned by building resin structures
	var/building_score = 0
	/// Score earned by damaging enemies
	var/damage_score = 0
	/// Score earned by supporting allied xenomorphs with pheromones
	var/pheromone_score = 0

/datum/evolve_queue/entry/New(/mob/living/carbon/xenomorph/owner, evolve_to)
	. = ..()

	src.owner = owner
	src.evolving_to = evolving_to

	src.queue_time = world.time

/datum/evolve_queue/entry/score()
	return weeding_score + building_score + damage_score + pheromone_score

