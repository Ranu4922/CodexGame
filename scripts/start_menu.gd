extends Control

signal new_game_requested(seed_text: String)
signal load_game_requested
signal quit_requested

@onready var seed_input: LineEdit = $PanelContainer/VBoxContainer/SeedInput
@onready var message_label: Label = $PanelContainer/VBoxContainer/MessageLabel


func _ready() -> void:
	$PanelContainer/VBoxContainer/GenerateSeedButton.pressed.connect(_on_generate_seed_button_pressed)
	$PanelContainer/VBoxContainer/StartGameButton.pressed.connect(_on_start_game_button_pressed)
	$PanelContainer/VBoxContainer/LoadGameButton.pressed.connect(_on_load_game_button_pressed)
	$PanelContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)
	message_label.text = ""


func set_message(text: String) -> void:
	message_label.text = text


func _on_generate_seed_button_pressed() -> void:
	var generated_seed: int = _generate_random_seed()
	seed_input.text = str(generated_seed)
	message_label.text = "Seed: %d" % generated_seed


func _on_start_game_button_pressed() -> void:
	new_game_requested.emit(seed_input.text.strip_edges())


func _on_load_game_button_pressed() -> void:
	load_game_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()


func _generate_random_seed() -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, 2147483647)
