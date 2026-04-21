## ============================================================================
## Options — Settings Screen con InputMapping CRUD
## ============================================================================
extends Control


# ── Node References ──────────────────────────────────────────────────────────
@onready var music_slider: HSlider = $MarginContainer/MainVBox/TabContainer/Sistema/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/MainVBox/TabContainer/Sistema/SfxContainer/SfxSlider
@onready var fullscreen_toggle: CheckButton = $MarginContainer/MainVBox/TabContainer/Sistema/FullscreenContainer/FullscreenToggle
@onready var back_button: Button = $MarginContainer/MainVBox/CenterContainer/BackButton

# ── CRUD Controls ──────────────────────────────────────────────────────────
@onready var profile_selector: OptionButton = $MarginContainer/MainVBox/TabContainer/Controles/TopBar/ProfileSelector
@onready var btn_new_profile: Button = $MarginContainer/MainVBox/TabContainer/Controles/TopBar/BtnNewProfile
@onready var btn_del_profile: Button = $MarginContainer/MainVBox/TabContainer/Controles/TopBar/BtnDeleteProfile
@onready var action_list: VBoxContainer = $MarginContainer/MainVBox/TabContainer/Controles/ScrollContainer/ActionList
@onready var key_modal: ColorRect = $KeyModal

# ── Modal Controls ──────────────────────────────────────────────────────────
@onready var modal_new_profile: ColorRect = $NewProfileModal
@onready var np_input_name: LineEdit = $NewProfileModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NameInput
@onready var np_device_select: OptionButton = $NewProfileModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DeviceSelect
@onready var np_btn_ok: Button = $NewProfileModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/BtnOk
@onready var np_btn_cancel: Button = $NewProfileModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/BtnCancel

var current_profile: String = ""
var waiting_for_input_action: String = ""

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_connect_signals()
	_setup_modal_devices()
	_refresh_profiles()
	music_slider.grab_focus()
	
func _setup_modal_devices() -> void:
	np_device_select.clear()
	np_device_select.add_item("⌨️ Izquierdo (WASD)", 0)
	np_device_select.set_item_metadata(0, -1)
	np_device_select.add_item("⌨️ Derecho (Flechas)", 1)
	np_device_select.set_item_metadata(1, -3)
	np_device_select.add_item("🎮 Mando", 2)
	np_device_select.set_item_metadata(2, 0)

# ── Signal Connections ───────────────────────────────────────────────────────

func _connect_signals() -> void:
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)
	
	profile_selector.item_selected.connect(_on_profile_selected)
	btn_new_profile.pressed.connect(_on_new_profile_pressed)
	btn_del_profile.pressed.connect(_on_delete_profile_pressed)
	
	np_btn_ok.pressed.connect(_on_modal_new_profile_ok)
	np_btn_cancel.pressed.connect(_on_modal_new_profile_cancel)

# ── CRUD Logic ──────────────────────────────────────────────────────────

func _refresh_profiles() -> void:
	profile_selector.clear()
	var idx = 0
	var select_idx = 0
	for pname in InputMultiDevice.custom_profiles.keys():
		profile_selector.add_item(pname)
		if pname == current_profile:
			select_idx = idx
		idx += 1
		
	if profile_selector.item_count > 0:
		if current_profile == "":
			current_profile = profile_selector.get_item_text(0)
		profile_selector.select(select_idx)
		current_profile = profile_selector.get_item_text(select_idx)
		_build_action_list(current_profile)

func _on_profile_selected(index: int) -> void:
	current_profile = profile_selector.get_item_text(index)
	_build_action_list(current_profile)

func _on_new_profile_pressed() -> void:
	np_input_name.text = ""
	np_device_select.select(0)
	modal_new_profile.show()
	np_input_name.grab_focus()

func _on_modal_new_profile_cancel() -> void:
	modal_new_profile.hide()

func _on_modal_new_profile_ok() -> void:
	var p_name = np_input_name.text.strip_edges()
	if p_name.is_empty() or p_name.begins_with("Default"):
		return # TODO: Mostrar error visual
		
	if InputMultiDevice.custom_profiles.has(p_name):
		return # Ya existe
		
	var base_device = np_device_select.get_item_metadata(np_device_select.selected)
	InputMultiDevice.create_custom_profile(p_name, base_device)
	current_profile = p_name
	_refresh_profiles()
	modal_new_profile.hide()

func _on_delete_profile_pressed() -> void:
	if current_profile.begins_with("Default"):
		print("No se puede borrar el perfil por defecto")
		return
	InputMultiDevice.delete_custom_profile(current_profile)
	current_profile = ""
	_refresh_profiles()

func _build_action_list(pname: String) -> void:
	# Borrar lista anterior
	for c in action_list.get_children():
		c.queue_free()
		
	var profile = InputMultiDevice.custom_profiles.get(pname, {})
	var all_actions = InputMultiDevice.movement_actions + InputMultiDevice.generic_actions
	
	for action in all_actions:
		var hbox = HBoxContainer.new()
		
		var lbl = Label.new()
		lbl.text = action.capitalize()
		lbl.custom_minimum_size = Vector2(250, 0)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 35)
		btn.text = _event_to_text(profile.get(action))
		
		# Proteger perfiles default de ser remapeados para que sirvan de base pura
		if pname.begins_with("Default"):
			btn.disabled = true
			
		# Bindeamos el click al remapeo enviando la accion especifica
		btn.pressed.connect(func(): _begin_remap(action))
		
		hbox.add_child(lbl)
		hbox.add_child(btn)
		action_list.add_child(hbox)

func _event_to_text(event: InputEvent) -> String:
	if event == null: return "N/A"
	if event is InputEventKey:
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		return OS.get_keycode_string(code)
	elif event is InputEventJoypadButton:
		return "Joy Btn " + str(event.button_index)
	elif event is InputEventJoypadMotion:
		return "Joy Axis " + str(event.axis) + (" (+)" if event.axis_value > 0 else " (-)")
	return event.as_text()

# ── Remapping Escucha de Inputs ──────────────────────────────────────────

func _begin_remap(action_name: String) -> void:
	waiting_for_input_action = action_name
	key_modal.show()
	$KeyModal/CenterContainer/Label.text = "Presiona nueva tecla para:\n" + action_name.capitalize()

func _input(event: InputEvent) -> void:
	if waiting_for_input_action != "":
		# Ignoramos mouse o echos
		if event is InputEventMouse or event.is_echo(): return
		
		if event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
			InputMultiDevice.remap_custom_profile(current_profile, waiting_for_input_action, event)
			waiting_for_input_action = ""
			key_modal.hide()
			_build_action_list(current_profile) # Refrescar nombres
			
			# Consumir el input para que no dispare otras cosas
			get_viewport().set_input_as_handled()

# ── Sistema Signal Handlers ──────────────────────────────────────────────────────────

func _on_music_volume_changed(value: float) -> void:
	print("Volumen Música: %d%%" % int(value))

func _on_sfx_volume_changed(value: float) -> void:
	print("Volumen SFX: %d%%" % int(value))

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed() -> void:
	# Guardamos los perfiles de manera persistente al salir
	InputMultiDevice.save_profiles()
	SceneManager.go_back()
