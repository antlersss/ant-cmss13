SUBSYSTEM_DEF(clever_mobs)
	name = "Clever Mobs"
	wait = 0.5
	flags = SS_KEEP_TIMING || SS_NO_INIT
	priority = SS_PRIORITY_MOB

	var/list/datum/nav_meshes = list()

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

/datum/nav_mesh
	var/z_level
	var/hive = XENO_HIVE_NORMAL

	var/next_id = 0

	var/list/datum/nav_node/nodes = list()
	var/list/datum/nav_node/nodeid_by_turf = list()

/// Generates a navmesh node for a given turf.
/// Does not check if such a node exists already! If you're looking to regenerate a node, use poke_node.
/datum/nav_mesh/generate_node(turf/loc)
	var/datum/nav_node/node = new /datum/nav_node(next_id, loc)

	// Update node vector and map
	if (nodes.len == next_id)
		nodes.Add(node)
	else if (nodes.len > next_id)
		nodes[next_id] = node
	next_id++
	nodeid_by_turf[loc] = node

/// Returns a value indicating the cost to move from start turf to end turf.
/// Should only be used on adjactent turfs.
/datum/nav_mesh/get_travel_cost(turf/start, turf/end)
	var/delta_x = end.x - start.x
	var/delta_y = end.y - start.y

	if (abs(delta_x) + abs(delta_y) > 1)
		CRASH("Attempted to find the travel cost between two turfs that are not adjacent: [start], [end]")
	if (abs(delta_x) + abs(delta_y) == 0)
		return 0

	var/move_dir
	if (delta_x > 0)
		move_dir = EAST
	else if (delta_x < 0)
		move_dir = WEST
	else if (delta_y > 0)
		move_dir = NORTH
	else if (delta_y < 0)
		move_dir = SOUTH

	var/travel_cost = 1

	// TODO: More advanced travel cost calculation, like barricades and destructable walls
	if (end.weeds != null)
		var/obj/effect/alien/weeds/weeds = end.weeds

		if (weeds.hivenumber != hive)
			travel_cost += weeds.weed_strength
		else
			travel_cost -= 0.1

	return travel_cost

/datum/nav_mesh/get_node_at_turf(turf/loc)
	var/node_id = nodeid_by_turf[loc]

	if (node_id == null)
		return null

	return nodes[node_id]

/datum/nav_node
	var/id
	var/turf/loc

	var/south_cost
	var/south_nodeid

	var/east_cost
	var/east_nodeid

	var/north_cost
	var/north_nodeid

	var/west_cost
	var/west_nodeid

/datum/nav_node/New(id, turf/loc)
	. = ..()

	id = id
	loc = loc

/datum/nav_node/get_dir_cost(dir)
	switch (dir)
		if (SOUTH)
			return south_cost
		if (EAST)
			return east_cost
		if (NORTH)
			return north_cost
		if (WEST)
			return west_cost

/datum/nav_node/get_dir_nodeid(dir)
	switch (dir)
		if (SOUTH)
			return south_nodeid
		if (EAST)
			return east_nodeid
		if (NORTH)
			return north_nodeid
		if (WEST)
			return west_nodeid

