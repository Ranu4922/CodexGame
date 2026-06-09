extends Node

@onready var game_world: Node = get_parent()
@onready var hex_grid: Node = get_parent().get_node("HexGrid")
@onready var farm_controller: Node = get_parent().get_node("FarmController")
@onready var info_label: Label = get_parent().get_node("CanvasLayer/InfoPanel/InfoLabel")
@onready var settlement_window: PanelContainer = get_parent().get_node("CanvasLayer/SettlementWindow")
@onready var settlement_content_label: Label = get_parent().get_node("CanvasLayer/SettlementWindow/VBoxContainer/ContentLabel")
@onready var unemployed_label: Label = get_parent().get_node("CanvasLayer/UnemployedLabel")


func _ready() -> void:
	hex_grid.hex_selected.connect(_on_hex_selected)


func _process(_delta: float) -> void:
	_update_unemployed_label()
	_update_settlement_window_display()


func _on_hex_selected(
	q: int,
	r: int,
	tile_type: String,
	buildable: bool,
	has_building: bool,
	building_name: String,
	assigned_workers: int,
	assigned_job: String,
	own_forest: bool,
	adjacent_forests: int,
	wood_production: int,
	food_production: int,
	own_stone: bool,
	adjacent_stones: int,
	stone_production: int,
	in_settlement_area: bool,
	village_center_distance: int
) -> void:
	await get_tree().process_frame
	if building_name == "Bauernhof":
		_show_farm_info(q, r, tile_type, buildable, has_building, building_name, assigned_workers, assigned_job, food_production, in_settlement_area, village_center_distance)
		return
	_update_info_panel_production_line(building_name, wood_production, stone_production, food_production)


func _show_farm_info(
	q: int,
	r: int,
	tile_type: String,
	buildable: bool,
	has_building: bool,
	building_name: String,
	assigned_workers: int,
	assigned_job: String,
	food_production: int,
	in_settlement_area: bool,
	village_center_distance: int
) -> void:
	if not has_building:
		return
	var buildable_text: String = "ja" if buildable else "nein"
	var settlement_text: String = "Ja" if in_settlement_area else "Nein"
	var workplace_status: String = "belegt" if assigned_workers > 0 else "unbesetzt"
	var produces_currently_text: String = "ja" if assigned_workers > 0 and food_production > 0 else "nein"
	var job_text: String = assigned_job if not assigned_job.is_empty() else "Bauer"
	var displayed_food_production: int = food_production if assigned_workers > 0 else 0
	var lines: PackedStringArray = PackedStringArray([
		"Koordinaten: q=%d, r=%d" % [q, r],
		"Tile-Typ: %s" % tile_type,
		"Bebaubar: %s" % buildable_text,
		"Gebäude: %s" % building_name,
		"Im Siedlungsgebiet: %s" % settlement_text,
		"Entfernung zum Dorfzentrum: %d" % village_center_distance,
		"Arbeitsplätze: 1",
		"Arbeitsplatz: %s" % workplace_status,
		"Zugewiesener Job: %s" % job_text,
		"Produziert aktuell: %s" % produces_currently_text,
		"Produktion: +%s Nahrung/s" % _format_rate(displayed_food_production),
	])
	game_world.call("_set_info_panel_text", "\n".join(lines))


func _update_info_panel_production_line(building_name: String, wood_production: int, stone_production: int, food_production: int) -> void:
	if info_label.text.is_empty():
		return
	var resource_name: String = ""
	var production_amount: int = 0
	if building_name == "Holzfällerhütte":
		resource_name = "Holz"
		production_amount = wood_production
	if building_name == "Steinmine":
		resource_name = "Stein"
		production_amount = stone_production
	if building_name == "Beerensammler":
		resource_name = "Nahrung"
		production_amount = food_production
	if resource_name.is_empty():
		return
	var lines: PackedStringArray = info_label.text.split("\n")
	for line_index in range(lines.size()):
		var line_text: String = lines[line_index]
		if line_text.begins_with("Produktion:"):
			lines[line_index] = "Produktion: +%s %s/s" % [_format_rate(production_amount), resource_name]
	info_label.text = "\n".join(lines)


func _update_unemployed_label() -> void:
	var adjusted_unemployed: int = int(farm_controller.call("get_adjusted_unemployed_count"))
	unemployed_label.text = "Arbeitslos: %d" % adjusted_unemployed


func _update_settlement_window_display() -> void:
	if not settlement_window.visible:
		return
	if settlement_content_label.text.is_empty():
		return
	var lines: PackedStringArray = settlement_content_label.text.split("\n")
	var farmer_count: int = int(farm_controller.get("farmer_count"))
	var farmer_line_exists: bool = false
	var total_workplaces: int = int(farm_controller.call("get_total_workplaces"))
	var assigned_workplaces: int = int(farm_controller.call("get_assigned_workplaces"))
	var free_workplaces: int = int(farm_controller.call("get_free_workplaces"))
	var adjusted_unemployed: int = int(farm_controller.call("get_adjusted_unemployed_count"))
	var wood_rate: String = _format_rate(_calculate_production_from_tiles(hex_grid.get("lumberjack_hut_tiles") as Array, "lumberjack_production"))
	var stone_rate: String = _format_rate(_calculate_production_from_tiles(hex_grid.get("stone_mine_tiles") as Array, "stone_mine_production"))
	var food_cycle_amount: int = _calculate_production_from_tiles(hex_grid.get("berry_gatherer_tiles") as Array, "food_production") + int(farm_controller.call("get_farm_food_production_per_cycle"))
	var food_rate: String = _format_rate(food_cycle_amount)

	for line_text in lines:
		if line_text.begins_with("Bauer:"):
			farmer_line_exists = true

	for line_index in range(lines.size()):
		var line_text: String = lines[line_index]
		if line_text.begins_with("Arbeitslos:"):
			lines[line_index] = "Arbeitslos: %d" % adjusted_unemployed
		if line_text.begins_with("Bauer:"):
			lines[line_index] = "Bauer: %d" % farmer_count
		if line_text.begins_with("Sammler:") and not farmer_line_exists:
			lines.insert(line_index + 1, "Bauer: %d" % farmer_count)
			farmer_line_exists = true
		if line_text.begins_with("Gesamt:"):
			lines[line_index] = "Gesamt: %d" % total_workplaces
		if line_text.begins_with("Belegt:"):
			lines[line_index] = "Belegt: %d" % assigned_workplaces
		if line_text.begins_with("Frei:"):
			lines[line_index] = "Frei: %d" % free_workplaces
		if line_text.begins_with("Holz: +"):
			lines[line_index] = "Holz: +%s/s" % wood_rate
		if line_text.begins_with("Stein: +"):
			lines[line_index] = "Stein: +%s/s" % stone_rate
		if line_text.begins_with("Nahrung: +"):
			lines[line_index] = "Nahrung: +%s/s" % food_rate
	settlement_content_label.text = "\n".join(lines)


func _calculate_production_from_tiles(tiles: Array, production_meta_name: String) -> int:
	var production: int = 0
	for tile_value in tiles:
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if not tile.has_meta(production_meta_name):
			continue
		if not tile.has_meta("assigned_workers"):
			continue
		if int(tile.get_meta("assigned_workers")) <= 0:
			continue
		production += int(tile.get_meta(production_meta_name))
	return production


func _format_rate(amount_per_cycle: int) -> String:
	var production_interval: float = float(hex_grid.get("production_interval"))
	if production_interval <= 0.0:
		return "0,0"
	var rate: float = float(amount_per_cycle) / production_interval
	var rate_text: String = "%.1f" % rate
	return rate_text.replace(".", ",")
