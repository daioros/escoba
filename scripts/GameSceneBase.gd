# GameSceneBase.gd
# Shared game logic for both landscape and portrait layouts.
# Subclasses must set these variables in _setup_nodes() before calling super._ready()
class_name GameSceneBase
extends Control

var logic: GameLogic

# These must be assigned by each subclass in _setup_nodes()
var table_area:       HBoxContainer
var player_hand_area: HBoxContainer
var comp_hand_area:   HBoxContainer
var status_label:     Label
var score_label:      Label
var deck_label:       Label
var escobas_label:    Label
var confirm_button:   Button
var pass_button:      Button
var end_turn_hint:    Label
var error_label:      Label
var button_row:       Control  # the ButtonRow node to show/hide

var round_summary_panel: Panel
var summary_content:     Label
var continue_button:     Button

const CARD_SCENE = preload("res://scenes/CardNode.tscn")

var selected_hand_card:   int   = 0
var selected_table_cards: Array = []
var _hand_nodes:          Dictionary = {}
var _table_nodes:         Dictionary = {}

# ------------------------------------------------------------------
# Subclasses override this to assign all node vars above
func _setup_nodes() -> void:
	pass

func _ready() -> void:
	_setup_nodes()
	_create_summary_panel()
	logic = GameLogic.new()
	logic.state_changed.connect(_on_state_changed)
	logic.new_game(GameSettings.target_points, GameSettings.first_dealer)
	SoundManager.play_flipping()
	confirm_button.pressed.connect(_on_confirm_pressed)
	pass_button.pressed.connect(_on_pass_pressed)
	_connect_quit_button()
	_update_ui()
	if logic.current_turn == 2:
		_maybe_comp_turn()

# Subclasses override to connect their specific quit button
func _connect_quit_button() -> void:
	pass

# ------------------------------------------------------------------
# SUMMARY PANEL (created in code — works in any resolution)
# ------------------------------------------------------------------

func _create_summary_panel() -> void:
	round_summary_panel = Panel.new()
	round_summary_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	round_summary_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color        = Color(0.04, 0.15, 0.04, 0.95)
	style.border_color    = Color(0.4, 0.8, 0.4, 1)
	style.border_width_left   = 2; style.border_width_right  = 2
	style.border_width_top    = 2; style.border_width_bottom = 2
	style.corner_radius_top_left     = 8; style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8; style.corner_radius_bottom_right = 8
	round_summary_panel.add_theme_stylebox_override("panel", style)
	add_child(round_summary_panel)

	var title := Label.new()
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24.0; title.offset_bottom = 70.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "RECUENTO PARCIAL"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	round_summary_panel.add_child(title)

	var table_root := Node2D.new()
	table_root.name = "TableRoot"
	round_summary_panel.add_child(table_root)

	summary_content = Label.new()
	summary_content.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	summary_content.offset_top = -130.0; summary_content.offset_bottom = -70.0
	summary_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_content.add_theme_font_size_override("font_size", 26)
	round_summary_panel.add_child(summary_content)

	continue_button = Button.new()
	continue_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	continue_button.offset_left = 150.0; continue_button.offset_right  = -150.0
	continue_button.offset_top  = -60.0; continue_button.offset_bottom = -12.0
	continue_button.text = "Continuar"
	continue_button.add_theme_font_size_override("font_size", 22)
	round_summary_panel.add_child(continue_button)

func _place_label(parent: Node, x: int, y: int, w: int, h: int,
		text: String, font_size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var lbl := Label.new()
	lbl.position = Vector2(x, y); lbl.size = Vector2(w, h)
	lbl.text = text; lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; lbl.clip_text = true
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)

func _place_hrule(parent: Node, x: int, y: int, w: int) -> void:
	var r := ColorRect.new()
	r.position = Vector2(x, y); r.size = Vector2(w, 1)
	r.color = Color(0.4, 0.8, 0.4, 0.5); parent.add_child(r)

func _place_vrule(parent: Node, x: int, y: int, h: int) -> void:
	var r := ColorRect.new()
	r.position = Vector2(x, y); r.size = Vector2(1, h)
	r.color = Color(0.4, 0.8, 0.4, 0.3); parent.add_child(r)

# ------------------------------------------------------------------
# UI UPDATE
# ------------------------------------------------------------------

func _update_ui() -> void:
	_rebuild_comp_hand()
	_sync_table()
	_sync_player_hand()
	_update_labels()
	_update_buttons()
	error_label.text = ""

func _sync_player_hand() -> void:
	for cid in _hand_nodes.keys():
		if cid not in logic.player_hand:
			_hand_nodes[cid].queue_free(); _hand_nodes.erase(cid)
	for card_id in logic.player_hand:
		if card_id not in _hand_nodes:
			var node := CARD_SCENE.instantiate()
			player_hand_area.add_child(node)
			node.setup(card_id, false)
			node.card_pressed.connect(_on_hand_card_pressed)
			_hand_nodes[card_id] = node
	for card_id in _hand_nodes:
		_hand_nodes[card_id].set_selected(card_id == selected_hand_card)

func _sync_table() -> void:
	for cid in _table_nodes.keys():
		if cid not in logic.table_cards:
			_table_nodes[cid].queue_free(); _table_nodes.erase(cid)
	for card_id in logic.table_cards:
		if card_id not in _table_nodes:
			var node := CARD_SCENE.instantiate()
			table_area.add_child(node)
			node.setup(card_id, false)
			node.card_pressed.connect(_on_table_card_pressed)
			_table_nodes[card_id] = node
	for card_id in _table_nodes:
		_table_nodes[card_id].set_selected(card_id in selected_table_cards)

func _rebuild_comp_hand() -> void:
	for child in comp_hand_area.get_children():
		child.queue_free()
	for _i in range(logic.comp_hand.size()):
		var node := CARD_SCENE.instantiate()
		comp_hand_area.add_child(node)
		node.setup(0, true)

func _update_labels() -> void:
	score_label.text    = "TÚ: %d   YO: %d   (hasta %d)" % [logic.player_points, logic.comp_points, logic.target_points]
	deck_label.text     = "Quedan %d cartas" % logic.cards_remaining_in_deck()
	escobas_label.text  = "Escobas TÚ: %d  YO: %d" % [logic.player_escobas, logic.comp_escobas]
	var sum_on_table := 0
	for c in logic.table_cards:
		sum_on_table += CardData.get_number(c)
	if logic.current_turn == 1:
		if selected_hand_card == 0:
			status_label.text = "① Elige una carta de TU MANO"
		elif selected_table_cards.is_empty():
			var hand_val := CardData.get_number(selected_hand_card)
			status_label.text = "② Elige cartas de la MESA que sumen %d (o confirma para dejar)" % (15 - hand_val)
		else:
			var s := CardData.get_number(selected_hand_card)
			for c in selected_table_cards:
				s += CardData.get_number(c)
			status_label.text = "Suma: %d / 15  —  Añade más o confirma" % s
	else:
		status_label.text = "Hay %d puntos en la mesa" % sum_on_table

func _update_buttons() -> void:
	var is_player_turn: bool = (logic.current_turn == 1)
	button_row.visible    = is_player_turn
	end_turn_hint.visible = not is_player_turn
	if is_player_turn and logic.player_hand.size() == 1 and selected_hand_card == 0:
		selected_hand_card = logic.player_hand[0]
		for card_id in _hand_nodes:
			_hand_nodes[card_id].set_selected(card_id == selected_hand_card)
		_update_labels()

# ------------------------------------------------------------------
# INPUT
# ------------------------------------------------------------------

func _on_hand_card_pressed(card_id: int) -> void:
	if logic.current_turn != 1: return
	if selected_hand_card != card_id:
		selected_table_cards.clear()
	selected_hand_card = card_id
	error_label.text = ""
	for cid in _hand_nodes:
		_hand_nodes[cid].set_selected(cid == selected_hand_card)
	for cid in _table_nodes:
		_table_nodes[cid].set_selected(false)
	_update_labels()

func _on_table_card_pressed(card_id: int) -> void:
	if logic.current_turn != 1: return
	if selected_hand_card == 0:
		_show_error("① Primero elige una carta de TU MANO."); return
	if card_id in selected_table_cards:
		selected_table_cards.erase(card_id)
	else:
		selected_table_cards.append(card_id)
	error_label.text = ""
	if card_id in _table_nodes:
		_table_nodes[card_id].set_selected(card_id in selected_table_cards)
	_update_labels()

func _on_confirm_pressed() -> void:
	if selected_hand_card == 0:
		_show_error("① Primero elige una carta de TU MANO."); return
	var err: String = logic.validate_player_move(selected_hand_card, selected_table_cards)
	if err != "":
		_show_error(err); return
	if selected_table_cards.is_empty():
		SoundManager.play_drop()
		logic.apply_player_leave(selected_hand_card)
	else:
		var all_cards: Array = [selected_hand_card] + selected_table_cards
		var is_escoba: bool = (selected_table_cards.size() == logic.table_cards.size())
		var takes_velo: bool = false
		for c in all_cards:
			if CardData.get_number(c) == 7 and CardData.get_suit(c) == CardData.Suit.OROS:
				takes_velo = true
		logic.apply_player_take(selected_hand_card, selected_table_cards)
		if is_escoba or takes_velo:
			SoundManager.play_end()
		else:
			SoundManager.play_take()
	selected_hand_card = 0
	selected_table_cards.clear()
	_after_player_move()

func _on_pass_pressed() -> void:
	selected_hand_card = 0; selected_table_cards.clear()
	for cid in _hand_nodes: _hand_nodes[cid].set_selected(false)
	for cid in _table_nodes: _table_nodes[cid].set_selected(false)
	error_label.text = ""; _update_labels()

func _on_quit_pressed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu.tscn")

func _show_error(msg: String) -> void:
	error_label.text = msg

# ------------------------------------------------------------------
# GAME FLOW
# ------------------------------------------------------------------

func _on_state_changed() -> void: _update_ui()
func _after_player_move() -> void: _update_ui(); _check_deal_or_end()

func _check_deal_or_end() -> void:
	if logic.hands_empty():
		if logic.is_last_deal:
			await get_tree().create_timer(0.8).timeout
			_finish_round()
		else:
			await get_tree().create_timer(0.5).timeout
			SoundManager.play_flipping()
			logic.deal_hands(); _update_ui()
			await _maybe_comp_turn()
	else:
		await _maybe_comp_turn()

func _maybe_comp_turn() -> void:
	if logic.current_turn == 2:
		await get_tree().create_timer(0.6).timeout
		var peek: Dictionary = logic.peek_comp_move()
		await _show_comp_card_preview(peek["played"], peek["taken"])
		var result: Dictionary = logic.apply_comp_move()
		_show_comp_action(result)
		await get_tree().create_timer(0.5).timeout
		await _check_deal_or_end()

func _show_comp_card_preview(played_card: int, taken_cards: Array) -> void:
	var vp := get_viewport_rect().size
	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO; overlay.size = vp
	overlay.color = Color(0, 0, 0, 0.9); add_child(overlay)

	var action_lbl := Label.new()
	action_lbl.position = Vector2(0, vp.y * 0.30)
	action_lbl.size = Vector2(vp.x, 50)
	action_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_lbl.add_theme_font_size_override("font_size", 24)
	action_lbl.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	action_lbl.text = "La Computadora deja:" if taken_cards.is_empty() else "La Computadora coge:"
	overlay.add_child(action_lbl)

	var all_cards: Array = [played_card] + taken_cards
	var card_w: int = 66; var card_h: int = 105; var card_gap: int = 8
	var total_w: int = all_cards.size() * card_w + (all_cards.size() - 1) * card_gap
	var start_x: int = max(8, int((vp.x - total_w) / 2))
	var card_y: int = int(vp.y * 0.38)

	for i in range(all_cards.size()):
		var card_node := CARD_SCENE.instantiate()
		overlay.add_child(card_node)
		card_node.setup(all_cards[i], false)
		card_node.position = Vector2(start_x + i * (card_w + card_gap), card_y)
		card_node.size = Vector2(card_w, card_h)
		card_node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not taken_cards.is_empty():
		var total_sum: int = CardData.get_number(played_card)
		for c in taken_cards: total_sum += CardData.get_number(c)
		var sum_lbl := Label.new()
		sum_lbl.position = Vector2(0, card_y + card_h + 12)
		sum_lbl.size = Vector2(vp.x, 30)
		sum_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sum_lbl.add_theme_font_size_override("font_size", 20)
		sum_lbl.add_theme_color_override("font_color", Color(0.6, 1, 0.6, 1))
		sum_lbl.text = "Suma: %d" % total_sum
		overlay.add_child(sum_lbl)

	await get_tree().create_timer(2.0).timeout
	overlay.queue_free()

func _show_comp_action(result: Dictionary) -> void:
	if result["action"] == "leave":
		SoundManager.play_drop()
		status_label.text = "Computadora deja: %s" % CardData.get_display_name(result["played"])
	else:
		# Check for velo (7 de Oros) or escoba before playing sound
		var all_taken: Array = [result["played"]] + result["taken"]
		var got_velo: bool = false
		for c in all_taken:
			if CardData.get_number(c) == 7 and CardData.get_suit(c) == CardData.Suit.OROS:
				got_velo = true
		var is_escoba: bool = logic.table_cards.is_empty()
		if got_velo or is_escoba:
			SoundManager.play_haha()
		else:
			SoundManager.play_take()
		var names: Array = []
		var total_sum: int = CardData.get_number(result["played"])
		for c in result["taken"]:
			names.append(CardData.get_display_name(c))
			total_sum += CardData.get_number(c)
		status_label.text = "Computadora coge: %s + %s  (suma %d)" % [
			CardData.get_display_name(result["played"]), ", ".join(names), total_sum]

func _finish_round() -> void:
	logic.sort_table()
	_show_round_summary(logic.end_round())

func _show_round_summary(s: Dictionary) -> void:
	round_summary_panel.visible = true
	var table_root := round_summary_panel.get_node("TableRoot")
	for child in table_root.get_children(): child.queue_free()

	var vp := get_viewport_rect().size
	var panel_w: float = vp.x
	var margin: int = int(panel_w * 0.03)
	var col_x: Array[int] = [margin, margin + int(panel_w*0.22), margin + int(panel_w*0.33),
		margin + int(panel_w*0.44), margin + int(panel_w*0.55), margin + int(panel_w*0.66), margin + int(panel_w*0.75)]
	var col_w: Array[int] = [int(panel_w*0.20), int(panel_w*0.11), int(panel_w*0.11),
		int(panel_w*0.11), int(panel_w*0.11), int(panel_w*0.09), int(panel_w*0.22)]
	var row_h: int = int(vp.y * 0.10)
	var hdr_y: int = int(vp.y * 0.14)
	var row1_y: int = hdr_y + 34; var row2_y: int = row1_y + row_h
	var tbl_x: int = col_x[0]; var tbl_w: int = col_x[6] + col_w[6] - tbl_x

	var hdr_color := Color(0.7, 1.0, 0.7, 1)
	var player_color := Color(1.0, 1.0, 0.5, 1)
	var comp_color   := Color(0.5, 0.9, 1.0, 1)
	var val_color    := Color(1.0, 1.0, 1.0, 1)

	for i in range(7):
		_place_label(table_root, col_x[i], hdr_y, col_w[i], 30,
			["", "Cartas", "Oros", "Sietes", "Escobas", "Velo", "Puntos"][i], 13, hdr_color)
	_place_hrule(table_root, tbl_x, hdr_y + 32, tbl_w)

	var p_velo: String = "SÍ" if s["seven_oros"] == GameLogic.STATE_PLAYER_TAKEN else "—"
	var player_vals := ["🧑 Jugador", str(s["player_cards"]), str(s["player_oros"]),
		str(s["player_sevens"]), str(s["player_escobas"]), p_velo, "+%d (=%d)" % [s["pp_player"], s["total_player"]]]
	for i in range(7):
		_place_label(table_root, col_x[i], row1_y, col_w[i], row_h,
			player_vals[i], 13 if i == 0 else 16, player_color if i == 0 else val_color)
	_place_hrule(table_root, tbl_x, row1_y + row_h, tbl_w)

	var c_velo: String = "SÍ" if s["seven_oros"] == GameLogic.STATE_COMP_TAKEN else "—"
	var comp_vals := ["🤖 Computadora", str(s["comp_cards"]), str(s["comp_oros"]),
		str(s["comp_sevens"]), str(s["comp_escobas"]), c_velo, "+%d (=%d)" % [s["pp_comp"], s["total_comp"]]]
	for i in range(7):
		_place_label(table_root, col_x[i], row2_y, col_w[i], row_h,
			comp_vals[i], 13 if i == 0 else 16, comp_color if i == 0 else val_color)
	_place_hrule(table_root, tbl_x, row2_y + row_h, tbl_w)
	for i in range(1, 7):
		_place_vrule(table_root, col_x[i] - 3, hdr_y, row_h * 2 + 36)

	if continue_button.pressed.is_connected(_on_continue_round):
		continue_button.pressed.disconnect(_on_continue_round)
	var winner: int = logic.check_game_over()
	if winner != 0:
		summary_content.text = "¡TÚ GANAS! 🎉" if winner == 1 else "¡YO GANO! 🤖"
		summary_content.add_theme_color_override("font_color",
			Color(0.3, 1.0, 0.3) if winner == 1 else Color(1.0, 0.4, 0.4))
		continue_button.text = "Menú Principal"
		continue_button.pressed.connect(
			func() -> void: get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu.tscn"))
	else:
		summary_content.text = ""
		continue_button.text = "▶  Siguiente Partida"
		continue_button.pressed.connect(_on_continue_round)

func _on_continue_round() -> void:
	for node in _hand_nodes.values(): node.queue_free()
	for node in _table_nodes.values(): node.queue_free()
	for child in comp_hand_area.get_children(): child.queue_free()
	_hand_nodes.clear(); _table_nodes.clear()
	round_summary_panel.visible = false
	SoundManager.play_flipping()
	logic.start_round(); _update_ui(); _maybe_comp_turn()
