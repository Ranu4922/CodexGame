extends Node

@export var water_pond_count: int = 4
@export var forest_cluster_count: int = 7
@export var stone_cluster_count: int = 4

@onready var hex_grid: Node = get_parent().get_node("HexGrid")

var tile_materials: Dictionary = {}
var tiles_by_coords: Dictionary = {}


func _ready() -> void:
	call_deferred("_run_world_generation")


func _run_world_generation() -> void:
	tile_materials = hex_grid.get("tile_materials") as Dictionary
	tiles_by_coords = hex_grid.get("tiles_by_coords") as Dictionary
	if tiles_by_coords.is_empty():
		return
	_generate_clustered_world()
	_reposition_village_center()
	_refresh_village_influence()


func _generate_clustered_world() -> void:
	_set_all_tiles_to_type("Gras")
	_create_resource_clusters("Wald", forest_cluster_count, 5, 9, 1100)
	_create_resource_clusters("Stein", stone_cluster_count, 3, 5, 2200)
	_create_water_ponds()


func _set_all_tiles_to_type(tile_type: String) -> void:
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		_set_tile_type(tile, tile_type)


func _create_resource_clusters(tile_type: String, cluster_count: int, min_size: int, max_size: int, seed_offset: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hex_grid.get("generation_seed")) + seed_offset
	var all_tiles: Array[MeshInstance3D] = _get_tiles_matching(false, "")
	for cluster_index in range(cluster_count):
		var center_tile: MeshInstance3D = _pick_cluster_center(rng, all_tiles, false)
		if center_tile == null:
			continue
		var cluster_size: int = rng.randi_range(min_size, max_size)
		_grow_cluster(center_tile, tile_type, cluster_size, rng, false)


func _create_water_ponds() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hex_grid.get("generation_seed")) + 3300
	var all_tiles: Array[MeshInstance3D] = _get_tiles_matching(false, "")
	for pond_index in range(water_pond_count):
		var center_tile: MeshInstance3D = _pick_cluster_center(rng, all_tiles, true)
		if center_tile == null:
			continue
		var cluster_size: int = rng.randi_range(2, 4)
		if rng.randf() > 0.86:
			cluster_size = rng.randi_range(5, 6)
		_grow_cluster(center_tile, "Wasser", cluster_size, rng, true)


func _pick_cluster_center(rng: RandomNumberGenerator, candidates: Array[MeshInstance3D], avoid_existing_special: bool) -> MeshInstance3D:
	if candidates.is_empty():
		return null
	var attempts: int = 0
	while attempts < 80:
		attempts += 1
		var candidate_index: int = rng.randi_range(0, candidates.size() - 1)
		var tile: MeshInstance3D = candidates[candidate_index]
		if tile == null:
			continue
		if _is_edge_tile(tile):
			continue
		if avoid_existing_special and String(tile.get_meta("tile_type")) != "Gras":
			continue
		return tile
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _grow_cluster(center_tile: MeshInstance3D, tile_type: String, target_size: int, rng: RandomNumberGenerator, only_overwrite_grass: bool) -> void:
	var cluster_tiles: Array[MeshInstance3D] = []
	var frontier: Array[MeshInstance3D] = []
	frontier.append(center_tile)
	while not frontier.is_empty() and cluster_tiles.size() < target_size:
		var frontier_index: int = rng.randi_range(0, frontier.size() - 1)
		var tile: MeshInstance3D = frontier[frontier_index]
		frontier.remove_at(frontier_index)
		if tile == null:
			continue
		if cluster_tiles.has(tile):
			continue
		if only_overwrite_grass and String(tile.get_meta("tile_type")) != "Gras":
			continue
		_set_tile_type(tile, tile_type)
		cluster_tiles.append(tile)
		var neighbors: Array[MeshInstance3D] = _get_neighbor_tiles(tile)
		for neighbor in neighbors:
			if neighbor == null:
				continue
			if cluster_tiles.has(neighbor):
				continue
			if only_overwrite_grass and String(neighbor.get_meta("tile_type")) != "Gras":
				continue
			frontier.append(neighbor)


func _reposition_village_center() -> void:
	_clear_existing_village_center()
	var center_tile: MeshInstance3D = _find_best_village_center_tile()
	if center_tile == null:
		var center_tile_value: Variant = tiles_by_coords.get("0:0")
		center_tile = center_tile_value as MeshInstance3D
	if center_tile == null:
		return
	_set_tile_type(center_tile, "Gras")
	_ensure_nearby_forest(center_tile)
	_place_village_center_on_tile(center_tile)


func _clear_existing_village_center() -> void:
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if String(tile.get_meta("building_type", "")) == "village_center":
			var marker: Node = tile.get_node_or_null("Dorfzentrum")
			_remove_child_immediately(tile, marker)
			tile.set_meta("has_building", false)
			tile.set_meta("building_name", "")
			tile.set_meta("building_type", "")
			tile.set_meta("workplace_count", 0)
			tile.set_meta("job_type", "")
			tile.set_meta("assigned_workers", 0)
			tile.set_meta("assigned_resident_id", 0)
			tile.remove_meta("resident_capacity")


func _find_best_village_center_tile() -> MeshInstance3D:
	var best_tile: MeshInstance3D = null
	var best_score: int = -1
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if String(tile.get_meta("tile_type")) != "Gras":
			continue
		if _is_edge_tile(tile):
			continue
		var nearby_forest_count: int = _count_tiles_in_range(tile, "Wald", 2)
		if nearby_forest_count <= 0:
			continue
		var center_distance_score: int = 20 - _distance_from_origin(tile)
		var score: int = nearby_forest_count * 5 + center_distance_score
		if score > best_score:
			best_score = score
			best_tile = tile
	return best_tile


func _ensure_nearby_forest(center_tile: MeshInstance3D) -> void:
	var nearby_forest_count: int = _count_tiles_in_range(center_tile, "Wald", 2)
	if nearby_forest_count > 0:
		return
	var converted_count: int = 0
	var neighbors: Array[MeshInstance3D] = _get_neighbor_tiles(center_tile)
	for neighbor in neighbors:
		if converted_count >= 2:
			return
		if neighbor == null:
			continue
		if String(neighbor.get_meta("tile_type")) == "Wasser":
			continue
		_set_tile_type(neighbor, "Wald")
		converted_count += 1


func _place_village_center_on_tile(tile: MeshInstance3D) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Dorfzentrum"
	var mesh: BoxMesh = BoxMesh.new()
	var hex_size: float = float(hex_grid.get("hex_size"))
	var tile_height: float = float(hex_grid.get("tile_height"))
	mesh.size = Vector3(hex_size * 1.35, hex_size * 0.75, hex_size * 1.35)
	marker.mesh = mesh
	marker.material_override = _make_material(Color(0.72, 0.58, 0.30))
	marker.position = Vector3(0.0, tile_height + hex_size * 0.375, 0.0)
	tile.add_child(marker)
	hex_grid.call("_set_building_meta", tile, "village_center")
	tile.set_meta("nearest_village_center_coords", Vector2i(int(tile.get_meta("q")), int(tile.get_meta("r"))))
	tile.set_meta("resident_capacity", 2)
	hex_grid.set("village_center_tile", tile)
	hex_grid.call("_recalculate_housing_capacity")


func _refresh_village_influence() -> void:
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		tile.set_meta("in_settlement_area", false)
		tile.set_meta("village_center_distance", -1)
		var influence_marker: Node = tile.get_node_or_null("InfluenceMarker")
		_remove_child_immediately(tile, influence_marker)
	hex_grid.call("_update_village_center_influence")


func _remove_child_immediately(parent_node: Node, child_node: Node) -> void:
	if child_node == null:
		return
	if child_node.get_parent() == parent_node:
		parent_node.remove_child(child_node)
	child_node.queue_free()


func _set_tile_type(tile: MeshInstance3D, tile_type: String) -> void:
	tile.set_meta("tile_type", tile_type)
	tile.set_meta("buildable", tile_type != "Wasser")
	if tile_materials.has(tile_type):
		tile.material_override = tile_materials[tile_type]


func _get_tiles_matching(require_inner: bool, tile_type: String) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if require_inner and _is_edge_tile(tile):
			continue
		if not tile_type.is_empty() and String(tile.get_meta("tile_type")) != tile_type:
			continue
		result.append(tile)
	return result


func _get_neighbor_tiles(tile: MeshInstance3D) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	var q: int = int(tile.get_meta("q"))
	var r: int = int(tile.get_meta("r"))
	var adjacent_offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
	for offset in adjacent_offsets:
		var neighbor_value: Variant = tiles_by_coords.get(_coords_key(q + offset.x, r + offset.y))
		var neighbor: MeshInstance3D = neighbor_value as MeshInstance3D
		if neighbor != null:
			result.append(neighbor)
	return result


func _count_tiles_in_range(center_tile: MeshInstance3D, tile_type: String, max_distance: int) -> int:
	var center_q: int = int(center_tile.get_meta("q"))
	var center_r: int = int(center_tile.get_meta("r"))
	var matching_count: int = 0
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if String(tile.get_meta("tile_type")) != tile_type:
			continue
		var distance: int = _hex_distance(center_q, center_r, int(tile.get_meta("q")), int(tile.get_meta("r")))
		if distance <= max_distance:
			matching_count += 1
	return matching_count


func _is_edge_tile(tile: MeshInstance3D) -> bool:
	return _distance_from_origin(tile) >= int(hex_grid.get("radius")) - 1


func _distance_from_origin(tile: MeshInstance3D) -> int:
	return _hex_distance(0, 0, int(tile.get_meta("q")), int(tile.get_meta("r")))


func _hex_distance(from_q: int, from_r: int, to_q: int, to_r: int) -> int:
	var delta_q: int = to_q - from_q
	var delta_r: int = to_r - from_r
	var delta_s: int = -delta_q - delta_r
	return int((abs(delta_q) + abs(delta_r) + abs(delta_s)) / 2)


func _coords_key(q: int, r: int) -> String:
	return "%d:%d" % [q, r]


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
