extends RefCounted


static func coords_key(q: int, r: int) -> String:
	return "%d:%d" % [q, r]


static func distance(from_q: int, from_r: int, to_q: int, to_r: int) -> int:
	var delta_q: int = to_q - from_q
	var delta_r: int = to_r - from_r
	var delta_s: int = -delta_q - delta_r
	return int((abs(delta_q) + abs(delta_r) + abs(delta_s)) / 2)


static func adjacent_offsets() -> Array[Vector2i]:
	return [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
