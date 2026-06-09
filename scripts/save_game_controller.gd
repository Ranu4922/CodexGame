extends Node

const SAVE_PATH: String = "res://savegames/test_save.json"
const SAVE_DIR: String = "res://savegames"

@onready var hex_grid: Node = get_parent().get_node("HexGrid")
@onready var world_generation_controller: Node = get_parent().get_node("WorldGenerationController")
@onready var farm_controller: Node = get_parent().get_node("FarmController")
@onready var storage_controller: Node = get_parent().get_node("StorageController")
@onready var game_world: Node = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_F5:
			save_game()
			get_viewport().set_input_as_handled()
		if key_event.keycode == KEY_F9:
			load_game()
			get_viewport().set_input_as_handled()


func save_game() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var save_file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		hex_grid.emit_signal("message_changed", "Speichern fehlgeschlagen")
		return
	var save_data: Dictionary = _create_save_data()
	var json_text: String = JSON.stringify(save_data, "\t")
	save_file.store_string(json_text)
	save_file.close()
	hex_grid.emit_signal("message_changed", "Spiel gespeichert")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		hex_grid.emit_signal("message_changed", "Kein Savegame gefunden")
		return
	var save_file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		hex_grid.emit_signal("message_changed", "Laden fehlgeschlagen")
		return
	var json_text: String = save_file.get_as_text()
	save_file.close()
	var parsed_data: Variant = JSON.parse_string(json_text)
	if not (parsed_data is Dictionary):
		hex_grid.emit_signal("message_changed", "Savegame ist ungueltig")
		return
	var save_data: Dictionary = parsed_data as Dictionary
	_apply_save_data(save_data)
	hex_grid.emit_signal("message_changed", "Spiel geladen")


func _create_save_data() -> Dictionary:
	var save_data: Dictionary = {
		"version": 1,
		"seed": int(hex_grid.get("generation_seed")),
		"resources": _create_resource_save_data(),
		"population": _create_population_save_data(),
		"settlement": _create_settlement_save_data(),
		"buildings": _create_building_save_data(),
	}
	return save_data


func _create_resource_save_data() -> Dictionary:
	return {
		"wood": int(hex_grid.get("wood")),
		"stone": int(hex_grid.get("stone")),
		"food": int(hex_grid.get("food")),
	}


func _create_population_save_data() -> Dictionary:
	return {
		"residents": int(hex_grid.get("population")),
		"resident_data": _copy_resident_data(),
		"housing_capacity": int(hex_grid.get("housing_capacity")),
		"free_housing": int(hex_grid.get("free_housing")),
	}


func _copy_resident_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var resident_list: Array = hex_grid.get("residents") as Array
	for resident_value in resident_list:
		var resident_data: Dictionary = resident_value as Dictionary
		result.append(resident_data.duplicate(true))
	return result


func _create_settlement_save_data() -> Dictionary:
	var village_center_data: Dictionary = {}
	var village_center_tile: MeshInstance3D = hex_grid.get("village_center_tile") as MeshInstance3D
	if village_center_tile != null:
		village_center_data = _create_tile_coords_data(village_center_tile)
	return {
		"name": "Dorfzentrum",
		"village_center": village_center_data,
		"influence_radius": int(hex_grid.get("village_center_influence_radius")),
		"housing_capacity": int(hex_grid.get("housing_capacity")),
		"workplaces": _get_total_workplaces(),
		"assigned_workplaces": _get_total_assigned_workplaces(),
		"free_workplaces": _get_total_free_workplaces(),
	}


func _create_building_save_data() -> Array[Dictionary]:
	var buildings: Array[Dictionary] = []
	var tiles_by_coords: Dictionary = hex_grid.get("tiles_by_coords") as Dictionary
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if not bool(tile.get_meta("has_building")):
			continue
		var building_data: Dictionary = _create_tile_coords_data(tile)
		building_data["type"] = String(tile.get_meta("building_type", ""))
		building_data["name"] = String(tile.get_meta("building_name", ""))
		building_data["tile_type"] = String(tile.get_meta("tile_type", ""))
		building_data["assigned_resident_id"] = int(tile.get_meta("assigned_resident_id", 0))
		buildings.append(building_data)
	return buildings


func _create_tile_coords_data(tile: MeshInstance3D) -> Dictionary:
	return {
		"q": int(tile.get_meta("q")),
		"r": int(tile.get_meta("r")),
	}


func _apply_save_data(save_data: Dictionary) -> void:
	var seed: int = _read_int(save_data, "seed", int(hex_grid.get("generation_seed")))
	hex_grid.set("generation_seed", seed)
	world_generation_controller.call("_regenerate_current_world")
	world_generation_controller.call("_clear_all_buildings")
	_clear_runtime_building_state()
	_apply_saved_buildings(save_data)
	world_generation_controller.call("_refresh_village_influence")
	_refresh_storage_capacity()
	hex_grid.call("_recalculate_housing_capacity")
	_apply_saved_population(save_data)
	_update_work_after_load()
	_apply_saved_resources(save_data)
	_refresh_selection_after_load()
	_refresh_settlement_window_after_load()


func _clear_runtime_building_state() -> void:
	var lumberjack_hut_tiles: Array = hex_grid.get("lumberjack_hut_tiles") as Array
	lumberjack_hut_tiles.clear()
	var stone_mine_tiles: Array = hex_grid.get("stone_mine_tiles") as Array
	stone_mine_tiles.clear()
	var berry_gatherer_tiles: Array = hex_grid.get("berry_gatherer_tiles") as Array
	berry_gatherer_tiles.clear()
	var farm_tiles: Array = farm_controller.get("farm_tiles") as Array
	farm_tiles.clear()
	farm_controller.set("farmer_count", 0)
	farm_controller.set("production_timer", 0.0)
	farm_controller.set("farm_selected", false)
	storage_controller.set("warehouse_count", 0)
	storage_controller.set("warehouse_selected", false)
	hex_grid.set("production_timer", 0.0)
	hex_grid.set("food_consumption_timer", 0.0)


func _apply_saved_buildings(save_data: Dictionary) -> void:
	var buildings: Array = _read_array(save_data, "buildings")
	var village_center_data: Dictionary = _find_village_center_data(save_data, buildings)
	if not village_center_data.is_empty():
		_place_saved_village_center(village_center_data)
	else:
		world_generation_controller.call("_reposition_village_center")
	for building_value in buildings:
		var building_data: Dictionary = building_value as Dictionary
		var building_type: String = String(building_data.get("type", ""))
		if building_type == "village_center":
			continue
		_place_saved_building(building_data)


func _find_village_center_data(save_data: Dictionary, buildings: Array) -> Dictionary:
	for building_value in buildings:
		var building_data: Dictionary = building_value as Dictionary
		if String(building_data.get("type", "")) == "village_center":
			return building_data
	if save_data.has("settlement"):
		var settlement_data: Dictionary = save_data["settlement"] as Dictionary
		if settlement_data.has("village_center"):
			var village_center_value: Variant = settlement_data["village_center"]
			if village_center_value is Dictionary:
				return village_center_value as Dictionary
	return {}


func _place_saved_village_center(building_data: Dictionary) -> void:
	var tile: MeshInstance3D = _get_tile_from_data(building_data)
	if tile == null:
		return
	world_generation_controller.call("_place_village_center_on_tile", tile)


func _place_saved_building(building_data: Dictionary) -> void:
	var tile: MeshInstance3D = _get_tile_from_data(building_data)
	if tile == null:
		return
	if bool(tile.get_meta("has_building")):
		return
	var building_type: String = String(building_data.get("type", ""))
	if building_type == "house":
		hex_grid.call("_place_house", tile)
	if building_type == "lumberjack_hut":
		hex_grid.call("_place_lumberjack_hut", tile)
	if building_type == "stone_mine":
		hex_grid.call("_place_stone_mine", tile)
	if building_type == "berry_gatherer":
		hex_grid.call("_place_berry_gatherer", tile)
	if building_type == "farm":
		_place_saved_farm(tile)
	if building_type == "warehouse":
		_place_saved_warehouse(tile)


func _place_saved_farm(tile: MeshInstance3D) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Bauernhof"
	var hex_size: float = float(hex_grid.get("hex_size"))
	var tile_height: float = float(hex_grid.get("tile_height"))
	var marker_size: float = hex_size * 1.20
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(marker_size, hex_size * 0.45, marker_size)
	marker.mesh = mesh
	marker.material_override = _make_material(Color(0.42, 0.62, 0.18))
	marker.position = Vector3(0.0, tile_height + hex_size * 0.225, 0.0)
	tile.add_child(marker)
	tile.set_meta("has_building", true)
	tile.set_meta("building_name", "Bauernhof")
	tile.set_meta("building_type", "farm")
	tile.set_meta("workplace_count", 1)
	tile.set_meta("job_type", "Bauer")
	tile.set_meta("assigned_workers", 0)
	tile.set_meta("assigned_resident_id", 0)
	tile.set_meta("food_production", int(farm_controller.get("farm_food_production")))
	tile.set_meta("nearest_village_center_coords", hex_grid.call("_get_nearest_village_center_coords"))
	var farm_tiles: Array = farm_controller.get("farm_tiles") as Array
	farm_tiles.append(tile)


func _place_saved_warehouse(tile: MeshInstance3D) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Lagerhaus"
	var hex_size: float = float(hex_grid.get("hex_size"))
	var tile_height: float = float(hex_grid.get("tile_height"))
	var marker_size: float = hex_size * 1.10
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(marker_size, hex_size * 0.75, marker_size)
	marker.mesh = mesh
	marker.material_override = _make_material(Color(0.80, 0.62, 0.28))
	marker.position = Vector3(0.0, tile_height + hex_size * 0.375, 0.0)
	tile.add_child(marker)
	tile.set_meta("has_building", true)
	tile.set_meta("building_name", "Lagerhaus")
	tile.set_meta("building_type", "warehouse")
	tile.set_meta("workplace_count", 0)
	tile.set_meta("job_type", "")
	tile.set_meta("assigned_workers", 0)
	tile.set_meta("assigned_resident_id", 0)
	var warehouse_capacity_bonus: int = int(storage_controller.get("warehouse_capacity_bonus"))
	tile.set_meta("storage_wood", warehouse_capacity_bonus)
	tile.set_meta("storage_stone", warehouse_capacity_bonus)
	tile.set_meta("storage_food", warehouse_capacity_bonus)
	var warehouse_count: int = int(storage_controller.get("warehouse_count")) + 1
	storage_controller.set("warehouse_count", warehouse_count)


func _apply_saved_population(save_data: Dictionary) -> void:
	var population_data: Dictionary = _read_dictionary(save_data, "population")
	var saved_population: int = _read_int(population_data, "residents", int(hex_grid.get("starting_population")))
	hex_grid.call("_set_population", saved_population)


func _apply_saved_resources(save_data: Dictionary) -> void:
	var resources: Dictionary = _read_dictionary(save_data, "resources")
	var wood: int = _read_int(resources, "wood", int(hex_grid.get("starting_wood")))
	var stone: int = _read_int(resources, "stone", int(hex_grid.get("starting_stone")))
	var food: int = _read_int(resources, "food", int(hex_grid.get("starting_food")))
	hex_grid.set("wood", wood)
	hex_grid.set("stone", stone)
	hex_grid.set("food", food)
	hex_grid.emit_signal("wood_changed", wood)
	hex_grid.emit_signal("stone_changed", stone)
	hex_grid.emit_signal("food_changed", food)


func _update_work_after_load() -> void:
	hex_grid.call("_update_work_assignments")
	farm_controller.call("_update_farm_assignments")


func _refresh_storage_capacity() -> void:
	storage_controller.call("_recalculate_storage_capacity")


func _refresh_selection_after_load() -> void:
	hex_grid.call("_clear_selection")
	hex_grid.set("build_mode", false)
	hex_grid.emit_signal("build_mode_changed", false)
	hex_grid.call("clear_selected_building")


func _refresh_settlement_window_after_load() -> void:
	if game_world.has_method("_update_settlement_window"):
		game_world.call("_update_settlement_window")


func _get_tile_from_data(building_data: Dictionary) -> MeshInstance3D:
	var q: int = _read_int(building_data, "q", 0)
	var r: int = _read_int(building_data, "r", 0)
	var tiles_by_coords: Dictionary = hex_grid.get("tiles_by_coords") as Dictionary
	var tile_value: Variant = tiles_by_coords.get(_coords_key(q, r))
	return tile_value as MeshInstance3D


func _get_total_workplaces() -> int:
	return int(farm_controller.call("get_total_workplaces"))


func _get_total_assigned_workplaces() -> int:
	return int(farm_controller.call("get_assigned_workplaces"))


func _get_total_free_workplaces() -> int:
	return int(farm_controller.call("get_free_workplaces"))


func _read_dictionary(data: Dictionary, key: String) -> Dictionary:
	if not data.has(key):
		return {}
	var value: Variant = data[key]
	if value is Dictionary:
		return value as Dictionary
	return {}


func _read_array(data: Dictionary, key: String) -> Array:
	if not data.has(key):
		return []
	var value: Variant = data[key]
	if value is Array:
		return value as Array
	return []


func _read_int(data: Dictionary, key: String, default_value: int) -> int:
	if not data.has(key):
		return default_value
	return int(data[key])


func _coords_key(q: int, r: int) -> String:
	return "%d:%d" % [q, r]


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
