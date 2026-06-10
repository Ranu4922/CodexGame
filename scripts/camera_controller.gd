extends Node3D

@export var zoom_step: float = 2.0
@export var min_zoom: float = 6.0
@export var max_zoom: float = 30.0
@export var zoom_smoothing: float = 10.0

@onready var camera: Camera3D = $Camera3D

var target_zoom: float = 16.0


func _ready() -> void:
	target_zoom = camera.size


func _process(delta: float) -> void:
	var zoom_weight: float = zoom_smoothing * delta
	if zoom_weight > 1.0:
		zoom_weight = 1.0
	camera.size = lerp(camera.size, target_zoom, zoom_weight)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		target_zoom = _clamp_zoom(target_zoom - zoom_step)
		get_viewport().set_input_as_handled()
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		target_zoom = _clamp_zoom(target_zoom + zoom_step)
		get_viewport().set_input_as_handled()


func _clamp_zoom(value: float) -> float:
	if value < min_zoom:
		return min_zoom
	if value > max_zoom:
		return max_zoom
	return value
