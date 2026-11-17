SUBSYSTEM_DEF(navigation)
	name = "Navigation"
	flags = SS_NO_INIT | SS_NO_FIRE // Lazy bum
	priority = SS_PRIORITY_MOB

	var/list/datum/navmesh/navmeshes = list()

/datum/controller/subsystem/navigation/register_navmesh(datum/navmesh/mesh)

/datum/controller/subsystem/navigation/turf_closed(turf/loc)
	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.turf_closed(loc)

/datum/controller/subsystem/navigation/turf_opened(turf/loc)
	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.turf_opened(loc)

/datum/controller/subsystem/navigation/blocker_created(obj/structure/blocker)
	// Can't block movement, no possible effect on navigation.
	if (!blocker.can_block_movement)
		return

	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.blocker_created(blocker)

/datum/controller/subsystem/navigation/blocker_anchored(obj/structure/blocker)
	// Can't block movement, no possible effect on navigation.
	if (!blocker.can_block_movement)
		return

	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.blocker_anchored(blocker)

/datum/controller/subsystem/navigation/blocker_removed(obj/structure/blocker)
	// Can't block movement, no possible effect on navigation.
	if (!blocker.can_block_movement)
		return

	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.blocker_removed(blocker)

/datum/controller/subsystem/navigation/blocker_unanchored(obj/structure/blocker)
	// Can't block movement, no possible effect on navigation.
	if (!blocker.can_block_movement)
		return

	for (var/datum/navmesh/navmesh as anything in navmeshes)
		navmesh.blocker_unanchored(blocker)

