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
	Faction.Type.DWARF,
	Faction.Type.ELF
]

const TURN_ORDER := FACTIONS

const DWARF_HOARD_THRESHOLDS := [40, 80, 120, 200, 320, 520]

const ORC_LORD_NONE := ""
const ORC_LORD_DRAGON := "Dragon"
const ORC_LORD_WRAITH := "Wraith"
const ORC_LORD_SORCERER := "Sorcerer"
const ORC_LORD_BLACKSMITH := "Blacksmith"

var orc_current_dark_lord: String = ORC_LORD_NONE

var orc_dead_dark_lords := {
	ORC_LORD_DRAGON: false,
	ORC_LORD_WRAITH: false,
	ORC_LORD_SORCERER: false,
	ORC_LORD_BLACKSMITH: false
}

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
var elves_extended_season_this_season: bool = false

# =========================
# Resources
# =========================

var elf_serenity: int = 2
var elf_magic: int = 8
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

	set_gold(Faction.Type.ORC, 16)
	set_gold(Faction.Type.ELF, 12)
	set_gold(Faction.Type.DWARF, 20)

	set_armor(Faction.Type.ORC, 4)
	set_armor(Faction.Type.ELF, 8)
	set_armor(Faction.Type.DWARF, 12)

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
	var serenity_gain := 2
	if season_extended_this_round:
		serenity_gain = 4
	elf_serenity += serenity_gain

	_spawn_orcs_from_gruesome_effigies()

	resources_changed.emit()

func _spawn_orcs_from_gruesome_effigies() -> void:
	var spawn_amount := 3

	if get_orc_dark_lord() == ORC_LORD_SORCERER:
		spawn_amount = 6

	if get_orc_dark_lord() == ORC_LORD_BLACKSMITH:
		add_armor(Faction.Type.ORC, 1)

	for settlement in get_tree().get_nodes_in_group("settlements"):
		if settlement.faction != Faction.Type.ORC:
			continue
		if settlement.has_minimum_soldiers(16):
			continue

		for slot in settlement.building_slots:
			if slot == "Gruesome Effigy":
				settlement.set_soldiers(settlement.soldiers + spawn_amount)
				break

# =========================
# Season
# =========================

func _advance_season() -> void:
	season_index = (season_index + 1) % SEASON_ORDER.size()
	current_season = SEASON_ORDER[season_index]
	elves_extended_season_this_season = false
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

func _deploy_elf_serenity() -> void:
	for settlement in get_tree().get_nodes_in_group("settlements"):
		if settlement.faction != Faction.Type.ELF:
			continue

		for slot in settlement.building_slots:
			if slot == "Sacred Grove":
				settlement.set_soldiers(settlement.soldiers + elf_serenity)
				break

	print("Elf Serenity deployed.")
	elf_serenity = 0
	resources_changed.emit()

func can_elves_extend_season() -> bool:
	return not elves_extended_season_this_season

func set_season_extended_this_round(value: bool) -> void:
	season_extended_this_round = value
	if value:
		elves_extended_season_this_season = true

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
# Orc Helpers
# =========================

func has_orc_dark_lord() -> bool:
	return orc_current_dark_lord != ORC_LORD_NONE

func get_orc_dark_lord() -> String:
	return orc_current_dark_lord

func set_orc_dark_lord(lord_name: String) -> void:
	orc_current_dark_lord = lord_name

func clear_orc_dark_lord() -> void:
	orc_current_dark_lord = ORC_LORD_NONE

func is_orc_dark_lord_dead(lord_name: String) -> bool:
	# Wraith undtagelse er en del af orccontroller
	return orc_dead_dark_lords.get(lord_name, false)

func kill_orc_dark_lord() -> void:
	if orc_current_dark_lord == ORC_LORD_NONE:
		return

	if orc_current_dark_lord != ORC_LORD_WRAITH:
		orc_dead_dark_lords[orc_current_dark_lord] = true

	orc_current_dark_lord = ORC_LORD_NONE
	clear_all_orc_war_promises()

func get_orc_dark_lord_strength() -> int:
	match orc_current_dark_lord:
		ORC_LORD_DRAGON:
			return 4
		ORC_LORD_WRAITH:
			return 1
		ORC_LORD_SORCERER:
			return 2
		ORC_LORD_BLACKSMITH:
			return 2
		_:
			return 0

func find_orc_dark_lord_settlement() -> Settlement:
	for settlement in get_tree().get_nodes_in_group("settlements"):
		if settlement.has_orc_dark_lord():
			return settlement
	return null

func place_orc_dark_lord_in_settlement(settlement: Settlement) -> void:
	var current := find_orc_dark_lord_settlement()
	if current != null:
		current.set_orc_dark_lord_present(false)

	if settlement != null:
		settlement.set_orc_dark_lord_present(true)

func clear_all_orc_war_promises() -> void:
	for settlement in get_tree().get_nodes_in_group("settlements"):
		settlement.set_orc_war_promise(false)

#func war_promise_must_control_all() -> void:
#	if are_all_war_promises_orc_owned():
#		return
#	var biggest_settlement = get_orc_settlement_with_most_soldiers()
#	if biggest_settlement == null:
#		return
#	
#	biggest_settlement.soldiers = int(biggest_settlement.soldiers / 2)

func get_orc_settlement_with_most_soldiers() -> Object:
	var best_settlement = null
	var most_soldiers = -1
	
	for settlement in get_tree().get_nodes_in_group("settlements"):
		if settlement.faction == Faction.Type.ORC:
			if settlement.soldiers > most_soldiers:
				most_soldiers = settlement.soldiers
				best_settlement = settlement
	
	print(best_settlement)
	return best_settlement

func get_orc_war_promise_settlements() -> Array:
	var result := []
	for settlement in get_tree().get_nodes_in_group("settlements"):
		if settlement.has_orc_war_promise():
			result.append(settlement)
	return result

func count_orc_owned_war_promises() -> int:
	var total := 0
	for settlement in get_orc_war_promise_settlements():
		if settlement.faction == Faction.Type.ORC:
			total += 1
	return total

func are_all_war_promises_orc_owned() -> bool:
	var promises := get_orc_war_promise_settlements()
	if promises.is_empty():
		return false

	for settlement in promises:
		if settlement.faction != Faction.Type.ORC:
			return false

	return true

# =========================
# Utility
# =========================

func get_faction_name(faction: Faction.Type) -> String:
	match faction:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Neutral"
