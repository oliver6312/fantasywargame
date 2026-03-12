extends CanvasLayer
class_name BoardUI

@onready var next_turn_button: Button = $LeftPanel/HBoxContainerBottom/VBoxContainer/NextTurnButton
@onready var turn_label: Label = $LeftPanel/HBoxContainerTop/VBoxContainer/TurnLabel

@onready var move_dialog: AcceptDialog = %MoveDialog
@onready var amount_edit: LineEdit = %AmountEdit
@onready var prompt_label: Label = %PromptLabel
@onready var deselect_button: Button = %DeselectButton

@onready var settings_button: Button = %SettingsButton
@onready var settings_dialog: Window = %SettingsDialog
@onready var quit_button: Button = %QuitButton

@onready var round_label: Label = %RoundLabel

@onready var settlement_panel: Control = %SettlementDetailPanel
@onready var settlement_name: Label = %SettlementNameLabel
@onready var settlement_faction: Label = %SettlementFactionLabel
@onready var settlement_soldiers: Label = %SettlementSoldiersLabel

@onready var orc_gold_label: Label = %OrcGoldLabel
@onready var orc_armor_label: Label = %OrcArmorLabel
@onready var elf_gold_label: Label = %ElfGoldLabel
@onready var elf_armor_label: Label = %ElfArmorLabel
@onready var dwarf_gold_label: Label = %DwarfGoldLabel
@onready var dwarf_armor_label: Label = %DwarfArmorLabel

@onready var season_button: Button = %SeasonButton
@onready var season_dialog: Window = %SeasonDialog

@onready var building_slot_button_1: Button = %BuildingSlotButton1
@onready var building_slot_button_2: Button = %BuildingSlotButton2
@onready var building_slot_button_3: Button = %BuildingSlotButton3

@onready var trade_button: Button = %TradeButton
@onready var trade_dialog: AcceptDialog = %TradeDialog
@onready var target_faction_option: OptionButton = %TargetFactionOption
@onready var trade_gold_edit: LineEdit = %GoldEdit
@onready var trade_armor_edit: LineEdit = %ArmorEdit
@onready var trade_info_label: Label = %TradeInfoLabel

@onready var attacker_armor_label: Label = %AttackerArmorLabel
@onready var attacker_armor_edit: LineEdit = %AttackerArmorEdit
@onready var defender_armor_label: Label = %DefenderArmorLabel
@onready var defender_armor_edit: LineEdit = %DefenderArmorEdit

@onready var mercenary_button: Button = %MercenaryButton

var current_settlement: Settlement = null

func _ready() -> void:
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	TurnState.turn_changed.connect(_on_turn_changed)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_quit_game)

	# Initialize label immediately
	_on_turn_changed(TurnState.current_turn)

	TurnState.round_changed.connect(_on_round_changed)

	round_label.text = "Round %d" % TurnState.round
	
	TurnState.resources_changed.connect(_update_resource_labels)
	_update_resource_labels()
	
	season_button.pressed.connect(_on_season_button_pressed)
	TurnState.season_changed.connect(_on_season_changed)
	_on_season_changed(TurnState.current_season)

	trade_button.pressed.connect(_on_trade_button_pressed)
	trade_dialog.confirmed.connect(_on_trade_confirmed)
	
	_populate_trade_targets()
	
	mercenary_button.pressed.connect(_on_mercenary_button_pressed)
	
	TurnState.resources_changed.connect(_on_resources_changed)

func _on_resources_changed() -> void:
	_update_resource_labels()
	if current_settlement != null:
		show_settlement_details(current_settlement)

func _on_mercenary_button_pressed() -> void:
	if current_settlement == null:
		return

	var success := current_settlement.hire_mercenaries()
	if success:
		show_settlement_details(current_settlement)
	else:
		print("Could not hire mercenaries.")

func _update_mercenary_button(s: Settlement) -> void:
	var cost := s.get_mercenary_gold_cost()
	var gain := s.get_mercenary_soldier_gain()

	mercenary_button.text = "Hire Mercenaries (+%d soldiers, %d gold)" % [gain, cost]

	if s.faction != TurnState.current_turn:
		mercenary_button.disabled = true
	elif s.mercenaries_hired_this_turn:
		mercenary_button.disabled = true
	elif TurnState.get_gold(s.faction) < cost:
		mercenary_button.disabled = true
	else:
		mercenary_button.disabled = false

func _on_trade_confirmed() -> void:
	var sender : int = TurnState.current_turn
	var receiver := target_faction_option.get_selected_id()

	var gold_amount := int(trade_gold_edit.text)
	var armor_amount := int(trade_armor_edit.text)

	gold_amount = max(0, gold_amount)
	armor_amount = max(0, armor_amount)

	if gold_amount > TurnState.get_gold(sender):
		print("Not enough gold.")
		return

	if armor_amount > TurnState.get_armor(sender):
		print("Not enough armor.")
		return

	TurnState.add_gold(sender, -gold_amount)
	TurnState.add_gold(receiver, gold_amount)

	TurnState.add_armor(sender, -armor_amount)
	TurnState.add_armor(receiver, armor_amount)

	print("%s sent %d gold and %d armor to %s." % [
		_faction_name(sender),
		gold_amount,
		armor_amount,
		_faction_name(receiver)
	])

func _on_trade_button_pressed() -> void:
	_populate_trade_targets()
	trade_gold_edit.text = ""
	trade_armor_edit.text = ""
	trade_info_label.text = "Send resources to another faction."
	trade_dialog.popup_centered()

func _faction_name(faction: int) -> String:
	match faction:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Neutral"

func _populate_trade_targets() -> void:
	target_faction_option.clear()

	var current: Faction.Type = TurnState.current_turn
	var factions := [
		Faction.Type.ORC,
		Faction.Type.ELF,
		Faction.Type.DWARF
	]

	for faction in factions:
		if faction == current:
			continue

		target_faction_option.add_item(_faction_name(faction), faction)

func _update_building_slot_buttons(s: Settlement) -> void:
	var buttons := [
		building_slot_button_1,
		building_slot_button_2,
		building_slot_button_3
	]

	for i in range(3):
		if i < s.building_slot_count:
			buttons[i].visible = true
			buttons[i].text = s.get_building_slot_display_name(i)
		else:
			buttons[i].visible = false

func _on_season_button_pressed() -> void:
	season_dialog.popup_centered()

func _on_season_changed(new_season: int) -> void:
	season_button.text = TurnState.get_season_name(new_season)

func _update_resource_labels() -> void:
	orc_gold_label.text = "Orc Gold: %d" % TurnState.get_gold(Faction.Type.ORC)
	orc_armor_label.text = "Orc Armor: %d" % TurnState.get_armor(Faction.Type.ORC)

	elf_gold_label.text = "Elf Gold: %d" % TurnState.get_gold(Faction.Type.ELF)
	elf_armor_label.text = "Elf Armor: %d" % TurnState.get_armor(Faction.Type.ELF)

	dwarf_gold_label.text = "Dwarf Gold: %d" % TurnState.get_gold(Faction.Type.DWARF)
	dwarf_armor_label.text = "Dwarf Armor: %d" % TurnState.get_armor(Faction.Type.DWARF)

func show_settlement_details(s:Settlement):
	current_settlement = s
	settlement_panel.visible = true

	settlement_name.text = s.get_display_name()
	settlement_soldiers.text = "Soldiers: %d" % s.soldiers

	match s.faction:
		Faction.Type.ORC:
			settlement_faction.text = "Faction: Orc"
		Faction.Type.ELF:
			settlement_faction.text = "Faction: Elf"
		Faction.Type.DWARF:
			settlement_faction.text = "Faction: Dwarf"
		_:
			settlement_faction.text = "Faction: Neutral"

	_update_building_slot_buttons(s)
	_update_mercenary_button(s)

func _on_round_changed(new_round:int):
	round_label.text = "Round %d" % new_round

func _open_settings():
	settings_dialog.popup_centered()

func hide_settlement_details():
	current_settlement = null
	settlement_panel.visible = false

func _quit_game():
	get_tree().quit()

func _on_next_turn_pressed() -> void:
	TurnState.next_turn()

func _on_turn_changed(new_turn: Faction.Type) -> void:
	turn_label.text = "%s turn" % _faction_name(TurnState.current_turn)
	_populate_trade_targets()
	if current_settlement != null:
		show_settlement_details(current_settlement)

func _turn_name(t: Faction.Type) -> String:
	match t:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Unknown"
