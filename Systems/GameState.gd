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

# =========================
# Turn / Round
# =========================

var turn_index: int = 0
var current_turn: Faction.Type = TURN_ORDER[0]

var round: int = 1

# =========================
# Season
# =========================

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
var season_extended_this_round: bool = false

# =========================
# Resources
# =========================

var elf_serenity: int = 1
var elf_magic: int = 0
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
		_handle_end_of_round()

		if not season_extended_this_round:
			_advance_season()

		season_extended_this_round = false

	current_turn = TURN_ORDER[turn_index]
	_emit_turn()

func _emit_turn() -> void:
	print("%s turn" % get_faction_name(current_turn))
	turn_changed.emit(current_turn)

func _handle_end_of_round() -> void:
	elf_serenity *= 2
	resources_changed.emit()

# =========================
# Season
# =========================

func _advance_season() -> void:
	season_index = (season_index + 1) % SEASON_ORDER.size()
	current_season = SEASON_ORDER[season_index]
	season_changed.emit(current_season)

	if current_season == Season.AUTUMN:
		_deploy_elf_serenity()

func get_season_name(season: int = current_season) -> String:
	match season:
		Season.SPRING: return "Spring"
		Season.SUMMER: return "Summer"
		Season.AUTUMN: return "Autumn"
		Season.WINTER: return "Winter"
		_: return "Unknown"

func set_season_extended_this_round(value: bool) -> void:
	season_extended_this_round = value

func _deploy_elf_serenity() -> void:
	for settlement in get_tree().get_nodes_in_group("settlements"):
		if settlement.faction != Faction.Type.ELF:
			continue

		for slot in settlement.building_slots:
			if slot == "Sacred Grove":
				settlement.set_soldiers(settlement.soldiers + elf_serenity)
				break

	print("Elf Serenity deployed.")
	elf_serenity = 1
	resources_changed.emit()

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

func get_elf_serenity() -> int:
	return elf_serenity

func set_elf_serenity(value: int) -> void:
	elf_serenity = max(1, value)
	resources_changed.emit()

func add_elf_serenity(amount: int) -> void:
	set_elf_serenity(elf_serenity + amount)

func get_elf_magic() -> int:
	return elf_magic

func set_elf_magic(value: int) -> void:
	elf_magic = max(0, value)
	resources_changed.emit()

func add_elf_magic(amount: int) -> void:
	set_elf_magic(elf_magic + amount)

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
