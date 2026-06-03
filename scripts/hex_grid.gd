extends Node3D

signal hex_selected(q: int, r: int)

@export var radius: int = 6
@export var hex_size: float = 1.0
@export var tile_height: float = 0.08

var selected_tile: MeshInstance3D
var tile_material: StandardMaterial3D
var selected_material: StandardMaterial3D


func _ready() -> void:
	tile_material = _make_material(Color(0.22, 0.55, 0.32))
	selected_material = _make_material(Color(0.95, 0.78, 0.25))
	_generate_grid()


func _generate_grid() -> void:
	for q in range(-radius, radius + 1):
		var r_min := max(-radius, -q - radius)
		var r_max := min(radius, -q + radius)
		for r in range(r_min, r_max + 1):
			_create_tile(q, r)


func _create_tile(q: int, r: int) -> void:
	var tile := MeshInstance3D.new()
	tile.name = "Hex_%d_%d" % [q, r]
	tile.mesh = _create_hex_mesh()
	tile.material_override = tile_material
	tile.position = axial_to_world(q, r)
	tile.set_meta("q", q)
	tile.set_meta("r", r)
	add_child(tile)

	var body := StaticBody3D.new()
	body.name = "ClickBody"
	tile.add_child(body)

	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = hex_size * 0.95
	shape.height = tile_height + 0.04
	collision.shape = shape
	body.add_child(collision)


func _create_hex_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	vertices.append(Vector3(0, tile_height, 0))
	normals.append(Vector3.UP)
	for i in range(6):
		var angle := deg_to_rad(60.0 * i + 30.0)
		vertices.append(Vector3(cos(angle) * hex_size, tile_height, sin(angle) * hex_size))
		normals.append(Vector3.UP)

	for i in range(6):
		indices.append(0)
		indices.append(i + 1)
		indices.append(1 if i == 5 else i + 2)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func axial_to_world(q: int, r: int) -> Vector3:
	var x := hex_size * sqrt(3.0) * (q + r * 0.5)
	var z := hex_size * 1.5 * r
	return Vector3(x, 0.0, z)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_tile_under_mouse()


func _select_tile_under_mouse() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_position) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return

	var collider := result["collider"] as Node
	var tile := collider.get_parent()
	if tile is MeshInstance3D and tile.has_meta("q") and tile.has_meta("r"):
		_set_selected_tile(tile)
		hex_selected.emit(tile.get_meta("q"), tile.get_meta("r"))


func _set_selected_tile(tile: MeshInstance3D) -> void:
	if selected_tile != null:
		selected_tile.material_override = tile_material

	selected_tile = tile
	selected_tile.material_override = selected_material


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
