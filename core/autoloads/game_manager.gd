extends Node

# Definimos acciones estandar necesarias por InputMultiDevice (Arriba, Derecha, Abajo, Izquierda)
var movements = ["move_up", "move_right", "move_down", "move_left"]

func _ready() -> void:
    # Configuramos los movimientos direccionales, pasando Numpad para el segundo teclado.
    var numpad = [KEY_KP_8, KEY_KP_6, KEY_KP_5, KEY_KP_4]
    InputMultiDevice.setup_movements(movements, [], numpad)
    
    # Configuramos las acciones genéricas. Añadiremos "crouch" para probar el Toggle
    InputMultiDevice.setup_actions(["crouch"], [KEY_SPACE], [KEY_KP_ENTER])
    
    # Inmediatamente cargamos lo que el usuario guardó en el menú de opciones (Persistence)
    InputMultiDevice.load_profiles()