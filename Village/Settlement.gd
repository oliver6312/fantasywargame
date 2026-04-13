extends Area2D
class_name Settlement

signal clicked(settlement: Settlement)

const BUILDING_FARM := "Farm"

@export var settlement_id: String = ""
@export var settlement_name: String = ""

@export var faction: Faction.Type = Faction.Type.NEUTRAL : set = set_faction
@export var soldiers: int = 0 : set = set_soldiers
@export var neighbors: Array[Settlement] = []

@export_range(1, 3, 1) var building_slot_count: int = 1 : set = set_building_slot_count
@export var building_slots: Array[String] = []

@onready var faction_symbol: Sprite2D = %FactionSymbol
@onready var selection_circle: Sprite2D = $SelectionCircle
@onready var available_circle: Sprite2D = $AvailableCircle
@onready var name_label: Label = $NameLabel
@onready var soldier_label: Label = $SoldierLabel

@onready var building_slot_1: Sprite2D = $BuildingSlot1
@onready var building_slot_2: Sprite2D = $BuildingSlot2
@onready var building_slot_3: Sprite2D = $BuildingSlot3

@onready var infiltration_token: Sprite2D = $InfiltrationToken
@onready var dragon_token: Sprite2D = $DragonToken
@onready var wraith_token: Sprite2D = $WraithToken
@onready var sorcerer_token: Sprite2D = $SorcererToken
@onready var blacksmith_token: Sprite2D = $BlacksmithToken
@onready var war_promise_token: Sprite2D = $WarPromiseToken

@export var farm_texture: Texture2D 
@export var gold_mine_texture: Texture2D
@export var armor_smith_texture: Texture2D
@export var goat_stable_texture: Texture2D
@export var training_grounds_texture: Texture2D
@export var sacred_grove_texture: Texture2D
@export var gruesome_effigy_texture: Texture2D

@onready var building_icon_1: Sprite2D = $BuildingIcon1
@onready var building_icon_2: Sprite2D = $BuildingIcon2
@onready var building_icon_3: Sprite2D = $BuildingIcon3

var mercenaries_hired_this_turn: bool = false

var infiltration_faction: int = Faction.Type.NEUTRAL
var has_orc_dark_lord_token: bool = false
@export var is_orc_war_promise: bool = false : set = set_orc_war_promise

func _ready() -> void:
	add_to_group("settlements")

	name_label.text = get_display_name()

	_resize_building_slots()
	_make_neighbors_two_way()

	if faction == Faction.Type.NEUTRAL and building_slot_count >=2:
		var empty_index := _get_first_empty_building_slot()
		if empty_index != -1 and not _has_any_building():
			building_slots[empty_index] = BUILDING_FARM

	_refresh_visuals()
	_refresh_building_slot_visuals()
	_refresh_infiltration_visuals()
	_refresh_dark_lord_token_visuals()
	_refresh_war_promise_visuals()
	_validate_neighbors()
	_refresh_building_icons()

	selection_circle.visible = false
	available_circle.visible = false

func get_display_name() -> String:
	return settlement_name if settlement_name != "" else name

func _get_building_texture(building_name: String) -> Texture2D:
	match building_name:
		"Farm":
			return farm_texture
		"Gold Mine":
			return gold_mine_texture
		"Armor Smith":
			return armor_smith_texture
		"Goat Stable":
			return goat_stable_texture
		"Training Grounds":
			return training_grounds_texture
		"Sacred Grove":
			return sacred_grove_texture
		"Gruesome Effigy":
			return gruesome_effigy_texture
		_:
			return null

func _refresh_building_icons() -> void:
	var icons := [building_icon_1, building_icon_2, building_icon_3]

	for i in range(icons.size()):
		var icon: Sprite2D = icons[i]

		if i >= building_slot_count:
			icon.visible = false
			icon.texture = null
			continue

		var building_name := building_slots[i]
		if building_name == "":
			icon.visible = false
			icon.texture = null
			continue

		icon.texture = _get_building_texture(building_name)
		icon.visible = icon.texture != null

func has_minimum_soldiers(amount: int) -> bool:
	return soldiers >= amount

# =========================
# Selection / click
# =========================

func set_selected(is_selected: bool) -> void:
	selection_circle.visible = is_selected
	if is_selected:
		name_label.text = get_display_name()

func set_available(is_available: bool) -> void:
	available_circle.visible = is_available

func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)

# =========================
# Faction / soldiers
# =========================

func set_faction(value: Faction.Type) -> void:
	faction = value
	if faction == Faction.Type.DWARF:
		faction_symbol.texture = preload("res://Village/SettlementGraphics/DwarfSymbolCrest2.png")
	if faction == Faction.Type.ORC:
		faction_symbol.texture = preload("res://Village/SettlementGraphics/OrcSymbolCrest6.png")
	if faction == Faction.Type.ELF:
		faction_symbol.texture = preload("res://Village/SettlementGraphics/ElfSymbolCrest4.png")
	_refresh_visuals()

func set_soldiers(value: int) -> void:
	soldiers = max(0, value)
	_refresh_visuals()

func set_garrison(new_faction: Faction.Type, amount: int) -> void:
	soldiers = max(0, amount)
	faction = new_faction
	_refresh_visuals()

func _refresh_visuals() -> void:
	if soldier_label == null:
		return

	soldier_label.text = str(soldiers)
	soldier_label.add_theme_color_override("font_color", Faction.color_for(faction))

# =========================
# Buildings
# =========================

func set_building_slot_count(value: int) -> void:
	building_slot_count = clamp(value, 1, 3)
	_resize_building_slots()
	_refresh_building_slot_visuals()

func _resize_building_slots() -> void:
	while building_slots.size() < building_slot_count:
		building_slots.append("")

	while building_slots.size() > building_slot_count:
		building_slots.remove_at(building_slots.size() - 1)

func _refresh_building_slot_visuals() -> void:
	if building_slot_1 == null:
		return

	building_slot_1.visible = building_slot_count >= 1
	building_slot_2.visible = building_slot_count >= 2
	building_slot_3.visible = building_slot_count >= 3

func get_building_in_slot(index: int) -> String:
	if index < 0 or index >= building_slots.size():
		return ""
	return building_slots[index]

func set_building_in_slot(index: int, building_name: String) -> void:
	if index < 0 or index >= building_slots.size():
		return

	building_slots[index] = building_name
	_refresh_building_icons()

func get_building_slot_display_name(index: int) -> String:
	var building := get_building_in_slot(index)
	if building == "":
		return "Empty"
	return building

func _get_first_empty_building_slot() -> int:
	for i in range(building_slots.size()):
		if building_slots[i] == "":
			return i
	return -1

func _has_any_building() -> bool:
	for building in building_slots:
		if building != "":
			return true
	return false

func clear_buildings():
	_resize_building_slots()
	
	for i in range(building_slots.size()):
		building_slots[i] = ""
	print(building_slots)
	_refresh_building_icons()

func add_building(building_name: String) -> bool:
	_resize_building_slots()
	for i in range(building_slots.size()):
		if building_slots[i] == "":
			building_slots[i] = building_name
			_refresh_building_icons()
			return true
	return false

# =========================
# Mercenaries
# =========================

func can_hire_mercenaries() -> bool:
	if faction != TurnState.current_turn:
		return false
	if faction != Faction.Type.ORC:
		return false
	if mercenaries_hired_this_turn:
		return false
	return true

func get_mercenary_gold_cost() -> int:
	return 8 * building_slot_count

func get_mercenary_soldier_gain() -> int:
	return 4 * building_slot_count

func hire_mercenaries() -> bool:
	if not can_hire_mercenaries():
		return false

	var cost := get_mercenary_gold_cost()
	if TurnState.get_gold(faction) < cost:
		return false

	TurnState.add_gold(faction, -cost)
	set_soldiers(soldiers + get_mercenary_soldier_gain())
	mercenaries_hired_this_turn = true
	return true

func reset_turn_limited_actions() -> void:
	mercenaries_hired_this_turn = false

# =========================
# Infiltration
# =========================

func has_infiltration() -> bool:
	return infiltration_faction != Faction.Type.NEUTRAL

func has_enemy_infiltration_for(faction_value: int) -> bool:
	return has_infiltration() and infiltration_faction != faction_value

func set_infiltration(faction_value: int) -> void:
	infiltration_faction = faction_value
	_refresh_infiltration_visuals()

func clear_infiltration() -> void:
	infiltration_faction = Faction.Type.NEUTRAL
	_refresh_infiltration_visuals()

func _refresh_infiltration_visuals() -> void:
	if infiltration_token == null:
		return

	infiltration_token.visible = has_infiltration()

# =========================
# Orc Dark Lord
# =========================

func has_orc_dark_lord() -> bool:
	return has_orc_dark_lord_token

func set_orc_dark_lord_present(value: bool) -> void:
	has_orc_dark_lord_token = value
	_refresh_dark_lord_token_visuals()

func _refresh_dark_lord_token_visuals() -> void:
	if dragon_token == null:
		return

	dragon_token.visible = false
	wraith_token.visible = false
	sorcerer_token.visible = false
	blacksmith_token.visible = false

	if not has_orc_dark_lord():
		return

	match TurnState.get_orc_dark_lord():
		TurnState.ORC_LORD_DRAGON:
			dragon_token.visible = true
		TurnState.ORC_LORD_WRAITH:
			wraith_token.visible = true
		TurnState.ORC_LORD_SORCERER:
			sorcerer_token.visible = true
		TurnState.ORC_LORD_BLACKSMITH:
			blacksmith_token.visible = true

# =========================
# Orc War Promise
# =========================

func set_orc_war_promise(value: bool) -> void:
	is_orc_war_promise = value
	_refresh_war_promise_visuals()

func has_orc_war_promise() -> bool:
	return is_orc_war_promise

func _refresh_war_promise_visuals() -> void:
	if war_promise_token == null:
		return

	war_promise_token.visible = is_orc_war_promise

# =========================
# Neighbors
# =========================

func _make_neighbors_two_way() -> void:
	neighbors = neighbors.filter(func(n): return n != null and n != self)

	for n in neighbors:
		if not n.neighbors.has(self):
			n.neighbors.append(self)

func _validate_neighbors() -> void:
	for n in neighbors:
		if n == null:
			continue
		if not n.neighbors.has(self):
			push_warning("%s has neighbor %s but not vice versa" % [name, n.name])

func is_adjacent_to(other: Settlement) -> bool:
	return neighbors.has(other)

func can_receive_faction(_incoming: Faction.Type) -> bool:
	return true
