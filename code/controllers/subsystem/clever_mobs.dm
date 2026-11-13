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

/datum/navmesh/
	/// The next unique ID to be assigned to a created node.
	var/next_id = 0

	/// The hivenumber associated with this navmesh.
	/// TODO: Update this in the future to be more flexible with nav ownership by factions!
	var/hive_number = XENO_HIVE_NORMAL

	/// List holding all nodes in the navmesh, indexed by their associated turfs.
	var/list/datum/nav_node/nodes = list()

/// Creates a new navmesh node at the given location and automatically links it to adjacent NORTH, SOUTH, EAST, and WEST nodes if they exist.
/// Does NOT check if a node already exists at this location.
/datum/navmesh/create_node(turf/loc)
	// Initialize the node and increment the next node id
	var/datum/nav_node/new_node = new (next_id, loc)
	next_id++

	// Insert it into the navmesh's node list
	nodes[loc] = new_node

	for (var/dir in CARDINAL_DIRS)
		var/turf/adjacent_turf = step(loc, dir)
		var/datum/nav_node/adjacent_node = nodes[adjacent_turf]

		if (adjacent_node == null)
			new_node.node_links[dir] = null
			continue

/datum/nav_node/
	var/datum/weakref/navmesh_weakref //! Weak reference to the nav mesh that owns this node.

	var/id //! Unique ID used for identifying nodes when converting to the rustg call. Never null.
	var/turf/loc //! Unique turf that this nav node is associated with. Never null.

	/// List of links to other nodes, indexed by their relative direction.
	var/list/datum/node_links = list()

/datum/nav_node/New(datum/navmesh/mesh, id, turf/loc)
	. = ..()

	navmesh_weakref = WEAKREF(mesh)
	id = id
	loc = loc

/// A directional link between two nodes in a navmesh.
/datum/node_link/
	var/datum/weakref/source_node_weakref //! A weakref to the start node of this link.
	var/datum/weakref/dest_node_weakref //! A weakref to the destination node of this link.

	/// Cost associated with how long it takes to move from the source node to the destination node.
	var/move_cost = INFINITY

	/// Cost associated with how much damage would need to be done to obstacles to move from the source node to destination node.
	var/damage_cost = INFINITY
	var/minimum_claws = CLAW_TYPE_VERY_SHARP

/datum/node_link/New(datum/nav_node/source_node, datum/nav_node/dest_node)
	. = ..()

	source_node_weakref = WEAKREF(source_node)
	dest_node_weakref = WEAKREF(dest_node)

/datum/node_link/evaluate_costs()
	// Dereferencing weakrefs
	var/datum/nav_node/source_node = source_node_weakref.resolve()
	var/datum/nav_node/dest_node = dest_node_weakref.resolve()

	// If these weakrefs have expired, then we don't have a node to work with anymore and this link shouldn't exist.
	if (source_node == null || dest_node == null)
		CRASH("Attempted to evaluate costs for a link between one or more null nav nodes: source [source_node], dest [dest_node]")

	// A node's loc will never be null, so this is okay to directly assign.
	var/turf/source_turf = source_node.loc
	var/turf/dest_turf = dest_node.loc

	// Determining the direction we're moving in (including composite directions like north-up but not diagonals)
	var/delta_x = dest_turf.x - source_turf.x
	var/delta_y = dest_turf.y - source_turf.y
	var/delta_z = dest_turf.z - source_turf.z
	var/move_dir = 0
	if (abs(delta_x) + abs(delta_y) > 1)
		CRASH("Attempted to evaluate costs for a link between nonadjacent nav nodes: source: ([source_turf.x], [source_turf.y]), dest: ([dest_turf.x], [dest_turf.y])")
	if (delta_x < 0)
		move_dir |= WEST
	else if (delta_x > 0)
		move_dir |= EAST
	else if (delta_y < 0)
		move_dir |= NORTH
	else if (delta_y > 0)
		move_dir |= SOUTH
	if (delta_z > 0)
		move_dir |= UP
	else if (delta_z < 0)
		move_dir |= DOWN

	// ===== HEALTH COST CALCULATIONS =====

	// Turf is hull; can't break, infinite damage cost
	if (dest_turf.turf_flags | TURF_HULL)
		damage_cost = INFINITY

	// Turf is a wall; mark its remaining health and required claws
	else if (istype(/turf/closed/wall, dest_turf))
		var/turf/closed/wall/wall_dest = dest_turf

		damage_cost = wall_dest.damage_cap - wall_dest.damage
		minimum_claws = wall_dest.claws_minimum

	// Turf is open; free to move into (not counting objects) and requires no claws
	else if (istype(/turf/open, dest_turf))
		damage_cost = 0
		minimum_claws = CLAW_TYPE_NORMAL

	// Fallback option; if we don't know what we're moving into then we probably shouldn't
	else
		damage_cost = INFINITY

	// Adding health of potential blocking structures in the way
	// TODO: Account for cades and other directional blockers
	for (var/obj/structure/blocking in dest_turf)
		if (!blocking.can_block_movement)
			continue
		if (!blocking.density)
			continue
		if (!blocking.anchored)
			continue
		if (blocking.unslashable)
			damage_cost = INFINITY
			break
		if (!blocking.breakable)
			damage_cost = INFINITY
			break

		damage_cost += blocking.health

	// ===== MOVE COST CALCULATIONS =====
	// Move cost is independent of the speed of the entity following the path.
	// For this reason, it can be thought of as a sort of "distance", as its units would purely be tiles.
	// For example, crossing a slowing resin would be like crossing over two tiles of normal resin.

	move_cost = 1

	if (source_turf.weeds != null)
		var/obj/effect/alien/weeds/weeds = source_turf.weeds
		var/datum/navmesh/mesh = source_node.navmesh_weakref.resolve()

		if (weeds.hivenumber != mesh?.hive_number)
			move_cost *= weeds.weed_strength

	// TODO: Account for vaultable cades
	for (var/atom/thing in source_turf)
		var/effect/effect
