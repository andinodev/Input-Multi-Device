# InputMultiDevice Plugin para Godot 4.x

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

## 2. Asignando Controladores y Perfiles

Para un juego local, la forma más moderna de asignar mandos es a través de una escena **Lobby** o mediante un **Modo Arcade** (amigable y directo).

El plugin incluye una señal universal lista para capturar Start/Enter. Puedes escuchar esto en tu menú, asignarle el Dispositivo a un número de Jugador de tu preferencia, y aplicar un Perfil Nombrado de Input:

```gdscript
# Conectado a la señal InputMultiDevice.player_joined_lobby
func _on_player_joined(device_id):
    var player_id = obtener_siguiente_libre_del_1_al_8()

    # 1. Emparejamos física (Hardware) con lógica (Jugador)
    InputMultiDevice.setup_player_device(player_id, device_id)

    # 2. Le inyectamos su perfil de botones favorito (estilo Super Smash Bros)
    InputMultiDevice.apply_custom_profile_to_player(player_id, "DANIEL_CUSTOM")
```

> [!TIP]
> En la carpeta `addons/input_multi_device/scenes/` encontrarás el **Modo Arcade**, una demostración técnica `Plug & Play` incluida directamente en el plugin para que veas cómo spawnear jugadores al vuelo sin un Lobby complejo.

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

## 4. Opciones Avanzadas: Sistema CRUD de Perfiles Nombrados

El plugin maneja un banco de datos interno llamado `custom_profiles`. Al contrario de sobreescribir "player 1", este sistema emula el estándar actual de peleas guardando _Perfiles Personalizados_ (Strings) que los jugadores pueden intercambiarse.

```gdscript
# 1. Crear un nuevo perfil clonando el layout de un Mando Base (Device = 0)
InputMultiDevice.create_custom_profile("Player_Pro", 0)

# 2. Escuchar un botón in-game para remapearlo en tu pantalla de Opciones
func _input(event):
    if listening_for_input and event.is_pressed():
        InputMultiDevice.remap_custom_profile("Player_Pro", "attack", event)

# 3. Eliminar perfiles basura
InputMultiDevice.delete_custom_profile("Player_Pro")
```

> [!TIP]
> Recuerda usar las plantillas protegidas del motor (`Default_Mando`, `Default_Teclado_1`, `Default_Teclado_2`) como bases inmutables para recuperar controles si alguien "rompe" su perfil durante el remapeo.

---

## 5. Zonas Muertas (Deadzones)

Por defecto, Godot aplica una zona muerta opaca de `0.5`, pero en juegos de alta precisión esto puede ser muy tosco. El plugin inyecta por defecto una `global_base_deadzone` optimizada de `0.2` a todos los ejes creados.
Puedes brindarle un control (slider) a tus jugadores en las Opciones para ajustarlo dinámicamente:

```gdscript
InputMultiDevice.set_global_deadzone(0.15)
```

---

## 6. Estados Automáticos "Toggle"

Si necesitas que un botón actúe como un **interruptor** ("agacharse" vs "levantarse", "prender o apagar linterna"), en lugar de crear molestas variables internas de estado en tu personaje, delega el trabajo de rastreo al plugin usando este método en tu `_physics_process`:

```gdscript
# Cambiará entre 'true' y 'false' mágicamente cada vez que el jugador haga el "just_pressed" de la acción.
if InputMultiDevice.is_action_toggled(mi_player_id, "crouch"):
    print("Modo sigilo activado")
else:
    print("Modo normal")
```

---

## 7. Vibración Enrutada (Rumble/Haptics)

En Godot puro tienes que saber el Device ID del gamepad y programar condiciones `if device >= 0` por todo tu código para no crashear los teclados virtuales. El plugin enruta esto automáticamente con total seguridad; si el jugador usa teclado, la orden hace _bypass_ silencioso sin consumir recursos:

```gdscript
# Sintaxis: start_vibration(player_id, motor_debil, motor_fuerte, duracion_en_segs)
InputMultiDevice.start_vibration(mi_player_id, 0.5, 1.0, 2.0)

# Parar manualmente una vibración infinita
InputMultiDevice.stop_vibration(mi_player_id)
```

---

## 8. Guardado y Carga de Perfiles (Persistencia)

Se ha integrado el script `profile_persistence.gd` diseñado para sortear la dificultad de serializar objetos `InputEvent` y transformarlos en formato encriptado de disco (CFG) a la ruta nativa y segura `user://input_profiles.cfg` sin ralentizar tu hilo principal.

```gdscript
# Simplemente llama a guardar cuando el jugador cierre el menú de mapeo de controles:
InputMultiDevice.save_profiles()

# Y llama a cargar en el _ready() de tu Juego o Menu Principal para restaurarlos:
InputMultiDevice.load_profiles()
```
