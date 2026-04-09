extends CanvasLayer
class_name BoardUI

signal war_meeting_finished()
@onready var war_meeting_done_button: Button = %WarMeetingDoneButton
signal action_requested(action_id: String)
signal dwarf_build_requested(building_name: String)
signal dwarf_gold_action_chosen(threshold: int, action_type: String)
signal dwarf_gold_assignment_requested(threshold: int)
signal trade_requested(receiver_faction: int, gold_amount: int, armor_amount: int)
signal next_turn_requested
signal dark_lord_move_requested(soldiers: int, armor: int)
signal orc_war_promise_chosen(settlement: Settlement)

signal infiltration_remove_requested()

@onready var remove_infiltration_button: Button = %RemoveInfiltrationButton
@onready var draft_label: Label = %DraftLabel
@onready var right_panel: Panel = %RightPanel

# =========================
# Left Panel UI
# =========================
@onready var next_turn_button: Button = %NextTurnButton
@onready var turn_label: Label = %TurnLabel
@onready var round_label: Label = %RoundLabel
@onready var season_button: Button = %SeasonButton
@onready var season_dialog: Window = %SeasonDialog

# =========================
# Movement / dialogs
# =========================
@onready var move_dialog: AcceptDialog = %MoveDialog
@onready var amount_edit: LineEdit = %AmountEdit
@onready var prompt_label: Label = %PromptLabel
@onready var deselect_button: Button = %DeselectButton

@onready var move_all_button: Button = %MoveAllButton
@onready var move_half_button: Button = %MoveHalfButton
signal move_half_requested()
signal move_all_requested()

@onready var attacker_armor_label: Label = %AttackerArmorLabel
@onready var attacker_armor_edit: LineEdit = %AttackerArmorEdit
@onready var defender_armor_label: Label = %DefenderArmorLabel
@onready var defender_armor_edit: LineEdit = %DefenderArmorEdit

@onready var bring_dark_lord_checkbox: CheckBox = %BringDarkLordCheckBox
# Settings
# =========================
@onready var settings_button: Button = %SettingsButton
@onready var settings_dialog: Window = %SettingsDialog
@onready var quit_button: Button = %QuitButton

# =========================
# Settlement details
# =========================
@onready var settlement_panel: Control = %SettlementDetailPanel
@onready var settlement_name: Label = %SettlementNameLabel
@onready var settlement_faction: Label = %SettlementFactionLabel
@onready var settlement_soldiers: Label = %SettlementSoldiersLabel
@onready var mercenary_button: Button = %MercenaryButton
@onready var delete_building_button: Button = %DeleteBuildingButton
var selected_building_slot_index: int = -1

@onready var building_slot_buttons: Array[Button] = [
	%BuildingSlotButton1,
	%BuildingSlotButton2,
	%BuildingSlotButton3
]

signal building_slot_selected(slot_index: int)
signal building_delete_requested(slot_index: int)

# =========================
# Resources / trade
# =========================
@onready var trade_button: Button = %TradeButton
@onready var trade_dialog: AcceptDialog = %TradeDialog
@onready var target_faction_option: OptionButton = %TargetFactionOption
@onready var trade_gold_edit: LineEdit = %GoldEdit
@onready var trade_armor_edit: LineEdit = %ArmorEdit
@onready var trade_info_label: Label = %TradeInfoLabel

var gold_labels: Dictionary = {}
var armor_labels: Dictionary = {}

@onready var elf_magic_label: Label = %ElfMagicLabel
@onready var elf_serenity_label: Label = %ElfSerenityLabel

# =========================
# Faction action panel
# =========================
@onready var faction_actions_container: VBoxContainer = %FactionActionsContainer
@onready var dwarf_march_label: Label = %DwarfMarchLabel

# =========================
# Dwarf build UI
# =========================
@onready var dwarf_building_menu: Panel = %DwarfBuildingMenu
@onready var armor_smith_button: Button = %"Armor Smith"
@onready var goat_stable_button: Button = %"Goat Stable"
@onready var gold_mine_button: Button = %"Gold Mine"
@onready var training_grounds_button: Button = %"Training Grounds"

# =========================
# Dwarf hoard UI
# =========================
@onready var dwarf_hoard_panel: Control = %DwarfGoldHoard
@onready var hoard_buttons: Dictionary = {
	40: %ThresholdButton40,
	80: %ThresholdButton80,
	120: %ThresholdButton120,
	200: %ThresholdButton200,
	320: %ThresholdButton320,
	520: %ThresholdButton520
}

var current_settlement: Settlement = null

func _ready() -> void:
	_setup_resource_label_maps()
	_connect_global_signals()
	_connect_button_signals()
	_initialize_ui()

# =========================
# Setup
# =========================


func _setup_resource_label_maps() -> void:
	gold_labels = {
		Faction.Type.ORC: %OrcGoldLabel,
		Faction.Type.ELF: %ElfGoldLabel,
		Faction.Type.DWARF: %DwarfGoldLabel
	}

	armor_labels = {
		Faction.Type.ORC: %OrcArmorLabel,
		Faction.Type.ELF: %ElfArmorLabel,
		Faction.Type.DWARF: %DwarfArmorLabel
	}

func _connect_global_signals() -> void:
	TurnState.turn_changed.connect(_on_turn_changed)
	TurnState.round_changed.connect(_on_round_changed)
	TurnState.resources_changed.connect(_on_resources_changed)
	TurnState.season_changed.connect(_on_season_changed)
	SignalBus.has_traded.connect(_on_trade_executed)

func _connect_button_signals() -> void:
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_quit_game)
	season_button.pressed.connect(_on_season_button_pressed)
	trade_button.pressed.connect(_on_trade_button_pressed)
	trade_dialog.confirmed.connect(_on_trade_confirmed)
	mercenary_button.pressed.connect(_on_mercenary_button_pressed)
	war_meeting_done_button.pressed.connect(func(): war_meeting_finished.emit())
	for i in range(building_slot_buttons.size()):
		var slot_index := i
		building_slot_buttons[i].pressed.connect(func(): _on_building_slot_button_pressed(slot_index))
	delete_building_button.pressed.connect(_on_delete_building_button_pressed)
	remove_infiltration_button.pressed.connect(func(): infiltration_remove_requested.emit())
	move_half_button.pressed.connect(func(): move_half_requested.emit())
	move_all_button.pressed.connect(func(): move_all_requested.emit())

	# Dwarf build buttons
	armor_smith_button.pressed.connect(func(): dwarf_build_requested.emit("Armor Smith"))
	goat_stable_button.pressed.connect(func(): dwarf_build_requested.emit("Goat Stable"))
	gold_mine_button.pressed.connect(func(): dwarf_build_requested.emit("Gold Mine"))
	training_grounds_button.pressed.connect(func(): dwarf_build_requested.emit("Training Grounds"))


	# Dwarf hoard buttons
	for threshold in hoard_buttons.keys():
		var t: int = threshold
		var button: Button = hoard_buttons[t]
		button.pressed.connect(func(): dwarf_gold_assignment_requested.emit(t))

func _initialize_ui() -> void:
	_on_turn_changed(TurnState.current_turn)
	_on_round_changed(TurnState.round)
	_on_season_changed(TurnState.current_season)
	_update_resource_labels()
	_populate_trade_targets()
	hide_dwarf_hoard_panel()

	settlement_panel.visible = false
	dwarf_building_menu.visible = false
	delete_building_button.visible = false
	dwarf_march_label.visible = false

# =========================
# General helpers
# =========================

func _faction_name(faction: int) -> String:
	match faction:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Neutral"

func _pretty_action_name(action_type: String) -> String:
	match action_type:
		"build": return "Build"
		"march": return "March"
		"train": return "Train"
		"mine": return "Mine"
		"smith": return "Smith"
		_: return action_type.capitalize()

func _set_faction_label(label: Label, faction: int, prefix: String) -> void:
	label.text = "%s: %s" % [prefix, _faction_name(faction)]

func show_orc_war_promise_picker(settlements: Array) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Choose War Promise"

	var container := VBoxContainer.new()
	dialog.add_child(container)

	var info_label := Label.new()
	info_label.text = "Choose one enemy settlement to mark as a War Promise."
	container.add_child(info_label)

	for settlement in settlements:
		var s: Settlement = settlement
		var button := Button.new()
		button.text = "%s (%d soldiers)" % [s.get_display_name(), s.soldiers]

		button.pressed.connect(func():
			orc_war_promise_chosen.emit(s)
			dialog.queue_free()
		)

		container.add_child(button)

	add_child(dialog)
	dialog.popup_centered()

func show_dwarf_march_status(moves_remaining: int) -> void:
	dwarf_march_label.visible = true
	dwarf_march_label.text = "March: %d moves remaining" % moves_remaining

func hide_dwarf_march_status() -> void:
	dwarf_march_label.visible = false

# =========================
# Turn / round / season UI / phases
# =========================

func _on_next_turn_pressed() -> void:
	next_turn_requested.emit()
	print("next turn signal emited")

func _on_turn_changed(new_turn: Faction.Type) -> void:
	turn_label.text = "%s turn" % _faction_name(new_turn)
	trade_button.visible = true

	# Show dwarf hoard only during dwarf turn
	dwarf_hoard_panel.visible = (new_turn == Faction.Type.DWARF)

	_populate_trade_targets()

	if current_settlement != null:
		show_settlement_details(current_settlement)

func _on_round_changed(new_round: int) -> void:
	round_label.text = "Round %d" % new_round

func _on_season_button_pressed() -> void:
	season_dialog.popup_centered()

func _on_season_changed(new_season: int) -> void:
	season_button.text = TurnState.get_season_name(new_season)

func show_war_meeting_button() -> void:
	war_meeting_done_button.visible = true

func hide_war_meeting_button() -> void:
	war_meeting_done_button.visible = false

# =========================
# Settings UI
# =========================

func _open_settings() -> void:
	settings_dialog.popup_centered()

func _quit_game() -> void:
	get_tree().quit()

# =========================
# Resource / trade UI
# =========================

func _on_resources_changed() -> void:
	_update_resource_labels()

	if current_settlement != null:
		show_settlement_details(current_settlement)

func _on_trade_executed():
	trade_button.visible = false

func _update_resource_labels() -> void:
	for faction in gold_labels.keys():
		var gold_label: Label = gold_labels[faction]
		var armor_label: Label = armor_labels[faction]

		gold_label.text = "%s Gold: %d" % [
			_faction_name(faction),
			TurnState.get_gold(faction)
		]

		armor_label.text = "%s Armor: %d" % [
			_faction_name(faction),
			TurnState.get_armor(faction)
		]
	
	elf_magic_label.text = "Elf Magic: %d" % TurnState.get_elf_magic()
	elf_serenity_label.text = "Elf Serenity: %d" % TurnState.get_elf_serenity()

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

func _on_trade_button_pressed() -> void:
	_populate_trade_targets()
	trade_gold_edit.text = ""
	trade_armor_edit.text = ""
	trade_info_label.text = "Send resources to another faction."
	trade_dialog.popup_centered()

func _on_trade_confirmed() -> void:
	var receiver := target_faction_option.get_selected_id()
	var gold_amount : int = max(0, int(trade_gold_edit.text))
	var armor_amount : int = max(0, int(trade_armor_edit.text))

	trade_requested.emit(receiver, gold_amount, armor_amount)

# =========================
# Settlement UI
# =========================

func show_settlement_details(s: Settlement) -> void:
	current_settlement = s
	settlement_panel.visible = true

	settlement_name.text = s.get_display_name()
	settlement_soldiers.text = "Soldiers: %d" % s.soldiers
	settlement_faction.text = "Faction: %s" % _faction_name(s.faction)

	_update_building_slot_buttons(s)
	_update_mercenary_button(s)
	_update_remove_infiltration_button(s)
	
	selected_building_slot_index = -1
	delete_building_button.visible = false

func _update_remove_infiltration_button(s: Settlement) -> void:
	var controller := TurnState.current_faction_controller

	if controller == null:
		remove_infiltration_button.visible = false
		return

	if not s.has_infiltration():
		remove_infiltration_button.visible = false
		return

	if not controller.can_remove_infiltration():
		remove_infiltration_button.visible = false
		return

	remove_infiltration_button.visible = true
	remove_infiltration_button.disabled = false

func hide_settlement_details() -> void:
	current_settlement = null
	settlement_panel.visible = false
	selected_building_slot_index = -1
	delete_building_button.visible = false

func _update_building_slot_buttons(s: Settlement) -> void:
	for i in range(building_slot_buttons.size()):
		var button := building_slot_buttons[i]

		if i < s.building_slot_count:
			button.visible = true
			button.text = s.get_building_slot_display_name(i)
		else:
			button.visible = false

func _on_building_slot_button_pressed(slot_index: int) -> void:
	if current_settlement == null:
		return

	if slot_index >= current_settlement.building_slot_count:
		return

	selected_building_slot_index = slot_index
	delete_building_button.visible = true

func _on_delete_building_button_pressed() -> void:
	if current_settlement == null:
		return
	if selected_building_slot_index == -1:
		return

	building_delete_requested.emit(selected_building_slot_index)

func _on_mercenary_button_pressed() -> void:
	if current_settlement == null:
		return

	var success := current_settlement.hire_mercenaries()
	if success:
		show_settlement_details(current_settlement)
	else:
		print("Could not hire mercenaries.")

func _update_mercenary_button(s: Settlement) -> void:
	var is_orc_turn := TurnState.current_turn == Faction.Type.ORC

	if not is_orc_turn:
		mercenary_button.visible = false
		return

	mercenary_button.visible = true

	var cost := s.get_mercenary_gold_cost()
	var gain := s.get_mercenary_soldier_gain()

	mercenary_button.text = "Hire 
	Mercenaries 
	(+%d soldiers,
	 %d gold)" % [gain, cost]

	if s.faction != TurnState.current_turn:
		mercenary_button.disabled = true
	elif s.mercenaries_hired_this_turn:
		mercenary_button.disabled = true
	elif TurnState.get_gold(s.faction) < cost:
		mercenary_button.disabled = true
	else:
		mercenary_button.disabled = false

# =========================
# Faction action UI
# =========================

func show_faction_actions(actions: Array) -> void:
	for child in faction_actions_container.get_children():
		child.queue_free()

	for action in actions:
		var button := Button.new()
		var action_id : String = action.id

		button.text = action.label
		button.disabled = not action.enabled
		button.pressed.connect(func(): action_requested.emit(action_id))

		faction_actions_container.add_child(button)

# =========================
# Dwarf build UI
# =========================

func show_dwarf_build_options() -> void:
	dwarf_building_menu.visible = true

func hide_dwarf_build_options() -> void:
	dwarf_building_menu.visible = false

func show_dwarf_hoard_panel() -> void:
	dwarf_hoard_panel.visible = true

func hide_dwarf_hoard_panel() -> void:
	dwarf_hoard_panel.visible = false

# =========================
# Dwarf hoard UI
# =========================

func show_dwarf_gold_assignment_picker(threshold: int) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Assign Gold Action (%d)" % threshold

	var container := VBoxContainer.new()
	dialog.add_child(container)

	var actions = ["build", "march", "train", "mine", "smith"]

	for action in actions:
		var action_id : String = action
		var button := Button.new()

		button.text = _pretty_action_name(action_id)
		button.pressed.connect(func():
			dwarf_gold_action_chosen.emit(threshold, action_id)
			dialog.queue_free()
		)

		container.add_child(button)

	add_child(dialog)
	dialog.popup_centered()

func update_dwarf_hoard_panel(controller: DwarfController) -> void:
	for threshold in hoard_buttons.keys():
		var t: int = threshold
		var button: Button = hoard_buttons[t]
		_update_hoard_button(t, button, controller)

func _update_hoard_button(threshold: int, button: Button, controller: DwarfController) -> void:
	if not controller.is_gold_threshold_active(threshold):
		button.text = "?"
		button.disabled = true
		return

	var assigned := controller.get_gold_assignment(threshold)

	if assigned == "":
		button.text = "Assign"
		button.disabled = false
	else:
		button.text = _pretty_action_name(assigned)
		button.disabled = true
