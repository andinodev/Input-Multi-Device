extends Control

func _ready():
	# No necesitamos inicializar nada, InputMultiDevice ya está corriendo
	pass

func _input(event):
	# Si presionan Start/Enter (la acción universal), entramos a la arena
	if event.is_action_pressed("lobby_universal_join"):
		get_tree().change_scene_to_file("res://addons/input_multi_device/scenes/spaceship/shmup_demo.tscn")
