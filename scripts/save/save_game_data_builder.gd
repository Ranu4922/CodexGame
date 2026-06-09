extends RefCounted


static func create_tile_coords_data(tile: MeshInstance3D) -> Dictionary:
	return {
		"q": int(tile.get_meta("q")),
		"r": int(tile.get_meta("r")),
	}


static func copy_resident_data(resident_list: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for resident_value in resident_list:
		var resident_data: Dictionary = resident_value as Dictionary
		result.append(resident_data.duplicate(true))
	return result


static func create_building_save_data(tiles_by_coords: Dictionary) -> Array[Dictionary]:
	var buildings: Array[Dictionary] = []
	for tile_value in tiles_by_coords.values():
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if not bool(tile.get_meta("has_building")):
			continue
		var building_data: Dictionary = create_tile_coords_data(tile)
		var building_type: String = String(tile.get_meta("building_type", ""))
		building_data["type"] = building_type
		building_data["name"] = String(tile.get_meta("building_name", ""))
		building_data["tile_type"] = String(tile.get_meta("tile_type", ""))
		building_data["assigned_resident_id"] = int(tile.get_meta("assigned_resident_id", 0))
		if building_type == "lumberjack_hut" and tile.has_meta("building_level"):
			building_data["building_level"] = int(tile.get_meta("building_level"))
		buildings.append(building_data)
	return buildings
