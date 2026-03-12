extends Node
class_name GameState

signal turn_changed(new_turn: Faction.Type)

# Only the playable factions (no neutral)
const TURN_ORDER: Array[Faction.Type] = [
	Faction.Type.ORC,
	Faction.Type.ELF,
	Faction.Type.DWARF
]

var turn_index: int = 0
var current_turn: Faction.Type = TURN_ORDER[0]

signal round_changed(new_round:int)

var round:int = 1

func _ready() -> void:
	_emit_turn()

func next_turn() -> void:
	turn_index += 1

	if turn_index >= TURN_ORDER.size():
		turn_index = 0
		round += 1
		emit_signal("round_changed", round)

	current_turn = TURN_ORDER[turn_index]
	_emit_turn()

func _emit_turn() -> void:
	var name := _turn_name(current_turn)
	print("%s turn" % name)
	emit_signal("turn_changed", current_turn)

func _turn_name(t: Faction.Type) -> String:
	match t:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Unknown"
