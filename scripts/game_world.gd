extends Node3D

@onready var hex_grid: Node3D = $HexGrid
@onready var build_mode_label: Label = $CanvasLayer/BuildModeLabel
@onready var resource_label: Label = $CanvasLayer/ResourceLabel
@onready var coordinate_label: Label = $CanvasLayer/CoordinateLabel
@onready var message_label: Label = $CanvasLayer/MessageLabel


func _ready() -> void:
	hex_grid.hex_selected.connect(_on_hex_selected)
	hex_grid.build_mode_changed.connect(_on_build_mode_changed)
	hex_grid.wood_changed.connect(_on_wood_changed)
	hex_grid.message_changed.connect(_on_message_changed)
	_on_build_mode_changed(false)
	_on_wood_changed(hex_grid.wood)


func _on_hex_selected(
	q: int,
	r: int,
	tile_type: String,
	buildable: bool,
	has_building: bool,
	own_forest: bool,
	adjacent_forests: int,
	production: int
) -> void:
	var buildable_text: String = "ja" if buildable else "nein"
	var building_text: String = "ja" if has_building else "nein"
	var own_forest_text: String = "ja" if own_forest else "nein"
	coordinate_label.text = "Hex: q=%d, r=%d | Typ: %s | Bebaubar: %s | Gebäude: %s | Eigenes Wald-Hex: %s | Angrenzende Wälder: %d/6 | Produktion: %d Holz pro 5 Sekunden" % [
		q,
		r,
		tile_type,
		buildable_text,
		building_text,
		own_forest_text,
		adjacent_forests,
		production
	]


func _on_build_mode_changed(enabled: bool) -> void:
	build_mode_label.text = "Baumodus: %s" % ("AN" if enabled else "AUS")
	build_mode_label.add_theme_color_override(
		"font_color",
		Color(0.20, 0.85, 0.25) if enabled else Color(0.95, 0.20, 0.18)
	)


func _on_wood_changed(amount: int) -> void:
	resource_label.text = "Holz: %d" % amount


func _on_message_changed(text: String) -> void:
	message_label.text = text
