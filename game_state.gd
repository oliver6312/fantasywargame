extends Node
class_name GameState

signal turn_changed(new_turn: Faction.Type)
signal resources_changed(faction: Faction.Type)

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
	_emit_turn()

func next_turn() -> void:
	turn_index = (turn_index + 1) % TURN_ORDER.size()
	current_turn = TURN_ORDER[turn_index]
	_start_turn_income(current_turn)
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
