extends Node
## InputMultiDevice (Singleton)
## Plugin genérico para gestión de inputs multijugador local en Godot 4.

signal device_connection_changed(device_id: int, connected: bool)
signal player_joined_lobby(device_id: int)

var movement_actions: Array = [] # [Up, Right, Down, Left]
var generic_actions: Array = [] # ["light_attack", "heavy_attack", ...]

# Perfiles por defecto para Acciones Genéricas (pueden ser sobreescritos en setup_actions)
var default_kb1_keys: Array = [KEY_J, KEY_K, KEY_M, KEY_N, KEY_L, KEY_I]
var default_kb2_keys: Array = [KEY_KP_1, KEY_KP_2, KEY_KP_4, KEY_KP_5, KEY_KP_3, KEY_KP_6]

var default_kb1_move_keys: Array = [KEY_W, KEY_D, KEY_S, KEY_A]
var default_kb2_move_keys: Array = [KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT]

var default_joy_btns: Array = [JOY_BUTTON_X, JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_Y, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_SHOULDER]

# Estado interno de los mandos
var connected_devices: Array = []
var player_to_device: Dictionary = {} # player_id: int -> device_id: int

var player_profiles: Dictionary = {}

# Banco de Perfiles Nombrados (CRUD para Opciones)
# profile_name: String -> Dictionary { action: InputEvent }
var custom_profiles: Dictionary = {}

var toggle_states: Dictionary = {} # player_id: int -> Dictionary de {action: bool}
var global_base_deadzone: float = 0.2

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_scan_connected_devices()

func _scan_connected_devices() -> void:
	connected_devices.clear()
	# Añadimos teclados como IDs negativos
	connected_devices.append(-1) # Teclado A (WASD)
	connected_devices.append(-3) # Teclado B (Flechas)
	
	for joy_id in Input.get_connected_joypads():
		if joy_id not in connected_devices:
			connected_devices.append(joy_id)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		if device not in connected_devices: connected_devices.append(device)
	else:
		connected_devices.erase(device)
	device_connection_changed.emit(device, connected)

## 1. Inicialización (Llamado por el Game Framework)
func setup_movements(p_movement: Array, opt_kb1: Array = [], opt_kb2: Array = []) -> void:
	assert(p_movement.size() == 4, "movement_actions debe tener 4 elementos: [Up, Right, Down, Left]")
	movement_actions = p_movement
	if opt_kb1.size() == 4: default_kb1_move_keys = opt_kb1
	if opt_kb2.size() == 4: default_kb2_move_keys = opt_kb2

func setup_actions(p_actions: Array, opt_kb1: Array = [], opt_kb2: Array = [], opt_joy: Array = []) -> void:
	generic_actions = p_actions
	
	if opt_kb1.size() > 0: default_kb1_keys = opt_kb1
	if opt_kb2.size() > 0: default_kb2_keys = opt_kb2
	if opt_joy.size() > 0: default_joy_btns = opt_joy
	
	_setup_lobby_global_actions()

## 2. Asignación de Jugador a Dispositivo (Lobby/MatchManager)
func setup_player_device(player_id: int, device_id: int) -> void:
	player_to_device[player_id] = device_id
	
	# Asegurarnos que existe un perfil vacio o cargarlo
	if not player_profiles.has(player_id):
		player_profiles[player_id] = get_default_profile(device_id)
	else:
		# Si ya hay un perfil (p.ej. cargado de disco o asignado), sincronizamos el dispositivo
		_sync_profile_device(player_id, device_id)
		
	_apply_profile_to_inputmap(player_id)

func _sync_profile_device(player_id: int, target_device: int) -> void:
	if not player_profiles.has(player_id): return
	for action in player_profiles[player_id]:
		var event = player_profiles[player_id][action]
		if event != null and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			event.device = target_device

## Genera un perfil base dependiendo del tipo de dispositivo
func get_default_profile(device_type: int) -> Dictionary:
	var profile = {}
	var all_actions = movement_actions + generic_actions
	
	for action in all_actions:
		var event: InputEvent = null
		
		# MANDOS (Device >= 0)
		if device_type >= 0:
			event = _get_default_joy_event(action, device_type)
		# TECLADO 1 (WASD) 
		elif device_type == -1:
			event = _get_default_kb1_event(action)
		# TECLADO 2 (FLECHAS)
		elif device_type == -3:
			event = _get_default_kb2_event(action)
			
		if event:
			profile[action] = event
			
	return profile

func _get_default_joy_event(action: String, device_id: int) -> InputEvent:
	# -- MOVIMIENTO (D-PAD O STICK) --
	if movement_actions.has(action):
		var idx = movement_actions.find(action)
		var is_vertical = (idx % 2 == 0) # 0: Up, 2: Down
		var is_positive = (idx == 1 or idx == 2) # 1: Right, 2: Down
		
		# Preferimos D-PAD por defecto para perfiles iniciales, o stick:
		var joy_btn = InputEventJoypadButton.new()
		joy_btn.device = device_id
		match idx:
			0: joy_btn.button_index = JOY_BUTTON_DPAD_UP
			1: joy_btn.button_index = JOY_BUTTON_DPAD_RIGHT
			2: joy_btn.button_index = JOY_BUTTON_DPAD_DOWN
			3: joy_btn.button_index = JOY_BUTTON_DPAD_LEFT
		return joy_btn
		
	# -- ACCIONES GENÉRICAS --
	# Usar el array de perfil preferido del desarrollador o el fallback del plugin
	var action_idx = generic_actions.find(action)
	var final_btn = JOY_BUTTON_A
	
	if action_idx >= 0 and action_idx < default_joy_btns.size():
		final_btn = default_joy_btns[action_idx]
		
	var joy_btn = InputEventJoypadButton.new()
	joy_btn.device = device_id
	joy_btn.button_index = final_btn
	return joy_btn

func _get_default_kb1_event(action: String) -> InputEventKey:
	var key_event = InputEventKey.new()
	if movement_actions.has(action):
		var idx = movement_actions.find(action)
		if idx >= 0 and idx < default_kb1_move_keys.size():
			key_event.physical_keycode = default_kb1_move_keys[idx]
	else:
		# Asigna las teclas usando el orden por defecto que entregó el desarrollador
		var action_idx = generic_actions.find(action)
		if action_idx >= 0 and action_idx < default_kb1_keys.size():
			key_event.physical_keycode = default_kb1_keys[action_idx]
	return key_event

func _get_default_kb2_event(action: String) -> InputEventKey:
	var key_event = InputEventKey.new()
	if movement_actions.has(action):
		var idx = movement_actions.find(action)
		if idx >= 0 and idx < default_kb2_move_keys.size():
			key_event.physical_keycode = default_kb2_move_keys[idx]
	else:
		# Asigna las teclas usando el orden por defecto que entregó el desarrollador
		var action_idx = generic_actions.find(action)
		if action_idx >= 0 and action_idx < default_kb2_keys.size():
			key_event.physical_keycode = default_kb2_keys[action_idx]
	return key_event

## 3. Remapeo Dinámico para un Jugador Activo
func remap_action(player_id: int, action_name: String, new_event: InputEvent) -> void:
	if not player_profiles.has(player_id):
		player_profiles[player_id] = {}
		
	# Nos aseguramos que el nuevo evento respete el device original si aplica
	if new_event is InputEventJoypadButton or new_event is InputEventJoypadMotion:
		new_event.device = player_to_device.get(player_id, -1)
		
	player_profiles[player_id][action_name] = new_event
	_apply_profile_to_inputmap(player_id)

## 3.1. CRUD de Perfiles Nombrados (Para la UI de Opciones)
func create_custom_profile(profile_name: String, base_device_type: int) -> void:
	custom_profiles[profile_name] = get_default_profile(base_device_type)

func delete_custom_profile(profile_name: String) -> void:
	if custom_profiles.has(profile_name):
		custom_profiles.erase(profile_name)

func remap_custom_profile(profile_name: String, action_name: String, new_event: InputEvent) -> void:
	if not custom_profiles.has(profile_name): return
	custom_profiles[profile_name][action_name] = new_event

func apply_custom_profile_to_player(player_id: int, profile_name: String) -> void:
	if not custom_profiles.has(profile_name): return
	
	# Copiamos profundamente los eventos para que los dispositivos no compartan referencias
	var new_profile = {}
	for action in custom_profiles[profile_name]:
		if custom_profiles[profile_name][action] != null:
			new_profile[action] = custom_profiles[profile_name][action].duplicate()
			
	player_profiles[player_id] = new_profile
	var current_device = player_to_device.get(player_id, -1)
	if current_device != -1:
		_sync_profile_device(player_id, current_device)
	_apply_profile_to_inputmap(player_id)


## Aplica el perfil guardado en memoria al InputMap de Godot
func _apply_profile_to_inputmap(player_id: int) -> void:
	if not player_profiles.has(player_id): return
	var profile = player_profiles[player_id]
	
	var all_actions = movement_actions + generic_actions
	for action in all_actions:
		var system_action_name = _get_system_action_name(player_id, action)
		
		# Crear acción en InputMap si no existe
		if not InputMap.has_action(system_action_name):
			InputMap.add_action(system_action_name)
			
		InputMap.action_erase_events(system_action_name)
		
		if profile.has(action) and profile[action] != null:
			InputMap.action_add_event(system_action_name, profile[action])
			
		# Añadir también los Ejes Analógicos forzados para Mandos (si es acción de movimiento)
		if movement_actions.has(action):
			var device_id = player_to_device.get(player_id, -1)
			if device_id >= 0:
				var axis_event = InputEventJoypadMotion.new()
				axis_event.device = device_id
				var idx = movement_actions.find(action)
				axis_event.axis = JOY_AXIS_LEFT_X if (idx == 1 or idx == 3) else JOY_AXIS_LEFT_Y
				axis_event.axis_value = 1.0 if (idx == 1 or idx == 2) else -1.0 # Right(1), Down(2)
				InputMap.action_add_event(system_action_name, axis_event)
				
		# Aplicar Deadzone a la acción generada
		InputMap.action_set_deadzone(system_action_name, global_base_deadzone)


func set_global_deadzone(deadzone: float) -> void:
	global_base_deadzone = clamp(deadzone, 0.0, 1.0)
	for player_id in player_profiles:
		_apply_profile_to_inputmap(player_id)

func _get_system_action_name(player_id: int, base_action: String) -> String:
	return "p%d_%s" % [player_id, base_action]

## 4. Consultas en Tiempo Real
func is_action_pressed(player_id: int, action: String) -> bool:
	var system_action_name = _get_system_action_name(player_id, action)
	if InputMap.has_action(system_action_name):
		return Input.is_action_pressed(system_action_name)
	return false
	
func is_action_just_pressed(player_id: int, action: String) -> bool:
	var system_action_name = _get_system_action_name(player_id, action)
	if InputMap.has_action(system_action_name):
		return Input.is_action_just_pressed(system_action_name)
	return false
	
func is_action_just_released(player_id: int, action: String) -> bool:
	var system_action_name = _get_system_action_name(player_id, action)
	if InputMap.has_action(system_action_name):
		return Input.is_action_just_released(system_action_name)
	return false

func is_action_toggled(player_id: int, action: String) -> bool:
	if not toggle_states.has(player_id): return false
	return toggle_states[player_id].get(action, false)

func get_axis(player_id: int, negative_action: String, positive_action: String) -> float:
	var sys_neg = _get_system_action_name(player_id, negative_action)
	var sys_pos = _get_system_action_name(player_id, positive_action)
	if InputMap.has_action(sys_neg) and InputMap.has_action(sys_pos):
		return Input.get_axis(sys_neg, sys_pos)
	return 0.0

func get_vector(player_id: int, neg_x: String, pos_x: String, neg_y: String, pos_y: String) -> Vector2:
	var sys_nx = _get_system_action_name(player_id, neg_x)
	var sys_px = _get_system_action_name(player_id, pos_x)
	var sys_ny = _get_system_action_name(player_id, neg_y)
	var sys_py = _get_system_action_name(player_id, pos_y)
	if InputMap.has_action(sys_nx) and InputMap.has_action(sys_px) and InputMap.has_action(sys_ny) and InputMap.has_action(sys_py):
		return Input.get_vector(sys_nx, sys_px, sys_ny, sys_py)
	return Vector2.ZERO

## 5. Listeners Universales (Lobby Join)
func _setup_lobby_global_actions() -> void:
	var action = "lobby_universal_join"
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
		
	# Añadimos A y START para todos los posibles mandos integrados (0-7 max)
	for joy_id in range(8):
		var btn_a = InputEventJoypadButton.new()
		btn_a.device = joy_id
		btn_a.button_index = JOY_BUTTON_A
		InputMap.action_add_event(action, btn_a)
		
		var btn_start = InputEventJoypadButton.new()
		btn_start.device = joy_id
		btn_start.button_index = JOY_BUTTON_START
		InputMap.action_add_event(action, btn_start)
		
	# Teclado global principal (Teclado 1)
	var kb_enter = InputEventKey.new()
	kb_enter.physical_keycode = KEY_ENTER
	InputMap.action_add_event(action, kb_enter)
	
	# Teclado global Numpad (Teclado 2)
	var kb_np_enter = InputEventKey.new()
	kb_np_enter.physical_keycode = KEY_KP_ENTER
	InputMap.action_add_event(action, kb_np_enter)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lobby_universal_join"):
		if event is InputEventJoypadButton:
			player_joined_lobby.emit(event.device)
		elif event is InputEventKey:
			if event.physical_keycode == KEY_KP_ENTER:
				player_joined_lobby.emit(-3) # Teclado 2
			else:
				player_joined_lobby.emit(-1) # Teclado 1 asume unirte

	# Gestion de Toggle States de forma eficiente
	if event.is_pressed() and not event.is_echo():
		for player_id in player_profiles:
			var all_actions = movement_actions + generic_actions
			for action in all_actions:
				var sys_action = _get_system_action_name(player_id, action)
				if event.is_action(sys_action):
					if not toggle_states.has(player_id): toggle_states[player_id] = {}
					var current = toggle_states[player_id].get(action, false)
					toggle_states[player_id][action] = not current

## 6. Funcionalidades Extra (Vibración y Persistencia)
func start_vibration(player_id: int, weak_motor: float, strong_motor: float, duration: float = 0.0) -> void:
	var device_id = player_to_device.get(player_id, -1)
	# Silencia silenciosamente si el device es menor a 0 (Teclados)
	if device_id >= 0:
		Input.start_joy_vibration(device_id, weak_motor, strong_motor, duration)

func stop_vibration(player_id: int) -> void:
	var device_id = player_to_device.get(player_id, -1)
	if device_id >= 0:
		Input.stop_joy_vibration(device_id)

func save_profiles(file_path: String = "user://input_profiles.cfg") -> void:
	InputMultiDevicePersistence.save_to_disk(custom_profiles, file_path)

func load_profiles(file_path: String = "user://input_profiles.cfg") -> void:
	var loaded = InputMultiDevicePersistence.load_from_disk(file_path)
	if loaded.size() > 0:
		for profile_name in loaded:
			custom_profiles[profile_name] = loaded[profile_name]
			
	_ensure_default_profiles_exist()

func _ensure_default_profiles_exist() -> void:
	if not custom_profiles.has("Default_Mando"): custom_profiles["Default_Mando"] = get_default_profile(0)
	if not custom_profiles.has("Default_Teclado_1"): custom_profiles["Default_Teclado_1"] = get_default_profile(-1)
	if not custom_profiles.has("Default_Teclado_2"): custom_profiles["Default_Teclado_2"] = get_default_profile(-3)

