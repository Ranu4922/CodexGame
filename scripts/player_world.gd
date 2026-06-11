extends Node3D

signal settlement_management_requested

@export var move_speed: float = 4.5
@export var interaction_distance: float = 2.7
@export var interaction_hint_height: float = 2.1

@onready var player: Node3D = $Player
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var village_center: Node3D = $VillageCenter
@onready var player_world_canvas_layer: CanvasLayer = $CanvasLayer
@onready var hint_label: Label = $CanvasLayer/HintLabel

var target_position: Vector3 = Vector3.ZERO
var has_move_target: bool = false
var world_data: RefCounted


func _ready() -> void:
	target_position = player.global_position
	_configure_hint_label()
	hint_label.visible = false


func set_world_data(shared_world_data: RefCounted) -> void:
	world_data = shared_world_data


func set_active(active: bool) -> void:
	visible = active
	player_world_canvas_layer.visible = active
	set_process(active)
	set_process_input(active)
	set_process_unhandled_input(active)
	if active:
		_update_camera()
		camera.current = true
		_update_interaction_hint()
	else:
		_stop_movement()
		hint_label.visible = false


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


func _stop_movement() -> void:
	target_position = player.global_position
	has_move_target = false


func _update_camera() -> void:
	camera_rig.global_position = player.global_position


func _update_interaction_hint() -> void:
	var should_show_hint: bool = _is_near_village_center()
	hint_label.visible = should_show_hint
	if not should_show_hint:
		return
	var hint_world_position: Vector3 = village_center.global_position + Vector3.UP * interaction_hint_height
	if camera.is_position_behind(hint_world_position):
		hint_label.visible = false
		return
	var hint_screen_position: Vector2 = camera.unproject_position(hint_world_position)
	var hint_size: Vector2 = hint_label.size
	hint_label.position = hint_screen_position - hint_size * 0.5


func _is_near_village_center() -> bool:
	var player_position: Vector3 = player.global_position
	var center_position: Vector3 = village_center.global_position
	player_position.y = 0.0
	center_position.y = 0.0
	return player_position.distance_to(center_position) <= interaction_distance


func _configure_hint_label() -> void:
	hint_label.text = "[E]"
	hint_label.size = Vector2(52.0, 34.0)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 22)
	hint_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.62, 1.0))
	var label_style: StyleBoxFlat = StyleBoxFlat.new()
	label_style.bg_color = Color(0.04, 0.04, 0.04, 0.76)
	label_style.border_color = Color(1.0, 0.82, 0.26, 0.9)
	label_style.set_border_width_all(1)
	label_style.corner_radius_top_left = 4
	label_style.corner_radius_top_right = 4
	label_style.corner_radius_bottom_left = 4
	label_style.corner_radius_bottom_right = 4
	hint_label.add_theme_stylebox_override("normal", label_style)
