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
	var growth_text: String = "aktiv" if growth_active else "blockiert"
	var required_food: int = int(population_growth.call("get_required_food"))
	var current_food: int = int(hex_grid.get("food"))
	var free_housing: int = int(hex_grid.get("free_housing"))
	var next_resident_text: String = "-"
	var block_reason: String = "-"

	if growth_active:
		var remaining_seconds: int = int(population_growth.call("get_remaining_seconds"))
		next_resident_text = "%d Sekunden" % remaining_seconds
	else:
		block_reason = String(population_growth.call("get_block_reason"))

	var lines: PackedStringArray = PackedStringArray([
		"",
		"Wachstum",
		"Wachstum: %s" % growth_text,
		"Benötigte Nahrung: %d" % required_food,
		"Aktuelle Nahrung: %d" % current_food,
		"Freier Wohnraum: %d" % free_housing,
		"Nächster Bewohner in: %s" % next_resident_text,
		"Blockiert wegen: %s" % block_reason,
	])
	text = "\n".join(lines)
