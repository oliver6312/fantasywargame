extends Node
class_name GameState

# =========================
# Signals
# =========================

signal turn_changed(new_turn: Faction.Type)
signal round_changed(new_round: int)
signal resources_changed()
signal season_changed(new_season: int)

# =========================
# Constants
# =========================

const FACTIONS := [
	Faction.Type.ORC,
	Faction.Type.ELF,
	Faction.Type.DWARF
]

const TURN_ORDER := FACTIONS

const DWARF_HOARD_THRESHOLDS := [40, 80, 120, 200, 320, 520]

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

# =========================
# Turn / Round
# =========================

var turn_index: int = 0
var current_turn: Faction.Type = TURN_ORDER[0]

var round: int = 1

# =========================
# Season
# =========================

var season_index: int = 0
var current_season: int = SEASON_ORDER[0]

# =========================
# Resources
# =========================

var gold := {}
var armor := {}

# =========================
# Controllers
# =========================

var current_faction_controller: FactionController

# =========================
# Dwarf persistent state
# =========================

var dwarf_gold_action_assignments := {}

# =========================
# Init
# =========================

func _ready() -> void:
	_initialize_resources()
	_initialize_dwarf_data()

	_emit_turn()
	round_changed.emit(round)
	resources_changed.emit()
	season_changed.emit(current_season)

# =========================
# Initialization helpers
# =========================

func _initialize_resources() -> void:
	for faction in FACTIONS:
		gold[faction] = 0
		armor[faction] = 0

	set_gold(Faction.Type.ORC, 10)
	set_gold(Faction.Type.ELF, 10)
	set_gold(Faction.Type.DWARF, 120)

	set_armor(Faction.Type.ORC, 5)
	set_armor(Faction.Type.ELF, 5)
	set_armor(Faction.Type.DWARF, 5)

func _initialize_dwarf_data() -> void:
	for threshold in DWARF_HOARD_THRESHOLDS:
		dwarf_gold_action_assignments[threshold] = ""

# =========================
# Turn system
# =========================

func next_turn() -> void:
	turn_index += 1

	if turn_index >= TURN_ORDER.size():
		turn_index = 0
		round += 1
		round_changed.emit(round)
		_advance_season()

	current_turn = TURN_ORDER[turn_index]
	_emit_turn()

func _emit_turn() -> void:
	print("%s turn" % get_faction_name(current_turn))
	turn_changed.emit(current_turn)

# =========================
# Season
# =========================

func _advance_season() -> void:
	season_index = (season_index + 1) % SEASON_ORDER.size()
	current_season = SEASON_ORDER[season_index]
	season_changed.emit(current_season)

func get_season_name(season: int = current_season) -> String:
	match season:
		Season.SPRING: return "Spring"
		Season.SUMMER: return "Summer"
		Season.AUTUMN: return "Autumn"
		Season.WINTER: return "Winter"
		_: return "Unknown"

# =========================
# Resource system
# =========================

func get_gold(faction: Faction.Type) -> int:
	return gold.get(faction, 0)

func get_armor(faction: Faction.Type) -> int:
	return armor.get(faction, 0)

func set_gold(faction: Faction.Type, value: int) -> void:
	gold[faction] = max(0, value)

	if faction == Faction.Type.DWARF:
		_refresh_dwarf_hoard_unlocks()

	resources_changed.emit()

func set_armor(faction: Faction.Type, value: int) -> void:
	armor[faction] = max(0, value)
	resources_changed.emit()

func add_gold(faction: Faction.Type, amount: int) -> void:
	set_gold(faction, get_gold(faction) + amount)

func add_armor(faction: Faction.Type, amount: int) -> void:
	set_armor(faction, get_armor(faction) + amount)

# =========================
# Dwarf hoard system
# =========================

func get_dwarf_gold_action_assignment(threshold: int) -> String:
	return dwarf_gold_action_assignments.get(threshold, "")

func set_dwarf_gold_action_assignment(threshold: int, action_type: String) -> void:
	dwarf_gold_action_assignments[threshold] = action_type

func clear_dwarf_gold_action_assignment(threshold: int) -> void:
	dwarf_gold_action_assignments[threshold] = ""

func _refresh_dwarf_hoard_unlocks() -> void:
	var current_gold := get_gold(Faction.Type.DWARF)

	for threshold in DWARF_HOARD_THRESHOLDS:
		if current_gold < threshold:
			dwarf_gold_action_assignments[threshold] = ""

# =========================
# Utility
# =========================

func get_faction_name(faction: Faction.Type) -> String:
	match faction:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Neutral"
