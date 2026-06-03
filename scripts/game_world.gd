extends Node3D

@onready var hex_grid: Node3D = $HexGrid
@onready var build_mode_label: Label = $CanvasLayer/BuildModeLabel
@onready var resource_label: Label = $CanvasLayer/ResourceLabel
@onready var message_label: Label = $CanvasLayer/MessageLabel
@onready var info_panel: PanelContainer = $CanvasLayer/InfoPanel
@onready var info_label: Label = $CanvasLayer/InfoPanel/InfoLabel

var message_version: int = 0


func _ready() -> void:
	hex_grid.hex_selected.connect(_on_hex_selected)
	hex_grid.selection_cleared.connect(_on_selection_cleared)
	hex_grid.build_mode_changed.connect(_on_build_mode_changed)
	hex_grid.wood_changed.connect(_on_wood_changed)
	hex_grid.message_changed.connect(_on_message_changed)
	_on_build_mode_changed(false)
	_on_wood_changed(hex_grid.wood)
	_on_selection_cleared()


func _on_hex_selected(
	q: int,
	r: int,
	tile_type: String,
	buildable: bool,
	has_building: bool,
	building_name: String,
	own_forest: bool,
	adjacent_forests: int,
	production: int
) -> void:
	var buildable_text: String = "ja" if buildable else "nein"
	var building_text: String = "ja" if has_building else "nein"
	var lines: PackedStringArray = PackedStringArray([
		"Koordinaten: q=%d, r=%d" % [q, r],
		"Tile-Typ: %s" % tile_type,
		"Bebaubar: %s" % buildable_text,
		"Gebäude: %s" % building_text,
	])

	if has_building and building_name == "Holzfällerhütte":
		var own_forest_text: String = "ja" if own_forest else "nein"
		lines.append("Gebäude: Holzfällerhütte")
		lines.append("Eigenes Wald-Hex: %s" % own_forest_text)
		lines.append("Angrenzende Wälder: %d/6" % adjacent_forests)
		lines.append("Produktion: %d Holz / 5 Sekunden" % production)

	info_label.text = "\n".join(lines)
	info_panel.visible = true


func _on_selection_cleared() -> void:
	info_panel.visible = false
	info_label.text = ""


func _on_build_mode_changed(enabled: bool) -> void:
	build_mode_label.text = "Baumodus: %s" % ("AN" if enabled else "AUS")
	build_mode_label.add_theme_color_override(
		"font_color",
		Color(0.20, 0.85, 0.25) if enabled else Color(0.95, 0.20, 0.18)
	)


func _on_wood_changed(amount: int) -> void:
	resource_label.text = "Holz: %d" % amount


func _on_message_changed(text: String) -> void:
	message_version += 1
	var current_version: int = message_version
	message_label.text = text
	_clear_message_after_delay(current_version)


func _clear_message_after_delay(version: int) -> void:
	await get_tree().create_timer(2.0).timeout
	if version == message_version:
		message_label.text = ""
