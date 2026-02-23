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
var slot_buttons: Array[Button]
var _current_settlement: Settlement = null

signal slot_clicked(settlement: Settlement, slot_index: int)



func _ready() -> void:
	slot_buttons = [slot1, slot2, slot3]
	slot1.pressed.connect(func(): _on_slot_pressed(0))
	slot2.pressed.connect(func(): _on_slot_pressed(1))
	slot3.pressed.connect(func(): _on_slot_pressed(2))
	hide_panel()

func _building_name_from_id(b_id: String) -> String:
	# Brute-force lookup across all factions (fine at this scale)
	for f in [Faction.Type.ORC, Faction.Type.ELF, Faction.Type.DWARF]:
		for b in BuildingDatabase.buildings_for_faction(f):
			if b.id == b_id:
				return b.display_name
	return b_id

func _on_slot_pressed(i: int) -> void:
	if _current_settlement == null:
		return
	emit_signal("slot_clicked", _current_settlement, i)

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
	name_label.text = "Name: %s" % display_name

	# Resource
	resource_label.text = "Resource: %s" % ResourceClass.name_for(s.resource_type)

	# Faction
	faction_label.text = "Faction: %s" % _faction_name(s.faction)

	# Soldiers
	soldiers_label.text = "Soldiers: %d" % s.soldiers

	# Building slots
	var slots: int = clamp(s.building_slots, 1, 3)
	building_slots_label.text = "Building slots: %d" % slots

	for i in range(3):
		var btn := slot_buttons[i]
		var slot_num := i + 1
		btn.visible = slot_num <= slots
		if btn.visible:
			var b_id := s.building_in_slot(i)
			if b_id == "":
				btn.text = "Building Slot %d: (empty)" % slot_num
			else:
				# Convert building id -> display name (via BuildingDB lookup helper below)
				btn.text = "Building Slot %d: %s" % [slot_num, _building_name_from_id(b_id)]

func hide_panel() -> void:
	visible = false

func _faction_name(f: Faction.Type) -> String:
	match f:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		Faction.Type.NEUTRAL: return "Neutral"
		_: return "Unknown"
