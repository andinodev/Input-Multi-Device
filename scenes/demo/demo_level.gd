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
]

func _ready():
    # Definimos acciones estandar necesarias por InputMultiDevice (Arriba, Derecha, Abajo, Izquierda)
    var movimientos = ["move_up", "move_right", "move_down", "move_left"]
    
    # Inicializamos el plugin
    if has_node("/root/InputMultiDevice"):
        # Configuramos los movimientos direccionales, pasando Numpad para el segundo teclado.
        var numpad = [KEY_KP_8, KEY_KP_6, KEY_KP_5, KEY_KP_4]
        InputMultiDevice.setup_movements(movimientos, [], numpad)
        
        # Configuramos las acciones genéricas (en nuestro caso, no tenemos botones sueltos aún)
        InputMultiDevice.setup_actions([])
    else:
        print("ERROR: AutoLoad InputMultiDevice no encontrado. Recuerda activarlo en Plugins.")

func _unhandled_input(event):
    # Si pulsamos la K (Device -1 => Teclado 1)
    if event is InputEventKey and event.is_pressed() and not event.echo:
        if event.physical_keycode == KEY_K:
            _try_spawn_player(-1)
        elif event.physical_keycode == KEY_KP_2:
            _try_spawn_player(-3)

    # Si es mando y pulsamos START
    if event is InputEventJoypadButton and event.is_pressed():
        if event.button_index == JOY_BUTTON_START:
            _try_spawn_player(event.device)

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
