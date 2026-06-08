extends Node

@export var growth_interval: float = 60.0
@export var required_food: int = 10

@onready var hex_grid: Node = get_parent().get_node("HexGrid")

var growth_timer: float = 0.0


func _process(delta: float) -> void:
	if hex_grid == null:
		return

	var free_housing_value: int = int(hex_grid.get("free_housing"))
	var food_value: int = int(hex_grid.get("food"))
	if free_housing_value <= 0 or food_value < required_food:
		growth_timer = 0.0
		return

	growth_timer += delta
	while growth_timer >= growth_interval:
		growth_timer -= growth_interval
		if not _can_grow_population():
			growth_timer = 0.0
			return
		_grow_population()


func _can_grow_population() -> bool:
	var free_housing_value: int = int(hex_grid.get("free_housing"))
	var food_value: int = int(hex_grid.get("food"))
	return free_housing_value > 0 and food_value >= required_food


func _grow_population() -> void:
	var current_population: int = int(hex_grid.get("population"))
	hex_grid.call("_set_population", current_population + 1)
	hex_grid.emit_signal("message_changed", "+1 Bewohner")
