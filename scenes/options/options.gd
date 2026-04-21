## ============================================================================
## Options — Settings Screen
## ============================================================================
##
## A placeholder settings screen with volume sliders and a fullscreen toggle.
## Demonstrates:
##   - Using SceneManager.go_back() to return to previous scene.
##   - ui_cancel (ESC) is handled globally by SceneManager.
##   - Slider and CheckButton controls for game settings.
##
## EDUCATIONAL NOTES:
##   - All visual styling is handled by the Theme resource (.tres).
##   - This script only contains LOGIC (signal handlers).
##   - The Back button uses theme_type_variation = "ButtonBack" in the .tscn.
##   - Settings are NOT saved to disk (it's just an example).
##   - In a real project, you'd save settings to user:// via ConfigFile.
## ============================================================================
extends Control


# ── Node References ──────────────────────────────────────────────────────────
@onready var music_slider: HSlider = $CenterContainer/VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $CenterContainer/VBoxContainer/SfxContainer/SfxSlider
@onready var fullscreen_toggle: CheckButton = $CenterContainer/VBoxContainer/FullscreenContainer/FullscreenToggle
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_connect_signals()
	# Give focus to the first interactive element.
	music_slider.grab_focus()


# ── Signal Handlers ──────────────────────────────────────────────────────────

func _on_music_volume_changed(value: float) -> void:
	# In a real project, you'd adjust the AudioServer bus volume here.
	print("Volumen Música: %d%%" % int(value))


func _on_sfx_volume_changed(value: float) -> void:
	print("Volumen SFX: %d%%" % int(value))


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_back_pressed() -> void:
	# Uses the breadcrumb stack to return to the previous scene.
	SceneManager.go_back()


# ── Signal Connections ───────────────────────────────────────────────────────

func _connect_signals() -> void:
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)
