extends Control

const DEMO_LEVEL = "res://scenes/demo/demo_level.tscn"

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/GridContainer
@onready var play_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/PlayButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/BackButton

# Tracking slots
var slots = []
var player_to_slot = {} # player_id -> slot index

func _ready() -> void:
	# Initialize 8 empty slots
	for i in range(8):
		_create_empty_slot(i)
	
	play_button.pressed.connect(_on_play_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	if has_node("/root/InputMultiDevice"):
		InputMultiDevice.player_joined_lobby.connect(_on_player_joined)
		
		# If there are already players assigned (e.g. returning to lobby)
		for player_id in InputMultiDevice.player_to_device:
			_on_player_joined(InputMultiDevice.player_to_device[player_id])

func _create_empty_slot(index: int) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 150)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var v_box = VBoxContainer.new()
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var p_label = Label.new()
	p_label.text = "JUGADOR " + str(index + 1)
	p_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_label.theme_type_variation = "LabelBody"
	
	var d_label = Label.new()
	d_label.name = "DeviceLabel"
	d_label.text = "LIBRE"
	d_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_label.modulate = Color(0.5, 0.5, 0.5)
	
	var profile_select = OptionButton.new()
	profile_select.name = "ProfileSelect"
	profile_select.visible = false
	profile_select.custom_minimum_size = Vector2(150, 0)
	
	v_box.add_child(p_label)
	v_box.add_child(d_label)
	v_box.add_child(profile_select)
	panel.add_child(v_box)
	
	grid_container.add_child(panel)
	slots.append(panel)

func _on_player_joined(device_id: int) -> void:
	# 1. Verificar si este dispositivo ya tiene un jugador asignado
	var player_id = -1
	for p_id in InputMultiDevice.player_to_device:
		if InputMultiDevice.player_to_device[p_id] == device_id:
			player_id = p_id
			break
	
	# 2. Si es un dispositivo nuevo, buscar el primer slot libre (0-7)
	if player_id == -1:
		for i in range(8):
			if not InputMultiDevice.player_to_device.has(i):
				player_id = i
				# Registramos el dispositivo en el Singleton
				InputMultiDevice.setup_player_device(player_id, device_id)
				break
				
	# 3. Si no hay espacio o no se pudo asignar, ignoramos
	if player_id == -1 or player_id >= 8:
		return
		
	var panel = slots[player_id]
	var d_label = panel.find_child("DeviceLabel", true, false)
	var profile_select = panel.find_child("ProfileSelect", true, false)
	
	# Detect device type
	var device_name = ""
	if device_id == -1:
		device_name = "TECLADO 1 - Izquierdo"
	elif device_id == -3:
		device_name = "TECLADO 2 - Derecho"
	else:
		device_name = Input.get_joy_name(device_id)
		# Clean name a bit
		if device_name.contains("XInput"): device_name = "MANDO XBOX"
		elif device_name.contains("PS4") or device_name.contains("DualShock"): device_name = "MANDO PS4"
		elif device_name.contains("PS5") or device_name.contains("DualSense"): device_name = "MANDO PS5"
		elif device_name.contains("Nintendo"): device_name = "MANDO SWITCH"
	
	d_label.text = device_name
	d_label.modulate = Color(1, 1, 1)
	
	# Fill profiles
	profile_select.clear()
	var profiles = InputMultiDevice.custom_profiles.keys()
	for p in profiles:
		profile_select.add_item(p)
	
	# Select default or current
	var current_p = "Default_Mando"
	if device_id < 0:
		current_p = "Default_Teclado_1" if device_id == -1 else "Default_Teclado_2"
	
	for i in range(profile_select.item_count):
		if profile_select.get_item_text(i) == current_p:
			profile_select.select(i)
			break
	
	profile_select.visible = true
	
	# Connect profile change
	if not profile_select.item_selected.is_connected(_on_profile_changed):
		profile_select.item_selected.connect(_on_profile_changed.bind(player_id))
	
	# Apply initial
	InputMultiDevice.apply_custom_profile_to_player(player_id, profile_select.get_item_text(profile_select.selected))

func _on_profile_changed(index: int, player_id: int) -> void:
	var profile_name = slots[player_id].find_child("ProfileSelect", true, false).get_item_text(index)
	InputMultiDevice.apply_custom_profile_to_player(player_id, profile_name)

func _on_play_pressed() -> void:
	if InputMultiDevice.player_to_device.size() == 0:
		# Maybe show a warning "Al menos 1 jugador"?
		print("No hay jugadores unidos")
		return
	SceneManager.change_scene(DEMO_LEVEL)

func _on_back_pressed() -> void:
	SceneManager.go_back()
