extends Node

@onready var hex_grid: Node3D = get_parent().get_node("HexGrid")

var neighbor_offsets: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]


func _input(event: InputEvent) -> void:
	if not bool(hex_grid.get("build_mode")):
		return
	if String(hex_grid.get("selected_building_type")) != "house":
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var hovered_control: Control = get_viewport().gui_get_hovered_control()
	if hovered_control != null:
		return
	var tile: MeshInstance3D = _get_tile_under_mouse()
	if tile == null:
		return
	if not _needs_housing_adjacency_message(tile):
		return
	hex_grid.emit_signal("message_changed", "Wohnhaus muss an Dorfzentrum oder Wohnhaus angrenzen")
	get_viewport().set_input_as_handled()


func _needs_housing_adjacency_message(tile: MeshInstance3D) -> bool:
	if not bool(tile.get_meta("buildable")):
		return false
	if bool(tile.get_meta("has_building")):
		return false
	if not _get_tile_in_settlement_area(tile):
		return false
	return not _has_adjacent_housing_anchor(tile)


func _has_adjacent_housing_anchor(tile: MeshInstance3D) -> bool:
	var q: int = int(tile.get_meta("q"))
	var r: int = int(tile.get_meta("r"))
	var tiles_by_coords: Dictionary = hex_grid.get("tiles_by_coords") as Dictionary
	for offset in neighbor_offsets:
		var neighbor_key: String = _coords_key(q + offset.x, r + offset.y)
		var neighbor_value: Variant = tiles_by_coords.get(neighbor_key)
		if not (neighbor_value is MeshInstance3D):
			continue
		var neighbor_tile: MeshInstance3D = neighbor_value as MeshInstance3D
		if _is_housing_anchor(neighbor_tile):
			return true
	return false


func _is_housing_anchor(tile: MeshInstance3D) -> bool:
	if not bool(tile.get_meta("has_building", false)):
		return false
	var building_type: String = String(tile.get_meta("building_type", ""))
	return building_type == "village_center" or building_type == "house"


func _get_tile_in_settlement_area(tile: MeshInstance3D) -> bool:
	if tile.has_meta("in_settlement_area"):
		return bool(tile.get_meta("in_settlement_area"))
	return false


func _get_tile_under_mouse() -> MeshInstance3D:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return null
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_position) * 1000.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result: Dictionary = get_parent().get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var collider: Node = result["collider"] as Node
	if collider == null:
		return null
	var tile_node: Node = collider.get_parent()
	if tile_node is MeshInstance3D and tile_node.has_meta("q") and tile_node.has_meta("r"):
		return tile_node as MeshInstance3D
	return null


func _coords_key(q: int, r: int) -> String:
	return "%d:%d" % [q, r]
