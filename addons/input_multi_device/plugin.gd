@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("InputMultiDevice", "res://addons/input_multi_device/input_multi_device.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("InputMultiDevice")
