extends Label

var game_world: Node
var hex_grid: Node
var population_growth: Node


func _ready() -> void:
	game_world = _find_game_world()
	if game_world == null:
		return
	hex_grid = game_world.get_node_or_null("HexGrid")
	population_growth = game_world.get_node_or_null("PopulationGrowth")
	_update_growth_info()


func _process(_delta: float) -> void:
	if hex_grid == null or population_growth == null:
		return
	_update_growth_info()


func _find_game_world() -> Node:
	var current_node: Node = self
	while current_node != null:
		if current_node.name == "GameWorld":
			return current_node
		current_node = current_node.get_parent()
	return null


func _update_growth_info() -> void:
	var growth_active: bool = bool(population_growth.call("get_growth_active"))
	var status_text: String = "Aktiv" if growth_active else "Blockiert"
	var required_food: int = int(population_growth.call("get_required_food"))
	var lines: PackedStringArray = PackedStringArray([
		"",
		"Wachstum",
		"Status: %s" % status_text,
		"Benötigte Nahrung: %d" % required_food,
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
