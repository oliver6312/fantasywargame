extends Panel
class_name SettlementInfoPanel

@onready var name_label: Label = $HBoxContainerMiddle/VBoxContainer/NameLabel
@onready var resource_label: Label = $HBoxContainerMiddle/VBoxContainer/ResourceLabel
@onready var faction_label: Label = $HBoxContainerMiddle/VBoxContainer/FactionLabel
@onready var soldiers_label: Label = $HBoxContainerMiddle/VBoxContainer/SoldiersLabel
@onready var building_slots_label: Label = $HBoxContainerMiddle/VBoxContainer/BuildingSlotsLabel

@onready var slot1: Label = $HBoxContainerMiddle/VBoxContainer/VBoxContainer/Slot1Label
@onready var slot2: Label = $HBoxContainerMiddle/VBoxContainer/VBoxContainer/Slot2Label
@onready var slot3: Label = $HBoxContainerMiddle/VBoxContainer/VBoxContainer/Slot3Label

var slot_labels: Array[Label]

func _ready() -> void:
	slot_labels = [slot1, slot2, slot3]
	hide_panel()

func show_for_settlement(s: Settlement) -> void:
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
	var slots: int = clampi(s.building_slots, 1, 3)
	building_slots_label.text = "Building slots: %d" % slots

	for i in range(3):
		var lbl: Label = slot_labels[i]
		var slot_num: int = i + 1
		lbl.visible = slot_num <= slots
		if lbl.visible:
			lbl.text = "Slot %d: (empty)" % slot_num

func hide_panel() -> void:
	visible = false

func _faction_name(f: Faction.Type) -> String:
	match f:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		Faction.Type.NEUTRAL: return "Neutral"
		_: return "Unknown"
