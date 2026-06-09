extends RefCounted


static func create_definitions(
	house_wood_cost: int,
	lumberjack_hut_wood_cost: int,
	stone_mine_wood_cost: int,
	berry_gatherer_wood_cost: int
) -> Dictionary:
	return {
		"village_center": {"name": "Dorfzentrum", "build_costs": {"wood": 0, "stone": 0}, "allowed_tile_types": ["Gras", "Wald", "Stein"], "housing": 2, "production": 0, "production_resource": "", "workplaces": 0, "job_type": ""},
		"house": {"name": "Wohnhaus", "build_costs": {"wood": house_wood_cost, "stone": 0}, "allowed_tile_types": ["Gras", "Wald", "Stein"], "housing": 2, "production": 0, "production_resource": "", "workplaces": 0, "job_type": ""},
		"lumberjack_hut": {"name": "Holzfällerhütte", "build_costs": {"wood": lumberjack_hut_wood_cost, "stone": 0}, "allowed_tile_types": ["Wald"], "housing": 0, "production": 1, "production_resource": "Holz", "workplaces": 1, "job_type": "Holzfäller"},
		"berry_gatherer": {"name": "Beerensammler", "build_costs": {"wood": berry_gatherer_wood_cost, "stone": 0}, "allowed_tile_types": ["Wald"], "housing": 0, "production": 1, "production_resource": "Nahrung", "workplaces": 1, "job_type": "Sammler"},
		"stone_mine": {"name": "Steinmine", "build_costs": {"wood": stone_mine_wood_cost, "stone": 0}, "allowed_tile_types": ["Stein"], "housing": 0, "production": 1, "production_resource": "Stein", "workplaces": 1, "job_type": "Bergarbeiter"},
	}


static func get_definition(building_definitions: Dictionary, building_type: String) -> Dictionary:
	if not building_definitions.has(building_type):
		return {}
	return building_definitions[building_type] as Dictionary


static func get_display_name(building_definitions: Dictionary, building_type: String) -> String:
	var definition: Dictionary = get_definition(building_definitions, building_type)
	if definition.is_empty():
		return "-"
	return String(definition["name"])


static func get_wood_cost(building_definitions: Dictionary, building_type: String) -> int:
	var definition: Dictionary = get_definition(building_definitions, building_type)
	if definition.is_empty():
		return 0
	var build_costs: Dictionary = definition["build_costs"] as Dictionary
	if not build_costs.has("wood"):
		return 0
	return int(build_costs["wood"])


static func get_housing(building_definitions: Dictionary, building_type: String) -> int:
	var definition: Dictionary = get_definition(building_definitions, building_type)
	if definition.is_empty():
		return 0
	return int(definition["housing"])


static func get_workplaces(building_definitions: Dictionary, building_type: String) -> int:
	var definition: Dictionary = get_definition(building_definitions, building_type)
	if definition.is_empty():
		return 0
	return int(definition["workplaces"])


static func get_job_type(building_definitions: Dictionary, building_type: String) -> String:
	var definition: Dictionary = get_definition(building_definitions, building_type)
	if definition.is_empty():
		return ""
	return String(definition["job_type"])


static func get_production(building_definitions: Dictionary, building_type: String) -> int:
	var definition: Dictionary = get_definition(building_definitions, building_type)
	if definition.is_empty():
		return 0
	return int(definition["production"])


static func is_tile_type_allowed(building_definitions: Dictionary, tile_type: String, building_type: String) -> bool:
	var definition: Dictionary = get_definition(building_definitions, building_type)
	if definition.is_empty():
		return false
	var allowed_tile_types: Array = definition["allowed_tile_types"] as Array
	return allowed_tile_types.has(tile_type)
