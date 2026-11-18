SUBSYSTEM_DEF(navigation)
	name = "Navigation"
	flags = SS_NO_FIRE // Lazy bum
	priority = SS_PRIORITY_MOB

	var/list/datum/navmesh/navmeshes = list()

/datum/controller/subsystem/navigation/proc/register_navmesh(datum/navmesh/mesh)
	navmeshes += mesh

/datum/controller/subsystem/navigation/proc/register_structure(obj/structure/structure)
	RegisterSignal(structure, COMSIG_STRUCTURE_WRENCHED, PROC_REF(blocker_anchored))
	RegisterSignal(structure, COMSIG_STRUCTURE_UNWRENCHED, PROC_REF(blocker_unanchored))

/datum/controller/subsystem/navigation/proc/turf_closed(turf/loc)
	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.turf_closed(loc)

/datum/controller/subsystem/navigation/proc/turf_opened(turf/loc)
	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.turf_opened(loc)

/datum/controller/subsystem/navigation/proc/blocker_created(obj/structure/blocker)
	// Can't block movement, no possible effect on navigation.
	if (!blocker.can_block_movement)
		return

	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.blocker_created(blocker)

/datum/controller/subsystem/navigation/proc/blocker_anchored(obj/structure/blocker)
	SIGNAL_HANDLER

	// Can't block movement, no possible effect on navigation.
	if (!blocker.can_block_movement)
		return

	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.blocker_anchored(blocker)

/datum/controller/subsystem/navigation/proc/blocker_removed(obj/structure/blocker)
	// Can't block movement, no possible effect on navigation.
	if (!blocker.can_block_movement)
		return

	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.blocker_removed(blocker)

/datum/controller/subsystem/navigation/proc/blocker_unanchored(obj/structure/blocker)
	SIGNAL_HANDLER

	// Can't block movement, no possible effect on navigation.
	if (!blocker.can_block_movement)
		return

	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.blocker_unanchored(blocker)

