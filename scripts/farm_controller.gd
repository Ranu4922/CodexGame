extends Node

@export var farm_wood_cost: int = 15
@export var farm_stone_cost: int = 5
@export var farm_food_production: int = 3

@onready var hex_grid: Node = get_parent().get_node("HexGrid")
@onready var farm_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/FarmButton")
@onready var lumberjack_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/LumberjackButton")
@onready var house_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/HouseButton")
@onready var stone_mine_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/StoneMineButton")
@onready var berry_gatherer_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/BerryGathererButton")
@onready var warehouse_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/WarehouseButton")

var farm_tiles: Array[MeshInstance3D] = []
var farm_selected: bool = false
var farmer_count: int = 0
var production_timer: float = 0.0


func _ready() -> void:
	farm_button.pressed.connect(_on_farm_button_pressed)
	lumberjack_button.pressed.connect(_clear_farm_selection)
	house_button.pressed.connect(_clear_farm_selection)
	stone_mine_button.pressed.connect(_clear_farm_selection)
	berry_gatherer_button.pressed.connect(_clear_farm_selection)
	warehouse_button.pressed.connect(_clear_farm_selection)
	hex_grid.population_changed.connect(_on_population_changed)
	hex_grid.work_changed.connect(_on_work_changed)
	_update_farm_button_style()


func _process(delta: float) -> void:
	if farm_selected and not bool(hex_grid.get("build_mode")):
		farm_selected = false
	var selected_building_type: String = String(hex_grid.get("selected_building_type"))
	if farm_selected and selected_building_type != "farm":
		farm_selected = false
	_update_farm_button_style()
	_update_production_timer(delta)


func _input(event: InputEvent) -> void:
	if not farm_selected:
		return
	if not bool(hex_grid.get("build_mode")):
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		var hovered_control: Control = get_viewport().gui_get_hovered_control()
		if hovered_control != null:
			return
		_try_place_farm_under_mouse()
		get_viewport().set_input_as_handled()


func _on_farm_button_pressed() -> void:
	farm_selected = true
	hex_grid.set("selected_building_type", "farm")
	hex_grid.emit_signal("selected_building_changed", "Bauernhof")


func _clear_farm_selection() -> void:
	farm_selected = false


func _try_place_farm_under_mouse() -> void:
	var tile: MeshInstance3D = _get_tile_under_mouse()
	if tile == null:
		return
	if not bool(tile.get_meta("buildable")):
		hex_grid.emit_signal("message_changed", "Kann hier nicht bauen: Feld ist nicht bebaubar.")
		return
	if bool(tile.get_meta("has_building")):
		hex_grid.emit_signal("message_changed", "Kann hier nicht bauen: Feld hat bereits ein Gebäude.")
		return
	if not _get_tile_in_settlement_area(tile):
		hex_grid.emit_signal("message_changed", "Außerhalb des Siedlungsgebiets")
		return
	if String(tile.get_meta("tile_type")) != "Gras":
		hex_grid.emit_signal("message_changed", "Bauernhof benötigt Gras")
		return
	if int(hex_grid.get("wood")) < farm_wood_cost or int(hex_grid.get("stone")) < farm_stone_cost:
		hex_grid.emit_signal("message_changed", "Nicht genug Ressourcen. Bauernhof kostet 15 Holz und 5 Stein.")
		return
	_place_farm(tile)


func _get_tile_under_mouse() -> MeshInstance3D:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return null
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_position) * 1000.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result: Dictionary = get_parent().get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var collider: Node = result["collider"] as Node
	if collider == null:
		return null
	var tile_node: Node = collider.get_parent()
	if tile_node is MeshInstance3D and tile_node.has_meta("q") and tile_node.has_meta("r"):
		return tile_node as MeshInstance3D
	return null


func _place_farm(tile: MeshInstance3D) -> void:
	var wood_value: int = int(hex_grid.get("wood")) - farm_wood_cost
	var stone_value: int = int(hex_grid.get("stone")) - farm_stone_cost
	hex_grid.set("wood", wood_value)
	hex_grid.set("stone", stone_value)
	hex_grid.emit_signal("wood_changed", wood_value)
	hex_grid.emit_signal("stone_changed", stone_value)

	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Bauernhof"
	var marker_size: float = float(hex_grid.get("hex_size")) * 1.20
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(marker_size, float(hex_grid.get("hex_size")) * 0.45, marker_size)
	marker.mesh = mesh
	marker.material_override = _make_material(Color(0.42, 0.62, 0.18))
	marker.position = Vector3(0.0, float(hex_grid.get("tile_height")) + float(hex_grid.get("hex_size")) * 0.225, 0.0)
	tile.add_child(marker)

	tile.set_meta("has_building", true)
	tile.set_meta("building_name", "Bauernhof")
	tile.set_meta("building_type", "farm")
	tile.set_meta("workplace_count", 1)
	tile.set_meta("job_type", "Bauer")
	tile.set_meta("assigned_workers", 0)
	tile.set_meta("assigned_resident_id", 0)
	tile.set_meta("food_production", farm_food_production)
	tile.set_meta("nearest_village_center_coords", hex_grid.call("_get_nearest_village_center_coords"))

	farm_tiles.append(tile)
	_update_farm_assignments()
	hex_grid.emit_signal("message_changed", "Bauernhof gebaut: -15 Holz, -5 Stein.")
	hex_grid.call("_set_selected_tile", tile)
	hex_grid.call("_emit_hex_selected", tile)
	_sync_parent_world_data()


func _sync_parent_world_data() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	if parent_node.has_method("sync_world_data"):
		parent_node.call("sync_world_data")


func _update_production_timer(delta: float) -> void:
	if farm_tiles.is_empty():
		return
	production_timer += delta
	var production_interval: float = float(hex_grid.get("production_interval"))
	while production_timer >= production_interval:
		production_timer -= production_interval
		_run_farm_production_cycle()


func _run_farm_production_cycle() -> void:
	_update_farm_assignments()
	var produced_food: int = get_farm_food_production_per_cycle()
	if produced_food <= 0:
		return
	var food_value: int = int(hex_grid.get("food")) + produced_food
	hex_grid.set("food", food_value)
	hex_grid.emit_signal("food_changed", food_value)
	hex_grid.emit_signal("message_changed", "+%d Nahrung" % produced_food)


func get_farm_food_production_per_cycle() -> int:
	var produced_food: int = 0
	for tile in farm_tiles:
		if int(tile.get_meta("assigned_workers")) > 0:
			produced_food += int(tile.get_meta("food_production"))
	return produced_food


func _on_population_changed(_amount: int) -> void:
	_update_farm_assignments_deferred()


func _on_work_changed(_unemployed: int, _lumberjacks: int, _miners: int, _workplaces: int, _free_workplaces: int) -> void:
	_update_farm_assignments_deferred()


func _update_farm_assignments_deferred() -> void:
	await get_tree().process_frame
	_update_farm_assignments()


func _update_farm_assignments() -> void:
	_clear_farm_jobs_from_residents()
	var used_resident_ids: Dictionary = _get_used_non_farm_resident_ids()
	for tile in farm_tiles:
		var assigned_resident_id: int = int(tile.get_meta("assigned_resident_id"))
		if assigned_resident_id <= 0 or used_resident_ids.has(assigned_resident_id) or not _resident_exists(assigned_resident_id):
			tile.set_meta("assigned_resident_id", 0)
			tile.set_meta("assigned_workers", 0)
			continue
		_set_resident_farm_job(assigned_resident_id, tile)
		used_resident_ids[assigned_resident_id] = true
		tile.set_meta("assigned_workers", 1)

	for tile in farm_tiles:
		if int(tile.get_meta("assigned_workers")) > 0:
			continue
		var free_resident_id: int = _get_next_free_resident_id(used_resident_ids)
		if free_resident_id <= 0:
			break
		tile.set_meta("assigned_resident_id", free_resident_id)
		tile.set_meta("assigned_workers", 1)
		_set_resident_farm_job(free_resident_id, tile)
		used_resident_ids[free_resident_id] = true

	_recalculate_farmer_count()


func _clear_farm_jobs_from_residents() -> void:
	var resident_list: Array = hex_grid.get("residents") as Array
	for resident_index in range(resident_list.size()):
		var resident_data: Dictionary = resident_list[resident_index] as Dictionary
		if String(resident_data["job"]) == "Bauer":
			resident_data["job"] = ""
			resident_data["workplace_key"] = ""
			resident_list[resident_index] = resident_data


func _get_used_non_farm_resident_ids() -> Dictionary:
	var used_resident_ids: Dictionary = {}
	var resident_list: Array = hex_grid.get("residents") as Array
	for resident_data_value in resident_list:
		var resident_data: Dictionary = resident_data_value as Dictionary
		var job_name: String = String(resident_data["job"])
		if not job_name.is_empty() and job_name != "Bauer":
			used_resident_ids[int(resident_data["id"])] = true
	return used_resident_ids


func _get_next_free_resident_id(used_resident_ids: Dictionary) -> int:
	var resident_list: Array = hex_grid.get("residents") as Array
	for resident_data_value in resident_list:
		var resident_data: Dictionary = resident_data_value as Dictionary
		var resident_id: int = int(resident_data["id"])
		if used_resident_ids.has(resident_id):
			continue
		if String(resident_data["job"]).is_empty():
			return resident_id
	return 0


func _resident_exists(resident_id: int) -> bool:
	var resident_list: Array = hex_grid.get("residents") as Array
	for resident_data_value in resident_list:
		var resident_data: Dictionary = resident_data_value as Dictionary
		if int(resident_data["id"]) == resident_id:
			return true
	return false


func _set_resident_farm_job(resident_id: int, tile: MeshInstance3D) -> void:
	var resident_list: Array = hex_grid.get("residents") as Array
	for resident_index in range(resident_list.size()):
		var resident_data: Dictionary = resident_list[resident_index] as Dictionary
		if int(resident_data["id"]) == resident_id:
			resident_data["job"] = "Bauer"
			resident_data["workplace_key"] = "%d:%d" % [int(tile.get_meta("q")), int(tile.get_meta("r"))]
			resident_list[resident_index] = resident_data
			return


func _recalculate_farmer_count() -> void:
	farmer_count = 0
	for tile in farm_tiles:
		if int(tile.get_meta("assigned_workers")) > 0:
			farmer_count += 1


func get_adjusted_unemployed_count() -> int:
	var adjusted_unemployed: int = int(hex_grid.get("population")) - int(hex_grid.get("assigned_workplace_count")) - farmer_count
	if adjusted_unemployed < 0:
		adjusted_unemployed = 0
	return adjusted_unemployed


func get_total_workplaces() -> int:
	return int(hex_grid.get("workplace_count")) + farm_tiles.size()


func get_assigned_workplaces() -> int:
	return int(hex_grid.get("assigned_workplace_count")) + farmer_count


func get_free_workplaces() -> int:
	var free_workplaces: int = get_total_workplaces() - get_assigned_workplaces()
	if free_workplaces < 0:
		free_workplaces = 0
	return free_workplaces


func _update_farm_button_style() -> void:
	var selected: bool = farm_selected or String(hex_grid.get("selected_building_type")) == "farm"
	var affordable: bool = int(hex_grid.get("wood")) >= farm_wood_cost and int(hex_grid.get("stone")) >= farm_stone_cost
	var background_color: Color = Color(0.09, 0.10, 0.10, 0.90)
	var border_color: Color = Color(0.22, 0.24, 0.24, 1.0)
	var font_color: Color = Color(0.92, 0.92, 0.88, 1.0)
	var border_width: int = 1
	if not affordable:
		font_color = Color(0.95, 0.38, 0.32, 1.0)
	if selected:
		background_color = Color(0.22, 0.34, 0.20, 0.95)
		border_color = Color(0.45, 0.86, 0.38, 1.0)
		font_color = Color(1.0, 1.0, 0.92, 1.0)
		border_width = 2
	farm_button.add_theme_stylebox_override("normal", _make_button_style(background_color, border_color, border_width))
	farm_button.add_theme_stylebox_override("hover", _make_button_style(background_color.lightened(0.08), border_color, border_width))
	farm_button.add_theme_stylebox_override("pressed", _make_button_style(background_color.darkened(0.08), border_color, border_width))
	farm_button.add_theme_stylebox_override("focus", _make_button_style(background_color, border_color, border_width))
	farm_button.add_theme_color_override("font_color", font_color)
	farm_button.add_theme_color_override("font_hover_color", font_color)
	farm_button.add_theme_color_override("font_pressed_color", font_color)


func _get_tile_in_settlement_area(tile: MeshInstance3D) -> bool:
	if tile.has_meta("in_settlement_area"):
		return bool(tile.get_meta("in_settlement_area"))
	return false


func _make_button_style(background_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.set_content_margin(SIDE_LEFT, 8.0)
	style.set_content_margin(SIDE_RIGHT, 8.0)
	style.set_content_margin(SIDE_TOP, 5.0)
	style.set_content_margin(SIDE_BOTTOM, 5.0)
	return style


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
