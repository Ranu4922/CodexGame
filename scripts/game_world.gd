extends Node3D

@onready var hex_grid: Node3D = $HexGrid
@onready var build_mode_label: Label = $CanvasLayer/BuildModeLabel
@onready var resource_label: Label = $CanvasLayer/ResourceLabel
@onready var stone_label: Label = $CanvasLayer/StoneLabel
@onready var food_label: Label = $CanvasLayer/FoodLabel
@onready var population_label: Label = $CanvasLayer/PopulationLabel
@onready var unemployed_label: Label = $CanvasLayer/UnemployedLabel
@onready var selected_building_label: Label = $CanvasLayer/SelectedBuildingLabel
@onready var message_label: Label = $CanvasLayer/MessageLabel
@onready var settlement_window: PanelContainer = $CanvasLayer/SettlementWindow
@onready var settlement_title_label: Label = $CanvasLayer/SettlementWindow/VBoxContainer/TitleLabel
@onready var settlement_content_label: Label = $CanvasLayer/SettlementWindow/VBoxContainer/ContentLabel
@onready var info_panel: PanelContainer = $CanvasLayer/InfoPanel
@onready var info_label: Label = $CanvasLayer/InfoPanel/InfoLabel
@onready var build_menu: PanelContainer = $CanvasLayer/BuildMenu
@onready var lumberjack_button: Button = $CanvasLayer/BuildMenu/VBoxContainer/LumberjackButton
@onready var house_button: Button = $CanvasLayer/BuildMenu/VBoxContainer/HouseButton
@onready var stone_mine_button: Button = $CanvasLayer/BuildMenu/VBoxContainer/StoneMineButton
@onready var berry_gatherer_button: Button = $CanvasLayer/BuildMenu/VBoxContainer/BerryGathererButton

var message_version: int = 0
var selected_building_name: String = "-"
var settlement_name: String = "Dorfzentrum"
var current_wood: int = 0
var current_stone: int = 0
var current_food: int = 0
var current_population: int = 0
var current_housing_capacity: int = 0
var current_free_housing: int = 0
var current_unemployed: int = 0
var current_lumberjacks: int = 0
var current_miners: int = 0
var current_gatherers: int = 0
var current_workplaces: int = 0
var current_assigned_workplaces: int = 0
var current_free_workplaces: int = 0
var building_workplaces: Dictionary = {
	"Holzfällerhütte": 1,
	"Steinmine": 1,
	"Beerensammler": 1,
}
var info_panel_resize_version: int = 0
var info_panel_position: Vector2 = Vector2(16.0, 452.0)
var info_panel_padding: float = 12.0
var info_panel_min_width: float = 300.0
var info_panel_line_spacing: int = 4
var settlement_window_width: float = 300.0
var settlement_window_padding: float = 14.0


func _ready() -> void:
	_configure_info_panel()
	_configure_settlement_window()
	hex_grid.hex_selected.connect(_on_hex_selected)
	hex_grid.selection_cleared.connect(_on_selection_cleared)
	hex_grid.build_mode_changed.connect(_on_build_mode_changed)
	hex_grid.selected_building_changed.connect(_on_selected_building_changed)
	hex_grid.wood_changed.connect(_on_wood_changed)
	hex_grid.stone_changed.connect(_on_stone_changed)
	hex_grid.food_changed.connect(_on_food_changed)
	hex_grid.housing_changed.connect(_on_housing_changed)
	hex_grid.population_changed.connect(_on_population_changed)
	hex_grid.free_housing_changed.connect(_on_free_housing_changed)
	hex_grid.work_changed.connect(_on_work_changed)
	hex_grid.message_changed.connect(_on_message_changed)
	lumberjack_button.pressed.connect(_on_lumberjack_button_pressed)
	house_button.pressed.connect(_on_house_button_pressed)
	stone_mine_button.pressed.connect(_on_stone_mine_button_pressed)
	berry_gatherer_button.pressed.connect(_on_berry_gatherer_button_pressed)
	current_population = hex_grid.population
	current_housing_capacity = hex_grid.housing_capacity
	current_free_housing = hex_grid.free_housing
	settlement_window.visible = false
	_on_build_mode_changed(false)
	_on_selected_building_changed("-")
	_on_wood_changed(hex_grid.wood)
	_on_stone_changed(hex_grid.stone)
	_on_food_changed(hex_grid.food)
	_update_population_housing_label()
	_on_work_changed(
		hex_grid.unemployed_count,
		hex_grid.lumberjack_count,
		hex_grid.miner_count,
		hex_grid.workplace_count,
		hex_grid.free_workplace_count
	)
	_on_selection_cleared()
	_update_settlement_window()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_I:
			settlement_window.visible = not settlement_window.visible
			if settlement_window.visible:
				_update_settlement_window()
			get_viewport().set_input_as_handled()
		if key_event.keycode == KEY_ESCAPE and settlement_window.visible:
			settlement_window.visible = false
			get_viewport().set_input_as_handled()


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
	var buildable_text: String = "ja" if buildable else "nein"
	var building_text: String = "nein"
	if has_building:
		building_text = building_name if not building_name.is_empty() else "ja"
	var settlement_text: String = "Ja" if in_settlement_area else "Nein"
	var lines: PackedStringArray = PackedStringArray([
		"Koordinaten: q=%d, r=%d" % [q, r],
		"Tile-Typ: %s" % tile_type,
		"Bebaubar: %s" % buildable_text,
		"Gebäude: %s" % building_text,
		"Im Siedlungsgebiet: %s" % settlement_text,
		"Entfernung zum Dorfzentrum: %d" % village_center_distance,
	])

	if has_building:
		var building_workplace_count: int = _get_workplaces_for_building_name(building_name)
		lines.append("Arbeitsplätze: %d" % building_workplace_count)
		if building_workplace_count > 0:
			var workplace_status: String = "belegt" if assigned_workers > 0 else "unbesetzt"
			var assigned_job_text: String = assigned_job if not assigned_job.is_empty() else _get_job_name_for_building(building_name)
			var produces_currently_text: String = "ja" if _is_building_currently_producing(building_name, assigned_workers, wood_production, stone_production, food_production) else "nein"
			lines.append("Arbeitsplatz: %s" % workplace_status)
			lines.append("Zugewiesener Job: %s" % assigned_job_text)
			lines.append("Produziert aktuell: %s" % produces_currently_text)
			lines.append(_get_production_text(building_name, wood_production, stone_production, food_production))

	if has_building and building_name == "Holzfällerhütte":
		var own_forest_text: String = "ja" if own_forest else "nein"
		lines.append("Eigenes Wald-Hex: %s" % own_forest_text)
		lines.append("Angrenzende Wälder: %d/6" % adjacent_forests)

	if has_building and building_name == "Beerensammler":
		var berry_own_forest_text: String = "ja" if own_forest else "nein"
		lines.append("Eigenes Wald-Hex: %s" % berry_own_forest_text)

	if has_building and building_name == "Steinmine":
		var own_stone_text: String = "ja" if own_stone else "nein"
		lines.append("Eigenes Stein-Hex: %s" % own_stone_text)
		lines.append("Angrenzende Steine: %d/6" % adjacent_stones)

	_set_info_panel_text("\n".join(lines))


func _on_selection_cleared() -> void:
	info_panel_resize_version += 1
	info_panel.visible = false
	info_label.text = ""
	info_label.custom_minimum_size = Vector2.ZERO
	info_label.size = Vector2.ZERO
	info_panel.custom_minimum_size = Vector2.ZERO
	info_panel.size = Vector2.ZERO


func _on_build_mode_changed(enabled: bool) -> void:
	_update_build_mode_label(enabled)
	build_menu.visible = enabled
	selected_building_label.visible = false
	build_mode_label.add_theme_color_override(
		"font_color",
		Color(0.20, 0.85, 0.25) if enabled else Color(0.95, 0.20, 0.18)
	)


func _on_selected_building_changed(display_name: String) -> void:
	selected_building_name = display_name
	selected_building_label.text = "Ausgewähltes Gebäude: %s" % selected_building_name
	_update_build_mode_label(hex_grid.build_mode)


func _update_build_mode_label(enabled: bool) -> void:
	if enabled:
		build_mode_label.text = "Baumodus: AN (%s)" % selected_building_name
	else:
		build_mode_label.text = "Baumodus: AUS"


func _configure_info_panel() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.05, 0.72)
	panel_style.set_content_margin(SIDE_LEFT, info_panel_padding)
	panel_style.set_content_margin(SIDE_TOP, info_panel_padding)
	panel_style.set_content_margin(SIDE_RIGHT, info_panel_padding)
	panel_style.set_content_margin(SIDE_BOTTOM, info_panel_padding)
	info_panel.add_theme_stylebox_override("panel", panel_style)
	info_panel.position = info_panel_position
	info_panel.custom_minimum_size = Vector2.ZERO
	info_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	info_label.add_theme_constant_override("line_spacing", info_panel_line_spacing)


func _configure_settlement_window() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.04, 0.04, 0.78)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	panel_style.shadow_size = 8
	panel_style.set_content_margin(SIDE_LEFT, settlement_window_padding)
	panel_style.set_content_margin(SIDE_TOP, settlement_window_padding)
	panel_style.set_content_margin(SIDE_RIGHT, settlement_window_padding)
	panel_style.set_content_margin(SIDE_BOTTOM, settlement_window_padding)
	settlement_window.add_theme_stylebox_override("panel", panel_style)
	settlement_window.custom_minimum_size = Vector2(settlement_window_width, 0.0)
	settlement_title_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	settlement_content_label.add_theme_constant_override("line_spacing", 3)


func _set_info_panel_text(text: String) -> void:
	info_panel_resize_version += 1
	var current_resize_version: int = info_panel_resize_version
	info_label.text = text
	info_label.custom_minimum_size = Vector2.ZERO
	info_label.size = Vector2.ZERO
	info_panel.custom_minimum_size = Vector2.ZERO
	info_panel.size = Vector2.ZERO
	info_panel.position = info_panel_position
	info_panel.visible = true
	_resize_info_panel_to_content()
	_resize_info_panel_deferred(current_resize_version)


func _resize_info_panel_deferred(resize_version: int) -> void:
	await get_tree().process_frame
	if resize_version != info_panel_resize_version:
		return
	if not info_panel.visible:
		return
	_resize_info_panel_to_content()


func _resize_info_panel_to_content() -> void:
	var font: Font = info_label.get_theme_font("font")
	var font_size: int = info_label.get_theme_font_size("font_size")
	var text_lines: PackedStringArray = info_label.text.split("\n")
	var text_width: float = 0.0

	for text_line in text_lines:
		var line_size: Vector2 = font.get_string_size(text_line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
		text_width = max(text_width, line_size.x)

	var line_height: float = font.get_height(font_size) + float(info_panel_line_spacing) + 4.0
	var text_height: float = float(text_lines.size()) * line_height
	var target_width: float = max(info_panel_min_width, text_width + info_panel_padding * 2.0)
	var target_height: float = text_height + info_panel_padding * 2.0
	var target_size: Vector2 = Vector2(target_width, target_height)
	var label_size: Vector2 = Vector2(text_width, text_height)

	info_panel.position = info_panel_position
	info_panel.custom_minimum_size = target_size
	info_panel.size = target_size
	info_label.custom_minimum_size = label_size
	info_label.size = label_size


func _on_lumberjack_button_pressed() -> void:
	hex_grid.call("select_building", "lumberjack_hut")


func _on_house_button_pressed() -> void:
	hex_grid.call("select_building", "house")


func _on_stone_mine_button_pressed() -> void:
	hex_grid.call("select_building", "stone_mine")


func _on_berry_gatherer_button_pressed() -> void:
	hex_grid.call("select_building", "berry_gatherer")


func _on_wood_changed(amount: int) -> void:
	current_wood = amount
	resource_label.text = "Holz: %d" % amount
	_update_settlement_window_if_visible()


func _on_stone_changed(amount: int) -> void:
	current_stone = amount
	stone_label.text = "Stein: %d" % amount
	_update_settlement_window_if_visible()


func _on_food_changed(amount: int) -> void:
	current_food = amount
	food_label.text = "Nahrung: %d" % amount
	_update_settlement_window_if_visible()


func _on_housing_changed(amount: int) -> void:
	current_housing_capacity = amount
	_update_population_housing_label()
	_update_settlement_window_if_visible()


func _on_population_changed(amount: int) -> void:
	current_population = amount
	_update_population_housing_label()
	_update_settlement_window_if_visible()


func _on_free_housing_changed(amount: int) -> void:
	current_free_housing = amount
	_update_settlement_window_if_visible()


func _update_population_housing_label() -> void:
	population_label.text = "Bewohner: %d / Wohnraum %d" % [current_population, current_housing_capacity]


func _on_work_changed(unemployed: int, lumberjacks: int, miners: int, workplaces: int, free_workplaces: int) -> void:
	current_unemployed = unemployed
	current_lumberjacks = lumberjacks
	current_miners = miners
	current_gatherers = hex_grid.berry_gatherer_count
	current_workplaces = workplaces
	current_free_workplaces = free_workplaces
	current_assigned_workplaces = current_workplaces - current_free_workplaces
	if current_assigned_workplaces < 0:
		current_assigned_workplaces = 0
	unemployed_label.text = "Arbeitslos: %d" % unemployed
	_update_settlement_window_if_visible()


func _update_settlement_window_if_visible() -> void:
	if settlement_window.visible:
		_update_settlement_window()


func _update_settlement_window() -> void:
	settlement_title_label.text = "Siedlung: %s" % settlement_name
	var lines: PackedStringArray = PackedStringArray([
		"Ressourcen",
		"Holz: %d" % current_wood,
		"Stein: %d" % current_stone,
		"Nahrung: %d" % current_food,
		"",
		"Bevölkerung",
		"Bewohner: %d" % current_population,
		"Wohnraum: %d" % current_housing_capacity,
		"Freier Wohnraum: %d" % current_free_housing,
		"Arbeitslos: %d" % current_unemployed,
		"",
		"Berufe",
		"Holzfäller: %d" % current_lumberjacks,
		"Bergarbeiter: %d" % current_miners,
		"Sammler: %d" % current_gatherers,
		"",
		"Arbeitsplätze",
		"Gesamt: %d" % current_workplaces,
		"Belegt: %d" % current_assigned_workplaces,
		"Frei: %d" % current_free_workplaces,
		"",
		"Produktion",
		"Holz: +%d / 5s" % _calculate_settlement_wood_production(),
		"Stein: +%d / 5s" % _calculate_settlement_stone_production(),
		"Nahrung: +%d / 5s" % _calculate_settlement_food_production(),
	])
	settlement_content_label.text = "\n".join(lines)


func _calculate_settlement_wood_production() -> int:
	return _calculate_production_from_tiles(hex_grid.lumberjack_hut_tiles, "lumberjack_production")


func _calculate_settlement_stone_production() -> int:
	return _calculate_production_from_tiles(hex_grid.stone_mine_tiles, "stone_mine_production")


func _calculate_settlement_food_production() -> int:
	return _calculate_production_from_tiles(hex_grid.berry_gatherer_tiles, "food_production")


func _calculate_production_from_tiles(tiles: Array, production_meta_name: String) -> int:
	var production: int = 0
	for tile_value in tiles:
		var tile: MeshInstance3D = tile_value as MeshInstance3D
		if tile == null:
			continue
		if not tile.has_meta(production_meta_name):
			continue
		if not _tile_has_assigned_worker(tile):
			continue
		production += int(tile.get_meta(production_meta_name))
	return production


func _tile_has_assigned_worker(tile: MeshInstance3D) -> bool:
	if not tile.has_meta("assigned_workers"):
		return false
	return int(tile.get_meta("assigned_workers")) > 0


func _get_workplaces_for_building_name(building_name: String) -> int:
	if not building_workplaces.has(building_name):
		return 0
	return int(building_workplaces[building_name])


func _get_job_name_for_building(building_name: String) -> String:
	if building_name == "Holzfällerhütte":
		return "Holzfäller"
	if building_name == "Steinmine":
		return "Bergarbeiter"
	if building_name == "Beerensammler":
		return "Sammler"
	return "-"


func _is_building_currently_producing(building_name: String, assigned_workers: int, wood_production: int, stone_production: int, food_production: int) -> bool:
	if assigned_workers <= 0:
		return false
	if building_name == "Holzfällerhütte":
		return wood_production > 0
	if building_name == "Steinmine":
		return stone_production > 0
	if building_name == "Beerensammler":
		return food_production > 0
	return false


func _get_production_text(building_name: String, wood_production: int, stone_production: int, food_production: int) -> String:
	if building_name == "Holzfällerhütte":
		return _format_building_production_text(wood_production, "Holz")
	if building_name == "Steinmine":
		return _format_building_production_text(stone_production, "Stein")
	if building_name == "Beerensammler":
		return _format_building_production_text(food_production, "Nahrung")
	return "Produktion: 0 / 5s"


func _format_building_production_text(amount: int, resource_name: String) -> String:
	if amount <= 0:
		return "Produktion: 0 %s / 5s" % resource_name
	return "Produktion: +%d %s / 5s" % [amount, resource_name]


func _on_message_changed(text: String) -> void:
	message_version += 1
	var current_version: int = message_version
	message_label.text = text
	_clear_message_after_delay(current_version)


func _clear_message_after_delay(version: int) -> void:
	await get_tree().create_timer(2.0).timeout
	if version == message_version:
		message_label.text = ""
