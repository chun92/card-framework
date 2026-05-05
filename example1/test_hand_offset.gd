extends Control

## Test scene for issue #31 (uneven offset for hand).
## RED line  = hand.global_position (framework anchor point)
## GREEN line = computed visual center of held cards (top-left + card_w/2)
## bias_x   = GREEN - RED. With CENTER anchor we expect bias_x ≈ 0.

@onready var card_manager: CardManager = $CardManager
@onready var card_factory = $CardManager/MyCardFactory
@onready var hand: Hand = $Hand
@onready var info_label: Label = $UI/InfoLabel

const CARD_NAMES := [
	"club_2", "club_3", "club_4", "club_5", "club_6", "club_7",
	"club_8", "club_9", "club_10", "club_J", "club_Q", "club_K",
]


func _ready() -> void:
	hand.max_hand_size = 16
	_set_card_count(5)


func _process(_delta: float) -> void:
	queue_redraw()
	_update_label()


func _draw() -> void:
	# _draw() runs in this Control's LOCAL space. Convert global X to local
	# by subtracting this Control's global_position.x, otherwise any non-zero
	# root offset (e.g. anchors_preset/offset_left) shifts the debug lines
	# even though the underlying math is correct.
	var vh := get_viewport_rect().size.y
	var origin_x := global_position.x
	var anchor_x := hand.global_position.x - origin_x
	draw_line(Vector2(anchor_x, 0), Vector2(anchor_x, vh), Color.RED, 2.0)

	if hand._held_cards.is_empty():
		return

	var bounds := _visual_bounds()
	var visual_center := (bounds.x + bounds.y) / 2.0 - origin_x
	draw_line(Vector2(visual_center, 0), Vector2(visual_center, vh), Color.LIME_GREEN, 2.0)


func _visual_bounds() -> Vector2:
	var card_w := card_manager.card_size.x
	var min_x := INF
	var max_x := -INF
	for card in hand._held_cards:
		var cx: float = card.global_position.x
		min_x = min(min_x, cx)
		max_x = max(max_x, cx + card_w)
	return Vector2(min_x, max_x)


func _update_label() -> void:
	var modes := ["CENTER", "LEFT", "RIGHT"]
	var bias := 0.0
	if not hand._held_cards.is_empty():
		var b := _visual_bounds()
		bias = (b.x + b.y) / 2.0 - hand.global_position.x
	info_label.text = "anchor=%s | N=%d | spread=%d | card_w=%d | bias_x=%.1f" % [
		modes[hand.hand_anchor],
		hand._held_cards.size(),
		hand.max_hand_spread,
		int(card_manager.card_size.x),
		bias,
	]


func _set_card_count(n: int) -> void:
	hand.clear_cards()
	for i in n:
		card_factory.create_card(CARD_NAMES[i], hand)


func _on_count_1() -> void:  _set_card_count(1)
func _on_count_2() -> void:  _set_card_count(2)
func _on_count_5() -> void:  _set_card_count(5)
func _on_count_10() -> void: _set_card_count(10)
func _on_count_12() -> void: _set_card_count(12)


func _on_anchor_center() -> void:
	hand.hand_anchor = Hand.HandAnchor.CENTER
	hand.update_card_ui()


func _on_anchor_left() -> void:
	hand.hand_anchor = Hand.HandAnchor.LEFT
	hand.update_card_ui()


func _on_anchor_right() -> void:
	hand.hand_anchor = Hand.HandAnchor.RIGHT
	hand.update_card_ui()


func _on_spread_300() -> void:
	hand.max_hand_spread = 300
	hand.update_card_ui()


func _on_spread_600() -> void:
	hand.max_hand_spread = 600
	hand.update_card_ui()


func _on_spread_900() -> void:
	hand.max_hand_spread = 900
	hand.update_card_ui()


func _on_spread_1200() -> void:
	hand.max_hand_spread = 1200
	hand.update_card_ui()
