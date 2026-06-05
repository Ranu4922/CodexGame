extends Node3D

signal hex_selected(
	q: int,
	r: int,
	tile_type: String,
	buildable: bool,
	has_building: bool,
	building_name: String,
	own_forest: bool,
	adjacent_forests: int,
	wood_production: int,
	own_stone: bool,
	adjacent_stones: int,
	stone_production: int,
	in_settlement_area: bool,
	village_center_distance: int
)
signal selection_cleared
signal build_mode_changed(enabled: bool)
signal selected_building_changed(display_name: String)
signal wood_changed(amount: int)
signal stone_changed(amount: int)
signal housing_changed(amount: int)
signal message_changed(text: String)

@export var radius: int = 6
@export var hex_size: float = 1.0
@export var tile_height: float = 0.08
@export var generation_seed: int = 12345
@export var starting_wood: int = 20
@export var starting_stone: int = 0
@export var lumberjack_hut_wood_cost: int = 5
@export var house_wood_cost: int = 10
@export var stone_mine_wood_cost: int = 10
@export var production_interval: float = 5.0
@export var village_center_influence_radius: int = 3

var selected_tile: MeshInstance3D
var selected_material: StandardMaterial3D
var building_material: StandardMaterial3D
var influence_marker_material: StandardMaterial3D
var tile_materials: Dictionary = {}
var build_mode: bool = false
var wood: int = 0
var stone: int = 0
var housing_capacity: int = 0
var tiles_by_coords: Dictionary = {}
var lumberjack_hut_tiles: Array[MeshInstance3D] = []
var stone_mine_tiles: Array[MeshInstance3D] = []
var production_timer: float = 0.0
var village_center_tile: MeshInstance3D
var show_influence_area: bool = false
var selected_building_type: String = "lumberjack_hut"


func _ready() -> void:
	wood = starting_wood
	stone = starting_stone
	tile_materials = {
		"Gras": _make_material(Color(0.22, 0.55, 0.32)),
		"Wald": _make_material(Color(0.08, 0.32, 0.16)),
		"Wasser": _make_material(Color(0.12, 0.36, 0.78)),
		"Stein": _make_material(Color(0.45, 0.46, 0.43)),
	}
	selected_material = _make_material(Color(0.95, 0.78, 0.25))
	building_material = _make_material(Color(0.46, 0.25, 0.10))
	influence_marker_material = _make_material(Color(0.90, 0.82, 0.20))
	_generate_grid()
	_place_starting_village_center()
	_update_village_center_influence()


func _process(delta: float) -> void:
	if lumberjack_hut_tiles.is_empty() and stone_mine_tiles.is_empty():
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
	var tile_type: String = _get_tile_type(q, r)

	var tile: MeshInstance3D = MeshInstance3D.new()
	tile.name = "Hex_%d_%d" % [q, r]
	tile.mesh = _create_hex_mesh()
	tile.material_override = tile_materials[tile_type]
	tile.position = axial_to_world(q, r)
	tile.set_meta("q", q)
	tile.set_meta("r", r)
	tile.set_meta("tile_type", tile_type)
	tile.set_meta("buildable", _is_tile_buildable(tile_type))
	tile.set_meta("has_building", false)
	tile.set_meta("in_settlement_area", false)
	tile.set_meta("village_center_distance", -1)
	add_child(tile)
	tiles_by_coords[_coords_key(q, r)] = tile

	var body: StaticBody3D = StaticBody3D.new()
	body.name = "ClickBody"
	tile.add_child(body)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = hex_size * 0.95
	shape.height = tile_height + 0.04
	collision.shape = shape
	body.add_child(collision)


func _create_hex_mesh() -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()

	vertices.append(Vector3(0, tile_height, 0))
	normals.append(Vector3.UP)
	for i in range(6):
		var angle: float = deg_to_rad(60.0 * i + 30.0)
		vertices.append(Vector3(cos(angle) * hex_size, tile_height, sin(angle) * hex_size))
		normals.append(Vector3.UP)

	for i in range(6):
		indices.append(0)
		indices.append(i + 1)
		indices.append(1 if i == 5 else i + 2)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func axial_to_world(q: int, r: int) -> Vector3:
	var x: float = hex_size * sqrt(3.0) * (q + r * 0.5)
	var z: float = hex_size * 1.5 * r
	return Vector3(x, 0.0, z)


func _get_tile_type(q: int, r: int) -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d" % [generation_seed, q, r])
	var roll: float = rng.randf()

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

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_add_wood(10)

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_1:
		selected_building_type = "lumberjack_hut"
		selected_building_changed.emit("Holzfällerhütte")

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_2:
		selected_building_type = "house"
		selected_building_changed.emit("Wohnhaus")

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_3:
		selected_building_type = "stone_mine"
		selected_building_changed.emit("Steinmine")

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_clear_selection()

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		show_influence_area = not show_influence_area
		_set_influence_markers_visible(show_influence_area)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_tile_under_mouse()


func _select_tile_under_mouse() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_position) * 1000.0

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		_clear_selection()
		return

	var collider: Node = result["collider"] as Node
	var tile: Node = collider.get_parent()
	if tile is MeshInstance3D and tile.has_meta("q") and tile.has_meta("r"):
		var tile_mesh: MeshInstance3D = tile as MeshInstance3D
		_set_selected_tile(tile_mesh)
		if build_mode:
			_try_place_selected_building(tile_mesh)

		hex_selected.emit(
			int(tile_mesh.get_meta("q")),
			int(tile_mesh.get_meta("r")),
			String(tile_mesh.get_meta("tile_type")),
			bool(tile_mesh.get_meta("buildable")),
			bool(tile_mesh.get_meta("has_building")),
			_get_tile_building_name(tile_mesh),
			_get_tile_own_forest(tile_mesh),
			_get_tile_adjacent_forests(tile_mesh),
			_get_tile_wood_production(tile_mesh),
			_get_tile_own_stone(tile_mesh),
			_get_tile_adjacent_stones(tile_mesh),
			_get_tile_stone_production(tile_mesh),
			_get_tile_in_settlement_area(tile_mesh),
			_get_tile_village_center_distance(tile_mesh)
		)


func _set_selected_tile(tile: MeshInstance3D) -> void:
	if selected_tile != null:
		selected_tile.material_override = tile_materials[selected_tile.get_meta("tile_type")]

	selected_tile = tile
	selected_tile.material_override = selected_material


func _clear_selection() -> void:
	if selected_tile != null:
		selected_tile.material_override = tile_materials[selected_tile.get_meta("tile_type")]
		selected_tile = null
	selection_cleared.emit()


func _try_place_selected_building(tile: MeshInstance3D) -> void:
	if not tile.get_meta("buildable"):
		message_changed.emit("Kann hier nicht bauen: Feld ist nicht bebaubar.")
		return

	if tile.get_meta("has_building"):
		message_changed.emit("Kann hier nicht bauen: Feld hat bereits ein Gebäude.")
		return

	if not _get_tile_in_settlement_area(tile):
		message_changed.emit("Außerhalb des Siedlungsgebiets")
		return

	if selected_building_type == "house":
		_try_place_house(tile)
		return

	if selected_building_type == "stone_mine":
		_try_place_stone_mine(tile)
		return

	_try_place_lumberjack_hut(tile)


func _try_place_lumberjack_hut(tile: MeshInstance3D) -> void:
	var own_forest: bool = tile.get_meta("tile_type") == "Wald"
	var adjacent_forests: int = _count_adjacent_tiles_of_type(int(tile.get_meta("q")), int(tile.get_meta("r")), "Wald")
	if not own_forest and adjacent_forests <= 0:
		message_changed.emit("Holzfällerhütte benötigt mindestens 1 Wald-Hex in Reichweite.")
		return

	if wood < lumberjack_hut_wood_cost:
		message_changed.emit("Nicht genug Holz. Holzfällerhütte kostet %d Holz." % lumberjack_hut_wood_cost)
		return

	wood -= lumberjack_hut_wood_cost
	wood_changed.emit(wood)
	_place_lumberjack_hut(tile)
	message_changed.emit("Holzfällerhütte gebaut: -%d Holz." % lumberjack_hut_wood_cost)


func _try_place_house(tile: MeshInstance3D) -> void:
	if wood < house_wood_cost:
		message_changed.emit("Nicht genug Holz. Wohnhaus kostet %d Holz." % house_wood_cost)
		return

	wood -= house_wood_cost
	wood_changed.emit(wood)
	_place_house(tile)
	message_changed.emit("Wohnhaus gebaut: -%d Holz." % house_wood_cost)


func _try_place_stone_mine(tile: MeshInstance3D) -> void:
	if String(tile.get_meta("tile_type")) != "Stein":
		message_changed.emit("Steinmine kann nur auf einem Stein-Hex gebaut werden.")
		return

	if wood < stone_mine_wood_cost:
		message_changed.emit("Nicht genug Holz. Steinmine kostet %d Holz." % stone_mine_wood_cost)
		return

	wood -= stone_mine_wood_cost
	wood_changed.emit(wood)
	_place_stone_mine(tile)
	message_changed.emit("Steinmine gebaut: -%d Holz." % stone_mine_wood_cost)


func _place_starting_village_center() -> void:
	var center_tile_variant: Variant = tiles_by_coords.get(_coords_key(0, 0))
	if not (center_tile_variant is MeshInstance3D):
		return

	var center_tile: MeshInstance3D = center_tile_variant as MeshInstance3D
	if bool(center_tile.get_meta("has_building")):
		return

	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Dorfzentrum"

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(hex_size * 1.35, hex_size * 0.75, hex_size * 1.35)
	marker.mesh = mesh
	marker.material_override = _make_material(Color(0.72, 0.58, 0.30))
	marker.position = Vector3(0.0, tile_height + hex_size * 0.375, 0.0)

	center_tile.add_child(marker)
	center_tile.set_meta("has_building", true)
	center_tile.set_meta("building_name", "Dorfzentrum")
	center_tile.set_meta("building_type", "village_center")
	center_tile.set_meta("nearest_village_center_coords", Vector2i(0, 0))
	village_center_tile = center_tile


func _update_village_center_influence() -> void:
	if village_center_tile == null:
		return

	var center_q: int = int(village_center_tile.get_meta("q"))
	var center_r: int = int(village_center_tile.get_meta("r"))

	for tile_variant in tiles_by_coords.values():
		if not (tile_variant is MeshInstance3D):
			continue

		var tile: MeshInstance3D = tile_variant as MeshInstance3D
		var distance: int = _hex_distance(center_q, center_r, int(tile.get_meta("q")), int(tile.get_meta("r")))
		var in_area: bool = distance <= village_center_influence_radius
		tile.set_meta("village_center_distance", distance)
		tile.set_meta("in_settlement_area", in_area)

		if in_area:
			_add_influence_marker(tile)


func _add_influence_marker(tile: MeshInstance3D) -> void:
	if tile.has_node("InfluenceMarker"):
		return

	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "InfluenceMarker"
	marker.mesh = _create_hex_mesh()
	marker.material_override = influence_marker_material
	marker.position = Vector3(0.0, 0.02, 0.0)
	marker.scale = Vector3(0.88, 1.0, 0.88)
	marker.visible = show_influence_area
	tile.add_child(marker)


func _set_influence_markers_visible(visible: bool) -> void:
	for tile_variant in tiles_by_coords.values():
		if not (tile_variant is MeshInstance3D):
			continue

		var tile: MeshInstance3D = tile_variant as MeshInstance3D
		var marker: Node = tile.get_node_or_null("InfluenceMarker")
		if marker is MeshInstance3D:
			marker.visible = visible


func _place_lumberjack_hut(tile: MeshInstance3D) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Holzfaellerhuette"

	var marker_size: float = hex_size * 1.25
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(marker_size, marker_size, marker_size)
	marker.mesh = mesh
	marker.material_override = building_material
	marker.position = Vector3(0.0, tile_height + marker_size * 0.5, 0.0)

	tile.add_child(marker)
	var own_forest: bool = tile.get_meta("tile_type") == "Wald"
	var adjacent_forests: int = _count_adjacent_tiles_of_type(int(tile.get_meta("q")), int(tile.get_meta("r")), "Wald")
	var production: int = 1

	tile.set_meta("has_building", true)
	tile.set_meta("building_name", "Holzfällerhütte")
	tile.set_meta("building_type", "lumberjack_hut")
	tile.set_meta("nearest_village_center_coords", _get_nearest_village_center_coords())
	tile.set_meta("own_forest", own_forest)
	tile.set_meta("adjacent_forests", adjacent_forests)
	tile.set_meta("lumberjack_production", production)
	lumberjack_hut_tiles.append(tile)


func _place_house(tile: MeshInstance3D) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Wohnhaus"

	var marker_size: float = hex_size * 1.10
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(marker_size, hex_size * 0.85, marker_size)
	marker.mesh = mesh
	marker.material_override = _make_material(Color(0.55, 0.28, 0.68))
	marker.position = Vector3(0.0, tile_height + hex_size * 0.425, 0.0)

	tile.add_child(marker)
	tile.set_meta("has_building", true)
	tile.set_meta("building_name", "Wohnhaus")
	tile.set_meta("building_type", "house")
	tile.set_meta("nearest_village_center_coords", _get_nearest_village_center_coords())
	tile.set_meta("resident_capacity", 2)
	tile.set_meta("current_residents", 0)
	_recalculate_housing_capacity()


func _place_stone_mine(tile: MeshInstance3D) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Steinmine"

	var marker_size: float = hex_size * 1.15
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(marker_size, hex_size * 0.95, marker_size)
	marker.mesh = mesh
	marker.material_override = _make_material(Color(0.36, 0.36, 0.38))
	marker.position = Vector3(0.0, tile_height + hex_size * 0.475, 0.0)

	tile.add_child(marker)
	var own_stone: bool = tile.get_meta("tile_type") == "Stein"
	var adjacent_stones: int = _count_adjacent_tiles_of_type(int(tile.get_meta("q")), int(tile.get_meta("r")), "Stein")
	var production: int = 1

	tile.set_meta("has_building", true)
	tile.set_meta("building_name", "Steinmine")
	tile.set_meta("building_type", "stone_mine")
	tile.set_meta("nearest_village_center_coords", _get_nearest_village_center_coords())
	tile.set_meta("own_stone", own_stone)
	tile.set_meta("adjacent_stones", adjacent_stones)
	tile.set_meta("stone_mine_production", production)
	stone_mine_tiles.append(tile)


func _add_wood(amount: int) -> void:
	wood += amount
	wood_changed.emit(wood)
	message_changed.emit("+%d Holz erhalten." % amount)


func _recalculate_housing_capacity() -> void:
	var total_capacity: int = 0

	for tile_variant in tiles_by_coords.values():
		if not (tile_variant is MeshInstance3D):
			continue

		var tile: MeshInstance3D = tile_variant as MeshInstance3D
		if String(tile.get_meta("building_type", "")) == "house":
			total_capacity += int(tile.get_meta("resident_capacity", 0))

	housing_capacity = total_capacity
	housing_changed.emit(housing_capacity)


func _run_production_cycle() -> void:
	var produced_wood: int = 0
	var produced_stone: int = 0

	for tile in lumberjack_hut_tiles:
		produced_wood += _get_tile_wood_production(tile)

	for tile in stone_mine_tiles:
		produced_stone += _get_tile_stone_production(tile)

	if produced_wood <= 0 and produced_stone <= 0:
		return

	if produced_wood > 0:
		wood += produced_wood
		wood_changed.emit(wood)

	if produced_stone > 0:
		stone += produced_stone
		stone_changed.emit(stone)

	var message_parts: PackedStringArray = PackedStringArray()
	if produced_wood > 0:
		message_parts.append("+%d Holz" % produced_wood)
	if produced_stone > 0:
		message_parts.append("+%d Stein" % produced_stone)
	message_changed.emit(", ".join(message_parts))


func _count_adjacent_tiles_of_type(q: int, r: int, tile_type: String) -> int:
	var adjacent_offsets: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(1, -1),
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
	]
	var matching_count: int = 0

	for offset in adjacent_offsets:
		var neighbor: Variant = tiles_by_coords.get(_coords_key(q + offset.x, r + offset.y))
		if neighbor is MeshInstance3D and neighbor.get_meta("tile_type") == tile_type:
			matching_count += 1

	return matching_count


func _get_tile_own_forest(tile: MeshInstance3D) -> bool:
	if tile.has_meta("own_forest"):
		return bool(tile.get_meta("own_forest"))
	return false


func _get_tile_own_stone(tile: MeshInstance3D) -> bool:
	if tile.has_meta("own_stone"):
		return bool(tile.get_meta("own_stone"))
	return false


func _get_tile_building_name(tile: MeshInstance3D) -> String:
	if tile.has_meta("building_name"):
		return String(tile.get_meta("building_name"))
	return ""


func _get_tile_in_settlement_area(tile: MeshInstance3D) -> bool:
	if tile.has_meta("in_settlement_area"):
		return bool(tile.get_meta("in_settlement_area"))
	return false


func _get_tile_village_center_distance(tile: MeshInstance3D) -> int:
	if tile.has_meta("village_center_distance"):
		return int(tile.get_meta("village_center_distance"))
	return -1


func _get_tile_adjacent_forests(tile: MeshInstance3D) -> int:
	if tile.has_meta("adjacent_forests"):
		return int(tile.get_meta("adjacent_forests"))
	return 0


func _get_tile_adjacent_stones(tile: MeshInstance3D) -> int:
	if tile.has_meta("adjacent_stones"):
		return int(tile.get_meta("adjacent_stones"))
	return 0


func _get_tile_wood_production(tile: MeshInstance3D) -> int:
	if tile.has_meta("lumberjack_production"):
		return int(tile.get_meta("lumberjack_production"))
	return 0


func _get_tile_stone_production(tile: MeshInstance3D) -> int:
	if tile.has_meta("stone_mine_production"):
		return int(tile.get_meta("stone_mine_production"))
	return 0


func _coords_key(q: int, r: int) -> String:
	return "%d:%d" % [q, r]


func _get_nearest_village_center_coords() -> Vector2i:
	if village_center_tile == null:
		return Vector2i.ZERO
	return Vector2i(int(village_center_tile.get_meta("q")), int(village_center_tile.get_meta("r")))


func _hex_distance(from_q: int, from_r: int, to_q: int, to_r: int) -> int:
	var delta_q: int = to_q - from_q
	var delta_r: int = to_r - from_r
	var delta_s: int = -delta_q - delta_r
	return int((abs(delta_q) + abs(delta_r) + abs(delta_s)) / 2)


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
