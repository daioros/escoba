# MainMenuLauncher.gd
# Detects orientation and loads the correct MainMenu layout.
extends Node

func _ready() -> void:
	if GameSettings.orientation == 1:
		get_tree().root.content_scale_size = Vector2i(540, 960)
		# Only set orientation on mobile platforms
		if OS.get_name() in ["Android", "iOS"]:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu_portrait.tscn")
	else:
		get_tree().root.content_scale_size = Vector2i(960, 540)
		# Only set orientation on mobile platforms
		if OS.get_name() in ["Android", "iOS"]:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu_landscape.tscn")
