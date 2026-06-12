extends Node

@export var upgrade_wood_cost: int = 10
@export var upgrade_stone_cost: int = 5
@export var max_upgrade_level: int = 2

@onready var hex_grid: Node = get_parent().get_node("HexGrid")
@onready var canvas_layer: CanvasLayer = get_parent().get_node("CanvasLayer")
@onready var building_detail_panel: PanelContainer = get_parent().get_node("CanvasLayer/BuildingDetailPanel")
@onready var building_detail_label: Label = get_parent().get_node("CanvasLayer/BuildingDetailPanel/BuildingDetailLabel")

var upgrade_button: Button
var selected_tile: MeshInstance3D
var upgradeable_building_types: Array[String] = ["lumberjack_hut", "stone_mine", "berry_gatherer", "farm"]


func _ready() -> void:
	_create_upgrade_button()
	hex_grid.hex_selected.connect(_on_hex_selected)
	hex_grid.selection_cleared.connect(_on_selection_cleared)


func _process(_delta: float) -> void:
	_clear_upgrade_meta_from_empty_tiles()


func _create_upgrade_button() -> void:
	upgrade_button = Button.new()
	upgrade_button.name = "UpgradeButton"
	upgrade_button.text = "Upgrade"
	upgrade_button.visible = false
	upgrade_button.custom_minimum_size = Vector2(140.0, 34.0)
	upgrade_button.z_index = 100
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	_apply_upgrade_button_style()
	canvas_layer.add_child(upgrade_button)


func _apply_upgrade_button_style() -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.22, 0.48, 0.24, 0.95)
	normal_style.border_color = Color(0.65, 0.95, 0.62, 1.0)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.28, 0.60, 0.30, 0.98)

	var disabled_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.22, 0.22, 0.22, 0.90)
	disabled_style.border_color = Color(0.45, 0.45, 0.45, 1.0)

	upgrade_button.add_theme_stylebox_override("normal", normal_style)
	upgrade_button.add_theme_stylebox_override("hover", hover_style)
	upgrade_button.add_theme_stylebox_override("pressed", hover_style)
	upgrade_button.add_theme_stylebox_override("disabled", disabled_style)
	upgrade_button.add_theme_color_override("font_color", Color.WHITE)
	upgrade_button.add_theme_color_override("font_disabled_color", Color(0.65, 0.65, 0.65))


func _on_hex_selected(
	_q: int,
	_r: int,
	_tile_type: String,
	_buildable: bool,
	_has_building: bool,
	_building_name: String,
	_assigned_workers: int,
	_assigned_job: String,
	_own_forest: bool,
	_adjacent_forests: int,
	_wood_production: int,
	_food_production: int,
	_own_stone: bool,
	_adjacent_stones: int,
	_stone_production: int,
	_in_settlement_area: bool,
	_village_center_distance: int
) -> void:
	selected_tile = hex_grid.get("selected_tile") as MeshInstance3D
	_update_upgrade_ui_deferred()


func _update_upgrade_ui_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_update_upgrade_info_text()
	await get_tree().process_frame
	_update_upgrade_button()


func _update_upgrade_info_text() -> void:
	if selected_tile == null:
		return
	if not _is_upgradeable_building(selected_tile):
		return
	if building_detail_label.text.is_empty():
		return
	var level: int = get_building_level(selected_tile)
	var lines: PackedStringArray = building_detail_label.text.split("\n")
	lines.append("Stufe: %d" % level)
	if can_upgrade_building(selected_tile):
		lines.append("Upgradekosten: %d Holz, %d Stein" % [upgrade_wood_cost, upgrade_stone_cost])
		lines.append("")
		lines.append("")
	building_detail_label.text = "\n".join(lines)
	if get_parent().has_method("_set_building_detail_panel_text"):
		get_parent().call("_set_building_detail_panel_text", building_detail_label.text)


func _update_upgrade_button() -> void:
	if selected_tile == null or not _is_upgradeable_building(selected_tile):
		upgrade_button.visible = false
		return
	if not can_upgrade_building(selected_tile):
		upgrade_button.visible = false
		return
	if not building_detail_panel.visible:
		upgrade_button.visible = false
		return
	upgrade_button.visible = true
	upgrade_button.disabled = not _has_upgrade_resources()
	upgrade_button.size = Vector2(140.0, 34.0)
	var panel_position: Vector2 = building_detail_panel.global_position
	var panel_size: Vector2 = building_detail_panel.size
	var button_size: Vector2 = upgrade_button.size
	var button_x: float = panel_position.x + 14.0
	var button_y: float = panel_position.y + panel_size.y - button_size.y - 14.0
	upgrade_button.global_position = Vector2(button_x, button_y)
	upgrade_button.move_to_front()


func _on_selection_cleared() -> void:
	selected_tile = null
	upgrade_button.visible = false


func reset_upgrade_ui() -> void:
	selected_tile = null
	upgrade_button.visible = false


func _on_upgrade_button_pressed() -> void:
	if selected_tile == null:
		return
	try_upgrade_building(selected_tile)


func try_upgrade_building(tile: MeshInstance3D) -> void:
	if not can_upgrade_building(tile):
		hex_grid.emit_signal("message_changed", "Kein Upgrade möglich")
		return
	if not _has_upgrade_resources():
		hex_grid.emit_signal("message_changed", "Nicht genug Ressourcen. Upgrade kostet 10 Holz und 5 Stein.")
		return
	var wood: int = int(hex_grid.get("wood")) - upgrade_wood_cost
	var stone: int = int(hex_grid.get("stone")) - upgrade_stone_cost
	hex_grid.set("wood", wood)
	hex_grid.set("stone", stone)
	hex_grid.emit_signal("wood_changed", wood)
	hex_grid.emit_signal("stone_changed", stone)
	_apply_building_level(tile, 2)
	var building_name: String = _get_building_name(tile)
	hex_grid.emit_signal("message_changed", "%s auf Stufe 2 verbessert" % building_name)
	hex_grid.call("_emit_hex_selected", tile)
	_sync_parent_world_data()


func _sync_parent_world_data() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	if parent_node.has_method("sync_world_data"):
		parent_node.call("sync_world_data")


func try_upgrade_lumberjack_hut(tile: MeshInstance3D) -> void:
	try_upgrade_building(tile)


func apply_saved_upgrade_data(tile: MeshInstance3D, building_data: Dictionary) -> void:
	if tile == null:
		return
	if not _is_upgradeable_building(tile):
		return
	var level: int = 1
	if building_data.has("building_level"):
		level = int(building_data["building_level"])
	if level < 1:
		level = 1
	if level > max_upgrade_level:
		level = max_upgrade_level
	_apply_building_level(tile, level)


func can_upgrade_building(tile: MeshInstance3D) -> bool:
	if not _is_upgradeable_building(tile):
		return false
	return get_building_level(tile) < max_upgrade_level


func can_upgrade_lumberjack_hut(tile: MeshInstance3D) -> bool:
	return can_upgrade_building(tile)


func get_building_level(tile: MeshInstance3D) -> int:
	if tile.has_meta("building_level"):
		return int(tile.get_meta("building_level"))
	return 1


func get_lumberjack_level(tile: MeshInstance3D) -> int:
	return get_building_level(tile)


func _apply_building_level(tile: MeshInstance3D, level: int) -> void:
	tile.set_meta("building_level", level)
	var building_type: String = _get_building_type(tile)
	if building_type == "lumberjack_hut":
		tile.set_meta("lumberjack_production", level)
	if building_type == "stone_mine":
		tile.set_meta("stone_mine_production", level)
	if building_type == "berry_gatherer":
		tile.set_meta("food_production", level)
	if building_type == "farm":
		var farm_production: int = 3
		if level >= 2:
			farm_production = 5
		tile.set_meta("food_production", farm_production)


func _apply_lumberjack_level(tile: MeshInstance3D, level: int) -> void:
	_apply_building_level(tile, level)


func _clear_upgrade_meta_from_empty_tiles() -> void:
	var tiles_by_coords: Dictionary = hex_grid.get("tiles_by_coords") as Dictionary
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if bool(tile.get_meta("has_building", false)):
			continue
		if tile.has_meta("building_level"):
			tile.remove_meta("building_level")


func _is_upgradeable_building(tile: MeshInstance3D) -> bool:
	var building_type: String = _get_building_type(tile)
	return upgradeable_building_types.has(building_type)


func _is_lumberjack_hut(tile: MeshInstance3D) -> bool:
	return _get_building_type(tile) == "lumberjack_hut"


func _get_building_type(tile: MeshInstance3D) -> String:
	if tile == null:
		return ""
	if not tile.has_meta("building_type"):
		return ""
	return String(tile.get_meta("building_type"))


func _get_building_name(tile: MeshInstance3D) -> String:
	if tile == null:
		return "Gebäude"
	if not tile.has_meta("building_name"):
		return "Gebäude"
	return String(tile.get_meta("building_name"))


func _has_upgrade_resources() -> bool:
	var wood: int = int(hex_grid.get("wood"))
	var stone: int = int(hex_grid.get("stone"))
	return wood >= upgrade_wood_cost and stone >= upgrade_stone_cost
