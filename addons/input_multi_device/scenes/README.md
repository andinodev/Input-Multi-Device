# Guía de Uso del Plugin: Input Multi Device

Este plugin centraliza la gestión de entradas para juegos multijugador local, permitiendo que cada jugador tenga su propio esquema de controles (Teclado 1, Teclado 2 o Mando) y perfiles personalizados.

---

## 🎥 Referencias de Video

Puedes ver el plugin en funcionamiento en los siguientes demos técnicos:

|                                                 Space Shooter                                                 |                                                 Menu Options                                                 |                                                 Platform Demo                                                 |
| :-----------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------: |
| [![Space Shooter](https://img.youtube.com/vi/OM8Y3rDhopg/0.jpg)](https://www.youtube.com/watch?v=OM8Y3rDhopg) | [![Options Demo](https://img.youtube.com/vi/WWS-FhEtuk4/0.jpg)](https://www.youtube.com/watch?v=WWS-FhEtuk4) | [![Platform Demo](https://img.youtube.com/vi/nqTrlHFIsfU/0.jpg)](https://www.youtube.com/watch?v=nqTrlHFIsfU) |
|                         [Ver en YouTube](https://www.youtube.com/watch?v=OM8Y3rDhopg)                         |                        [Ver en YouTube](https://www.youtube.com/watch?v=WWS-FhEtuk4)                         |                         [Ver en YouTube](https://www.youtube.com/watch?v=nqTrlHFIsfU)                         |

---

## 1. Zonas de Juego (Gameplay)

En las escenas de acción, no uses el `Input` global de Godot. Usa el Singleton `InputMultiDevice` pasando el `player_id` (0-7):

- **Movimiento**:
  `velocity.x = InputMultiDevice.get_axis(player_id, "move_left", "move_right") * SPEED`
- **Acciones**:
  `if InputMultiDevice.is_action_just_pressed(player_id, "shoot"): _fire()`
- **Vibración** :
  `InputMultiDevice.start_vibration(player_id, 0.5, 0.5, 0.2)`
- **Dead Zones**:
  `InputMultiDevice.set_global_deadzone(0.1)`

## 2. Lobby (Selección de Jugadores)

En cualquier momento puedes vincular el hardware físico con un ID de jugador lógico, pero el lobby es perfecto para establecer configuraciones como perfiles para los jugadores (Los perfiles nos permiten modificar la asignación de teclas/botones).

1.  **Detectar Unión**: Conecta la señal `player_joined_lobby(device_id)`.
2.  **Asignar Dispositivo**: Llama a `InputMultiDevice.setup_player_device(player_id, device_id)`.
3.  **Aplicar Perfil**: Una vez elegido un perfil (ej. "Mando_Zurdo"), usa `InputMultiDevice.apply_custom_profile_to_player(player_id, profile_name)`.

## 3. Menú de Opciones (Configuración)

Permite a los usuarios crear sus propios mapeos persistentes.

- **Gestión de Perfiles**: Usa `create_custom_profile`, `delete_custom_profile` y `remap_custom_profile`.
- **Persistencia**:
  - `InputMultiDevice.save_profiles()`: Guarda todos los perfiles personalizados en `user://`.
  - `InputMultiDevice.load_profiles()`: Carga los perfiles al iniciar el juego (recomendado en el `_ready` de tu script principal).
