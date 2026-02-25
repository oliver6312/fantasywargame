extends Panel
class_name SettlementInfoPanel

@onready var name_label: Label = $HBoxContainerMiddle/VBoxContainer/NameLabel
@onready var resource_label: Label = $HBoxContainerMiddle/VBoxContainer/ResourceLabel
@onready var faction_label: Label = $HBoxContainerMiddle/VBoxContainer/FactionLabel
@onready var soldiers_label: Label = $HBoxContainerMiddle/VBoxContainer/SoldiersLabel
@onready var building_slots_label: Label = $HBoxContainerMiddle/VBoxContainer/BuildingSlotsLabel

@onready var slot1: Button = $HBoxContainerMiddle/VBoxContainer/VBoxContainer/Slot1Label
@onready var slot2: Button = $HBoxContainerMiddle/VBoxContainer/VBoxContainer/Slot2Label
@onready var slot3: Button = $HBoxContainerMiddle/VBoxContainer/VBoxContainer/Slot3Label

@onready var delete_button: Button = $DeletePromptPanel/DeleteBuildingButton
var slot_buttons: Array[Button]
var _current_settlement: Settlement = null

signal slot_clicked(settlement: Settlement, slot_index: int)

signal delete_building_requested(settlement: Settlement, slot_index: int)

var _selected_slot_index: int = -1

func _ready() -> void:
	slot_buttons = [slot1, slot2, slot3]
	slot1.pressed.connect(func(): _on_slot_pressed(0))
	slot2.pressed.connect(func(): _on_slot_pressed(1))
	slot3.pressed.connect(func(): _on_slot_pressed(2))
	delete_button.pressed.connect(_on_delete_pressed)
	hide_panel()

func _on_slot_pressed(i: int) -> void:
	if _current_settlement == null:
		return
	_selected_slot_index = i
	_update_delete_button()
	emit_signal("slot_clicked", _current_settlement, i)

func _update_delete_button() -> void:
	if _current_settlement == null or _selected_slot_index < 0:
		delete_button.visible = false
		return

	if _selected_slot_index >= _current_settlement.building_slots:
		delete_button.visible = false
		return

	delete_button.visible = (_current_settlement.building_in_slot(_selected_slot_index) != "")

func _on_delete_pressed() -> void:
	if _current_settlement == null or _selected_slot_index < 0:
		return
	emit_signal("delete_building_requested", _current_settlement, _selected_slot_index)

func _building_name_from_id(b_id: String) -> String:
	# Brute-force lookup across all factions (fine at this scale)
	for f in [Faction.Type.ORC, Faction.Type.ELF, Faction.Type.DWARF]:
		for b in BuildingDB.buildings_for_faction(f):
			if b.id == b_id:
				return b.display_name
	return b_id


func show_for_settlement(s: Settlement) -> void:
	_current_settlement = s
	visible = true
	if s == null:
		hide_panel()
		return

	visible = true

	# Name
	var display_name: String = s.settlement_name
	if display_name == "":
		display_name = s.name
	name_label.text = "%s" % display_name

	# Resource
	resource_label.text = "%s" % ResourceClass.name_for(s.resource_type)

	# Faction
	faction_label.text = "%s" % _faction_name(s.faction)

	# Soldiers
	soldiers_label.text = "%d" % s.soldiers

	# Building slots
	var slots: int = clamp(s.building_slots, 1, 3)
	building_slots_label.text = "Slots: %d" % slots

	for i in range(3):
		var btn := slot_buttons[i]
		var slot_num := i + 1
		btn.visible = slot_num <= slots
		if btn.visible:
			var b_id := s.building_in_slot(i)
			if b_id == "":
				btn.text = "Slot %d: (empty)" % slot_num
			else:
				# Convert building id -> display name (via BuildingDB lookup helper below)
				btn.text = "Slot %d: %s" % [slot_num, _building_name_from_id(b_id)]
	_selected_slot_index = -1
	_update_delete_button()

func hide_panel() -> void:
	visible = false

func _faction_name(f: Faction.Type) -> String:
	match f:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		Faction.Type.NEUTRAL: return "Neutral"
		_: return "Unknown"
