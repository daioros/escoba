# CardData.gd
# Suits: 0=Oros, 1=Copas, 2=Espadas, 3=Bastos
# Numbers: 1-7, Sota(8), Caballo(9), Rey(10)
# Card IDs 1-40: number = (id-1) % 10 + 1, suit = (id-1) / 10

class_name CardData

enum Suit { OROS = 0, COPAS = 1, ESPADAS = 2, BASTOS = 3 }

const SUIT_NAMES   := ["Oros", "Copas", "Espadas", "Bastos"]
const NUMBER_NAMES := ["", "As", "2", "3", "4", "5", "6", "7", "Sota", "Caballo", "Rey"]
const TARGET_SUM      := 15
const DECK_SIZE       := 40
const CARDS_PER_SUIT  := 10

static func get_number(card_id: int) -> int:
	return 1 + (card_id - 1) % CARDS_PER_SUIT

static func get_suit(card_id: int) -> int:
	@warning_ignore("integer_division")
	return (card_id - 1) / CARDS_PER_SUIT

static func get_suit_name(card_id: int) -> String:
	return SUIT_NAMES[get_suit(card_id)]

static func get_number_name(card_id: int) -> String:
	return NUMBER_NAMES[get_number(card_id)]

static func get_display_name(card_id: int) -> String:
	return "%s de %s" % [get_number_name(card_id), get_suit_name(card_id)]

static func get_image_key(card_id: int) -> String:
	var n: int = get_number(card_id)
	var s: int = get_suit(card_id)
	var suit_letter: String = (["O", "C", "E", "B"] as Array[String])[s]
	return "%d%s" % [n, suit_letter]
