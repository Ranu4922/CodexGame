extends Node

@export var growth_interval: float = 60.0
@export var food_per_resident: int = 10
@export var base_food_requirement: int = 10

@onready var hex_grid: Node = get_parent().get_node("HexGrid")

var growth_timer: float = 0.0


func _process(delta: float) -> void:
	if hex_grid == null:
		return
	if not _can_grow_population():
		return

	growth_timer += delta
	while growth_timer >= growth_interval:
		growth_timer -= growth_interval
		if not _can_grow_population():
			return
		_grow_population()


func get_required_food() -> int:
	var current_population: int = int(hex_grid.get("population"))
	return current_population * food_per_resident + base_food_requirement


func get_growth_active() -> bool:
	return _can_grow_population()


func get_remaining_seconds() -> int:
	if not _can_grow_population():
		return 0
	var remaining_seconds: float = growth_interval - growth_timer
	if remaining_seconds < 0.0:
		remaining_seconds = 0.0
	return int(ceil(remaining_seconds))


func get_block_reason() -> String:
	var free_housing_value: int = int(hex_grid.get("free_housing"))
	var food_value: int = int(hex_grid.get("food"))
	if free_housing_value <= 0:
		return "kein freier Wohnraum"
	if food_value < get_required_food():
		return "zu wenig Nahrung"
	return "-"


func _can_grow_population() -> bool:
	var free_housing_value: int = int(hex_grid.get("free_housing"))
	var food_value: int = int(hex_grid.get("food"))
	return free_housing_value > 0 and food_value >= get_required_food()


func _grow_population() -> void:
	var current_population: int = int(hex_grid.get("population"))
	hex_grid.call("_set_population", current_population + 1)
	hex_grid.emit_signal("message_changed", "+1 Bewohner")
