# MainMenu.gd
# Shared by both MainMenu_landscape.tscn and MainMenu_portrait.tscn
extends Control

func _ready() -> void:
	$CenterContainer/VBox/PlayButton.pressed.connect(_on_play)
	$CenterContainer/VBox/ConfigButton.pressed.connect(_on_config)
	$CenterContainer/VBox/CreditsButton.pressed.connect(
		func(): $CreditsPanel.visible = not $CreditsPanel.visible)
	$CreditsPanel/CloseButton.pressed.connect(
		func(): $CreditsPanel.visible = false)
	$CenterContainer/VBox/ExitRow/ExitButton.pressed.connect(func(): get_tree().quit())

func _on_play() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/GameScene.tscn")

func _on_config() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Config.tscn")
