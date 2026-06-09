extends Node

@export var base_wood_capacity: int = 50
@export var base_stone_capacity: int = 50
@export var base_food_capacity: int = 50
@export var warehouse_capacity_bonus: int = 50
@export var warehouse_wood_cost: int = 20
@export var warehouse_stone_cost: int = 10

@onready var game_world: Node = get_parent()
@onready var hex_grid: Node = get_parent().get_node("HexGrid")
@onready var resource_label: Label = get_parent().get_node("CanvasLayer/ResourceLabel")
@onready var stone_label: Label = get_parent().get_node("CanvasLayer/StoneLabel")
@onready var food_label: Label = get_parent().get_node("CanvasLayer/FoodLabel")
@onready var settlement_content_label: Label = get_parent().get_node("CanvasLayer/SettlementWindow/VBoxContainer/ContentLabel")
@onready var warehouse_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/WarehouseButton")
@onready var lumberjack_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/LumberjackButton")
@onready var house_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/HouseButton")
@onready var stone_mine_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/StoneMineButton")
@onready var berry_gatherer_button: Button = get_parent().get_node("CanvasLayer/BuildMenu/VBoxContainer/BerryGathererButton")

var wood_capacity: int = 50
var stone_capacity: int = 50
var food_capacity: int = 50
var warehouse_count: int = 0
var warehouse_selected: bool = false
var clamping_resource: bool = false


func _ready() -> void:
	_recalculate_storage_capacity()
	hex_grid.wood_changed.connect(_on_wood_changed)
	hex_grid.stone_changed.connect(_on_stone_changed)
	hex_grid.food_changed.connect(_on_food_changed)
	warehouse_button.pressed.connect(_on_warehouse_button_pressed)
	lumberjack_button.pressed.connect(_clear_warehouse_selection)
	house_button.pressed.connect(_clear_warehouse_selection)
	stone_mine_button.pressed.connect(_clear_warehouse_selection)
	berry_gatherer_button.pressed.connect(_clear_warehouse_selection)
	_clamp_all_resources()
	_update_resource_labels()


func _process(_delta: float) -> void:
	_update_resource_labels()
	_update_settlement_resource_lines()
	if warehouse_selected and not bool(hex_grid.get("build_mode")):
		warehouse_selected = false
	var selected_building_type: String = String(hex_grid.get("selected_building_type"))
	if warehouse_selected and not selected_building_type.is_empty():
		warehouse_selected = false


func _input(event: InputEvent) -> void:
	if not warehouse_selected:
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
		_try_place_warehouse_under_mouse()
		get_viewport().set_input_as_handled()


func _on_warehouse_button_pressed() -> void:
	warehouse_selected = true
	hex_grid.set("selected_building_type", "")
	hex_grid.emit_signal("selected_building_changed", "Lagerhaus")


func _clear_warehouse_selection() -> void:
	warehouse_selected = false


func _try_place_warehouse_under_mouse() -> void:
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
		hex_grid.emit_signal("message_changed", "Lagerhaus benötigt Gras")
		return
	if int(hex_grid.get("wood")) < warehouse_wood_cost or int(hex_grid.get("stone")) < warehouse_stone_cost:
		hex_grid.emit_signal("message_changed", "Nicht genug Ressourcen. Lagerhaus kostet 20 Holz und 10 Stein.")
		return
	_place_warehouse(tile)


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


func _place_warehouse(tile: MeshInstance3D) -> void:
	var wood_value: int = int(hex_grid.get("wood")) - warehouse_wood_cost
	var stone_value: int = int(hex_grid.get("stone")) - warehouse_stone_cost
	hex_grid.set("wood", wood_value)
	hex_grid.set("stone", stone_value)
	hex_grid.emit_signal("wood_changed", wood_value)
	hex_grid.emit_signal("stone_changed", stone_value)

	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Lagerhaus"
	var marker_size: float = float(hex_grid.get("hex_size")) * 1.10
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(marker_size, float(hex_grid.get("hex_size")) * 0.75, marker_size)
	marker.mesh = mesh
	marker.material_override = _make_material(Color(0.80, 0.62, 0.28))
	marker.position = Vector3(0.0, float(hex_grid.get("tile_height")) + float(hex_grid.get("hex_size")) * 0.375, 0.0)
	tile.add_child(marker)

	tile.set_meta("has_building", true)
	tile.set_meta("building_name", "Lagerhaus")
	tile.set_meta("building_type", "warehouse")
	tile.set_meta("workplace_count", 0)
	tile.set_meta("job_type", "")
	tile.set_meta("assigned_workers", 0)
	tile.set_meta("assigned_resident_id", 0)
	tile.set_meta("storage_wood", warehouse_capacity_bonus)
	tile.set_meta("storage_stone", warehouse_capacity_bonus)
	tile.set_meta("storage_food", warehouse_capacity_bonus)

	warehouse_count += 1
	_recalculate_storage_capacity()
	hex_grid.emit_signal("message_changed", "Lagerhaus gebaut: -20 Holz, -10 Stein.")
	hex_grid.call("_set_selected_tile", tile)
	hex_grid.call("_emit_hex_selected", tile)


func _recalculate_storage_capacity() -> void:
	wood_capacity = base_wood_capacity + warehouse_count * warehouse_capacity_bonus
	stone_capacity = base_stone_capacity + warehouse_count * warehouse_capacity_bonus
	food_capacity = base_food_capacity + warehouse_count * warehouse_capacity_bonus


func _clamp_all_resources() -> void:
	_clamp_resource("wood", wood_capacity, "wood_changed", "Holz")
	_clamp_resource("stone", stone_capacity, "stone_changed", "Stein")
	_clamp_resource("food", food_capacity, "food_changed", "Nahrung")


func _on_wood_changed(_amount: int) -> void:
	_clamp_resource("wood", wood_capacity, "wood_changed", "Holz")


func _on_stone_changed(_amount: int) -> void:
	_clamp_resource("stone", stone_capacity, "stone_changed", "Stein")


func _on_food_changed(_amount: int) -> void:
	_clamp_resource("food", food_capacity, "food_changed", "Nahrung")


func _clamp_resource(property_name: String, capacity: int, signal_name: String, display_name: String) -> void:
	if clamping_resource:
		return
	var current_value: int = int(hex_grid.get(property_name))
	if current_value <= capacity:
		return
	clamping_resource = true
	hex_grid.set(property_name, capacity)
	hex_grid.emit_signal(signal_name, capacity)
	clamping_resource = false
	hex_grid.call_deferred("emit_signal", "message_changed", "Lager voll: %s" % display_name)


func _update_resource_labels() -> void:
	resource_label.text = "Holz: %d / %d" % [int(hex_grid.get("wood")), wood_capacity]
	stone_label.text = "Stein: %d / %d" % [int(hex_grid.get("stone")), stone_capacity]
	food_label.text = "Nahrung: %d / %d" % [int(hex_grid.get("food")), food_capacity]


func _update_settlement_resource_lines() -> void:
	if settlement_content_label == null:
		return
	if settlement_content_label.text.is_empty():
		return
	var lines: PackedStringArray = settlement_content_label.text.split("\n")
	var in_resource_section: bool = false
	for line_index in range(lines.size()):
		var line_text: String = lines[line_index]
		if line_text == "Ressourcen":
			in_resource_section = true
			continue
		if in_resource_section and line_text.is_empty():
			break
		if not in_resource_section:
			continue
		if line_text.begins_with("Holz:"):
			lines[line_index] = "Holz: %d / %d" % [int(hex_grid.get("wood")), wood_capacity]
		if line_text.begins_with("Stein:"):
			lines[line_index] = "Stein: %d / %d" % [int(hex_grid.get("stone")), stone_capacity]
		if line_text.begins_with("Nahrung:"):
			lines[line_index] = "Nahrung: %d / %d" % [int(hex_grid.get("food")), food_capacity]
	settlement_content_label.text = "\n".join(lines)


func _get_tile_in_settlement_area(tile: MeshInstance3D) -> bool:
	if tile.has_meta("in_settlement_area"):
		return bool(tile.get_meta("in_settlement_area"))
	return false


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
