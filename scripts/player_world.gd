extends Node3D

signal settlement_management_requested

@export var move_speed: float = 8.0
@export var interaction_distance: float = 6.0
@export var interaction_hint_height: float = 3.0
@export var world_hex_size: float = 8.0

@onready var player: Node3D = $Player
@onready var world_map: Node3D = $WorldMap
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var village_center: Node3D = $VillageCenter
@onready var player_world_canvas_layer: CanvasLayer = $CanvasLayer
@onready var hint_label: Label = $CanvasLayer/HintLabel

var target_position: Vector3 = Vector3.ZERO
var has_move_target: bool = false
var world_data: RefCounted
var tile_materials: Dictionary = {}
var marker_materials: Dictionary = {}
var has_initialized_player_position: bool = false


func _ready() -> void:
	target_position = player.global_position
	_create_world_materials()
	_configure_hint_label()
	hint_label.visible = false


func set_world_data(shared_world_data: RefCounted) -> void:
	world_data = shared_world_data
	refresh_world_visuals()


func set_active(active: bool) -> void:
	visible = active
	player_world_canvas_layer.visible = active
	set_process(active)
	set_process_input(active)
	set_process_unhandled_input(active)
	if active:
		refresh_world_visuals()
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
	# Water blocking will be added later; for now water is only marked visually.
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


func refresh_world_visuals() -> void:
	if world_data == null:
		return
	_clear_world_map()
	_create_world_tiles()
	_create_world_building_markers()
	_update_village_center_from_world_data()
	_place_player_near_village_center_if_needed()


func _clear_world_map() -> void:
	for child in world_map.get_children():
		var child_node: Node = child as Node
		if child_node == null:
			continue
		world_map.remove_child(child_node)
		child_node.queue_free()


func _create_world_tiles() -> void:
	var tiles: Dictionary = world_data.get("tiles_by_coords") as Dictionary
	for tile_value in tiles.values():
		if not (tile_value is Dictionary):
			continue
		var tile_data: Dictionary = tile_value as Dictionary
		var q: int = int(tile_data.get("q", 0))
		var r: int = int(tile_data.get("r", 0))
		var tile_type: String = String(tile_data.get("tile_type", "Gras"))
		var tile_position: Vector3 = _axial_to_player_world(q, r)
		_create_tile_visual(tile_position, tile_type)
		if tile_type == "Wald":
			_create_forest_placeholders(tile_position)
		if tile_type == "Stein":
			_create_stone_placeholders(tile_position)


func _create_world_building_markers() -> void:
	var buildings: Dictionary = world_data.get("buildings_by_coords") as Dictionary
	for building_value in buildings.values():
		if not (building_value is Dictionary):
			continue
		var building_data: Dictionary = building_value as Dictionary
		var building_type: String = String(building_data.get("type", ""))
		if building_type == "village_center":
			continue
		var q: int = int(building_data.get("q", 0))
		var r: int = int(building_data.get("r", 0))
		var building_position: Vector3 = _axial_to_player_world(q, r)
		_create_building_placeholder(building_position, building_type)


func _create_tile_visual(tile_position: Vector3, tile_type: String) -> void:
	var tile: MeshInstance3D = MeshInstance3D.new()
	tile.name = "WorldTile_%s" % tile_type
	tile.mesh = _create_hex_tile_mesh()
	tile.position = Vector3(tile_position.x, 0.02, tile_position.z)
	tile.material_override = _get_tile_material(tile_type)
	world_map.add_child(tile)


func _create_tree_placeholder(tile_position: Vector3) -> void:
	var trunk: MeshInstance3D = MeshInstance3D.new()
	trunk.name = "TreePlaceholder"
	var trunk_mesh: BoxMesh = BoxMesh.new()
	trunk_mesh.size = Vector3(0.45, 1.45, 0.45)
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(tile_position.x, 0.75, tile_position.z)
	trunk.material_override = marker_materials["tree_trunk"]
	world_map.add_child(trunk)

	var crown: MeshInstance3D = MeshInstance3D.new()
	crown.name = "TreeCrownPlaceholder"
	var crown_mesh: BoxMesh = BoxMesh.new()
	crown_mesh.size = Vector3(1.75, 1.55, 1.75)
	crown.mesh = crown_mesh
	crown.position = Vector3(tile_position.x, 1.90, tile_position.z)
	crown.material_override = marker_materials["tree_crown"]
	world_map.add_child(crown)


func _create_stone_placeholder(tile_position: Vector3) -> void:
	var stone_marker: MeshInstance3D = MeshInstance3D.new()
	stone_marker.name = "StonePlaceholder"
	var stone_mesh: BoxMesh = BoxMesh.new()
	stone_mesh.size = Vector3(1.65, 0.95, 1.25)
	stone_marker.mesh = stone_mesh
	stone_marker.position = Vector3(tile_position.x, 0.55, tile_position.z)
	stone_marker.material_override = marker_materials["stone_marker"]
	world_map.add_child(stone_marker)


func _create_building_placeholder(tile_position: Vector3, building_type: String) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "BuildingPlaceholder_%s" % building_type
	var marker_mesh: BoxMesh = BoxMesh.new()
	marker_mesh.size = Vector3(2.2, 1.8, 2.2)
	marker.mesh = marker_mesh
	marker.position = Vector3(tile_position.x, 0.95, tile_position.z)
	marker.material_override = marker_materials["building_marker"]
	world_map.add_child(marker)


func _update_village_center_from_world_data() -> void:
	var has_center: bool = bool(world_data.get("has_village_center"))
	if not has_center:
		return
	var center_coords_value: Variant = world_data.get("village_center_coords")
	if not (center_coords_value is Vector2i):
		return
	var center_coords: Vector2i = center_coords_value as Vector2i
	var center_position: Vector3 = _axial_to_player_world(center_coords.x, center_coords.y)
	village_center.global_position = Vector3(center_position.x, 1.25, center_position.z)


func _place_player_near_village_center_if_needed() -> void:
	if has_initialized_player_position:
		return
	var has_center: bool = bool(world_data.get("has_village_center"))
	if not has_center:
		return
	var center_position: Vector3 = village_center.global_position
	player.global_position = Vector3(center_position.x - world_hex_size * 1.6, player.global_position.y, center_position.z)
	target_position = player.global_position
	camera_rig.global_position = player.global_position
	has_initialized_player_position = true


func _axial_to_player_world(q: int, r: int) -> Vector3:
	var x_position: float = world_hex_size * sqrt(3.0) * (float(q) + float(r) * 0.5)
	var z_position: float = world_hex_size * 1.5 * float(r)
	return Vector3(x_position, 0.0, z_position)


func _create_forest_placeholders(tile_position: Vector3) -> void:
	var offsets: Array[Vector3] = [
		Vector3(-world_hex_size * 0.28, 0.0, -world_hex_size * 0.12),
		Vector3(world_hex_size * 0.18, 0.0, -world_hex_size * 0.24),
		Vector3(world_hex_size * 0.32, 0.0, world_hex_size * 0.16),
		Vector3(-world_hex_size * 0.10, 0.0, world_hex_size * 0.30),
	]
	for offset in offsets:
		_create_tree_placeholder(tile_position + offset)


func _create_stone_placeholders(tile_position: Vector3) -> void:
	var offsets: Array[Vector3] = [
		Vector3(-world_hex_size * 0.20, 0.0, -world_hex_size * 0.10),
		Vector3(world_hex_size * 0.18, 0.0, world_hex_size * 0.08),
		Vector3(0.0, 0.0, world_hex_size * 0.28),
	]
	for offset in offsets:
		_create_stone_placeholder(tile_position + offset)


func _create_hex_tile_mesh() -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	for corner_index in range(6):
		var angle_degrees: float = 60.0 * float(corner_index) + 30.0
		var angle_radians: float = deg_to_rad(angle_degrees)
		var x_position: float = cos(angle_radians) * world_hex_size
		var z_position: float = sin(angle_radians) * world_hex_size
		vertices.append(Vector3(x_position, 0.0, z_position))
		normals.append(Vector3.UP)
	for triangle_index in range(6):
		var first_corner_index: int = triangle_index + 1
		var second_corner_index: int = 1
		if triangle_index < 5:
			second_corner_index = triangle_index + 2
		indices.append(0)
		indices.append(second_corner_index)
		indices.append(first_corner_index)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _create_world_materials() -> void:
	tile_materials = {
		"Gras": _make_material(Color(0.22, 0.52, 0.28)),
		"Wald": _make_material(Color(0.09, 0.34, 0.17)),
		"Wasser": _make_material(Color(0.10, 0.34, 0.76)),
		"Stein": _make_material(Color(0.45, 0.46, 0.43)),
	}
	marker_materials = {
		"tree_trunk": _make_material(Color(0.34, 0.20, 0.10)),
		"tree_crown": _make_material(Color(0.07, 0.42, 0.18)),
		"stone_marker": _make_material(Color(0.58, 0.59, 0.56)),
		"building_marker": _make_material(Color(0.77, 0.54, 0.24)),
	}


func _get_tile_material(tile_type: String) -> StandardMaterial3D:
	if tile_materials.has(tile_type):
		return tile_materials[tile_type] as StandardMaterial3D
	return tile_materials["Gras"] as StandardMaterial3D


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


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
