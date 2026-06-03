extends Node3D

@onready var hex_grid: Node3D = $HexGrid
@onready var coordinate_label: Label = $CanvasLayer/CoordinateLabel


func _ready() -> void:
	hex_grid.hex_selected.connect(_on_hex_selected)


func _on_hex_selected(q: int, r: int) -> void:
	coordinate_label.text = "Hex: q=%d, r=%d" % [q, r]
