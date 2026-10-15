## Headless checks for the card effect system. Run from the project root:
##   godot --headless --path . --script res://tests/effects_test.gd
## Exits with code 0 when every check passes.
extends SceneTree

var db: CardDatabase
var lib: EffectLibrary
var failures := 0

func expect(cond: bool, label: String) -> void:
	if cond:
		print("  ok   ", label)
	else:
		print("  FAIL ", label)
		failures += 1

func energies(ids: Array) -> Array[CardData]:
	var out: Array[CardData] = []
	for id: String in ids:
		out.append(db.make(id))
	return out

## Player 1 (index 0) to act with attacker vs defender.
func setup(attacker_id: String, attached: Array, defender_id: String, defender_attached: Array = []) -> MatchEngine:
	var decks := DataLoader.read_json(DataLoader.DECKS_PATH) as Dictionary
	var engine := MatchEngine.new()
	engine.effects = lib
	engine.start(db.build_deck(decks["fighting_starter"]), db.build_deck(decks["lightning_starter"]), 3, 3, Rng.new(7))
	engine.current_index = 0
	for p in engine.players:
		p.bench.clear()
		p.reset_turn_flags()
	var a := CardInPlay.new(db.make(attacker_id), 0)
	a.attached_energy.assign(energies(attached))
	engine.players[0].active = a
	var d := CardInPlay.new(db.make(defender_id), 0)
	d.attached_energy.assign(energies(defender_attached))
	engine.players[1].active = d
	engine.events.clear()
	return engine

var last_defender: CardInPlay
var last_attacker: CardInPlay

func attack(engine: MatchEngine, name: String) -> bool:
	last_defender = engine.players[1].active
	last_attacker = engine.players[0].active
	for action in engine.legal_actions():
		if action["type"] == "attack" and str(action["label"]).begins_with("Attack: %s " % name):
			engine.apply(action)
			return true
	return false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	db = DataLoader.load_card_database()
	lib = DataLoader.load_effect_library(db)
	print("== load")
	expect(lib.errors.is_empty(), "no validation errors: %s" % [lib.errors])
	expect(lib.valid_binding_count() == 74, "74 card effect entries in use (%d)" % lib.valid_binding_count())
	print("  warnings: ", lib.warnings)

	print("== scenarios")
	var W := "base1-102"; var F := "base1-98"; var L := "base1-100"; var P := "base1-101"; var G := "base1-97"

	# Ember: Charmander with Fire + Lightning, defender Voltorb (no W/R vs Fire)
	var e := setup("base1-46", [F, L], "base1-67")
	expect(attack(e, "Ember"), "Ember is legal")
	var voltorb := e.players[1].active
	expect(voltorb.damage == 30, "Ember deals 30 (%d)" % voltorb.damage)
	var charmander_energy := e.players[0].active.energy_pool()
	expect(charmander_energy == ["Lightning"], "Ember discarded the Fire Energy (%s)" % [charmander_energy])
	expect(e.players[0].discard.size() == 1, "discarded card is in the discard pile")

	# Requirement: discard_own_energy needs a Fire Energy
	var r := setup("base1-46", [L, L], "base1-67")
	var ctx := EffectContext.new()
	ctx.engine = r; ctx.source = r.players[0].active; ctx.defender = r.players[1].active
	ctx.player = r.players[0]; ctx.opponent = r.players[1]; ctx.attack = ctx.source.card.attacks[1]
	var resolver := EffectResolver.new(lib, ctx)
	expect(not resolver.requirements_met("discard_energy_cards_then_damage", {"energy_type": "Fire", "count": 1}), "requirement fails without Fire Energy")
	r.players[0].active.attached_energy.assign(energies([F]))
	expect(resolver.requirements_met("discard_energy_cards_then_damage", {"energy_type": "Fire", "count": 1}), "requirement passes with one Fire Energy")
	expect(not resolver.requirements_met("discard_energy_cards_then_damage", {"energy_type": "Fire", "count": 2}), "requirement fails asking for two")

	# Karate Chop: Machoke 50 minus 10 per counter
	var k := setup("base1-34", [G, G, G], "base1-26")
	k.players[0].active.damage = 30
	expect(attack(k, "Karate Chop"), "Karate Chop is legal")
	expect(last_defender.damage == 20, "Karate Chop with 3 counters deals 20 (%d)" % last_defender.damage)

	# Flail: Magikarp times own counters
	var fl := setup("base1-35", [W], "base1-67")
	fl.players[0].active.damage = 20
	expect(attack(fl, "Flail"), "Flail is legal")
	expect(last_defender.damage == 20, "Flail with 2 counters deals 20 (%d)" % last_defender.damage)

	# Hydro Pump: Blastoise 40 + 10 per unpaid Water, max 2
	var hp := setup("base1-2", [W, W, W, W, G], "base2-11")
	expect(attack(hp, "Hydro Pump"), "Hydro Pump is legal")
	expect(last_defender.damage == 50, "Hydro Pump with one extra Water and one Fighting deals 50 (%d)" % last_defender.damage)
	var hp2 := setup("base1-2", [W, W, W, W, W, W], "base2-11")
	attack(hp2, "Hydro Pump")
	expect(last_defender.damage == 60, "Hydro Pump caps at two extra Water: 60 (%d)" % last_defender.damage)

	# Psychic: Mewtwo 10 + 10 per Energy on the defender
	var ps := setup("base1-10", [P, P], "base1-67", [L, L, L])
	expect(attack(ps, "Psychic"), "Psychic is legal")
	expect(last_defender.damage == 40, "Psychic against 3 Energy deals 40 (%d)" % last_defender.damage)

	# Thunderbolt: Zapdos discards all
	var tb := setup("base1-16", [L, L, L, L, F], "base1-52")
	expect(attack(tb, "Thunderbolt"), "Thunderbolt is legal")
	expect(tb.players[0].active.attached_energy.is_empty(), "Thunderbolt discarded every Energy")
	expect(tb.players[0].discard.size() == 5, "five Energy in the discard pile")

	# Fetch draws a card and deals nothing
	var fe := setup("base2-5", [G], "base1-67")
	var hand_before := fe.players[0].hand.size()
	expect(attack(fe, "Fetch"), "Fetch is legal")
	expect(fe.players[0].hand.size() == hand_before + 1, "Fetch drew one card")
	expect(last_defender.damage == 0, "Fetch dealt no damage")

	var DCE := "base1-96"

	print("== energy cards and units")
	expect(db.make(DCE).provides == ["Colorless", "Colorless"], "Double Colorless Energy provides two Colorless")
	expect(db.warnings.is_empty(), "no parse warnings left: %s" % [db.warnings])
	var ps2 := setup("base1-10", [P, P], "base1-65", [DCE, L])
	attack(ps2, "Psychic")
	expect(last_defender.damage == 30, "Psychic counts Energy cards: DCE + Lightning is 2, deals 30 (%d)" % last_defender.damage)
	var egg := setup("base2-35", [DCE, G], "base2-11")
	attack(egg, "Big Eggsplosion")
	var flips := 0
	for line in egg.events:
		if line.contains("Coin flip"):
			flips += 1
	expect(flips == 3, "Big Eggsplosion counts Energy units: DCE + Fighting flips 3 coins (%d)" % flips)
	var wg := setup("base1-13", [W, W, W, DCE], "base2-11")
	attack(wg, "Water Gun")
	expect(last_defender.damage == 40, "Water Gun: DCE pays the Colorless, so the third Water is unpaid, deals 40 (%d)" % last_defender.damage)
	var rt := setup("base1-7", [G, DCE], "base2-11")
	rt.players[0].bench.append(CardInPlay.new(db.make("base1-26"), 0))
	for action in rt.legal_actions():
		if action["type"] == "retreat":
			rt.apply(action)
			break
	expect(rt.players[0].bench[0].energy_pool() == ["Fighting"], "retreat cost 2 is paid by the DCE alone")

	print("== choosing Energy to discard")
	var fs := setup("base1-4", [F, F, F, F, DCE], "base1-3")
	expect(attack(fs, "Fire Spin"), "Fire Spin is legal")
	expect(fs.is_waiting_for_choice(), "Fire Spin waits for a choice")
	var choices := fs.legal_actions()
	var labels: Array = []
	for action in choices:
		labels.append(action["label"])
	expect(choices.size() == 2, "two options, Fire Energy and DCE, not five: %s" % [labels])
	expect(fs.players[0].discard.is_empty() and last_defender.damage == 0, "nothing happens before the choice")
	for action in choices:
		if str(action["label"]).contains("Double Colorless"):
			fs.apply(action)
	expect(not fs.is_waiting_for_choice(), "the second card is the only kind left and needs no choice")
	var discarded_names: Array = []
	for card in fs.players[0].discard:
		discarded_names.append(card.name)
	discarded_names.sort()
	expect(discarded_names == ["Double Colorless Energy", "Fire Energy"], "discarded DCE and one Fire Energy: %s" % [discarded_names])
	expect(last_defender.damage == 100, "Fire Spin dealt 100 after the choice (%d)" % last_defender.damage)
	var fs2 := setup("base1-4", [F, F, F, F, F, F], "base1-3")
	attack(fs2, "Fire Spin")
	expect(not fs2.is_waiting_for_choice() and fs2.players[0].discard.size() == 2, "identical Fire Energy need no choice")

	print("== simultaneous knockouts")
	var both := setup("base1-3", [G, G, G, G], "base1-7")
	both.players[0].active.damage = 50
	both.players[0].bench.append(CardInPlay.new(db.make("base1-26"), 0))
	both.players[1].bench.append(CardInPlay.new(db.make("base1-61"), 0))
	var p0 := both.players[0].prizes.size()
	var p1 := both.players[1].prizes.size()
	attack(both, "Double-edge")
	expect(both.players[0].prizes.size() == p0 - 1 and both.players[1].prizes.size() == p1 - 1, "both players took a prize")
	expect(not both.is_over() and both.players[0].active.card.id == "base1-26" and both.players[1].active.card.id == "base1-61", "both promoted and the match goes on")
	var sd := setup("base1-3", [G, G, G, G], "base1-7")
	sd.players[0].active.damage = 50
	sd.players[0].bench.append(CardInPlay.new(db.make("base1-26"), 0))
	sd.players[1].bench.append(CardInPlay.new(db.make("base1-61"), 0))
	while sd.players[0].prizes.size() > 1: sd.players[0].prizes.pop_back()
	while sd.players[1].prizes.size() > 1: sd.players[1].prizes.pop_back()
	attack(sd, "Double-edge")
	expect(sd.winner == MatchEngine.SUDDEN_DEATH, "both take their last prize: Sudden Death")
	var two := setup("base1-3", [G, G, G, G], "base1-7")
	two.players[0].active.damage = 50
	two.players[0].bench.append(CardInPlay.new(db.make("base1-26"), 0))
	while two.players[0].prizes.size() > 1: two.players[0].prizes.pop_back()
	while two.players[1].prizes.size() > 1: two.players[1].prizes.pop_back()
	attack(two, "Double-edge")
	expect(two.winner == 0, "player 1 wins in two ways, player 2 in one: player 1 wins")

	# Double-edge: Chansey 80 to defender and 80 to itself; knocked out if already damaged
	var de := setup("base1-3", [G, G, G, G], "base1-7")
	expect(attack(de, "Double-edge"), "Double-edge is legal")
	expect(last_attacker.damage == 80, "Chansey took 80 (%d)" % last_attacker.damage)
	var ko := setup("base1-3", [G, G, G, G], "base2-11")
	ko.players[0].active.damage = 50
	ko.players[0].bench.append(CardInPlay.new(db.make("base1-26"), 0))
	var prizes_before := ko.players[1].prizes.size()
	attack(ko, "Double-edge")
	expect(ko.players[1].prizes.size() == prizes_before - 1, "opponent took a prize for Chansey knocking itself out")
	expect(ko.players[0].active.card.id == "base1-26", "Dratini was promoted")

	# Coin-based: Comet Punch = 20 x heads, Thunder Jolt self-damage only on tails
	var consistent := true
	var jolt_ok := true
	for trial in 60:
		var cp := setup("base2-5", [G, G, G, G], "base2-11")
		cp.set("_rng", Rng.new(trial))
		attack(cp, "Comet Punch")
		var heads := 0
		for line in cp.events:
			if line.ends_with("heads"): heads += 1
		if last_defender.damage != 20 * heads:
			consistent = false
		var tj := setup("base1-58", [L, L], "base1-7")
		tj.set("_rng", Rng.new(trial))
		attack(tj, "Thunder Jolt")
		var tails := tj.events.has("  Coin flip: tails")
		if (last_attacker.damage == 10) != tails:
			jolt_ok = false
	expect(consistent, "Comet Punch deals 20 per heads across 60 seeds")
	expect(jolt_ok, "Thunder Jolt damages Pikachu only on tails across 60 seeds")

	print("== validator")
	var bad_functions := {
		"flip_coins": {"params": {}, "steps": [{"call": "draw_cards", "args": {"player": "$player", "count": 1}}]},
		"unknown_call": {"params": {}, "steps": [{"call": "does_not_exist", "args": {}}]},
		"missing_arg": {"params": {}, "steps": [{"call": "multiply", "args": {"a": 1}}]},
		"extra_arg": {"params": {}, "steps": [{"call": "multiply", "args": {"a": 1, "b": 2, "c": 3}}]},
		"wrong_literal": {"params": {}, "steps": [{"call": "multiply", "args": {"a": "Fire", "b": 2}}]},
		"undefined_ref": {"params": {}, "steps": [{"call": "multiply", "args": {"a": "$nope", "b": 2}}]},
		"output_reuses_param": {"params": {"x": "int"}, "steps": [{"call": "multiply", "args": {"a": "$x", "b": 2}, "as": "x"}]},
		"conditional_output": {"params": {}, "steps": [{"call": "multiply", "args": {"a": 1, "b": 2}, "as": "y", "when": {"value": 1, "eq": 1}}]},
		"requires_under_when": {"params": {}, "steps": [{"call": "discard_own_energy_cards", "args": {"energy_type": "Fire", "count": 1}, "when": {"value": 1, "eq": 1}}]},
		"output_to_requires": {"params": {}, "steps": [{"call": "flip_coins", "args": {"count": 1}, "as": "h"}, {"call": "discard_own_energy_cards", "args": {"energy_type": "Fire", "count": "$h"}}]},
		"cycle_a": {"params": {}, "steps": [{"call": "cycle_b", "args": {}}]},
		"cycle_b": {"params": {}, "steps": [{"call": "cycle_a", "args": {}}]},
		"wrong_ref_type": {"params": {}, "steps": [{"call": "multiply", "args": {"a": "$self", "b": 2}}]},
	}
	var functions := (DataLoader.read_json(DataLoader.FUNCTIONS_PATH) as Dictionary).duplicate(true)
	functions.merge(bad_functions)
	var bad_cards := {
		"base1-91": {"trainer": {"function": "damage_times_heads", "args": {"coins": 1}}},
		"base1-92": {"trainer": {"function": "damage_self", "args": {"amount": 10}}},
		"base1-46": {"attacks": {"Flamethrower": {"function": "draw", "args": {"count": 1}}, "Ember": {"function": "discard_energy_cards_then_damage", "args": {"energy_type": "$self", "count": 1}}}},
		"base1-58": {"attacks": {"Thunder Jolt": {"function": "damage_then_damage_self_on_tails", "args": {}}}},
		"base1-24": {"attacks": {"Flamethrower": {"function": "draw", "args": {"count": 1}}}},
		"base1-36": {"attacks": {"Flamethrower": {"function": "discard_energy_cards_then_damage", "args": {"energy_type": "Purple", "count": 1}}}},
		"nope-1": {"attacks": {}},
	}
	var bad := EffectLibrary.new()
	bad.load_data(functions, bad_cards, db)
	var all_errors := "\n".join(PackedStringArray(bad.errors))
	for needle: String in [
		"functions flip_coins: the name is also an atomic effect",
		"'does_not_exist', which is neither a function nor an atomic effect",
		"is missing argument 'b'",
		"has extra argument 'c'",
		"argument 'a' has a value that is not a valid int",
		"refers to undefined '$nope'",
		"output 'x' reuses a parameter name",
		"is conditional and may not publish an output",
		"which has requirements, under when",
		"passes output '$h' to a function with requirements",
		"call cycle",
		"argument 'a' is pokemon, expected int",
		"only works while an attack resolves",
		"uses $self, which a Trainer does not have",
		"'Flamethrower': the card does not print it",
		"is a reference; card effects take literal values only",
		"missing argument 'amount'",
		"argument 'energy_type' is not a valid energy_type_or_any",
		"card_effects nope-1: no such card",
	]:
		expect(all_errors.contains(needle), "error: %s" % needle)
	expect("\n".join(PackedStringArray(bad.warnings)).contains("attacks 'Flamethrower' is bound to different functions"), "warning: same name, different functions")
	expect(bad.binding_for("base1-58", "attacks", "Thunder Jolt").is_empty(), "an invalid entry is never resolved")
	expect(not bad.binding_for("base1-24", "attacks", "Flamethrower").is_empty(), "a valid entry in the same file still resolves")

	print("== simulation")
	var decks := DataLoader.read_json(DataLoader.DECKS_PATH) as Dictionary
	var picker := RandomNumberGenerator.new()
	picker.seed = 99
	var wins := [0, 0]
	var warnings_seen := 0
	for game in 300:
		var engine := MatchEngine.new()
		engine.effects = lib
		engine.start(db.build_deck(decks["effects_fire_lightning"]), db.build_deck(decks["effects_colorless"]), 3, 3, Rng.new(game))
		var steps := 0
		while not engine.is_over() and steps < 5000:
			var actions := engine.legal_actions()
			var chosen := actions[picker.randi_range(0, actions.size() - 1)]
			for a in actions:
				if a["type"] == "attack" and picker.randf() < 0.7:
					chosen = a
					break
			engine.apply(chosen)
			steps += 1
			for p in engine.players:
				var n := p.deck.size() + p.hand.size() + p.discard.size() + p.prizes.size() + p.bench.size()
				if p.active != null:
					n += 1 + p.active.attached_energy.size()
				for b in p.bench:
					n += b.attached_energy.size()
				if n != 30:
					push_error("card count %d" % n)
					failures += 1
					quit(1)
					return
		if not engine.is_over():
			failures += 1
		wins[engine.winner] += 1
		for line in engine.events:
			if line.contains("[effect warning]"):
				warnings_seen += 1
	expect(true, "300 games finished with 30 cards per side; wins %s" % [wins])
	expect(warnings_seen == 0, "no runtime effect warnings (%d)" % warnings_seen)

	print("FAILURES: ", failures)
	quit(1 if failures > 0 else 0)
