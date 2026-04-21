extends Node2D

# Cargamos el personaje de la demo existente
var player_scene = preload("res://scenes/demo/player.tscn")

# Tracking de dispositivos ya spawneados en esta sesion
var spawned_devices = []

func _ready():
	# En el modo Arcade, el Singleton nos avisara con su señal universal
	if has_node("/root/InputMultiDevice"):
		InputMultiDevice.player_joined_lobby.connect(_on_player_joined)
		
		# Spawneamos a los que ya esten en el Singleton (si venimos del launcher con hardware ya listo)
		for p_id in InputMultiDevice.player_to_device:
			var d_id = InputMultiDevice.player_to_device[p_id]
			_on_player_joined(d_id)

func _on_player_joined(device_id: int):
	if device_id in spawned_devices:
		return
	
	spawned_devices.append(device_id)
	
	# Buscamos el primer ID de jugador libre (0-7)
	var player_id = -1
	for i in range(8):
		if not InputMultiDevice.player_to_device.has(i):
			player_id = i
			break
	
	if player_id == -1:
		print("Arena Arcade llena (8 jugadores max)")
		return
		
	# Registramos al jugador en el sistema de forma "Plug & Play"
	# Esto le asignará automáticamente su perfil Default (Keyboard 1, 2 o Joypad)
	InputMultiDevice.setup_player_device(player_id, device_id)
	
	# Instanciar personaje
	var player_node = player_scene.instantiate()
	add_child(player_node)
	
	# Configuracion visual rapida
	var color = Color(randf(), randf(), randf())
	player_node.global_position = Vector2(250 + (player_id * 120), 200)
	player_node.setup(player_id, device_id, color)
	
	print("Arcade: Jugador %d unido con dispositivo %d" % [player_id, device_id])
