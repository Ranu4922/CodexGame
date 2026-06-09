extends RefCounted


static func can_afford(wood: int, stone: int, wood_cost: int, stone_cost: int) -> bool:
	return wood >= wood_cost and stone >= stone_cost


static func apply_delta(current_value: int, amount: int) -> int:
	var new_value: int = current_value + amount
	if new_value < 0:
		return 0
	return new_value
