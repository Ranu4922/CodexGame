extends RefCounted


static func create_lines(data: Dictionary) -> PackedStringArray:
	return PackedStringArray([
		"Ressourcen",
		"Holz: %d" % int(data["wood"]),
		"Stein: %d" % int(data["stone"]),
		"Nahrung: %d" % int(data["food"]),
		"",
		"Bevölkerung",
		"Bewohner: %d" % int(data["population"]),
		"Wohnraum: %d" % int(data["housing_capacity"]),
		"Freier Wohnraum: %d" % int(data["free_housing"]),
		"Arbeitslos: %d" % int(data["unemployed"]),
		"",
		"Berufe",
		"Holzfäller: %d" % int(data["lumberjacks"]),
		"Bergarbeiter: %d" % int(data["miners"]),
		"Sammler: %d" % int(data["gatherers"]),
		"",
		"Arbeitsplätze",
		"Gesamt: %d" % int(data["workplaces"]),
		"Belegt: %d" % int(data["assigned_workplaces"]),
		"Frei: %d" % int(data["free_workplaces"]),
		"",
		"Produktion",
		"Holz: +%d / 5s" % int(data["wood_production"]),
		"Stein: +%d / 5s" % int(data["stone_production"]),
		"Nahrung: +%d / 5s" % int(data["food_production"]),
	])
