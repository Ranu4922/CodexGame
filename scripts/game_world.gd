extends Node3D

@onready var hex_grid: Node3D = $HexGrid
@onready var coordinate_label: Label = $CanvasLayer/CoordinateLabel


func _ready() -> void:
	hex_grid.hex_selected.connect(_on_hex_selected)


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
