SUBSYSTEM_DEF(clever_mobs)
	name = "Clever Mobs"
	wait = 0.5
	flags = SS_NO_INIT | SS_KEEP_TIMING
	priority = SS_PRIORITY_MOB

	var/list/current_run = list()
	var/list/registered_clever_mobs = list()

/datum/controller/subsystem/clever_mobs/stat_entry(msg)
	msg = "P:[length(registered_clever_mobs)]"
	return ..()

/datum/controller/subsystem/clever_mobs/fire(resumed = FALSE)
	if (!resumed)
		current_run = registered_clever_mobs.Copy()

	while (length(current_run))
		var/mob/living/target = current_run[length(current_run)]
		current_run.len--

		if (!target || QDELETED(target))
			continue

		target.Life(wait * 0.1)

		if (MC_TICK_CHECK)
			return


