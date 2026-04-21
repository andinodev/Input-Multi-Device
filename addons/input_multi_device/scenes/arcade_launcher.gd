extends Control

# ── Scene Paths ───────────────────────────────────────────────────────────────
const PLATFORMER_SCENE := "res://addons/input_multi_device/scenes/arcade_demo.tscn"
const SHMUP_SCENE := "res://addons/input_multi_device/scenes/spaceship/shmup_demo.tscn"
const OPTIONS_SCENE := "res://addons/input_multi_device/scenes/options/options.tscn"
const LOBBY_SCENE := "res://addons/input_multi_device/scenes/lobby/lobby.tscn"

# ── Node References ──────────────────────────────────────────────────────────
@onready var platformer_button: Button = %PlatformerButton
@onready var shmup_button: Button = %ShmupButton
@onready var options_button: Button = %OptionsButton


func _ready() -> void:
	_connect_buttons()
	# Grab focus for gamepad/keyboard support
	platformer_button.grab_focus()


func _connect_buttons() -> void:
	platformer_button.pressed.connect(_on_platformer_pressed)
	shmup_button.pressed.connect(_on_shmup_pressed)
	options_button.pressed.connect(_on_options_pressed)


# ── Button Handlers ──────────────────────────────────────────────────────────

func _on_platformer_pressed() -> void:
	GameManager.target_game_scene = PLATFORMER_SCENE
	SceneManager.change_scene(LOBBY_SCENE)


func _on_shmup_pressed() -> void:
	GameManager.target_game_scene = SHMUP_SCENE
	SceneManager.change_scene(LOBBY_SCENE)


func _on_options_pressed() -> void:
	SceneManager.change_scene(OPTIONS_SCENE)
