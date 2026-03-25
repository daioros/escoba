# ConfigLauncher.gd
# Detects orientation and loads the correct Config layout.
extends Node

func _ready() -> void:
	if GameSettings.orientation == 1:
		get_tree().root.content_scale_size = Vector2i(540, 960)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/Config_portrait.tscn")
	else:
		get_tree().root.content_scale_size = Vector2i(960, 540)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/Config_landscape.tscn")
