# Config.gd
extends Control

@onready var target_label    = $CenterContainer/VBox/TargetRow/TargetLabel
@onready var target_minus    = $CenterContainer/VBox/TargetRow/TargetMinus
@onready var target_plus     = $CenterContainer/VBox/TargetRow/TargetPlus
@onready var btn_dealer_tu   = $CenterContainer/VBox/DealerRow/BtnDealer_Tu
@onready var btn_dealer_yo   = $CenterContainer/VBox/DealerRow/BtnDealer_Yo
@onready var orientation_btn = $CenterContainer/VBox/OrientationButton
@onready var sound_btn       = $CenterContainer/VBox/SoundButton

var _target:      int  = 21
var _dealer:      int  = 1
var _orientation: int  = 0

func _ready() -> void:
	_target      = GameSettings.target_points
	_dealer      = GameSettings.first_dealer
	_orientation = GameSettings.orientation

	# Lighter background on the target number label
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.45, 0.15, 1)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	target_label.add_theme_stylebox_override("normal", style)

	_refresh_target()
	_refresh_dealer_buttons()
	_refresh_orientation_label()
	_refresh_sound_label()

	target_minus.pressed.connect(_on_minus)
	target_plus.pressed.connect(_on_plus)
	btn_dealer_tu.pressed.connect(_on_dealer_tu)
	btn_dealer_yo.pressed.connect(_on_dealer_yo)
	orientation_btn.pressed.connect(_on_orientation_toggle)
	sound_btn.pressed.connect(_on_sound_toggle)
	$CenterContainer/VBox/BackRow/BackButton.pressed.connect(_on_back)

func _on_minus() -> void:
	_target = max(1, _target - 1)
	_refresh_target()

func _on_plus() -> void:
	_target = min(21, _target + 1)
	_refresh_target()

func _refresh_target() -> void:
	target_label.text     = str(_target)
	target_minus.disabled = (_target <= 1)
	target_plus.disabled  = (_target >= 21)

func _on_dealer_tu() -> void:
	_dealer = 1
	_refresh_dealer_buttons()

func _on_dealer_yo() -> void:
	_dealer = 2
	_refresh_dealer_buttons()

func _refresh_dealer_buttons() -> void:
	btn_dealer_tu.button_pressed = (_dealer == 1)
	btn_dealer_yo.button_pressed = (_dealer == 2)
	_style_dealer_btn(btn_dealer_tu, _dealer == 1)
	_style_dealer_btn(btn_dealer_yo, _dealer == 2)

func _style_dealer_btn(btn: Button, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color     = Color(0.1, 0.7, 0.2, 1)   # bright green
		style.border_color = Color(0.3, 1.0, 0.4, 1)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	else:
		style.bg_color     = Color(0.15, 0.15, 0.15, 1) # dark grey
		style.border_color = Color(0.4, 0.4, 0.4, 1)
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal",   style)
	btn.add_theme_stylebox_override("pressed",  style)
	btn.add_theme_stylebox_override("hover",    style)
	btn.add_theme_stylebox_override("disabled", style)

func _on_orientation_toggle() -> void:
	_orientation = 1 - _orientation
	_apply_orientation()

func _apply_orientation() -> void:
	GameSettings.orientation = _orientation

	if _orientation == 0:
		# Landscape: 960x540
		get_tree().root.content_scale_size = Vector2i(960, 540)
		if OS.get_name() == "Android":
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
		else:
			# On desktop, just resize the window. No rotation happens.
			get_window().size = Vector2i(960, 540)
	else:
		# Portrait: 540x960
		get_tree().root.content_scale_size = Vector2i(540, 960)
		if OS.get_name() == "Android":
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		else:
			# On desktop, just resize the window. No rotation happens.
			get_window().size = Vector2i(540, 960)
	_refresh_orientation_label()
	
	

func _refresh_orientation_label() -> void:
	if _orientation == 0:
		orientation_btn.text = "📱 Modo: Horizontal"
	else:
		orientation_btn.text = "📱 Modo: Vertical"

func _on_sound_toggle() -> void:
	GameSettings.sound_enabled = not GameSettings.sound_enabled
	# Mute/unmute the master audio bus
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),
		not GameSettings.sound_enabled)
	_refresh_sound_label()

func _refresh_sound_label() -> void:
	if GameSettings.sound_enabled:
		sound_btn.text = "🔊 Sonido: ON"
	else:
		sound_btn.text = "🔇 Sonido: OFF"

func _on_back() -> void:
	GameSettings.target_points = _target
	GameSettings.first_dealer  = _dealer
	get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu.tscn")
