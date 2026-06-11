extends RefCounted

var seed: int = 0
var tiles_by_coords: Dictionary = {}
var buildings_by_coords: Dictionary = {}
var village_center_coords: Vector2i = Vector2i.ZERO
var has_village_center: bool = false


func sync_from_hex_grid(hex_grid: Node) -> void:
	seed = int(hex_grid.get("generation_seed"))
	tiles_by_coords.clear()
	buildings_by_coords.clear()
	has_village_center = false

	var grid_tiles: Dictionary = hex_grid.get("tiles_by_coords") as Dictionary
	for tile_value in grid_tiles.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		_store_tile_data(tile)
		if bool(tile.get_meta("has_building")):
			_store_building_data(tile)


func _store_tile_data(tile: MeshInstance3D) -> void:
	var q: int = int(tile.get_meta("q"))
	var r: int = int(tile.get_meta("r"))
	var key: String = _coords_key(q, r)
	var tile_data: Dictionary = {
		"q": q,
		"r": r,
		"coords": Vector2i(q, r),
		"tile_type": String(tile.get_meta("tile_type")),
		"buildable": bool(tile.get_meta("buildable")),
		"has_building": bool(tile.get_meta("has_building")),
	}
	tiles_by_coords[key] = tile_data


func _store_building_data(tile: MeshInstance3D) -> void:
	var q: int = int(tile.get_meta("q"))
	var r: int = int(tile.get_meta("r"))
	var key: String = _coords_key(q, r)
	var building_type: String = String(tile.get_meta("building_type", ""))
	var building_data: Dictionary = {
		"q": q,
		"r": r,
		"coords": Vector2i(q, r),
		"type": building_type,
		"name": String(tile.get_meta("building_name", "")),
		"tile_type": String(tile.get_meta("tile_type")),
	}
	if tile.has_meta("building_level"):
		building_data["building_level"] = int(tile.get_meta("building_level"))
	buildings_by_coords[key] = building_data

	if building_type == "village_center":
		village_center_coords = Vector2i(q, r)
		has_village_center = true


func get_tile_data(q: int, r: int) -> Dictionary:
	var tile_value: Variant = tiles_by_coords.get(_coords_key(q, r))
	if tile_value is Dictionary:
		var tile_data: Dictionary = tile_value as Dictionary
		return tile_data.duplicate(true)
	return {}


func get_building_data(q: int, r: int) -> Dictionary:
	var building_value: Variant = buildings_by_coords.get(_coords_key(q, r))
	if building_value is Dictionary:
		var building_data: Dictionary = building_value as Dictionary
		return building_data.duplicate(true)
	return {}


func get_building_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for building_value in buildings_by_coords.values():
		if building_value is Dictionary:
			var building_data: Dictionary = building_value as Dictionary
			result.append(building_data.duplicate(true))
	return result


func _coords_key(q: int, r: int) -> String:
	return "%d:%d" % [q, r]
