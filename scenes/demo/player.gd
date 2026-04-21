extends CharacterBody2D

const SPEED = 400.0
const JUMP_VELOCITY = -600.0

var player_id: int = 0
var device_id: int = -1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func setup(p_id: int, d_id: int, color: Color) -> void:
	player_id = p_id
	device_id = d_id
	if has_node("Sprite2D"):
		$Sprite2D.modulate = color

func _physics_process(delta):
	# Obtener dirección horizontal con el plugin
	var direction = InputMultiDevice.get_axis(player_id, "move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Añadir Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Controlar Salto solo si está en el suelo
		if InputMultiDevice.is_action_just_pressed(player_id, "move_up"):
			velocity.y = JUMP_VELOCITY

	move_and_slide()

	# Mostrar el input presionado en el Label superior
	if has_node("InputLabel") and has_node("/root/InputMultiDevice"):
		var inputs_pressed = []
		
		# Función rápida para sacar el texto literal de Enum (KEY_W, KEY_KP_8, etc.)
		var get_key_str = func(action):
			var profile = InputMultiDevice.player_profiles.get(player_id, {})
			var event = profile.get(action)
			if not event: return ""
			
			if event is InputEventKey:
				var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
				var raw_str = OS.get_keycode_string(code).to_upper().replace(" ", "_")
				return "KEY_" + raw_str
			elif event is InputEventJoypadButton:
				return "JOY_BTN_" + str(event.button_index)
			elif event is InputEventJoypadMotion:
				return "JOY_AXIS_" + str(event.axis)
			return event.as_text()

		if InputMultiDevice.is_action_pressed(player_id, "move_up"): inputs_pressed.append("UP " + get_key_str.call("move_up"))
		if InputMultiDevice.is_action_pressed(player_id, "move_down"): inputs_pressed.append("DOWN " + get_key_str.call("move_down"))
		if InputMultiDevice.is_action_pressed(player_id, "move_left"): inputs_pressed.append("LEFT " + get_key_str.call("move_left"))
		if InputMultiDevice.is_action_pressed(player_id, "move_right"): inputs_pressed.append("RIGHT " + get_key_str.call("move_right"))
		
		$InputLabel.text = " ".join(inputs_pressed)
