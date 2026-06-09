extends Node

@export var water_pond_count: int = 4
@export var forest_cluster_count: int = 7
@export var stone_cluster_count: int = 4

@onready var hex_grid: Node = get_parent().get_node("HexGrid")
@onready var settlement_window: PanelContainer = get_parent().get_node("CanvasLayer/SettlementWindow")
@onready var settlement_content_label: Label = get_parent().get_node("CanvasLayer/SettlementWindow/VBoxContainer/ContentLabel")
@onready var info_panel: PanelContainer = get_parent().get_node("CanvasLayer/InfoPanel")

var tile_materials: Dictionary = {}
var tiles_by_coords: Dictionary = {}


func _ready() -> void:
	call_deferred("_run_world_generation")


func _process(_delta: float) -> void:
	_update_seed_display()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_N:
			_regenerate_with_random_seed()
			get_viewport().set_input_as_handled()


func _run_world_generation() -> void:
	tile_materials = hex_grid.get("tile_materials") as Dictionary
	tiles_by_coords = hex_grid.get("tiles_by_coords") as Dictionary
	if tiles_by_coords.is_empty():
		return
	_generate_clustered_world()
	_reposition_village_center()
	_refresh_village_influence()


func _regenerate_with_random_seed() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var new_seed: int = rng.randi_range(1, 2147483647)
	hex_grid.set("generation_seed", new_seed)
	_regenerate_current_world()
	hex_grid.emit_signal("message_changed", "Neue Welt: Seed %d" % new_seed)


func _regenerate_current_world() -> void:
	tile_materials = hex_grid.get("tile_materials") as Dictionary
	tiles_by_coords = hex_grid.get("tiles_by_coords") as Dictionary
	if tiles_by_coords.is_empty():
		return
	_reset_selection_and_build_mode()
	_reset_runtime_controllers()
	_clear_all_buildings()
	_reset_hex_grid_runtime_state()
	_generate_clustered_world()
	_reposition_village_center()
	_refresh_village_influence()
	_reset_population_to_start()
	_update_seed_display()


func _reset_selection_and_build_mode() -> void:
	hex_grid.set("build_mode", false)
	hex_grid.emit_signal("build_mode_changed", false)
	hex_grid.call("clear_selected_building")
	hex_grid.call("_clear_selection")
	info_panel.visible = false


func _reset_runtime_controllers() -> void:
	var farm_controller: Node = get_parent().get_node_or_null("FarmController")
	if farm_controller != null:
		farm_controller.set("farm_tiles", Array([], TYPE_OBJECT, "MeshInstance3D", null))
		farm_controller.set("farmer_count", 0)
		farm_controller.set("production_timer", 0.0)
		farm_controller.set("farm_selected", false)
	var storage_controller: Node = get_parent().get_node_or_null("StorageController")
	if storage_controller != null:
		storage_controller.set("warehouse_count", 0)
		storage_controller.set("warehouse_selected", false)
		storage_controller.call("_recalculate_storage_capacity")


func _clear_all_buildings() -> void:
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		_remove_building_children(tile)
		tile.set_meta("has_building", false)
		tile.set_meta("building_name", "")
		tile.set_meta("building_type", "")
		tile.set_meta("workplace_count", 0)
		tile.set_meta("job_type", "")
		tile.set_meta("assigned_workers", 0)
		tile.set_meta("assigned_resident_id", 0)
		_remove_optional_meta(tile, "resident_capacity")
		_remove_optional_meta(tile, "current_residents")
		_remove_optional_meta(tile, "own_forest")
		_remove_optional_meta(tile, "adjacent_forests")
		_remove_optional_meta(tile, "lumberjack_production")
		_remove_optional_meta(tile, "own_stone")
		_remove_optional_meta(tile, "adjacent_stones")
		_remove_optional_meta(tile, "stone_mine_production")
		_remove_optional_meta(tile, "food_production")
		_remove_optional_meta(tile, "storage_wood")
		_remove_optional_meta(tile, "storage_stone")
		_remove_optional_meta(tile, "storage_food")
		_remove_optional_meta(tile, "nearest_village_center_coords")


func _remove_building_children(tile: MeshInstance3D) -> void:
	var children: Array[Node] = []
	for child in tile.get_children():
		var child_node: Node = child as Node
		if child_node == null:
			continue
		if child_node.name == "ClickBody" or child_node.name == "InfluenceMarker":
			continue
		children.append(child_node)
	for child_node in children:
		_remove_child_immediately(tile, child_node)


func _reset_hex_grid_runtime_state() -> void:
	hex_grid.set("lumberjack_hut_tiles", Array([], TYPE_OBJECT, "MeshInstance3D", null))
	hex_grid.set("stone_mine_tiles", Array([], TYPE_OBJECT, "MeshInstance3D", null))
	hex_grid.set("berry_gatherer_tiles", Array([], TYPE_OBJECT, "MeshInstance3D", null))
	hex_grid.set("production_timer", 0.0)
	hex_grid.set("food_consumption_timer", 0.0)
	hex_grid.set("wood", int(hex_grid.get("starting_wood")))
	hex_grid.set("stone", int(hex_grid.get("starting_stone")))
	hex_grid.set("food", int(hex_grid.get("starting_food")))
	hex_grid.set("residents", Array([], TYPE_DICTIONARY, "", null))
	hex_grid.set("lumberjack_count", 0)
	hex_grid.set("miner_count", 0)
	hex_grid.set("berry_gatherer_count", 0)
	hex_grid.set("workplace_count", 0)
	hex_grid.set("assigned_workplace_count", 0)
	hex_grid.set("free_workplace_count", 0)
	hex_grid.set("unemployed_count", 0)
	hex_grid.emit_signal("wood_changed", int(hex_grid.get("wood")))
	hex_grid.emit_signal("stone_changed", int(hex_grid.get("stone")))
	hex_grid.emit_signal("food_changed", int(hex_grid.get("food")))
	hex_grid.emit_signal("work_changed", 0, 0, 0, 0, 0)


func _reset_population_to_start() -> void:
	hex_grid.call("_recalculate_housing_capacity")
	hex_grid.call("_set_population", int(hex_grid.get("starting_population")))


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
			_remove_optional_meta(tile, "resident_capacity")


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


func _update_seed_display() -> void:
	if not settlement_window.visible:
		return
	if settlement_content_label.text.is_empty():
		return
	var lines: PackedStringArray = settlement_content_label.text.split("\n")
	var seed_text: String = "Seed: %d" % int(hex_grid.get("generation_seed"))
	if lines.size() > 0 and lines[0].begins_with("Seed:"):
		lines[0] = seed_text
	else:
		lines.insert(0, seed_text)
	settlement_content_label.text = "\n".join(lines)


func _remove_optional_meta(tile: MeshInstance3D, meta_name: String) -> void:
	if tile.has_meta(meta_name):
		tile.remove_meta(meta_name)


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
