# GameLogic.gd
# Pure game-logic translation from ESCOBA.BAS (QuickBasic original).

class_name GameLogic

# ---- Deck state codes ----
const STATE_DECK         := 0
const STATE_TABLE        := 1
const STATE_COMP         := 2
const STATE_COMP_TAKEN   := 3
const STATE_PLAYER       := 4
const STATE_PLAYER_TAKEN := 5

# ---- Game state ----
var table_cards: Array[int] = []
var comp_hand:   Array[int] = []
var player_hand: Array[int] = []
var deck_state:  Dictionary = {}
var shuffled:    Array[int] = []
var dealt_count: int = 0

# ---- Round accumulators ----
var player_cards_taken: int = 0
var player_oros:        int = 0
var player_sevens:      int = 0
var player_escobas:     int = 0
var comp_cards_taken:   int = 0
var comp_oros:          int = 0
var comp_sevens:        int = 0
var comp_escobas:       int = 0

# ---- Match scores ----
var player_points: int = 0
var comp_points:   int = 0
var target_points: int = 21

# ---- Turn tracking ----
var last_taker:      int  = 0
var who_deals_first: int  = 1
var current_turn:    int  = 1
var is_last_deal:    bool = false

# ---- AI working storage ----
var _best_score:  float = -9999999.0
var _ai_taking:   bool  = false

# ---- Signals ----
signal state_changed()

# ------------------------------------------------------------------
func new_game(target: int, first_dealer: int) -> void:
	target_points   = target
	who_deals_first = first_dealer
	player_points   = 0
	comp_points     = 0
	_reset_round_accumulators()
	start_round()

func start_round() -> void:
	_reset_round_accumulators()
	_init_deck()
	_shuffle()
	_deal_initial_table()
	if who_deals_first == 1:
		current_turn = 2
	else:
		current_turn = 1
	deal_hands()
	state_changed.emit()

func deal_hands() -> void:
	comp_hand.clear()
	player_hand.clear()
	for _i in range(3):
		dealt_count += 1
		if dealt_count > 40:
			break
		var card: int = shuffled[dealt_count - 1]
		deck_state[card] = STATE_COMP
		comp_hand.append(card)
	for _i in range(3):
		dealt_count += 1
		if dealt_count > 40:
			break
		var card: int = shuffled[dealt_count - 1]
		deck_state[card] = STATE_PLAYER
		player_hand.append(card)
	is_last_deal = dealt_count >= 40

func cards_remaining_in_deck() -> int:
	return 40 - dealt_count

func hands_empty() -> bool:
	return comp_hand.is_empty() and player_hand.is_empty()

# ------------------------------------------------------------------
# PLAYER MOVE VALIDATION
# ------------------------------------------------------------------

func validate_player_move(hand_card_id: int, table_selection: Array) -> String:
	if hand_card_id == 0:
		return "Selecciona una carta de tu mano."
	if table_selection.is_empty():
		if _can_take_with(hand_card_id):
			return "Puedes coger con esa carta."
		return ""
	var s: int = CardData.get_number(hand_card_id)
	for c in table_selection:
		s += CardData.get_number(c)
	if s != 15:
		return "Esas cartas no suman 15."
	return ""

func _can_take_with(hand_card_id: int) -> bool:
	var hand_val: int = CardData.get_number(hand_card_id)
	return _subset_sums_to(table_cards, hand_val, 15, 0)

func _subset_sums_to(arr: Array[int], running: int, target: int, start: int) -> bool:
	if running == target:
		return true
	if running > target or start >= arr.size():
		return false
	for i in range(start, arr.size()):
		if _subset_sums_to(arr, running + CardData.get_number(arr[i]), target, i + 1):
			return true
	return false

# ------------------------------------------------------------------
# APPLY MOVES
# ------------------------------------------------------------------

func apply_player_leave(hand_card_id: int) -> void:
	player_hand.erase(hand_card_id)
	table_cards.append(hand_card_id)
	deck_state[hand_card_id] = STATE_TABLE
	last_taker   = 0
	current_turn = 2
	state_changed.emit()

func apply_player_take(hand_card_id: int, table_selection: Array) -> void:
	player_hand.erase(hand_card_id)
	for c in table_selection:
		table_cards.erase(c)
		deck_state[c] = STATE_PLAYER_TAKEN
	deck_state[hand_card_id] = STATE_PLAYER_TAKEN

	player_cards_taken += table_selection.size() + 1
	for c in table_selection:
		if CardData.get_suit(c) == CardData.Suit.OROS:
			player_oros += 1
		if CardData.get_number(c) == 7:
			player_sevens += 1
	if CardData.get_suit(hand_card_id) == CardData.Suit.OROS:
		player_oros += 1
	if CardData.get_number(hand_card_id) == 7:
		player_sevens += 1

	last_taker = STATE_PLAYER_TAKEN
	if table_cards.is_empty():
		player_escobas += 1

	current_turn = 2
	state_changed.emit()

func peek_comp_move() -> Dictionary:
	_run_ai()
	var hand_card: int = comp_hand[_best_hand_idx]
	if not _ai_taking:
		return {"played": hand_card, "taken": []}
	var taken: Array[int] = []
	for ti in _best_taken_idxs:
		taken.append(table_cards[ti])
	return {"played": hand_card, "taken": taken}

func apply_comp_move() -> Dictionary:

	# Defensive check: is there a card to play?
	if comp_hand.is_empty():
		push_error("apply_comp_move called with empty computer hand!")
		return {"action": "none"}
		
	# Re-use results from peek if already computed, otherwise run AI
	if _best_score <= -9999999.0:
		_run_ai()

	var hand_idx: int  = _best_hand_idx
	var hand_card: int = comp_hand[hand_idx]
	comp_hand.remove_at(hand_idx)

	# After removing from hand, adjust taken indices if needed
	# (table_cards unchanged at this point, indices still valid)
	var result: Dictionary = {}

	if not _ai_taking:
		table_cards.append(hand_card)
		deck_state[hand_card] = STATE_TABLE
		last_taker = 0
		result = {"action": "leave", "played": hand_card, "taken": []}
	else:
		var taken_table: Array[int] = []
		for ti in _best_taken_idxs:
			if ti < table_cards.size():
				taken_table.append(table_cards[ti])
		for c in taken_table:
			table_cards.erase(c)
			deck_state[c] = STATE_COMP_TAKEN
		deck_state[hand_card] = STATE_COMP_TAKEN

		comp_cards_taken += taken_table.size() + 1
		for c in taken_table:
			if CardData.get_suit(c) == CardData.Suit.OROS:
				comp_oros += 1
			if CardData.get_number(c) == 7:
				comp_sevens += 1
		if CardData.get_suit(hand_card) == CardData.Suit.OROS:
			comp_oros += 1
		if CardData.get_number(hand_card) == 7:
			comp_sevens += 1

		last_taker = STATE_COMP_TAKEN
		if table_cards.is_empty():
			comp_escobas += 1

		result = {"action": "take", "played": hand_card, "taken": taken_table}

	# Reset so next call re-runs AI fresh
	_best_score = -9999999.0
	current_turn = 1
	state_changed.emit()
	return result

# ------------------------------------------------------------------
# END-OF-ROUND SCORING
# ------------------------------------------------------------------

func end_round() -> Dictionary:
	for c in table_cards:
		if last_taker == STATE_PLAYER_TAKEN:
			deck_state[c]  = STATE_PLAYER_TAKEN
			player_cards_taken += 1
			if CardData.get_suit(c) == CardData.Suit.OROS:
				player_oros += 1
			if CardData.get_number(c) == 7:
				player_sevens += 1
		else:
			deck_state[c] = STATE_COMP_TAKEN
			comp_cards_taken += 1
			if CardData.get_suit(c) == CardData.Suit.OROS:
				comp_oros += 1
			if CardData.get_number(c) == 7:
				comp_sevens += 1
	table_cards.clear()

	var seven_oros_holder: int = deck_state.get(7, 0)

	var pp_player: int = 0
	var pp_comp:   int = 0

	if player_cards_taken > comp_cards_taken:
		pp_player += 1
	elif comp_cards_taken > player_cards_taken:
		pp_comp += 1
	if player_oros > comp_oros:
		pp_player += 1
	elif comp_oros > player_oros:
		pp_comp += 1
	if player_sevens > comp_sevens:
		pp_player += 1
	elif comp_sevens > player_sevens:
		pp_comp += 1

	pp_player += player_escobas
	pp_comp   += comp_escobas

	if seven_oros_holder == STATE_PLAYER_TAKEN:
		pp_player += 1
	elif seven_oros_holder == STATE_COMP_TAKEN:
		pp_comp += 1

	player_points += pp_player
	comp_points   += pp_comp

	var summary: Dictionary = {
		"player_cards":   player_cards_taken,
		"comp_cards":     comp_cards_taken,
		"player_oros":    player_oros,
		"comp_oros":      comp_oros,
		"player_sevens":  player_sevens,
		"comp_sevens":    comp_sevens,
		"player_escobas": player_escobas,
		"comp_escobas":   comp_escobas,
		"seven_oros":     seven_oros_holder,
		"pp_player":      pp_player,
		"pp_comp":        pp_comp,
		"total_player":   player_points,
		"total_comp":     comp_points,
	}

	if who_deals_first == 1:
		who_deals_first = 2
	else:
		who_deals_first = 1

	return summary

func check_game_over() -> int:
	if player_points >= target_points and comp_points >= target_points:
		return 0
	if player_points >= target_points:
		return 1
	if comp_points >= target_points:
		return 2
	return 0

# ------------------------------------------------------------------
# PRIVATE HELPERS
# ------------------------------------------------------------------

func _reset_round_accumulators() -> void:
	player_cards_taken = 0
	player_oros        = 0
	player_sevens      = 0
	player_escobas     = 0
	comp_cards_taken   = 0
	comp_oros          = 0
	comp_sevens        = 0
	comp_escobas       = 0
	last_taker         = 0

func _init_deck() -> void:
	deck_state.clear()
	shuffled.clear()
	table_cards.clear()
	comp_hand.clear()
	player_hand.clear()
	dealt_count = 0
	for i in range(1, 41):
		deck_state[i] = STATE_DECK
		shuffled.append(i)

func _shuffle() -> void:
	randomize()
	for _i in range(40):
		for _j in range(50):
			var a: int   = randi_range(0, 39)
			var b: int   = randi_range(0, 39)
			var tmp: int = shuffled[a]
			shuffled[a]  = shuffled[b]
			shuffled[b]  = tmp

func _deal_initial_table() -> void:
	for _i in range(4):
		dealt_count += 1
		var card: int = shuffled[dealt_count - 1]
		deck_state[card] = STATE_TABLE
		table_cards.append(card)

# ------------------------------------------------------------------
# AI — finds the best move for the computer
# ------------------------------------------------------------------
# Strategy:
#   For each card in hand, try all subsets of table cards.
#   If subset + hand card == 15  -> scored as a capture.
#   If no capture exists         -> leave the hand card on the table.
# The best scored move is stored in _comp_play and _ai_taking.

# Working state for the recursive search
var _best_hand_idx:   int        = 0
var _best_taken_idxs: Array[int] = []  # indices into table_cards

func _run_ai() -> void:
	_best_score      = -9999999.0
	_ai_taking       = false
	_best_hand_idx   = 0
	_best_taken_idxs = []

	# Search for captures across all hand cards
	# Captures always beat leaves, so we search first.
	for hi in range(comp_hand.size()):
		var hand_val: int  = CardData.get_number(comp_hand[hi])
		var remaining: int = 15 - hand_val
		if remaining > 0:
			var current: Array[int] = []
			_search_subsets(hi, remaining, 0, current)

	# If a capture was found, _ai_taking is true — we're done.
	if _ai_taking:
		return

	# No capture possible — pick the best leave move
	for hi in range(comp_hand.size()):
		var score: float = _score_leave_simple(hi)
		if score > _best_score:
			_best_score    = score
			_best_hand_idx = hi

func _search_subsets(hi: int, remaining: int, start: int, current: Array[int]) -> void:
	if remaining == 0:
		var score: float = _score_capture(hi, current)
		if score > _best_score:
			_best_score      = score
			_best_hand_idx   = hi
			_ai_taking       = true
			_best_taken_idxs = current.duplicate()
		return
	if remaining < 0 or start >= table_cards.size():
		return
	for i in range(start, table_cards.size()):
		var card_val: int = CardData.get_number(table_cards[i])
		if card_val <= remaining:
			current.append(i)
			_search_subsets(hi, remaining - card_val, i + 1, current)
			current.pop_back()

func _score_capture(hi: int, taken_idxs: Array[int]) -> float:
	var hand_card: int = comp_hand[hi]
	var nc: int = 1 + taken_idxs.size()
	var no: int = 1 if CardData.get_suit(hand_card) == CardData.Suit.OROS else 0
	var ns: int = 1 if CardData.get_number(hand_card) == 7 else 0
	var p: float = 0.0

	for ti in taken_idxs:
		var c: int = table_cards[ti]
		if CardData.get_suit(c) == CardData.Suit.OROS:
			no += 1
		if CardData.get_number(c) == 7:
			ns += 1
			p  += 17.0

	# Escoba bonus: capturing all table cards
	if taken_idxs.size() == table_cards.size():
		p += 17.0

	p += _fnpunt(nc, 2.0, 21.0, comp_cards_taken)
	p += _fnpunt(no, 5.0,  6.0, comp_oros)
	p += _fnpunt(ns, 10.0, 3.0, comp_sevens)
	return p

func _score_leave_simple(hi: int) -> float:
	var s: int = CardData.get_number(comp_hand[hi])
	for i in range(table_cards.size()):
		s += CardData.get_number(table_cards[i])
	if s < 5:
		return 7.0
	if s >= 15:
		return 5.0
	return 0.0

func _fnpunt(nx: int, x: float, xmax: float, nxc: int) -> float:
	return x * float(nx - int(float(nx) * float(nxc) / xmax))

func sort_table() -> void:
	table_cards.sort_custom(func(a: int, b: int) -> bool:
		return CardData.get_number(a) < CardData.get_number(b))
