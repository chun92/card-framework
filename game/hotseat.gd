extends Control

const DECK_PLAYER_1 := "effects_fire_lightning"
const DECK_PLAYER_2 := "effects_colorless"
const PRIZE_COUNT := 3
const FONT_SIZE := 22

var _engine := MatchEngine.new()
var _seed: int = 0

var _status_label: Label
var _player_labels: Array[Label] = []
var _actions_box: VBoxContainer
var _log_label: Label


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = FONT_SIZE
	theme = ui_theme
	_build_ui()
	_start_match()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	margin.add_child(columns)

	# Left column: match status and both players.
	var board := VBoxContainer.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_stretch_ratio = 2.0
	columns.add_child(board)

	_status_label = Label.new()
	board.add_child(_status_label)

	# Player 2 on top, player 1 at the bottom.
	_player_labels.resize(2)
	_player_labels[1] = _make_panel_label()
	board.add_child(_player_labels[1])
	board.add_child(HSeparator.new())
	_player_labels[0] = _make_panel_label()
	board.add_child(_player_labels[0])

	# Right column: legal actions, log, new match.
	var side_panel := VBoxContainer.new()
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(side_panel)

	var actions_title := Label.new()
	actions_title.text = "Legal actions"
	side_panel.add_child(actions_title)

	var actions_scroll := ScrollContainer.new()
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_panel.add_child(actions_scroll)

	_actions_box = VBoxContainer.new()
	_actions_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_scroll.add_child(_actions_box)

	var log_title := Label.new()
	log_title.text = "Log (newest first)"
	side_panel.add_child(log_title)

	var log_scroll := ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_panel.add_child(log_scroll)

	_log_label = Label.new()
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_scroll.add_child(_log_label)

	var new_match_button := Button.new()
	new_match_button.text = "New match"
	new_match_button.pressed.connect(_start_match)
	side_panel.add_child(new_match_button)


func _make_panel_label() -> Label:
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _start_match() -> void:
	_start_with_prizes(PRIZE_COUNT)


func _start_with_prizes(prize_count: int) -> void:
	var database := DataLoader.load_card_database()
	var decks: Variant = DataLoader.read_json(DataLoader.DECKS_PATH)
	if database.card_count() == 0 or not decks is Dictionary:
		_show_error("Could not load data/tcgdex/ or data/decks.json. See the Output panel.")
		return

	var deck_defs := decks as Dictionary
	if not deck_defs.has(DECK_PLAYER_1) or not deck_defs.has(DECK_PLAYER_2):
		_show_error("decks.json must define '%s' and '%s'." % [DECK_PLAYER_1, DECK_PLAYER_2])
		return


	_seed = randi()
	_engine = MatchEngine.new()
	_engine.effects = DataLoader.load_effect_library(database)
	_engine.start(
		database.build_deck(deck_defs[DECK_PLAYER_1] as Dictionary),
		database.build_deck(deck_defs[DECK_PLAYER_2] as Dictionary),
		prize_count,
		prize_count,
		Rng.new(_seed),
	)
	_refresh()


func _refresh() -> void:
	if _engine.winner == MatchEngine.SUDDEN_DEATH:
		_status_label.text = "Turn %d  |  Seed %d  |  Both players won: Sudden Death" % [_engine.turn, _seed]
	elif _engine.is_over():
		_status_label.text = "Turn %d  |  Seed %d  |  Player %d wins" % [_engine.turn, _seed, _engine.winner + 1]
	elif _engine.is_waiting_for_choice():
		_status_label.text = "Turn %d  |  Seed %d  |  Player %d: %s" % [_engine.turn, _seed, _engine.current_index + 1, _engine.choice_prompt()]
	else:
		_status_label.text = "Turn %d  |  Seed %d  |  Player %d to act" % [_engine.turn, _seed, _engine.current_index + 1]

	for index in 2:
		_player_labels[index].text = _describe_player(index)

	for child in _actions_box.get_children():
		_actions_box.remove_child(child)
		child.queue_free()
	for action in _engine.legal_actions():
		var button := Button.new()
		button.text = str(action["label"])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_action_pressed.bind(action))
		_actions_box.add_child(button)

	if _engine.winner == MatchEngine.SUDDEN_DEATH:
		var sudden_death := Button.new()
		sudden_death.text = "Play Sudden Death (1 Prize each)"
		sudden_death.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sudden_death.pressed.connect(_start_with_prizes.bind(1))
		_actions_box.add_child(sudden_death)

	var lines := PackedStringArray(_engine.events)
	lines.reverse()
	_log_label.text = "\n".join(lines)


func _on_action_pressed(action: Dictionary) -> void:
	_engine.apply(action)
	_refresh()


func _describe_player(index: int) -> String:
	var player := _engine.players[index]
	var lines := PackedStringArray()

	var header := "PLAYER %d" % (index + 1)
	if not _engine.is_over() and _engine.current_index == index:
		header += "   <- to act"
	lines.append(header)
	lines.append("Prizes left: %d   Deck: %d   Discard: %d   Hand: %d" % [
		player.prizes.size(), player.deck.size(), player.discard.size(), player.hand.size(),
	])
	lines.append("")
	lines.append("Active: %s" % (_describe_in_play(player.active) if player.active != null else "none"))

	if player.bench.is_empty():
		lines.append("Bench: empty")
	else:
		lines.append("Bench:")
		for slot in player.bench.size():
			lines.append("   %d) %s" % [slot + 1, _describe_in_play(player.bench[slot])])

	var hand_names := PackedStringArray()
	for card in player.hand:
		hand_names.append(card.name)
	lines.append("")
	lines.append("Hand: %s" % ", ".join(hand_names))
	return "\n".join(lines)


func _describe_in_play(pokemon: CardInPlay) -> String:
	var energy := ", ".join(PackedStringArray(pokemon.energy_pool()))
	return "%s  %d/%d HP  [%s]" % [pokemon.card.name, pokemon.remaining_hp(), pokemon.card.hp, energy]


func _show_error(message: String) -> void:
	_status_label.text = message
	for label in _player_labels:
		label.text = ""
