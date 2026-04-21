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

# Perfiles de jugadores (para remapeo dinámico)
# Estructura: profile[player_id][action_name] = InputEvent
var player_profiles: Dictionary = {}

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
		_generate_default_profile(player_id, device_id)
		
	_apply_profile_to_inputmap(player_id)

## Genera un perfil por defecto basado en si es mando o teclado virtual
func _generate_default_profile(player_id: int, device_id: int) -> void:
	var profile = {}
	var all_actions = movement_actions + generic_actions
	
	for action in all_actions:
		var event: InputEvent = null
		
		# MANDOS (Device >= 0)
		if device_id >= 0:
			event = _get_default_joy_event(action, device_id)
			
		# TECLADO 1 (WASD) 
		elif device_id == -1:
			event = _get_default_kb1_event(action)
			
		# TECLADO 2 (FLECHAS)
		elif device_id == -3:
			event = _get_default_kb2_event(action)
			
		if event:
			profile[action] = event
			
	player_profiles[player_id] = profile

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

## 3. Remapeo Dinámico
func remap_action(player_id: int, action_name: String, new_event: InputEvent) -> void:
	if not player_profiles.has(player_id):
		player_profiles[player_id] = {}
		
	# Nos aseguramos que el nuevo evento respete el device original si aplica
	if new_event is InputEventJoypadButton or new_event is InputEventJoypadMotion:
		new_event.device = player_to_device.get(player_id, -1)
		
	player_profiles[player_id][action_name] = new_event
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
		
	# Teclado global
	var kb_enter = InputEventKey.new()
	kb_enter.physical_keycode = KEY_ENTER
	InputMap.action_add_event(action, kb_enter)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lobby_universal_join"):
		if event is InputEventJoypadButton:
			player_joined_lobby.emit(event.device)
		elif event is InputEventKey:
			player_joined_lobby.emit(-1) # Teclado 1 asume unirte
