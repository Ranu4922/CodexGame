extends Node

const WorldData = preload("res://scripts/data/world_data.gd")

# Main starts in the first player world prototype and opens the settlement
# management view when the player interacts with the village center.

@onready var start_menu: Control = $StartMenu
@onready var player_world: Node = $PlayerWorld
@onready var settlement_management_view: Node = $SettlementManagementView

var world_data: RefCounted = WorldData.new()


func _ready() -> void:
	print("Hex Survival MVP gestartet")
	player_world.call("set_world_data", world_data)
	settlement_management_view.call("set_world_data", world_data)
	settlement_management_view.call("reset_settlement_ui_state")
	player_world.call("set_active", false)
	player_world.process_mode = Node.PROCESS_MODE_DISABLED
	settlement_management_view.visible = false
	settlement_management_view.process_mode = Node.PROCESS_MODE_DISABLED
	start_menu.visible = true
	start_menu.connect("new_game_requested", Callable(self, "_on_new_game_requested"))
	start_menu.connect("load_game_requested", Callable(self, "_on_load_game_requested"))
	start_menu.connect("quit_requested", Callable(self, "_on_quit_requested"))
	player_world.connect("settlement_management_requested", Callable(self, "_open_settlement_management_view"))
	settlement_management_view.connect("management_exit_requested", Callable(self, "_open_player_world"))


func _on_new_game_requested(seed_text: String) -> void:
	var seed: int = _resolve_seed(seed_text)
	_start_new_game(seed)
	start_menu.call("set_message", "Seed: %d" % seed)


func _on_load_game_requested() -> void:
	var save_controller: Node = settlement_management_view.get_node("SaveGameController")
	if not bool(save_controller.call("has_save_game")):
		start_menu.call("set_message", "Kein Spielstand gefunden.")
		return
	var loaded: bool = bool(save_controller.call("load_game"))
	if not loaded:
		start_menu.call("set_message", "Spielstand konnte nicht geladen werden.")
		return
	_open_player_world_from_menu()


func _on_quit_requested() -> void:
	get_tree().quit()


func _start_new_game(seed: int) -> void:
	var hex_grid: Node = settlement_management_view.get_node("HexGrid")
	var world_generation_controller: Node = settlement_management_view.get_node("WorldGenerationController")
	hex_grid.set("generation_seed", seed)
	world_generation_controller.call("_regenerate_current_world")
	settlement_management_view.call("reset_settlement_ui_state")
	settlement_management_view.call("sync_world_data")
	_open_player_world_from_menu()


func _open_player_world_from_menu() -> void:
	start_menu.visible = false
	settlement_management_view.call("reset_settlement_ui_state")
	settlement_management_view.call("sync_world_data")
	settlement_management_view.visible = false
	settlement_management_view.process_mode = Node.PROCESS_MODE_DISABLED
	player_world.call("refresh_world_visuals")
	player_world.process_mode = Node.PROCESS_MODE_INHERIT
	player_world.call("set_active", true)


func _open_settlement_management_view() -> void:
	player_world.call("set_active", false)
	player_world.process_mode = Node.PROCESS_MODE_DISABLED
	settlement_management_view.process_mode = Node.PROCESS_MODE_INHERIT
	settlement_management_view.visible = true
	settlement_management_view.call("activate_management_view")


func _open_player_world() -> void:
	settlement_management_view.call("reset_settlement_ui_state")
	settlement_management_view.call("sync_world_data")
	player_world.call("refresh_world_visuals")
	settlement_management_view.visible = false
	settlement_management_view.process_mode = Node.PROCESS_MODE_DISABLED
	player_world.process_mode = Node.PROCESS_MODE_INHERIT
	player_world.call("set_active", true)


func _resolve_seed(seed_text: String) -> int:
	var trimmed_seed: String = seed_text.strip_edges()
	if trimmed_seed.is_valid_int():
		var parsed_seed: int = int(trimmed_seed)
		if parsed_seed > 0:
			return parsed_seed
	return _generate_random_seed()


func _generate_random_seed() -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, 2147483647)
