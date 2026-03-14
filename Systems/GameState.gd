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

signal resources_changed()

var gold := {
	Faction.Type.ORC: 0,
	Faction.Type.ELF: 0,
	Faction.Type.DWARF: 0
}

var armor := {
	Faction.Type.ORC: 0,
	Faction.Type.ELF: 0,
	Faction.Type.DWARF: 0
}

signal season_changed(new_season: int)

enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER
}

const SEASON_ORDER := [
	Season.SPRING,
	Season.SUMMER,
	Season.AUTUMN,
	Season.WINTER
]

var season_index: int = 0
var current_season: int = SEASON_ORDER[0]

var current_turn_controller : FactionTurn

var current_faction_controller: FactionController

func _ready() -> void:
	set_gold(Faction.Type.ORC, 10)
	set_gold(Faction.Type.ELF, 10)
	set_gold(Faction.Type.DWARF, 10)

	set_armor(Faction.Type.ORC, 5)
	set_armor(Faction.Type.ELF, 5)
	set_armor(Faction.Type.DWARF, 5)

	_emit_turn()
	emit_signal("round_changed", round)
	emit_signal("resources_changed")
	emit_signal("season_changed", current_season)



func _create_turn_controller(faction:int):

	if current_turn_controller != null:
		current_turn_controller.queue_free()

	match faction:
		Faction.Type.ORC:
			current_turn_controller = OrcTurn.new()

		Faction.Type.ELF:
			current_turn_controller = ElfTurn.new()

		Faction.Type.DWARF:
			current_turn_controller = DwarfTurn.new()

	add_child(current_turn_controller)

	current_turn_controller.faction = faction
	current_turn_controller.start_turn()

func _advance_season() -> void:
	season_index = (season_index + 1) % SEASON_ORDER.size()
	current_season = SEASON_ORDER[season_index]
	emit_signal("season_changed", current_season)

func get_season_name(season: int = current_season) -> String:
	match season:
		Season.SPRING: return "Spring"
		Season.SUMMER: return "Summer"
		Season.AUTUMN: return "Autumn"
		Season.WINTER: return "Winter"
		_: return "Unknown"

func next_turn() -> void:
	turn_index += 1

	if turn_index >= TURN_ORDER.size():
		turn_index = 0
		round += 1
		emit_signal("round_changed", round)
		_advance_season()

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

func get_gold(faction: Faction.Type) -> int:
	return gold.get(faction, 0)

func get_armor(faction: Faction.Type) -> int:
	return armor.get(faction, 0)

func set_gold(faction: Faction.Type, value: int) -> void:
	gold[faction] = max(0, value)
	emit_signal("resources_changed")

func set_armor(faction: Faction.Type, value: int) -> void:
	armor[faction] = max(0, value)
	emit_signal("resources_changed")

func add_gold(faction: Faction.Type, amount: int) -> void:
	set_gold(faction, get_gold(faction) + amount)

func add_armor(faction: Faction.Type, amount: int) -> void:
	set_armor(faction, get_armor(faction) + amount)
