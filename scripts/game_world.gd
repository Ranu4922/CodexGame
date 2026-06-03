extends Node3D

@onready var hex_grid: Node3D = $HexGrid
@onready var build_mode_label: Label = $CanvasLayer/BuildModeLabel
@onready var coordinate_label: Label = $CanvasLayer/CoordinateLabel


func _ready() -> void:
	hex_grid.hex_selected.connect(_on_hex_selected)
	hex_grid.build_mode_changed.connect(_on_build_mode_changed)
	_on_build_mode_changed(false)


func _on_hex_selected(q: int, r: int, tile_type: String, buildable: bool, has_building: bool) -> void:
	var buildable_text := "ja" if buildable else "nein"
	var building_text := "ja" if has_building else "nein"
	coordinate_label.text = "Hex: q=%d, r=%d | Typ: %s | Bebaubar: %s | Gebäude: %s" % [
		q,
		r,
		tile_type,
		buildable_text,
		building_text
	]


func _on_build_mode_changed(enabled: bool) -> void:
	build_mode_label.text = "Baumodus: %s" % ("AN" if enabled else "AUS")
	build_mode_label.add_theme_color_override(
		"font_color",
		Color(0.20, 0.85, 0.25) if enabled else Color(0.95, 0.20, 0.18)
	)
