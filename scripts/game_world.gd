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
var workplace_count: int = 0
var assigned_workplace_count: int = 0
var free_workplace_count: int = 0
var building_workplaces: Dictionary = {
	"lumberjack_hut": 1,
	"stone_mine": 1,
}
var building_name_to_type: Dictionary = {
	"Holzfällerhütte": "lumberjack_hut",
	"Steinmine": "stone_mine",
}


func _ready() -> void:
	hex_grid.hex_selected.connect(_on_hex_selected)
	hex_grid.selection_cleared.connect(_on_selection_cleared)
	hex_grid.build_mode_changed.connect(_on_build_mode_changed)
	hex_grid.selected_building_changed.connect(_on_selected_building_changed)
	hex_grid.wood_changed.connect(_on_wood_changed)
	hex_grid.stone_changed.connect(_on_stone_changed)
	hex_grid.housing_changed.connect(_on_housing_changed)
	hex_grid.population_changed.connect(_on_population_changed)
	hex_grid.free_housing_changed.connect(_on_free_housing_changed)
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
	_update_workplace_labels()
	_on_selection_cleared()


func _process(_delta: float) -> void:
	_update_workplace_labels()


func _on_hex_selected(
	q: int,
	r: int,
	tile_type: String,
	buildable: bool,
	has_building: bool,
	building_name: String,
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

	info_label.text = "\n".join(lines)
	info_panel.visible = true


func _on_selection_cleared() -> void:
	info_panel.visible = false
	info_label.text = ""


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


func _update_workplace_labels() -> void:
	workplace_count = _calculate_workplace_count()
	free_workplace_count = workplace_count - assigned_workplace_count
	if free_workplace_count < 0:
		free_workplace_count = 0

	workplace_label.text = "Arbeitsplätze: %d" % workplace_count
	free_workplace_label.text = "Freie Arbeitsplätze: %d" % free_workplace_count


func _calculate_workplace_count() -> int:
	var total_workplaces: int = 0
	var tile_nodes: Array[Node] = hex_grid.get_children()

	for tile_node in tile_nodes:
		if tile_node is MeshInstance3D and tile_node.has_meta("building_type"):
			var building_type: String = String(tile_node.get_meta("building_type"))
			total_workplaces += _get_workplaces_for_building_type(building_type)

	return total_workplaces


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
