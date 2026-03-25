# SoundManager.gd
# Plays MP3 sound effects. Autoloaded as "SoundManager".
extends Node

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func _play(path: String) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("SoundManager: could not load " + path)
		return
	_player.stream = stream
	_player.play()

func play_drop() -> void:
	_play("res://sounds/cardDrop.mp3")

func play_take() -> void:
	_play("res://sounds/cardTaken.mp3")

func play_flipping() -> void:
	_play("res://sounds/cardFlipping.mp3")

func play_end() -> void:
	_play("res://sounds/putaMadre.mp3")

func play_haha() -> void:
	_play("res://sounds/haha.mp3")
