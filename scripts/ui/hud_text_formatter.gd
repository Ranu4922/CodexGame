extends RefCounted


static func wood_text(amount: int) -> String:
	return "Holz: %d" % amount


static func stone_text(amount: int) -> String:
	return "Stein: %d" % amount


static func food_text(amount: int) -> String:
	return "Nahrung: %d" % amount


static func population_text(population: int, housing_capacity: int) -> String:
	return "Bewohner: %d / Wohnraum %d" % [population, housing_capacity]


static func unemployed_text(unemployed: int) -> String:
	return "Arbeitslos: %d" % unemployed


static func build_mode_text(enabled: bool) -> String:
	if enabled:
		return "Baumodus: AN"
	return "Baumodus: AUS"
