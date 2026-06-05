extends Node3D

@onready var hex_grid: Node3D = $HexGrid
@onready var build_mode_label: Label = $CanvasLayer/BuildModeLabel
@onready var resource_label: Label = $CanvasLayer/ResourceLabel
@onready var stone_label: Label = $CanvasLayer/StoneLabel
@onready var housing_label: Label = $CanvasLayer/HousingLabel
@onready var population_label: Label = $CanvasLayer/PopulationLabel
@onready var free_housing_label: Label = $CanvasLayer/FreeHousingLabel
@onready var workplace_label: Label = $CanvasLayer/WorkplaceLabel
@onready var free_workplace_label: Label = $CanvasLayer/FreeWorkplaceLabel
@onready var unemployed_label: Label = $CanvasLayer/UnemployedLabel
@onready var lumberjack_worker_label: Label = $CanvasLayer/LumberjackWorkerLabel
@onready var miner_worker_label: Label = $CanvasLayer/MinerWorkerLabel
@onready var selected_building_label: Label = $CanvasLayer/SelectedBuildingLabel
@onready var message_label: Label = $CanvasLayer/MessageLabel
@onready var info_panel: PanelContainer = $CanvasLayer/InfoPanel
@onready var info_label: Label = $CanvasLayer/InfoPanel/InfoLabel
@onready var build_menu: PanelContainer = $CanvasLayer/BuildMenu
@onready var lumberjack_button: Button = $CanvasLayer/BuildMenu/VBoxContainer/LumberjackButton
@onready var house_button: Button = $CanvasLayer/BuildMenu/VBoxContainer/HouseButton
@onready var stone_mine_button: Button = $CanvasLayer/BuildMenu/VBoxContainer/StoneMineButton

var message_version: int = 0
var selected_building_name: String = "-"
var building_workplaces: Dictionary = {
	"lumberjack_hut": 1,
	"stone_mine": 1,
}
var building_name_to_type: Dictionary = {
	"Holzfällerhütte": "lumberjack_hut",
	"Steinmine": "stone_mine",
}
var info_panel_resize_version: int = 0
var info_panel_position: Vector2 = Vector2(16.0, 452.0)
var info_panel_padding: float = 12.0
var info_panel_min_width: float = 300.0
var info_panel_line_spacing: int = 4


func _ready() -> void:
	_configure_info_panel()
	hex_grid.hex_selected.connect(_on_hex_selected)
	hex_grid.selection_cleared.connect(_on_selection_cleared)
	hex_grid.build_mode_changed.connect(_on_build_mode_changed)
	hex_grid.selected_building_changed.connect(_on_selected_building_changed)
	hex_grid.wood_changed.connect(_on_wood_changed)
	hex_grid.stone_changed.connect(_on_stone_changed)
	hex_grid.housing_changed.connect(_on_housing_changed)
	hex_grid.population_changed.connect(_on_population_changed)
	hex_grid.free_housing_changed.connect(_on_free_housing_changed)
	hex_grid.work_changed.connect(_on_work_changed)
	hex_grid.message_changed.connect(_on_message_changed)
	lumberjack_button.pressed.connect(_on_lumberjack_button_pressed)
	house_button.pressed.connect(_on_house_button_pressed)
	stone_mine_button.pressed.connect(_on_stone_mine_button_pressed)
	_on_build_mode_changed(false)
	_on_selected_building_changed("-")
	_on_wood_changed(hex_grid.wood)
	_on_stone_changed(hex_grid.stone)
	_on_housing_changed(hex_grid.housing_capacity)
	_on_population_changed(hex_grid.population)
	_on_free_housing_changed(hex_grid.free_housing)
	_on_work_changed(
		hex_grid.unemployed_count,
		hex_grid.lumberjack_count,
		hex_grid.miner_count,
		hex_grid.workplace_count,
		hex_grid.free_workplace_count
	)
	_on_selection_cleared()


func _on_hex_selected(
	q: int,
	r: int,
	tile_type: String,
	buildable: bool,
	has_building: bool,
	building_name: String,
	assigned_workers: int,
	own_forest: bool,
	adjacent_forests: int,
	wood_production: int,
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
		lines.append("Zugewiesene Arbeiter: %d" % assigned_workers)

	if has_building and building_name == "Holzfällerhütte":
		var own_forest_text: String = "ja" if own_forest else "nein"
		lines.append("Eigenes Wald-Hex: %s" % own_forest_text)
		lines.append("Angrenzende Wälder: %d/6" % adjacent_forests)
		lines.append("Produktion: %d Holz / 5 Sekunden" % wood_production)

	if has_building and building_name == "Steinmine":
		var own_stone_text: String = "ja" if own_stone else "nein"
		lines.append("Eigenes Stein-Hex: %s" % own_stone_text)
		lines.append("Angrenzende Steine: %d/6" % adjacent_stones)
		lines.append("Produktion: %d Stein / 5 Sekunden" % stone_production)

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


func _on_wood_changed(amount: int) -> void:
	resource_label.text = "Holz: %d" % amount


func _on_stone_changed(amount: int) -> void:
	stone_label.text = "Stein: %d" % amount


func _on_housing_changed(amount: int) -> void:
	housing_label.text = "Wohnraum: %d" % amount


func _on_population_changed(amount: int) -> void:
	population_label.text = "Bewohner: %d" % amount


func _on_free_housing_changed(amount: int) -> void:
	free_housing_label.text = "Freier Wohnraum: %d" % amount


func _on_work_changed(unemployed: int, lumberjacks: int, miners: int, workplaces: int, free_workplaces: int) -> void:
	workplace_label.text = "Arbeitsplätze: %d" % workplaces
	free_workplace_label.text = "Freie Arbeitsplätze: %d" % free_workplaces
	unemployed_label.text = "Arbeitslos: %d" % unemployed
	lumberjack_worker_label.text = "Holzfäller: %d" % lumberjacks
	miner_worker_label.text = "Bergarbeiter: %d" % miners


func _get_workplaces_for_building_type(building_type: String) -> int:
	if not building_workplaces.has(building_type):
		return 0
	return int(building_workplaces[building_type])


func _get_workplaces_for_building_name(building_name: String) -> int:
	if not building_name_to_type.has(building_name):
		return 0

	var building_type: String = String(building_name_to_type[building_name])
	return _get_workplaces_for_building_type(building_type)


func _on_message_changed(text: String) -> void:
	message_version += 1
	var current_version: int = message_version
	message_label.text = text
	_clear_message_after_delay(current_version)


func _clear_message_after_delay(version: int) -> void:
	await get_tree().create_timer(2.0).timeout
	if version == message_version:
		message_label.text = ""
