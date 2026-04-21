extends Node2D

var player_scene = preload("res://scenes/demo/player.tscn")
var spawned_devices = []
var current_player_id = 0

# Colors for players
var player_colors = [
    Color(0.9, 0.2, 0.2), # Red
    Color(0.2, 0.5, 0.9), # Blue
    Color(0.2, 0.8, 0.2), # Green
    Color(0.9, 0.8, 0.2), # Yellow
    Color(0.8, 0.2, 0.8), # Purple
    Color(0.2, 0.8, 0.8), # Cyan
    Color(1, 1, 1), # White
    Color(0, 0, 0), # Black
]

func _ready():
    # Inicializamos el plugin
    if has_node("/root/InputMultiDevice"):
        # Conectamos la señal universal del Plugin para spawnear jugadores
        InputMultiDevice.player_joined_lobby.connect(_try_spawn_player)
        
        # Spawneamos a los que ya se unieron en el Lobby
        for p_id in InputMultiDevice.player_to_device:
            _try_spawn_player(InputMultiDevice.player_to_device[p_id])
    else:
        print("ERROR: AutoLoad InputMultiDevice no encontrado. Recuerda activarlo en Plugins.")

func _try_spawn_player(device_id: int):
    if device_id in spawned_devices:
        return
        
    spawned_devices.append(device_id)
    
    if has_node("/root/InputMultiDevice"):
        var p_id = current_player_id
        InputMultiDevice.setup_player_device(p_id, device_id)
        
        var player_node = player_scene.instantiate()
        add_child(player_node)
        
        var color = player_colors[p_id % player_colors.size()]
        # Position players slightly separated
        player_node.global_position = Vector2(250 + (p_id * 150), 200)
        player_node.setup(p_id, device_id, color)
        
        current_player_id += 1
