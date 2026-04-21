## ============================================================================
## SceneManager — Autoload Singleton
## ============================================================================
##
## Manages all scene navigation in the game. It combines three responsibilities
## into one easy-to-understand class:
##
##   1. SCENE LOADING  — Swaps the current scene for a new one.
##   2. TRANSITIONS    — Fades the screen to black and back for smooth changes.
##   3. BREADCRUMB     — Keeps a history stack so you can "go back" with ESC.
##
## HOW TO USE (from any script):
##   SceneManager.change_scene("res://scenes/gameplay/gameplay.tscn")
##   SceneManager.go_back()        # Returns to the previous scene
##   SceneManager.can_go_back()    # Returns true if there's history
##
## SIGNALS:
##   scene_changed(scene_path)     — Emitted after a scene swap completes.
##   transition_started            — Emitted when fade-out begins.
##   transition_finished           — Emitted when fade-in ends.
## ============================================================================
extends Node


# ── Signals ──────────────────────────────────────────────────────────────────
## Emitted after the new scene is fully loaded and the fade-in finishes.
signal scene_changed(scene_path: String)
## Emitted when the fade-out animation starts (screen going dark).
signal transition_started
## Emitted when the fade-in animation ends (screen fully visible again).
signal transition_finished


# ── Configuration ────────────────────────────────────────────────────────────
## Duration in seconds for each fade (out and in). Total transition = 2× this.
const FADE_DURATION: float = 0.3


# ── Internal State ───────────────────────────────────────────────────────────
## The breadcrumb stack: an Array of scene paths (Strings).
## Example: ["res://scenes/main_menu/main_menu.tscn"]
## When we navigate to a new scene, we push the CURRENT scene path.
## When we go back, we pop the last path and load it.
var _scene_stack: Array[String] = []

## Guard flag to prevent calling change_scene while already transitioning.
var _is_transitioning: bool = false

## Reference to the transition overlay (CanvasLayer + ColorRect).
var _transition_layer: CanvasLayer
var _transition_rect: ColorRect


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# We always process (even when tree is paused) so transitions work everywhere.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# --- Build the transition overlay programmatically ---
	# This avoids depending on an external .tscn file.
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 100 # On top of everything
	_transition_layer.name = "TransitionLayer"
	add_child(_transition_layer)
	
	_transition_rect = ColorRect.new()
	_transition_rect.color = Color.BLACK
	# Full-screen rect via anchors
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Start fully transparent (invisible)
	_transition_rect.modulate.a = 0.0
	# Don't block mouse clicks on the UI below when not transitioning
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_layer.add_child(_transition_rect)


func _unhandled_input(event: InputEvent) -> void:
	# ── Breadcrumb Navigation ──
	# When the player presses ESC (ui_cancel), go back to the previous scene.
	if event.is_action_pressed("ui_cancel"):
		if can_go_back():
			# Mark the input as handled so nothing else reacts to it.
			get_viewport().set_input_as_handled()
			go_back()


# ── Public API ───────────────────────────────────────────────────────────────

## Navigate to a new scene. The current scene is pushed onto the breadcrumb stack.
## [param scene_path] The resource path of the scene to load, e.g.
##   "res://scenes/gameplay/gameplay.tscn"
## [param with_transition] Whether to play the fade animation (default: true).
func change_scene(scene_path: String, with_transition: bool = true) -> void:
	if _is_transitioning:
		push_warning("SceneManager: Already transitioning, ignoring change_scene call.")
		return
	
	# Push current scene path onto the stack (breadcrumb)
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.scene_file_path != "":
		_scene_stack.push_back(current_scene.scene_file_path)
	
	if with_transition:
		await _transition_to_scene(scene_path)
	else:
		_swap_scene(scene_path)


## Go back to the previous scene in the breadcrumb stack.
## Does nothing if there's no history (we're at the root).
func go_back(with_transition: bool = true) -> void:
	if _is_transitioning:
		push_warning("SceneManager: Already transitioning, ignoring go_back call.")
		return
	
	if _scene_stack.is_empty():
		# Nothing to go back to — this is normal at the main menu.
		return
	
	# Pop the last scene path from the stack
	var previous_scene_path: String = _scene_stack.pop_back()
	
	if with_transition:
		# Note: We do NOT push the current scene here (we're going BACK).
		await _transition_to_scene(previous_scene_path, false)
	else:
		_swap_scene(previous_scene_path)


## Returns true if there's at least one scene in the breadcrumb history.
func can_go_back() -> bool:
	return not _scene_stack.is_empty()


## Returns the current breadcrumb stack (read-only copy) for debugging.
func get_breadcrumb() -> Array[String]:
	return _scene_stack.duplicate()


## Clears all breadcrumb history. Useful when resetting to main menu.
func clear_history() -> void:
	_scene_stack.clear()


# ── Private Methods ──────────────────────────────────────────────────────────

## Full transition sequence: fade out → swap scene → fade in.
func _transition_to_scene(scene_path: String, push_to_stack: bool = true) -> void:
	_is_transitioning = true
	transition_started.emit()
	
	# Block mouse during transition
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# ── Fade Out (screen goes dark) ──
	var tween_out := create_tween()
	tween_out.tween_property(_transition_rect, "modulate:a", 1.0, FADE_DURATION)
	await tween_out.finished
	
	# ── Swap the scene while the screen is black ──
	_swap_scene(scene_path)
	
	# Wait one frame for the new scene to initialize
	await get_tree().process_frame
	
	# ── Fade In (screen becomes visible) ──
	var tween_in := create_tween()
	tween_in.tween_property(_transition_rect, "modulate:a", 0.0, FADE_DURATION)
	await tween_in.finished
	
	# Restore mouse passthrough
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_is_transitioning = false
	transition_finished.emit()
	scene_changed.emit(scene_path)


## Immediately replaces the current scene. No animation.
func _swap_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneManager: Failed to load scene '%s' (error %d)" % [scene_path, error])
