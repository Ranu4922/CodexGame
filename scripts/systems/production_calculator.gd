extends RefCounted


static func calculate_from_tiles(tiles: Array, production_meta_name: String) -> int:
	var production: int = 0
	for tile_value in tiles:
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if not tile.has_meta(production_meta_name):
			continue
		if not tile_has_assigned_worker(tile):
			continue
		production += int(tile.get_meta(production_meta_name))
	return production


static func tile_has_assigned_worker(tile: MeshInstance3D) -> bool:
	if not tile.has_meta("assigned_workers"):
		return false
	return int(tile.get_meta("assigned_workers")) > 0


static func format_rate(amount_per_cycle: int, production_interval: float) -> String:
	if production_interval <= 0.0:
		return "0,0"
	var rate: float = float(amount_per_cycle) / production_interval
	var rate_text: String = "%.1f" % rate
	return rate_text.replace(".", ",")


static func collect_basic_production(
	lumberjack_hut_tiles: Array,
	stone_mine_tiles: Array,
	berry_gatherer_tiles: Array
) -> Dictionary:
	return {
		"wood": calculate_from_tiles(lumberjack_hut_tiles, "lumberjack_production"),
		"stone": calculate_from_tiles(stone_mine_tiles, "stone_mine_production"),
		"food": calculate_from_tiles(berry_gatherer_tiles, "food_production"),
	}
