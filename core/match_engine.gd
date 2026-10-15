class_name MatchEngine
extends RefCounted

const HAND_SIZE := 7
const BENCH_LIMIT := 5
const MAX_SETUP_ATTEMPTS := 50
const NO_WINNER := -1
## Both players won at the same time and in the same number of ways: play Sudden Death.
const SUDDEN_DEATH := -2
const WEAKNESS_DOUBLE := "\u00d72"
const RESISTANCE_MINUS_30 := "-30"

var players: Array[PlayerState] = []
var current_index: int = 0
var turn: int = 0
var winner: int = NO_WINNER
var events: Array[String] = []
## Card effects (Design Document 7). Null means every attack resolves as its printed damage.
var effects: EffectLibrary = null

var _rng: Rng
## An attack waiting for a player's choice (Design Document 7.6).
var _pending_resolver: EffectResolver = null
var _pending_context: EffectContext = null


## Prize counts are parameters, never constants: the run supplies the NPC value.
func start(deck_a: Array[CardData], deck_b: Array[CardData], prize_count_a: int, prize_count_b: int, rng: Rng) -> void:
	_rng = rng
	players.clear()
	events.clear()
	winner = NO_WINNER
	turn = 0
	_pending_resolver = null
	_pending_context = null
	players.append(_setup_player(0, deck_a, prize_count_a))
	players.append(_setup_player(1, deck_b, prize_count_b))
	# _begin_turn switches the active player first, so player 1 (index 0) opens.
	current_index = 1
	_begin_turn()


func is_over() -> bool:
	return winner != NO_WINNER


func current_player() -> PlayerState:
	return players[current_index]


func opponent_player() -> PlayerState:
	return players[_opponent_index()]


func is_waiting_for_choice() -> bool:
	return _pending_context != null


## The question being asked while an attack waits for a choice, or an empty string.
func choice_prompt() -> String:
	return str(_pending_context.choice.get("prompt", "")) if _pending_context != null else ""


func legal_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if is_over():
		return actions

	# While a choice is open, answering it is the only legal action.
	if _pending_context != null:
		var options := _pending_context.choice.get("options", []) as Array
		for index in options.size():
			actions.append({
				"type": "choose",
				"option": index,
				"label": str((options[index] as Dictionary)["label"]),
			})
		return actions

	var player := current_player()
	var opponent := opponent_player()

	for hand_index in player.hand.size():
		var card := player.hand[hand_index]
		if card.is_basic_pokemon() and player.bench.size() < BENCH_LIMIT:
			actions.append({
				"type": "bench",
				"hand_index": hand_index,
				"label": "Bench %s" % card.name,
			})
		elif card.is_energy() and not player.energy_attached_this_turn:
			if player.active != null:
				actions.append({
					"type": "attach",
					"hand_index": hand_index,
					"slot": -1,
					"label": "Attach %s to %s (active)" % [card.name, player.active.card.name],
				})
			for slot in player.bench.size():
				actions.append({
					"type": "attach",
					"hand_index": hand_index,
					"slot": slot,
					"label": "Attach %s to %s (bench %d)" % [card.name, player.bench[slot].card.name, slot + 1],
				})

	if player.active != null and not player.retreated_this_turn and player.active.can_pay(player.active.retreat_cost()):
		for slot in player.bench.size():
			actions.append({
				"type": "retreat",
				"slot": slot,
				"label": "Retreat %s for %s" % [player.active.card.name, player.bench[slot].card.name],
			})

	if player.active != null and opponent.active != null:
		var attacks := player.active.card.attacks
		for attack_index in attacks.size():
			var attack := attacks[attack_index]
			if player.active.can_pay(attack.cost) and _attack_requirements_met(attack):
				actions.append({
					"type": "attack",
					"attack_index": attack_index,
					"label": "Attack: %s (%d)" % [attack.name, attack.damage],
				})

	actions.append({"type": "end_turn", "label": "End turn"})
	return actions


func apply(action: Dictionary) -> void:
	if not legal_actions().has(action):
		push_error("MatchEngine: illegal action %s" % action)
		return

	match str(action["type"]):
		"bench":
			_do_bench(int(action["hand_index"]))
		"attach":
			_do_attach(int(action["hand_index"]), int(action["slot"]))
		"retreat":
			_do_retreat(int(action["slot"]))
		"attack":
			_do_attack(int(action["attack_index"]))
		"end_turn":
			_log("Player %d ends the turn" % (current_index + 1))
			_begin_turn()
		"choose":
			_do_choose(int(action["option"]))


func _setup_player(index: int, deck: Array[CardData], prize_count: int) -> PlayerState:
	var player := PlayerState.new()
	player.deck = deck

	for attempt in MAX_SETUP_ATTEMPTS:
		_rng.shuffle(player.deck)
		for _i in HAND_SIZE:
			player.draw_card()
		if player.first_basic_pokemon_in_hand() != -1:
			break
		# Known divergence (4.8): the opponent gets nothing for a mulligan.
		_log("Player %d mulligan (attempt %d)" % [index + 1, attempt + 1])
		player.deck.append_array(player.hand)
		player.hand.clear()

	var pokemon_index := player.first_basic_pokemon_in_hand()
	if pokemon_index == -1:
		push_error("MatchEngine: player %d has no Basic Pokemon after %d attempts" % [index + 1, MAX_SETUP_ATTEMPTS])
	else:
		# Known divergence (4.8): the first Basic Pokemon in hand is chosen automatically.
		var starter := player.hand.pop_at(pokemon_index) as CardData
		player.active = CardInPlay.new(starter, 0)

	for _i in prize_count:
		if player.deck.is_empty():
			break
		player.prizes.append(player.deck.pop_back() as CardData)

	return player


func _begin_turn() -> void:
	current_index = _opponent_index()
	turn += 1
	var player := current_player()
	player.reset_turn_flags()
	_log("--- Turn %d: Player %d ---" % [turn, current_index + 1])

	# Project rule (4.7): deck-out costs a prize instead of losing.
	if player.deck.is_empty():
		_log("Player %d cannot draw: the opponent takes a prize" % (current_index + 1))
		_take_prize(_opponent_index())
		if players[_opponent_index()].prizes.is_empty():
			winner = _opponent_index()
			_log("Player %d took the last prize and wins" % (winner + 1))
		return

	player.draw_card()


func _do_bench(hand_index: int) -> void:
	var player := current_player()
	var card := player.hand.pop_at(hand_index) as CardData
	player.bench.append(CardInPlay.new(card, turn))
	_log("Player %d benches %s" % [current_index + 1, card.name])


func _do_attach(hand_index: int, slot: int) -> void:
	var player := current_player()
	var energy := player.hand.pop_at(hand_index) as CardData
	var target: CardInPlay = player.active if slot == -1 else player.bench[slot]
	target.attached_energy.append(energy)
	player.energy_attached_this_turn = true
	_log("Player %d attaches %s to %s" % [current_index + 1, energy.name, target.card.name])


func _do_retreat(slot: int) -> void:
	var player := current_player()
	var retreating := player.active
	var paid := retreating.detach_energy_units(retreating.card.retreat_cost)
	player.discard.append_array(paid)
	player.active = player.bench[slot]
	player.bench[slot] = retreating
	player.retreated_this_turn = true
	_log("Player %d retreats %s for %s" % [current_index + 1, retreating.card.name, player.active.card.name])


func _do_attack(attack_index: int) -> void:
	var attacker := current_player()
	var attack := attacker.active.card.attacks[attack_index]
	_log("%s uses %s" % [attacker.active.card.name, attack.name])

	var context := _attack_context(attack)
	var binding := _attack_binding(attack)
	if binding.is_empty():
		if attack.has_effect():
			# Known divergence (4.8): without a card effect entry only the printed number is dealt.
			_log("  [effect not implemented]")
		deal_attack_damage(context, attack.damage)
		_finish_attack()
		return

	var resolver := EffectResolver.new(effects, context)
	if resolver.run(str(binding["function"]), binding["args"] as Dictionary):
		_finish_attack()
	else:
		_pending_resolver = resolver
		_pending_context = context


func _do_choose(option: int) -> void:
	var options := _pending_context.choice["options"] as Array
	var picked := options[option] as Dictionary
	_log("  Player %d chooses: %s" % [current_index + 1, picked["label"]])
	_pending_context.selection.append(picked["value"])
	if _pending_resolver.resume():
		_pending_resolver = null
		_pending_context = null
		_finish_attack()


func _finish_attack() -> void:
	_resolve_knockouts()
	# Attacking passes priority.
	if not is_over():
		_begin_turn()


# --- Mutations available to atomic effects ---------------------------------------------

## Deals attack damage to the defending Pokemon through the damage pipeline (4.5).
func deal_attack_damage(context: EffectContext, base_damage: int) -> int:
	var defender := context.defender
	if defender == null:
		return 0
	var dealt := _apply_modifiers(context.source.card, defender.card, base_damage)
	defender.damage += dealt
	_log("  %d damage to %s (%d/%d HP)" % [dealt, defender.card.name, defender.remaining_hp(), defender.card.hp])
	return dealt


## Damage without Weakness or Resistance, such as an attacker damaging itself.
func deal_direct_damage(target: CardInPlay, amount: int) -> int:
	if amount <= 0:
		return 0
	target.damage += amount
	_log("  %s takes %d damage (%d/%d HP)" % [target.card.name, amount, target.remaining_hp(), target.card.hp])
	return amount


## Discards the given Energy cards from a Pokemon into its owner's discard pile.
func discard_energy_cards(target: CardInPlay, cards: Array[CardData]) -> int:
	var owner := owner_of(target)
	var discarded := 0
	for energy in cards:
		var index := target.attached_energy.find(energy)
		if index == -1:
			continue
		target.attached_energy.remove_at(index)
		if owner != null:
			owner.discard.append(energy)
		discarded += 1
		_log("  %s discards %s" % [target.card.name, energy.name])
	return discarded


func draw_cards(player: PlayerState, count: int) -> int:
	var drawn := 0
	for _i in maxi(count, 0):
		if not player.draw_card():
			break
		drawn += 1
	_log("  Player %d draws %d card%s" % [players.find(player) + 1, drawn, "" if drawn == 1 else "s"])
	return drawn


func flip_coin() -> bool:
	var heads := _rng.coin_flip()
	_log("  Coin flip: %s" % ("heads" if heads else "tails"))
	return heads


func owner_of(pokemon: CardInPlay) -> PlayerState:
	for player in players:
		if player.active == pokemon or player.bench.has(pokemon):
			return player
	return null


func log_event(text: String) -> void:
	_log(text)


# --- Attack resolution helpers ----------------------------------------------------------

func _attack_context(attack: AttackData) -> EffectContext:
	var context := EffectContext.new()
	context.engine = self
	context.kind = EffectContext.KIND_ATTACK
	context.source = current_player().active
	context.defender = opponent_player().active
	context.player = current_player()
	context.opponent = opponent_player()
	context.attack = attack
	return context


func _attack_binding(attack: AttackData) -> Dictionary:
	if effects == null:
		return {}
	return effects.binding_for(current_player().active.card.id, EffectLibrary.SECTION_ATTACKS, attack.name)


func _attack_requirements_met(attack: AttackData) -> bool:
	var binding := _attack_binding(attack)
	if binding.is_empty():
		return true
	var resolver := EffectResolver.new(effects, _attack_context(attack))
	return resolver.requirements_met(str(binding["function"]), binding["args"] as Dictionary)


## Resolves every Active Pokemon knocked out by the attack at once, as the rulebook does:
## all of them are discarded, every prize is taken, and only then are wins checked. A player
## wins by taking their last prize, or when an opponent has no Benched Pokemon to promote.
## If both win, the one who won in more ways is the winner; otherwise it is Sudden Death.
func _resolve_knockouts() -> void:
	var knocked_out: Array[int] = []
	for index: int in [_opponent_index(), current_index]:
		var side := players[index]
		if side.active != null and side.active.is_knocked_out():
			knocked_out.append(index)
	if knocked_out.is_empty():
		return

	for index in knocked_out:
		var side := players[index]
		_log("%s is knocked out" % side.active.card.name)
		side.discard_from_play(side.active)
		side.active = null

	var ways := [0, 0]
	for index in knocked_out:
		var taker := 1 - index
		_take_prize(taker)
		if players[taker].prizes.is_empty():
			ways[taker] = maxi(int(ways[taker]), 1)
	for index in knocked_out:
		if players[index].bench.is_empty():
			ways[1 - index] = int(ways[1 - index]) + 1

	if int(ways[0]) > 0 or int(ways[1]) > 0:
		if int(ways[0]) == int(ways[1]):
			winner = SUDDEN_DEATH
			_log("Both players win at the same time: Sudden Death")
		else:
			winner = 0 if int(ways[0]) > int(ways[1]) else 1
			_log("Player %d wins" % (winner + 1))
		return

	for index in knocked_out:
		# Known divergence (4.8): bench[0] is promoted automatically.
		var side := players[index]
		side.active = side.bench.pop_at(0) as CardInPlay
		_log("Player %d promotes %s" % [index + 1, side.active.card.name])


func _apply_modifiers(attacker: CardData, defender: CardData, base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	var result := base_damage
	# Weakness before Resistance, each applied once.
	if defender.weakness_modifier == WEAKNESS_DOUBLE and _shares_type(attacker.types, defender.weakness_types):
		result *= 2
	if defender.resistance_modifier == RESISTANCE_MINUS_30 and _shares_type(attacker.types, defender.resistance_types):
		result = maxi(result - 30, 0)
	return result


func _shares_type(attacker_types: Array[String], target_types: Array[String]) -> bool:
	for attacker_type in attacker_types:
		if target_types.has(attacker_type):
			return true
	return false


func _take_prize(taker_index: int) -> void:
	var taker := players[taker_index]
	if taker.prizes.is_empty():
		return
	taker.hand.append(taker.prizes.pop_back() as CardData)
	_log("Player %d takes a prize (%d left)" % [taker_index + 1, taker.prizes.size()])


func _opponent_index() -> int:
	return 1 - current_index


func _log(text: String) -> void:
	events.append(text)
