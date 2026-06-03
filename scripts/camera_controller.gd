extends Node3D

@export var move_speed: float = 12.0
@export var zoom_step: float = 1.5
@export var min_zoom: float = 6.0
@export var max_zoom: float = 30.0

@onready var camera: Camera3D = $Camera3D


func _process(delta: float) -> void:
	var input := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		input.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		input.z += 1.0
	if Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input.x += 1.0

	if input != Vector3.ZERO:
		input = input.normalized()
		global_position += input * move_speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = max(min_zoom, camera.size - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = min(max_zoom, camera.size + zoom_step)
