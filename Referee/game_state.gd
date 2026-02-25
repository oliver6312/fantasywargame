extends Node
class_name GameState

signal turn_changed(new_turn: Faction.Type)
signal resources_changed(faction: Faction.Type)

signal round_changed(round: int)

var round: int = 1

const TRAIT_BONUS := 0.33

# NEW: base unit strength per faction
var base_unit_strength := {
	Faction.Type.ORC: 1.0,
	Faction.Type.ELF: 1.0,
	Faction.Type.DWARF: 2.0,
}

# NEW: derived per-turn from buildings
# traits[faction] is a set: { "Armor": true, "Rage": true, ... }
var traits := {
	Faction.Type.ORC: {},
	Faction.Type.ELF: {},
	Faction.Type.DWARF: {},
}

# counters[faction] is a set: { "Armor": true, ... }
var counters := {
	Faction.Type.ORC: {},
	Faction.Type.ELF: {},
	Faction.Type.DWARF: {},
}

func apply_start_of_turn_building_effects(f: Faction.Type) -> void:
	var db := get_node_or_null("/root/BuildingDB")
	if db == null:
		return

	# For each settlement owned by f, apply each building's SOT effects
	for s in get_tree().get_nodes_in_group("settlements"):
		if s == null:
			continue
		if s.faction != f:
			continue

		for i in range(s.building_slots):
			var b_id : String = s.buildings[i]
			if b_id == "":
				continue

			var def: BuildingDef = db.get_def_by_id(b_id)
			if def == null:
				continue

			# Soldiers (spawn into the settlement)
			if def.sot_add_soldiers != 0:
				s.set_soldiers(s.soldiers + def.sot_add_soldiers)

			# Resources to faction
			if def.sot_add_lumber != 0:
				resources[f][ResourceClass.Type.LUMBER] += def.sot_add_lumber
			if def.sot_add_food != 0:
				resources[f][ResourceClass.Type.FOOD] += def.sot_add_food
			if def.sot_add_minerals != 0:
				resources[f][ResourceClass.Type.MINERALS] += def.sot_add_minerals

	# Notify UI
	emit_signal("resources_changed", f)

	# Ownership counts might change if you later add effects that change faction/soldiers to 0 etc.
	recalculate_control_from_board()
	recalculate_buildings_from_board()
	recalculate_traits_and_counters()

func recalculate_traits_and_counters() -> void:
	for f in TURN_ORDER:
		traits[f].clear()
		counters[f].clear()

	for s in get_tree().get_nodes_in_group("settlements"):
		if s == null:
			continue
		var f: Faction.Type = s.faction
		if not traits.has(f):
			continue # ignore NEUTRAL

		for i in range(s.building_slots):
			var b_id: String = s.buildings[i]
			if b_id == "":
				continue

			var def: BuildingDef = _get_building_def_by_id(b_id)
			if def == null:
				continue

			if def.grants_trait != "":
				traits[f][def.grants_trait] = true  # set-like, duplicates don't stack

			if def.counters_trait != "":
				counters[f][def.counters_trait] = true

func _get_building_def_by_id(id: String) -> BuildingDef:
	var db := get_node_or_null("/root/BuildingDB")
	if db == null:
		return null
	return db.get_def_by_id(id)

func effective_unit_strength(side: Faction.Type, opponent: Faction.Type) -> float:
	var strength := _base_strength(side)

	# If side is neutral, it has no traits, done.
	if side == Faction.Type.NEUTRAL:
		return strength

	# If opponent is neutral, it has no counters, so no trait gets nullified.
	if opponent == Faction.Type.NEUTRAL:
		for trait_name in traits[side].keys():
			strength += TRAIT_BONUS
		return strength

	# Normal case: apply traits unless opponent counters them
	for trait_name in traits[side].keys():
		if counters[opponent].has(trait_name):
			continue
		strength += TRAIT_BONUS

	return strength

func _base_strength(f: Faction.Type) -> float:
	if f == Faction.Type.NEUTRAL:
		return 1.0
	return float(base_unit_strength.get(f, 1.0))

func can_afford(f: Faction.Type, cost: Dictionary) -> bool:
	for r in cost.keys():
		if resources[f][r] < int(cost[r]):
			return false
	return true

func spend_resources(f: Faction.Type, cost: Dictionary) -> bool:
	if not can_afford(f, cost):
		return false
	for r in cost.keys():
		resources[f][r] -= int(cost[r])
	emit_signal("resources_changed", f)
	return true

# buildings_owned[faction][building_id] = count
var buildings_owned := {
	Faction.Type.ORC: {},
	Faction.Type.ELF: {},
	Faction.Type.DWARF: {},
}

func recalculate_buildings_from_board() -> void:
	for f in TURN_ORDER:
		buildings_owned[f].clear()

	for s in get_tree().get_nodes_in_group("settlements"):
		if s == null:
			continue
		var f: Faction.Type = s.faction
		if not buildings_owned.has(f):
			continue
		for i in range(s.building_slots):
			var b_id: String = str(s.buildings[i])
			if b_id == "":
				continue
			buildings_owned[f][b_id] = int(buildings_owned[f].get(b_id, 0)) + 1

const TURN_ORDER: Array[Faction.Type] = [
	Faction.Type.ORC,
	Faction.Type.ELF,
	Faction.Type.DWARF
]

var turn_index := 0
var current_turn: Faction.Type = TURN_ORDER[0]

# --- NEW: bookkeeping ---
# settlements_controlled[faction] = int
var settlements_controlled := {
	Faction.Type.ORC: 0,
	Faction.Type.ELF: 0,
	Faction.Type.DWARF: 0
}

# controlled_by_resource[faction][resource] = int
var controlled_by_resource := {
	Faction.Type.ORC: { ResourceClass.Type.LUMBER: 0, ResourceClass.Type.FOOD: 0, ResourceClass.Type.MINERALS: 0 },
	Faction.Type.ELF: { ResourceClass.Type.LUMBER: 0, ResourceClass.Type.FOOD: 0, ResourceClass.Type.MINERALS: 0 },
	Faction.Type.DWARF: { ResourceClass.Type.LUMBER: 0, ResourceClass.Type.FOOD: 0, ResourceClass.Type.MINERALS: 0 },
}

# resources[faction][resource] = int (your stored amounts)
var resources := {
	Faction.Type.ORC: { ResourceClass.Type.LUMBER: 0, ResourceClass.Type.FOOD: 0, ResourceClass.Type.MINERALS: 0 },
	Faction.Type.ELF: { ResourceClass.Type.LUMBER: 0, ResourceClass.Type.FOOD: 0, ResourceClass.Type.MINERALS: 0 },
	Faction.Type.DWARF: { ResourceClass.Type.LUMBER: 0, ResourceClass.Type.FOOD: 0, ResourceClass.Type.MINERALS: 0 },
}

func _ready() -> void:
	recalculate_control_from_board()
	recalculate_buildings_from_board()
	recalculate_traits_and_counters()
	_emit_turn()
	

func next_turn() -> void:
	turn_index = (turn_index + 1) % TURN_ORDER.size()
	if turn_index == 0:
		round += 1
		emit_signal("round_changed", round)

	current_turn = TURN_ORDER[turn_index]
	
	# Always keep derived state fresh
	recalculate_buildings_from_board()
	recalculate_traits_and_counters()
	recalculate_control_from_board()
	
	# Base income from settlements
	_start_turn_income(current_turn)
	
	# Extra effects from buildings
	apply_start_of_turn_building_effects(current_turn)
	
	_emit_turn()

func _emit_turn() -> void:
	print("%s turn" % _turn_name(current_turn))
	emit_signal("turn_changed", current_turn)

func _turn_name(t: Faction.Type) -> String:
	match t:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Unknown"

# --- NEW: call this after any move that might change ownership ---
func recalculate_control_from_board() -> void:
	# reset counts
	for f in TURN_ORDER:
		settlements_controlled[f] = 0
		for r in [ResourceClass.Type.LUMBER, ResourceClass.Type.FOOD, ResourceClass.Type.MINERALS]:
			controlled_by_resource[f][r] = 0

	# count from actual settlement state
	for s in get_tree().get_nodes_in_group("settlements"):
		if s == null:
			continue
		var f: Faction.Type = s.faction
		if not settlements_controlled.has(f):
			continue # ignore NEUTRAL
		settlements_controlled[f] += 1
		controlled_by_resource[f][s.resource_type] += 1

# --- b4 (your second b3): start-of-turn income ---
func _start_turn_income(f: Faction.Type) -> void:
	# Ensure counts are fresh (in case something changed since last recalculation)
	recalculate_control_from_board()

	for r in [ResourceClass.Type.LUMBER, ResourceClass.Type.FOOD, ResourceClass.Type.MINERALS]:
		var income: int = controlled_by_resource[f][r]
		resources[f][r] += income

	print("%s income: +%d Lumber, +%d Food, +%d Minerals"
		% [
			_turn_name(f),
			controlled_by_resource[f][ResourceClass.Type.LUMBER],
			controlled_by_resource[f][ResourceClass.Type.FOOD],
			controlled_by_resource[f][ResourceClass.Type.MINERALS]
		]
	)

	emit_signal("resources_changed", f)
