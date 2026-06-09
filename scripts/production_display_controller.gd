extends Node

const ProductionCalculator = preload("res://scripts/systems/production_calculator.gd")
const HudTextFormatter = preload("res://scripts/ui/hud_text_formatter.gd")

@onready var game_world: Node = get_parent()
@onready var hex_grid: Node = get_parent().get_node("HexGrid")
@onready var farm_controller: Node = get_parent().get_node("FarmController")
@onready var building_detail_label: Label = get_parent().get_node("CanvasLayer/BuildingDetailPanel/BuildingDetailLabel")
@onready var settlement_window: PanelContainer = get_parent().get_node("CanvasLayer/SettlementWindow")
@onready var settlement_content_label: Label = get_parent().get_node("CanvasLayer/SettlementWindow/VBoxContainer/ContentLabel")
@onready var unemployed_label: Label = get_parent().get_node("CanvasLayer/UnemployedLabel")


func _ready() -> void:
	hex_grid.hex_selected.connect(_on_hex_selected)


func _process(_delta: float) -> void:
	_update_unemployed_label()
	_update_settlement_window_display()


func _on_hex_selected(
	_q: int,
	_r: int,
	_tile_type: String,
	_buildable: bool,
	_has_building: bool,
	building_name: String,
	_assigned_workers: int,
	_assigned_job: String,
	_own_forest: bool,
	_adjacent_forests: int,
	wood_production: int,
	food_production: int,
	_own_stone: bool,
	_adjacent_stones: int,
	stone_production: int,
	_in_settlement_area: bool,
	_village_center_distance: int
) -> void:
	await get_tree().process_frame
	_update_building_detail_production_line(building_name, wood_production, stone_production, food_production)


func _update_building_detail_production_line(building_name: String, wood_production: int, stone_production: int, food_production: int) -> void:
	if building_detail_label.text.is_empty():
		return
	var resource_name: String = ""
	var production_amount: int = 0
	if building_name == "Holzfällerhütte":
		resource_name = "Holz"
		production_amount = wood_production
	if building_name == "Steinmine":
		resource_name = "Stein"
		production_amount = stone_production
	if building_name == "Beerensammler" or building_name == "Bauernhof":
		resource_name = "Nahrung"
		production_amount = food_production
	if resource_name.is_empty():
		return
	var lines: PackedStringArray = building_detail_label.text.split("\n")
	for line_index in range(lines.size()):
		var line_text: String = lines[line_index]
		if line_text.begins_with("Produktion:"):
			lines[line_index] = "Produktion: +%s %s/s" % [_format_rate(production_amount), resource_name]
	building_detail_label.text = "\n".join(lines)
	if game_world.has_method("_set_building_detail_panel_text"):
		game_world.call("_set_building_detail_panel_text", building_detail_label.text)


func _update_unemployed_label() -> void:
	var adjusted_unemployed: int = int(farm_controller.call("get_adjusted_unemployed_count"))
	unemployed_label.text = HudTextFormatter.unemployed_text(adjusted_unemployed)


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
	return ProductionCalculator.calculate_from_tiles(tiles, production_meta_name)


func _format_rate(amount_per_cycle: int) -> String:
	var production_interval: float = float(hex_grid.get("production_interval"))
	return ProductionCalculator.format_rate(amount_per_cycle, production_interval)
