extends Node

@export var lumberjack_upgrade_wood_cost: int = 10
@export var lumberjack_upgrade_stone_cost: int = 5
@export var lumberjack_max_level: int = 2

@onready var hex_grid: Node = get_parent().get_node("HexGrid")
@onready var canvas_layer: CanvasLayer = get_parent().get_node("CanvasLayer")
@onready var info_panel: PanelContainer = get_parent().get_node("CanvasLayer/InfoPanel")
@onready var info_label: Label = get_parent().get_node("CanvasLayer/InfoPanel/InfoLabel")

var upgrade_button: Button
var selected_tile: MeshInstance3D


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
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	canvas_layer.add_child(upgrade_button)


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
	_update_upgrade_button()


func _update_upgrade_info_text() -> void:
	if selected_tile == null:
		return
	if not _is_lumberjack_hut(selected_tile):
		return
	if info_label.text.is_empty():
		return
	var level: int = get_lumberjack_level(selected_tile)
	var lines: PackedStringArray = info_label.text.split("\n")
	lines.append("Stufe: %d" % level)
	if can_upgrade_lumberjack_hut(selected_tile):
		lines.append("Upgradekosten: %d Holz, %d Stein" % [lumberjack_upgrade_wood_cost, lumberjack_upgrade_stone_cost])
	info_label.text = "\n".join(lines)
	if get_parent().has_method("_set_info_panel_text"):
		get_parent().call("_set_info_panel_text", info_label.text)


func _update_upgrade_button() -> void:
	if selected_tile == null or not _is_lumberjack_hut(selected_tile):
		upgrade_button.visible = false
		return
	if not can_upgrade_lumberjack_hut(selected_tile):
		upgrade_button.visible = false
		return
	upgrade_button.visible = true
	upgrade_button.disabled = not _has_upgrade_resources()
	var panel_position: Vector2 = info_panel.position
	var panel_size: Vector2 = info_panel.size
	upgrade_button.position = Vector2(panel_position.x + 12.0, panel_position.y + panel_size.y + 8.0)


func _on_selection_cleared() -> void:
	selected_tile = null
	upgrade_button.visible = false


func _on_upgrade_button_pressed() -> void:
	if selected_tile == null:
		return
	try_upgrade_lumberjack_hut(selected_tile)


func try_upgrade_lumberjack_hut(tile: MeshInstance3D) -> void:
	if not can_upgrade_lumberjack_hut(tile):
		hex_grid.emit_signal("message_changed", "Kein Upgrade möglich")
		return
	if not _has_upgrade_resources():
		hex_grid.emit_signal("message_changed", "Nicht genug Ressourcen. Upgrade kostet 10 Holz und 5 Stein.")
		return
	var wood: int = int(hex_grid.get("wood")) - lumberjack_upgrade_wood_cost
	var stone: int = int(hex_grid.get("stone")) - lumberjack_upgrade_stone_cost
	hex_grid.set("wood", wood)
	hex_grid.set("stone", stone)
	hex_grid.emit_signal("wood_changed", wood)
	hex_grid.emit_signal("stone_changed", stone)
	_apply_lumberjack_level(tile, 2)
	hex_grid.emit_signal("message_changed", "Holzfällerhütte auf Stufe 2 verbessert")
	hex_grid.call("_emit_hex_selected", tile)


func apply_saved_upgrade_data(tile: MeshInstance3D, building_data: Dictionary) -> void:
	if tile == null:
		return
	if not _is_lumberjack_hut(tile):
		return
	var level: int = 1
	if building_data.has("building_level"):
		level = int(building_data["building_level"])
	if level < 1:
		level = 1
	if level > lumberjack_max_level:
		level = lumberjack_max_level
	_apply_lumberjack_level(tile, level)


func can_upgrade_lumberjack_hut(tile: MeshInstance3D) -> bool:
	if not _is_lumberjack_hut(tile):
		return false
	return get_lumberjack_level(tile) < lumberjack_max_level


func get_lumberjack_level(tile: MeshInstance3D) -> int:
	if tile.has_meta("building_level"):
		return int(tile.get_meta("building_level"))
	return 1


func _apply_lumberjack_level(tile: MeshInstance3D, level: int) -> void:
	tile.set_meta("building_level", level)
	tile.set_meta("lumberjack_production", level)


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


func _is_lumberjack_hut(tile: MeshInstance3D) -> bool:
	if tile == null:
		return false
	if not tile.has_meta("building_type"):
		return false
	return String(tile.get_meta("building_type")) == "lumberjack_hut"


func _has_upgrade_resources() -> bool:
	var wood: int = int(hex_grid.get("wood"))
	var stone: int = int(hex_grid.get("stone"))
	return wood >= lumberjack_upgrade_wood_cost and stone >= lumberjack_upgrade_stone_cost
