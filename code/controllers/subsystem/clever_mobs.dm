SUBSYSTEM_DEF(clever_mobs)
	name = "Clever Mobs"
	wait = 0.5
	flags = SS_NO_INIT | SS_KEEP_TIMING
	priority = SS_PRIORITY_MOB

	var/list/datum/threat_assessment/threat_assessments = list()

	var/list/current_run = list()
	var/list/registered_clever_mobs = list()

/datum/controller/subsystem/clever_mobs/stat_entry(msg)
	msg = "P:[length(registered_clever_mobs)]"
	return ..()

/datum/controller/subsystem/clever_mobs/fire(resumed = FALSE)
	if (!resumed)
		current_run = registered_clever_mobs.Copy()

	while (length(current_run))
		var/mob/living/clever/target = current_run[length(current_run)]
		current_run.len--

		if (!target || QDELETED(target))
			continue

		target.Life(wait * 0.1)

		if (MC_TICK_CHECK)
			return

/datum/threat_assessment
	var/faction
	var/list/threat_values

/datum/threat_assessment/New(faction = FACTION_XENOMORPH)
	. = ..()
	faction = faction
	threat_values = list()

/datum/threat_assessment/generate_at(turf/loc, range = 7, faction = FACTION_XENOMORPH)
	var/list/mob/living/carbon/entity_buffer = range(range + 7, loc)
	var/list/turf/target_turfs = RANGE_TURFS(range, loc)

	for (var/turf/target_turf in target_turfs)
		var/threat = threat_at_loc(target_turf, entity_buffer)
		threat_values[target_turfs] = threat


/// Evaluates the "threat level" at every turf for a given faction.
/// Extremely naive threat assessment function for development purposes. TODO: Make this better.
/datum/threat_assessment/threat_at_loc(turf/loc, list/mob/living/carbon/entity_buffer, faction = FACTION_XENOMORPH)
	if (!entity_buffer)
		return 0;

	var/total_threat = 0
	for (var/mob/living/carbon/entity as anything in entity_buffer)
		var/has_los = inLineOfSight()

		if (istype(/mob/living/carbon/human/, entity))
			if (entity.faction.is_ally)




