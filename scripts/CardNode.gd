# CardNode.gd
extends Button

signal card_pressed(card_id: int)

var _card_id: int = 0
var _face_down: bool = false
var _selected: bool = false

func setup(card_id: int, face_down: bool) -> void:
	_card_id = card_id
	_face_down = face_down
	pressed.connect(func(): card_pressed.emit(_card_id))
	# Defer the visual refresh so child nodes are guaranteed ready
	call_deferred("_refresh")

func set_selected(sel: bool) -> void:
	_selected = sel
	# Apply highlight directly via modulate — no child nodes needed
	if _selected:
		modulate = Color(1.4, 1.4, 0.4, 1)
	else:
		modulate = Color.WHITE

func _ready() -> void:
	# Ensure visuals are correct once fully in the tree
	_refresh()

func _refresh() -> void:
	var lbl := get_node_or_null("Label") as Label
	var tex := get_node_or_null("TextureRect") as TextureRect
	if lbl == null or tex == null:
		return

	if _face_down or _card_id == 0:
		var back := load("res://assets/cards/REVES.png") as Texture2D
		if back:
			tex.texture = back
			tex.visible = true
			lbl.visible = false
		else:
			tex.visible = false
			lbl.visible = true
			lbl.text = "???"
		tooltip_text = "Carta boca abajo"
	else:
		var key: String = CardData.get_image_key(_card_id)
		var path: String = "res://assets/cards/%s.png" % key
		var img := load(path) as Texture2D
		if img:
			tex.texture = img
			tex.visible = true
			lbl.visible = false
		else:
			tex.visible = false
			lbl.visible = true
			var num: int = CardData.get_number(_card_id)
			var suit: int = CardData.get_suit(_card_id)
			var suit_symbols: Array[String] = ["○", "♥", "♠", "♣"]
			lbl.text = "%d\n%s" % [num, suit_symbols[suit]]
		tooltip_text = CardData.get_display_name(_card_id)

	# Reapply selection highlight after refresh
	if _selected:
		modulate = Color(1.4, 1.4, 0.4, 1)
	else:
		modulate = Color.WHITE
