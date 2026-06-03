extends Node3D

signal hex_selected(
	q: int,
	r: int,
	tile_type: String,
	buildable: bool,
	has_building: bool,
	adjacent_forests: int,
	production: int
)
signal build_mode_changed(enabled: bool)
signal wood_changed(amount: int)
signal message_changed(text: String)

@export var radius: int = 6
@export var hex_size: float = 1.0
@export var tile_height: float = 0.08
@export var generation_seed: int = 12345
@export var starting_wood: int = 20
@export var lumberjack_hut_wood_cost: int = 5
@export var production_interval: float = 5.0

var selected_tile: MeshInstance3D
var selected_material: StandardMaterial3D
var building_material: StandardMaterial3D
var tile_materials: Dictionary = {}
var build_mode: bool = false
var wood: int = 0
var tiles_by_coords: Dictionary = {}
var lumberjack_hut_tiles: Array[MeshInstance3D] = []
var production_timer: float = 0.0


func _ready() -> void:
	wood = starting_wood
	tile_materials = {
		"Gras": _make_material(Color(0.22, 0.55, 0.32)),
		"Wald": _make_material(Color(0.08, 0.32, 0.16)),
		"Wasser": _make_material(Color(0.12, 0.36, 0.78)),
		"Stein": _make_material(Color(0.45, 0.46, 0.43)),
	}
	selected_material = _make_material(Color(0.95, 0.78, 0.25))
	building_material = _make_material(Color(0.46, 0.25, 0.10))
	_generate_grid()


func _process(delta: float) -> void:
	if lumberjack_hut_tiles.is_empty():
		return

	production_timer += delta
	while production_timer >= production_interval:
		production_timer -= production_interval
		_run_production_cycle()


func _generate_grid() -> void:
	for q in range(-radius, radius + 1):
		var r_min: int = max(-radius, -q - radius)
		var r_max: int = min(radius, -q + radius)
		for r in range(r_min, r_max + 1):
			_create_tile(q, r)


func _create_tile(q: int, r: int) -> void:
	var tile_type := _get_tile_type(q, r)

	var tile := MeshInstance3D.new()
	tile.name = "Hex_%d_%d" % [q, r]
	tile.mesh = _create_hex_mesh()
	tile.material_override = tile_materials[tile_type]
	tile.position = axial_to_world(q, r)
	tile.set_meta("q", q)
	tile.set_meta("r", r)
	tile.set_meta("tile_type", tile_type)
	tile.set_meta("buildable", _is_tile_buildable(tile_type))
	tile.set_meta("has_building", false)
	add_child(tile)
	tiles_by_coords[_coords_key(q, r)] = tile

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


func _get_tile_type(q: int, r: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d" % [generation_seed, q, r])
	var roll := rng.randf()

	if roll < 0.16:
		return "Wasser"
	if roll < 0.36:
		return "Wald"
	if roll < 0.48:
		return "Stein"
	return "Gras"


func _is_tile_buildable(tile_type: String) -> bool:
	return tile_type != "Wasser"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		build_mode = not build_mode
		build_mode_changed.emit(build_mode)
		print("Baumodus: %s" % ("an" if build_mode else "aus"))

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_add_wood(10)

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
		if build_mode:
			_try_place_lumberjack_hut(tile)

		hex_selected.emit(
			tile.get_meta("q"),
			tile.get_meta("r"),
			tile.get_meta("tile_type"),
			tile.get_meta("buildable"),
			tile.get_meta("has_building"),
			_get_tile_adjacent_forests(tile),
			_get_tile_production(tile)
		)


func _set_selected_tile(tile: MeshInstance3D) -> void:
	if selected_tile != null:
		selected_tile.material_override = tile_materials[selected_tile.get_meta("tile_type")]

	selected_tile = tile
	selected_tile.material_override = selected_material


func _try_place_lumberjack_hut(tile: MeshInstance3D) -> void:
	if not tile.get_meta("buildable"):
		message_changed.emit("Kann hier nicht bauen: Feld ist nicht bebaubar.")
		return

	if tile.get_meta("has_building"):
		message_changed.emit("Kann hier nicht bauen: Feld hat bereits ein Gebäude.")
		return

	if wood < lumberjack_hut_wood_cost:
		message_changed.emit("Nicht genug Holz. Holzfällerhütte kostet %d Holz." % lumberjack_hut_wood_cost)
		return

	wood -= lumberjack_hut_wood_cost
	wood_changed.emit(wood)
	_place_lumberjack_hut(tile)
	message_changed.emit("Holzfällerhütte gebaut: -%d Holz." % lumberjack_hut_wood_cost)


func _place_lumberjack_hut(tile: MeshInstance3D) -> void:
	var marker := MeshInstance3D.new()
	marker.name = "Holzfaellerhuette"

	var marker_size := hex_size * 1.25
	var mesh := BoxMesh.new()
	mesh.size = Vector3(marker_size, marker_size, marker_size)
	marker.mesh = mesh
	marker.material_override = building_material
	marker.position = Vector3(0.0, tile_height + marker_size * 0.5, 0.0)

	tile.add_child(marker)
	var adjacent_forests := _count_adjacent_forests(int(tile.get_meta("q")), int(tile.get_meta("r")))
	tile.set_meta("has_building", true)
	tile.set_meta("building_name", "Holzfällerhütte")
	tile.set_meta("adjacent_forests", adjacent_forests)
	tile.set_meta("lumberjack_production", adjacent_forests)
	lumberjack_hut_tiles.append(tile)


func _add_wood(amount: int) -> void:
	wood += amount
	wood_changed.emit(wood)
	message_changed.emit("+%d Holz erhalten." % amount)


func _run_production_cycle() -> void:
	var produced_wood := 0

	for tile in lumberjack_hut_tiles:
		produced_wood += _get_tile_production(tile)

	if produced_wood <= 0:
		return

	wood += produced_wood
	wood_changed.emit(wood)
	message_changed.emit("Holzfällerhütten produziert: +%d Holz." % produced_wood)


func _count_adjacent_forests(q: int, r: int) -> int:
	var adjacent_offsets := [
		Vector2i(1, 0),
		Vector2i(1, -1),
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
	]
	var forest_count := 0

	for offset in adjacent_offsets:
		var neighbor := tiles_by_coords.get(_coords_key(q + offset.x, r + offset.y))
		if neighbor is MeshInstance3D and neighbor.get_meta("tile_type") == "Wald":
			forest_count += 1

	return forest_count


func _get_tile_adjacent_forests(tile: MeshInstance3D) -> int:
	if tile.has_meta("adjacent_forests"):
		return int(tile.get_meta("adjacent_forests"))
	return 0


func _get_tile_production(tile: MeshInstance3D) -> int:
	if tile.has_meta("lumberjack_production"):
		return int(tile.get_meta("lumberjack_production"))
	return 0


func _coords_key(q: int, r: int) -> String:
	return "%d:%d" % [q, r]


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
