extends RefCounted


static func get_workplaces_for_building_name(building_workplaces: Dictionary, building_name: String) -> int:
	if not building_workplaces.has(building_name):
		return 0
	return int(building_workplaces[building_name])


static func get_job_name_for_building(building_name: String) -> String:
	if building_name == "Holzfällerhütte":
		return "Holzfäller"
	if building_name == "Steinmine":
		return "Bergarbeiter"
	if building_name == "Beerensammler":
		return "Sammler"
	if building_name == "Bauernhof":
		return "Bauer"
	return "-"


static func is_building_currently_producing(
	building_name: String,
	assigned_workers: int,
	wood_production: int,
	stone_production: int,
	food_production: int
) -> bool:
	if assigned_workers <= 0:
		return false
	if building_name == "Holzfällerhütte":
		return wood_production > 0
	if building_name == "Steinmine":
		return stone_production > 0
	if building_name == "Beerensammler" or building_name == "Bauernhof":
		return food_production > 0
	return false


static func get_cycle_production_text(building_name: String, wood_production: int, stone_production: int, food_production: int) -> String:
	if building_name == "Holzfällerhütte":
		return format_cycle_production_text(wood_production, "Holz")
	if building_name == "Steinmine":
		return format_cycle_production_text(stone_production, "Stein")
	if building_name == "Beerensammler" or building_name == "Bauernhof":
		return format_cycle_production_text(food_production, "Nahrung")
	return "Produktion: 0 / 5s"


static func format_cycle_production_text(amount: int, resource_name: String) -> String:
	if amount <= 0:
		return "Produktion: 0 %s / 5s" % resource_name
	return "Produktion: +%d %s / 5s" % [amount, resource_name]


static func format_rate_production_text(amount: int, resource_name: String, production_interval: float) -> String:
	var rate_text: String = _format_rate(amount, production_interval)
	return "Produktion: +%s %s/s" % [rate_text, resource_name]


static func _format_rate(amount_per_cycle: int, production_interval: float) -> String:
	if production_interval <= 0.0:
		return "0,0"
	var rate: float = float(amount_per_cycle) / production_interval
	var rate_text: String = "%.1f" % rate
	return rate_text.replace(".", ",")
