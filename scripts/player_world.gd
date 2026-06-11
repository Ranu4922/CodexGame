extends Node3D

signal settlement_management_requested

@export var move_speed: float = 6.0
@export var interaction_distance: float = 2.4

@onready var player: Node3D = $Player
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var village_center: Node3D = $VillageCenter
@onready var hint_label: Label = $CanvasLayer/HintLabel

var target_position: Vector3 = Vector3.ZERO
var has_move_target: bool = false


func _ready() -> void:
	target_position = player.global_position
	hint_label.visible = false


func set_active(active: bool) -> void:
	visible = active
	set_process(active)
	set_process_input(active)
	set_process_unhandled_input(active)
	if active:
		camera.current = true


func _process(delta: float) -> void:
	_update_player_movement(delta)
	_update_camera()
	_update_interaction_hint()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_try_set_move_target()
			get_viewport().set_input_as_handled()

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_E and _is_near_village_center():
			settlement_management_requested.emit()
			get_viewport().set_input_as_handled()


func _try_set_move_target() -> void:
	var ray_result: Dictionary = _get_mouse_ray_result()
	if ray_result.is_empty():
		return
	var collider: Variant = ray_result.get("collider")
	if not (collider is Node):
		return
	var collider_node: Node = collider as Node
	if collider_node.name != "Ground":
		return
	var hit_position: Vector3 = ray_result["position"]
	target_position = Vector3(hit_position.x, player.global_position.y, hit_position.z)
	has_move_target = true


func _get_mouse_ray_result() -> Dictionary:
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_position) * 1000.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _update_player_movement(delta: float) -> void:
	if not has_move_target:
		return
	var current_position: Vector3 = player.global_position
	var direction: Vector3 = target_position - current_position
	direction.y = 0.0
	var distance: float = direction.length()
	if distance <= 0.08:
		player.global_position = target_position
		has_move_target = false
		return
	var step_distance: float = move_speed * delta
	if step_distance > distance:
		step_distance = distance
	player.global_position = current_position + direction.normalized() * step_distance


func _update_camera() -> void:
	camera_rig.global_position = player.global_position


func _update_interaction_hint() -> void:
	hint_label.visible = _is_near_village_center()


func _is_near_village_center() -> bool:
	var player_position: Vector3 = player.global_position
	var center_position: Vector3 = village_center.global_position
	player_position.y = 0.0
	center_position.y = 0.0
	return player_position.distance_to(center_position) <= interaction_distance
