# InputMultiDevice Plugin para Godot 4

Este plugin permite a los desarrolladores gestionar ágilmente las entradas físicas (Inputs) para partidas multijugador local en un mismo PC, ya sean juegos de plataforma cooperativos, de mesa, o de peleas.

En lugar de crear manualmente cientos de eventos en el `InputMap` usando sufijos extraños como `"p0_jump"`, `"p1_jump"`, etc. este plugin intercepta la conexión de gamepads y asigna un mapeo seguro para evitar "ghosting" e interferencias entre mandos.

## Pasos de Instalación

1. Copia la carpeta **`input_multi_device/`** al directorio **`addons/`** de tu proyecto Godot.
2. Abre tu proyecto de Godot.
3. Ve a `Proyecto` > `Configuración del Proyecto` > `Plugins`.
4. Activa el plugin marcando la casilla de verificación en **"InputMultiDevice"**.
5. ¡Listo! El entorno ya cuenta con un AutoLoad principal global bajo el nombre `InputMultiDevice`.

---

## 1. Configuración Inicial (El "Setup")

Dicha configuración solo necesitas mandarla a llamar **1 sola vez** al momento en el que inicie tu juego (`_ready` del `Main` o del `Lobby`).

Le diremos a nuestro AutoLoad qué acciones queremos registrar divididas en dos grandes grupos: `Movimientos` y `Acciones Genéricas`.

```gdscript
func _ready():
    # 1. Definimos las direcciones de movimiento ESTRICTAMENTE en sentido Horario!
    var movimientos = ["move_up", "move_right", "move_down", "move_left"]

    # 2. Definimos nuestras acciones sueltas del estilo de juego
    var acciones = ["jump", "attack", "interact", "dash"]

    # 3. (Opcional) Puedes inyectar las teclas por defecto que quieras para tu juego.
    var defaults_mov_teclado2 = [KEY_KP_8, KEY_KP_6, KEY_KP_5, KEY_KP_4] # Numpad
    var defaults_act_teclado1 = [KEY_SPACE, KEY_X, KEY_E, KEY_SHIFT]
    var defaults_act_mando = [JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B]

    # 4. Inicializamos Movimientos y Acciones por separado
    if has_node("/root/InputMultiDevice"):
        var imd = get_node("/root/InputMultiDevice")
        imd.setup_movements(movimientos, [], defaults_mov_teclado2)
        imd.setup_actions(acciones, defaults_act_teclado1, [], defaults_act_mando)
```

> [!NOTE]
> Si no provees perfiles por defecto (parámetros opcionales), el plugin utilizará un mapeado genérico "Fallback" intentando asignar lógicamente tu lista a WASD / Flechas para movimientos, y a los botones principales para las acciones (A, B, X, Y, etc.).

---

## 2. Asignando Controladores

Para un juego local, tendrás que decidir el momento de "asignarle el control al jugador 1" y "asignarle otro mando al jugador 2". Normalmente tienes una pantalla para esto (`Lobby`).

Cuando sepas con qué hardware quiere correr cada jugador, llama la función:

```gdscript
# Sintaxis: setup_player_device(player_id, device_id)

# Ejemplo para el Jugador 0 y Teclado principal (Device = -1)
InputMultiDevice.setup_player_device(0, -1)

# Ejemplo para Jugador 1 y el Joypad #0 de USB/Bluetooth (Device = 0)
InputMultiDevice.setup_player_device(1, 0)
```

---

## 3. Consultando el Estado In-Game

Cierra los ojos y olvídate del anticuado `Input.is_action_pressed()`. En tu clase de Personaje de aquí en adelante siempre consultarás la capa de InputMultiDevice, brindándole el ID del personaje:

```gdscript
var mi_player_id = 0 # (El jugador asignado a este PlayerNode)

func _physics_process(delta):
    # Preguntar por acciones simples
    if InputMultiDevice.is_action_pressed(mi_player_id, "jump"):
        velocity.y = -400.0

    if InputMultiDevice.is_action_just_pressed(mi_player_id, "attack"):
        print("Toma golpe!")

    # Preguntar por vectores armados (Ideal para mover tu KinematicBody!)
    var dir = InputMultiDevice.get_vector(mi_player_id, "move_left", "move_right", "move_up", "move_down")
    velocity.x = dir.x * SPEED
```

---

## 4. Opciones Avanzadas: Remapeando controles en tiempo real

Si ofreces un menú de opciones donde permites al Jugador apretar su tecla deseada:

```gdscript
func _input(event):
    if listening_for_input and event.is_pressed():
        # Cambiar el ataque para el jugador 1 a la nueva tecla presionada
        InputMultiDevice.remap_action(1, "attack", event)
```

> [!TIP]
> Puedes conseguir todo el diccionario de los eventos y perfiles (para pasarlos a un guardado JSON) desde el caché: `InputMultiDevice.player_profiles`
