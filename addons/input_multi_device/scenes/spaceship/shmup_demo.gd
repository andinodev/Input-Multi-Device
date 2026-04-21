extends Node2D

var player_scene = preload("res://addons/input_multi_device/scenes/spaceship/space_ship.tscn")
var spawned_devices = []

@onready var pcam = $PCam

func _ready():
	if has_node("/root/InputMultiDevice"):
		InputMultiDevice.set_global_deadzone(0.9)
		InputMultiDevice.player_joined_lobby.connect(_on_player_joined)
		for p_id in InputMultiDevice.player_to_device:
			var d_id = InputMultiDevice.player_to_device[p_id]
			_on_player_joined(d_id)

func _on_player_joined(device_id: int):
	if device_id in spawned_devices:
		return
	
	spawned_devices.append(device_id)
	
	var player_id = -1
	for i in range(8):
		if not InputMultiDevice.player_to_device.has(i):
			player_id = i
			break
	
	if player_id == -1: return
	
	InputMultiDevice.setup_player_device(player_id, device_id)
	
	var player_node = player_scene.instantiate()
	add_child(player_node)
	
	var color = Color(0.8, 0.8, 0.8)
	if player_id == 1: color = Color(1.0, 0.5, 0.5)
	if player_id == 2: color = Color(0.5, 1.0, 0.5)
	if player_id == 3: color = Color(0.5, 0.5, 1.0)
	
	player_node.global_position = Vector2(400 + (player_id * 150), 400)
	player_node.setup(player_id, device_id, color)
	
	# Usar Phantom Camera para agregar el auto encuadre dinámico 
	if pcam.has_method("append_follow_targets"):
		pcam.append_follow_targets(player_node)
