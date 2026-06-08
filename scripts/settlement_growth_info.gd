extends Label

@onready var game_world: Node = get_tree().current_scene
@onready var hex_grid: Node = game_world.get_node("HexGrid")
@onready var population_growth: Node = game_world.get_node("PopulationGrowth")


func _process(_delta: float) -> void:
	if hex_grid == null or population_growth == null:
		return
	_update_growth_info()


func _update_growth_info() -> void:
	var growth_active: bool = bool(population_growth.call("get_growth_active"))
	var status_text: String = "Aktiv" if growth_active else "Blockiert"
	var required_food: int = int(population_growth.call("get_required_food"))
	var current_food: int = int(hex_grid.get("food"))
	var free_housing: int = int(hex_grid.get("free_housing"))
	var lines: PackedStringArray = PackedStringArray([
		"",
		"Wachstum",
		"Status: %s" % status_text,
		"Benötigte Nahrung: %d" % required_food,
		"Aktuelle Nahrung: %d" % current_food,
		"Freier Wohnraum: %d" % free_housing,
	])

	if growth_active:
		var remaining_seconds: int = int(population_growth.call("get_remaining_seconds"))
		lines.append("Nächster Bewohner in: %d Sekunden" % remaining_seconds)
	else:
		lines.append("Grund: %s" % _get_display_block_reason())

	text = "\n".join(lines)


func _get_display_block_reason() -> String:
	var block_reason: String = String(population_growth.call("get_block_reason"))
	if block_reason == "zu wenig Nahrung":
		return "Zu wenig Nahrung"
	if block_reason == "kein freier Wohnraum":
		return "Kein freier Wohnraum"
	return block_reason
