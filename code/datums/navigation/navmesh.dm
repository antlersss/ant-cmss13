/// Navmeshes, or navigation meshes, are planar graphs of individual nav_node datums.
/// They are lazily created, which means:
///  - Only evaluated when needed by AI's
///  - Only updated when turfs and structures inside them are modified, created, or destroyed
///
/// Navmeshes are automatically registered in the SSnavigation subsystem.
/datum/navmesh/
	/// The next unique ID to be assigned to a created node.
	var/next_id = 0

	var/lower_x_bound //! The X value of the furthest west node.
	var/upper_x_bound //! The X value of the furthest east node.
	var/lower_y_bound //! The Y value of the furthest south node.
	var/upper_y_bound //! The Y value of the furthest north node.

	var/list/z_levels = list() //! List of all z-levels the navmesh is in.

	/// List holding all nodes in the navmesh, indexed by their associated turfs.
	var/list/datum/nav_node/nodes = list()

/datum/navmesh/New()
	SHOULD_CALL_PARENT(TRUE)
	. = ..()

	SSnavigation.register_navmesh(src)

/// Creates a new navmesh node at the given location and automatically links it to adjacent NORTH, SOUTH, EAST, and WEST nodes if they exist.
/// Does NOT check if a node already exists at this location.
/datum/navmesh/create_node(turf/loc, autolink = TRUE)
	// Initialize the node and increment the next node id
	var/datum/nav_node/new_node = new (src, next_id, loc)
	next_id++

	// Insert it into the navmesh's node list
	nodes[loc] = new_node

	// Update navmesh bounds
	lower_x_bound = min(lower_x_bound, loc.x)
	upper_x_bound = max(upper_x_bound, loc.x)
	lower_y_bound = min(lower_y_bound, loc.y)
	upper_y_bound = max(upper_y_bound, loc.y)

	if (!z_levels.Find(loc.z) == 0)
		z_levels += loc.z

	// Auto linking
	if (!autolink)
		return
	for (var/dir in CARDINAL_DIRS)
		var/turf/adjacent_turf = step(loc, dir)
		var/datum/nav_node/adjacent_node = nodes[adjacent_turf]

		if (adjacent_node == null)
			new_node.node_links[dir] = null
			continue

		new_node.node_links[dir] = new (new_node, adjacent_node)
		adjacent_node.node_links[REVERSE_DIR(dir)] = new (adjacent_node, new_node)

/// Removes a nav node from the navmesh cleanly, removing any associated links and references.
/datum/navmesh/remove_node(datum/nav_node/node)
	nodes.Remove(node) // Clear from node hashmap

	var/list/datum/nav_node/hanging_nodes = node.get_neighbor_nodes()
	for (var/datum/nav_node/hanging_node as anything in hanging_nodes)
		for (var/datum/node_link/link as anything in hanging_node.node_links)
			if (link.dest_node_weakref.resolve() != node) // Should always resolve
				continue

			hanging_node.node_links.Remove(link)
			qdel(link)

/// Updates all node_links that have the target node as a source or destination by calling
/// calculate_costs() on them with no arguments.
/datum/navmesh/update_associated_links(datum/nav_node/node)
	// Collect all node_links that could potentially need to be updated
	var/list/datum/node_link/outdated_links = node.node_links.Copy()
	for (var/datum/nav_node/neighbor_node as anything in node.get_neighbor_nodes())
		outdated_links += neighbor_node.node_links

	for (var/datum/node_link/link as anything in outdated_links)
		var/datum/nav_node/source_node = link.source_node_weakref.resolve()
		var/datum/nav_node/dest_node = link.dest_node_weakref.resolve()

		// This link is not associated with the updated node, ignore it.
		if (source_node != node && dest_node != node)
			continue

		// Recalculate the link's costs.
		link.calculate_costs()

/// Called when a turf is converted to a closed turf.
///
/// If the turf is outside of the navmesh or the turf does not already have an associated nav node, nothing
/// happens and the function early returns.
///
/// If an associated nav node is found then the base implementation removes the node if the turf was replaced by either:
///  - A turf that is not a subtype of /turf/closed/wall
///  - A turf that has the flag TURF_HULL or lacks the flag TURF_BREAKABLE
///
/// Otherwise, all neighboring nodes's links to the target node as well as all outgoing links from the target
/// node are updated by calling calculate_costs() with no arguments.
/datum/navmesh/turf_closed(turf/loc)
	if (!turf_within_bounds(loc) || z_levels.Find(loc.z) == 0)
		return

	var/datum/nav_node/node_at_loc = nodes[loc]
	if (node_at_loc == null)
		return

	// Closed turfs that are not walls cannot be pathed into, as they cannot be broken. Just remove the node.
	if (!istype(loc, /turf/closed/wall))
		remove_node(node_at_loc)
		return
	else
		// Ditto for hull or unbreakable walls
		var/turf/closed/wall/wall = loc
		if (wall.turf_flags & TURF_HULL || !(wall.turf_flags & TURF_BREAKABLE))
			remove_node(node_at_loc)
			return

	update_associated_links(node_at_loc)

/// Called when a turf is converted to an open turf.
///
/// Does the following:
///  - If the turf is outside of the bounds of the navmesh, nothing happens.
///  - If the turf is within the bounds of the navmesh and there is not already an associated node with said turf,
/// but it is bordering turfs that DO have nodes, then create a new node at the target turf.
///  - If there's already a node associated with the target turf, simply update all associated links.
/datum/navmesh/turf_opened(turf/loc)
	if (!turf_within_bounds(loc) || z_levels.Find(loc.z) == 0)
		return

	var/datum/nav_node/node_at_loc = nodes[loc]
	if (node_at_loc != null)
		update_associated_links(node_at_loc)
		return

	// Search for nodes in the neighboring turfs
	for (var/dir in CARDINAL_DIRS)
		var/turf/neighbor = get_step(loc, dir)
		var/datum/nav_node/neighbor_node = nodes[neighbor]

		if (neighbor_node == null)
			continue

		// Found a potential neighbor. Add a node at this turf.
		create_node(loc)
		return

/// Called when a blocking structure is created.
/datum/navmesh/blocker_created(obj/structure/blocker)
	if (!turf_within_bounds(get_turf(blocker)) || z_levels.Find(blocker.z) == 0)
		return

/// Called when a blocking structure is anchored.
/datum/navmesh/blocker_anchored(obj/structure/blocker)
	if (!turf_within_bounds(get_turf(blocker)) || z_levels.Find(blocker.z) == 0)
		return

/// Called when a blocking structure is removed.
/datum/navmesh/blocker_removed(obj/structure/blocker)
	if (!turf_within_bounds(get_turf(blocker)) || z_levels.Find(blocker.z) == 0)
		return

/// Called when a blocking structure is unanchored.
/datum/navmesh/blocker_unanchored(obj/structure/blocker)
	if (!turf_within_bounds(get_turf(blocker)) || z_levels.Find(blocker.z) == 0)
		return

/// Returns true if the turf is within the x-y bounds of the navmesh.
/datum/navmesh/turf_within_bounds(turf/loc)
	return loc.x >= lower_x_bound && loc.x <= upper_x_bound && loc.y >= lower_y_bound && loc.y <= upper_y_bound

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

/// Returns a list of nodes that are linked to this node.
/// Such nodes are considered the "neighbors" of this node.
/datum/nav_node/get_neighbor_nodes()
	var/list/datum/nav_node/linked_nodes = list()
	for (var/datum/node_link/link as anything in node_links)
		var/datum/nav_node/linked_node = link.dest_node_weakref.resolve()
		if (linked_node == null)
			continue

		linked_nodes += linked_node

	return linked_nodes

/// A directional link between two nodes in a navmesh.
/datum/node_link/
	var/datum/weakref/source_node_weakref //! A weakref to the start node of this link.
	var/datum/weakref/dest_node_weakref //! A weakref to the destination node of this link.

	/// Cost associated with how long it takes to move from the source node to the destination node.
	var/move_cost = INFINITY

/datum/node_link/New(datum/nav_node/source_node, datum/nav_node/dest_node)
	. = ..()

	source_node_weakref = WEAKREF(source_node)
	dest_node_weakref = WEAKREF(dest_node)

	calculate_costs()

/// Function used by pathfinding to get the objective scalar value of the cost of traversing this node.
/datum/node_link/get_total_cost()
	return move_cost

/// Used to actually run the evaluation functions for the various costs associated with moving along the navmesh.
/// These costs are cached to the navmesh itself and are only updated if the navmesh itself changes.
///
/// Should not be used to calculate costs that vary per-entity, like hive number and claw sharpness.
/// Modify get_total_cost() and pass an argument to it with the entity instead.
/datum/node_link/calculate_costs()
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

	// ===== MOVE COST CALCULATIONS =====
	// Move cost is independent of the speed of the entity following the path.
	// For this reason, it can be thought of as a sort of "distance", as its units would purely be tiles.
	// For example, crossing a slowing resin would be like crossing over two tiles of normal resin.

	move_cost = 1

	// TODO: Account for vaultable cades
	for (var/atom/thing in source_turf)

