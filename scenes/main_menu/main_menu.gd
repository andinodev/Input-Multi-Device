## ============================================================================
## MainMenu — Main Menu Screen
## ============================================================================
##
## The first screen the player sees. Provides navigation to:
##   - Gameplay scene (Jugar)
##   - Options scene  (Opciones)
##   - Quit the game  (Salir)
##
## EDUCATIONAL NOTES:
##   - All visual styling is handled by the Theme resource (.tres),
##     NOT by code. This script only contains LOGIC.
##   - Buttons use theme_type_variation in the .tscn file:
##       PlayButton    → "ButtonPrimary"
##       OptionsButton → "ButtonSecondary"
##       QuitButton    → "ButtonDanger"
##   - The first button grabs focus for keyboard/gamepad support.
##   - Navigation uses SceneManager.change_scene() which pushes to breadcrumb.
## ============================================================================
extends Control


# ── Scene Paths (Constants) ──────────────────────────────────────────────────
## Using constants makes it easy to find and change paths in one place.
const GAMEPLAY_SCENE := "res://scenes/gameplay/gameplay.tscn"
const OPTIONS_SCENE := "res://scenes/options/options.tscn"


# ── Node References ──────────────────────────────────────────────────────────
@onready var play_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/PlayButton
@onready var options_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/OptionsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/QuitButton


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_connect_buttons()
	# Give focus to the first button so keyboard/gamepad works immediately.
	play_button.grab_focus()


# ── Button Handlers ──────────────────────────────────────────────────────────

func _on_play_pressed() -> void:
	SceneManager.change_scene(GAMEPLAY_SCENE)


func _on_options_pressed() -> void:
	SceneManager.change_scene(OPTIONS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


# ── Signal Connections ───────────────────────────────────────────────────────

func _connect_buttons() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
