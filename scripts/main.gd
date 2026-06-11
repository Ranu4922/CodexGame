extends Node

const WorldData = preload("res://scripts/data/world_data.gd")

# Main starts in the first player world prototype and opens the settlement
# management view when the player interacts with the village center.

@onready var player_world: Node = $PlayerWorld
@onready var settlement_management_view: Node = $SettlementManagementView

var world_data: RefCounted = WorldData.new()


func _ready() -> void:
	print("Hex Survival MVP gestartet")
	player_world.call("set_world_data", world_data)
	settlement_management_view.call("set_world_data", world_data)
	player_world.call("set_active", true)
	settlement_management_view.visible = false
	settlement_management_view.process_mode = Node.PROCESS_MODE_DISABLED
	player_world.connect("settlement_management_requested", Callable(self, "_open_settlement_management_view"))
	settlement_management_view.connect("management_exit_requested", Callable(self, "_open_player_world"))


func _open_settlement_management_view() -> void:
	player_world.call("set_active", false)
	player_world.process_mode = Node.PROCESS_MODE_DISABLED
	settlement_management_view.process_mode = Node.PROCESS_MODE_INHERIT
	settlement_management_view.visible = true
	settlement_management_view.call("activate_management_view")


func _open_player_world() -> void:
	settlement_management_view.call("sync_world_data")
	settlement_management_view.visible = false
	settlement_management_view.process_mode = Node.PROCESS_MODE_DISABLED
	player_world.process_mode = Node.PROCESS_MODE_INHERIT
	player_world.call("set_active", true)
