extends Area2D

const SPEED = 800.0
var owner_id = -1
@onready var sprite = $ColorRect

func setup(p_id: int):
	owner_id = p_id

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += Vector2.RIGHT * SPEED * delta
	
	if position.y < -1000:
		queue_free()

func _on_body_entered(body):
	if body.has_method("setup") and body.my_player_id != owner_id:
		# Hit another player
		body.anim.play("damage")
		InputMultiDevice.start_vibration(body.my_player_id, 1.0, 1.0, 0.2)
		queue_free()
