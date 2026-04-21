extends Node

# Definimos acciones estandar necesarias por InputMultiDevice (Arriba, Derecha, Abajo, Izquierda)
var movements = ["move_up", "move_right", "move_down", "move_left"]

# Almacena temporalmente la escena de juego seleccionada para el Lobby
var target_game_scene: String = ""

func _ready() -> void:
    # Configuramos los movimientos direccionales, pasando Numpad para el segundo teclado.
    var numpad = [KEY_KP_8, KEY_KP_6, KEY_KP_5, KEY_KP_4]
    InputMultiDevice.setup_movements(movements, [], numpad)
    
    # Configuramos las acciones genéricas. Añadiremos "crouch" para probar el Toggle
    InputMultiDevice.setup_actions(["crouch", "shoot"], [KEY_SPACE, KEY_SPACE], [KEY_KP_ENTER, KEY_KP_ENTER], [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER])
    
    # Inmediatamente cargamos lo que el usuario guardó en el menú de opciones (Persistence)
    InputMultiDevice.load_profiles()