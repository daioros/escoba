# GameScene_portrait.gd
extends GameSceneBase

func _setup_nodes() -> void:
	table_area       = $MainVBox/TableArea
	player_hand_area = $MainVBox/PlayerHandArea
	comp_hand_area   = $MainVBox/CompHandArea
	status_label     = $MainVBox/StatusLabel
	score_label      = $MainVBox/InfoRow/ScoreLabel
	deck_label       = $MainVBox/InfoRow/DeckLabel
	escobas_label    = $MainVBox/InfoRow/EscobasLabel
	confirm_button   = $MainVBox/BottomBar/ButtonRow/ConfirmButton
	pass_button      = $MainVBox/BottomBar/ButtonRow/PassButton
	end_turn_hint    = $MainVBox/BottomBar/EndTurnHint
	error_label      = $MainVBox/ErrorLabel
	button_row       = $MainVBox/BottomBar/ButtonRow

func _connect_quit_button() -> void:
	$MainVBox/BottomBar/ButtonRow/QuitButton.pressed.connect(_on_quit_pressed)
