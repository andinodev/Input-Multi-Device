extends CharacterBody2D

const SPEED = 400.0
const FIRE_RATE = 0.2

@onready var anim = $AnimatedSprite2D
var bullet_scene = preload("res://addons/input_multi_device/scenes/spaceship/bullet.tscn")

var my_player_id: int = -1
var my_device_id: int = -1
var last_fire_time = 0.0

func setup(player_id: int, device_id: int, color_tint: Color) -> void:
	my_player_id = player_id
	my_device_id = device_id
	anim.modulate = color_tint
	anim.play("idle")
	
	# Colocamos un pequeño indicador de que player es
	var lbl = Label.new()
	lbl.text = "P" + str(player_id + 1)
	lbl.position = Vector2(-15, 40)
	lbl.theme_type_variation = "LabelBody"
	add_child(lbl)

func _physics_process(delta: float) -> void:
	if my_player_id < 0: return

	# 1. Movimiento (Galaga 8-way)
	var dir = InputMultiDevice.get_vector(my_player_id, "move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
	
	# Animaciones
	if dir.y > 0.1:
		print(dir)
		anim.play("turn_left") # The sprite actually has turn_1/turn_2? We might need to check the anim names.
	elif dir.y < -0.1:
		print(dir)
		anim.play("turn_right")
	else:
		if velocity.length() > 0:
			anim.play("move")
		else:
			anim.play("idle")

	# 2. Disparo "Touhou" (recto hacia arriba)
	last_fire_time += delta
	# Si presionamos saltar/atacar -> disparar
	if InputMultiDevice.is_action_pressed(my_player_id, "shoot"):
		if last_fire_time >= FIRE_RATE:
			_fire()

func _fire() -> void:
	last_fire_time = 0.0
	var bullet = bullet_scene.instantiate()
	bullet.setup(my_player_id)
	
	# Usamos global_position para no atar la bala al padre
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -50)
	
	InputMultiDevice.start_vibration(my_player_id, 0.2, 0.0, 0.1)
