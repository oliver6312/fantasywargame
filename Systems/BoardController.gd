extends Node
const CombatResolver = preload("res://Systems/combat_resolver.gd")

@export_node_path("BoardUI") var ui_path
@onready var ui: BoardUI = get_node(ui_path)

@onready var move_dialog: AcceptDialog = ui.move_dialog
@onready var amount_edit: LineEdit = ui.amount_edit
@onready var prompt_label: Label = ui.prompt_label
@onready var deselect_button: Button = ui.deselect_button

@onready var attacker_armor_edit: LineEdit = ui.attacker_armor_edit
@onready var defender_armor_edit: LineEdit = ui.defender_armor_edit
@onready var attacker_armor_label: Label = ui.attacker_armor_label
@onready var defender_armor_label: Label = ui.defender_armor_label

var selected: Settlement = null
var pending_target: Settlement = null
var pending_is_attack: bool = false

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_connect_settlement_signals()
	_connect_ui_signals()
	_connect_game_signals()

	_show_deselect_button(false)
	_on_turn_changed(TurnState.current_turn)

# =========================
# Setup
# =========================

func _connect_settlement_signals() -> void:
	for settlement in get_tree().get_nodes_in_group("settlements"):
		settlement.clicked.connect(_on_settlement_clicked)

func _connect_ui_signals() -> void:
	move_dialog.confirmed.connect(_on_move_confirmed)
	move_dialog.canceled.connect(_on_move_canceled)
	deselect_button.pressed.connect(_on_deselect_pressed)

	ui.trade_requested.connect(_on_trade_requested)
	ui.action_requested.connect(_on_action_requested)
	ui.dwarf_gold_action_chosen.connect(_on_dwarf_gold_action_chosen)
	ui.dwarf_gold_assignment_requested.connect(_on_dwarf_gold_assignment_requested)
	ui.dwarf_build_requested.connect(_on_dwarf_build_requested)
	ui.war_meeting_finished.connect(_on_war_meeting_finished)
	ui.building_delete_requested.connect(_on_building_delete_requested)

func _connect_game_signals() -> void:
	TurnState.turn_changed.connect(_on_turn_changed)
	TurnState.resources_changed.connect(_on_resources_changed)

func _make_command_context() -> CommandContext:
	var context := CommandContext.new()
	context.board = self
	context.ui = ui
	context.turn_state = TurnState
	context.current_faction = TurnState.current_turn
	return context

# =========================
# Controller helpers
# =========================

func _run_command(command: GameCommand) -> bool:
	var context := _make_command_context()

	if not command.validate(context):
		print(command.get_error(context))
		return false

	command.execute(context)
	return true

func _controller() -> FactionController:
	return TurnState.current_faction_controller

func _dwarf_controller() -> DwarfController:
	var controller := _controller()
	if controller is DwarfController:
		return controller
	return null

func _build_faction_controller(faction: int) -> FactionController:
	var controller: FactionController

	match faction:
		Faction.Type.ORC:
			controller = OrcController.new()
		Faction.Type.ELF:
			controller = ElfController.new()
		Faction.Type.DWARF:
			controller = DwarfController.new()
		_:
			controller = FactionController.new()

	controller.setup(faction, self, ui)
	return controller

func _faction_name(faction: int) -> String:
	match faction:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Neutral"

# =========================
# Turn / resource updates
# =========================

func _on_turn_changed(new_turn: int) -> void:
	TurnState.current_faction_controller = _build_faction_controller(new_turn)

	var controller := _controller()
	controller.start_turn()
	ui.show_faction_actions(controller.get_action_list())

	for settlement in get_tree().get_nodes_in_group("settlements"):
		if settlement.faction == new_turn:
			settlement.reset_turn_limited_actions()

	if selected != null:
		ui.show_settlement_details(selected)

	if controller.is_in_war_meeting():
		ui.show_war_meeting_button()
	else:
		ui.hide_war_meeting_button()

func _on_resources_changed() -> void:
	var dwarf := _dwarf_controller()
	if dwarf != null:
		dwarf.on_resources_changed()

func _on_trade_requested(receiver_faction: int, gold_amount: int, armor_amount: int) -> void:
	var command := TradeCommand.new()
	command.sender_faction = TurnState.current_turn
	command.receiver_faction = receiver_faction
	command.gold_amount = gold_amount
	command.armor_amount = armor_amount

	_run_command(command)

# =========================
# UI action routing
# =========================

func _on_action_requested(action_id: String) -> void:
	var controller := _controller()
	if controller != null:
		controller.handle_action(action_id)

func _on_war_meeting_finished() -> void:
	var controller := _controller()
	if controller != null:
		controller.finish_war_meeting()
		ui.hide_war_meeting_button()

func _on_dwarf_build_requested(building_name: String) -> void:
	var dwarf := _dwarf_controller()
	if dwarf != null:
		dwarf.finish_build(building_name)

func _on_dwarf_gold_assignment_requested(threshold: int) -> void:
	var dwarf := _dwarf_controller()
	if dwarf != null:
		dwarf.request_gold_assignment(threshold)

func _on_dwarf_gold_action_chosen(threshold: int, action_type: String) -> void:
	var dwarf := _dwarf_controller()
	if dwarf != null:
		dwarf.assign_gold_action(threshold, action_type)

func _on_building_delete_requested(slot_index: int) -> void:
	if selected == null:
		return

	var dwarf := _dwarf_controller()
	if dwarf != null:
		dwarf.delete_building(selected, slot_index)

# =========================
# Input / selection
# =========================

func _unhandled_input(event: InputEvent) -> void:
	if selected == null:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_deselect()

func _on_deselect_pressed() -> void:
	_deselect()

func _show_deselect_button(show: bool) -> void:
	deselect_button.visible = show

func _clear_all_highlights() -> void:
	for settlement in get_tree().get_nodes_in_group("settlements"):
		settlement.set_selected(false)
		settlement.set_available(false)

func _apply_selection_visuals() -> void:
	_clear_all_highlights()

	if selected == null:
		return

	selected.set_selected(true)

	for neighbor in selected.neighbors:
		if neighbor != null:
			neighbor.set_available(true)

func _select(settlement: Settlement) -> void:
	selected = settlement
	_apply_selection_visuals()
	ui.show_settlement_details(settlement)

	print("Selected: %s (%s soldiers)" % [selected.name, selected.soldiers])

	var controller := _controller()
	if controller != null:
		controller.on_settlement_selected(settlement)

	_show_deselect_button(true)

func _deselect() -> void:
	selected = null
	pending_target = null
	pending_is_attack = false

	_clear_all_highlights()
	ui.hide_settlement_details()
	_show_deselect_button(false)

func _on_settlement_clicked(settlement: Settlement) -> void:
	if selected == null:
		_select(settlement)
		return

	if settlement == selected:
		_select(settlement)
		return

	if not selected.is_adjacent_to(settlement):
		_select(settlement)
		return

	if not _can_start_move_from_selected():
		return

	if selected.soldiers <= 0:
		print("No soldiers to move.")
		return

	pending_target = settlement
	_open_move_dialog(selected, pending_target)

func _can_start_move_from_selected() -> bool:
	if selected == null:
		return false

	if selected.faction != TurnState.current_turn:
		print("Not your turn to move that faction.")
		return false

	var controller := _controller()
	if controller != null and not controller.can_start_move_from_settlement(selected):
		print("You cannot move from that settlement right now.")
		return false

	return true

# =========================
# Move dialog
# =========================

func _open_move_dialog(source: Settlement, target: Settlement) -> void:
	var max_send := source.soldiers
	var is_attack := target.faction != source.faction

	pending_is_attack = is_attack

	prompt_label.text = "Send how many soldiers from %s to %s? (1-%d)" % [
		source.get_display_name(),
		target.get_display_name(),
		max_send
	]

	amount_edit.text = ""
	amount_edit.placeholder_text = "1-%d" % max_send

	attacker_armor_edit.text = ""
	defender_armor_edit.text = ""

	attacker_armor_label.text = "%s's armor used" % _faction_name(source.faction)
	defender_armor_label.text = "%s's armor used" % _faction_name(target.faction)

	var defender_has_armor := is_attack and target.faction != Faction.Type.NEUTRAL

	attacker_armor_label.visible = is_attack
	attacker_armor_edit.visible = is_attack
	defender_armor_label.visible = defender_has_armor
	defender_armor_edit.visible = defender_has_armor

	amount_edit.grab_focus()
	move_dialog.popup_centered()

func _on_move_canceled() -> void:
	pending_target = null
	pending_is_attack = false

func _on_move_confirmed() -> void:
	if selected == null or pending_target == null:
		return

	var source := selected
	var target := pending_target

	pending_target = null

	var amount := int(amount_edit.text)
	if amount < 1:
		print("Must send at least 1.")
		return

	if amount > source.soldiers:
		print("Cannot send more than you have.")
		return

	var attacker_armor := 0
	var defender_armor := 0

	if pending_is_attack:
		attacker_armor = max(0, int(attacker_armor_edit.text))

		if target.faction != Faction.Type.NEUTRAL:
			defender_armor = max(0, int(defender_armor_edit.text))

		if attacker_armor > TurnState.get_armor(source.faction):
			print("Not enough attacker armor.")
			return

		if target.faction != Faction.Type.NEUTRAL and defender_armor > TurnState.get_armor(target.faction):
			print("Not enough defender armor.")
			return

	var arriving_amount := _apply_season_effect_to_movement(amount)

	var cmd := MoveCommand.new()
	cmd.source = source
	cmd.target = target
	cmd.soldiers = amount
	cmd.is_attack = pending_is_attack

	if pending_is_attack:
		cmd.attacker_armor = attacker_armor
		cmd.defender_armor = defender_armor

	if not _run_command(cmd):
		return

	_deselect()

# =========================
# Move / combat resolution
# =========================

func _apply_season_effect_to_movement(amount: int) -> int:
	if TurnState.current_season == TurnState.Season.WINTER:
		var loss : int = min(rng.randi_range(1, 6), amount)
		print("Winter effect: lost %d soldiers to the cold." % loss)
		return amount - loss

	return amount

func resolve_move_command(cmd: MoveCommand, _context: CommandContext) -> void:
	var source := cmd.source
	var target := cmd.target

	var original_amount := cmd.soldiers
	var arriving_amount := _apply_season_effect_to_movement(original_amount)

	source.set_soldiers(source.soldiers - original_amount)

	if target.faction == source.faction:
		target.set_soldiers(target.soldiers + arriving_amount)
	else:
		var result := target.soldiers - arriving_amount

		if result > 0:
			target.set_soldiers(result)
		elif result == 0:
			target.set_soldiers(0)
		else:
			target.set_garrison(source.faction, -result)

	_finish_successful_move(source, target)

func resolve_attack_command(cmd: MoveCommand, context: CommandContext) -> void:
	var source := cmd.source
	var target := cmd.target

	var original_amount := cmd.soldiers
	var arriving_amount := _apply_season_effect_to_movement(original_amount)

	var attacker_armor := cmd.attacker_armor
	var defender_armor := cmd.defender_armor

	# Clamp AFTER winter
	attacker_armor = min(attacker_armor, arriving_amount)
	defender_armor = min(defender_armor, target.soldiers)

	source.set_soldiers(source.soldiers - original_amount)

	if attacker_armor > 0:
		context.turn_state.add_armor(source.faction, -attacker_armor)

	if target.faction != Faction.Type.NEUTRAL and defender_armor > 0:
		context.turn_state.add_armor(target.faction, -defender_armor)

	var result := CombatResolver.resolve_battle(
		source.faction,
		target.faction,
		arriving_amount,
		target.soldiers,
		attacker_armor,
		defender_armor
	)

	var winning_faction : int = result["winning_faction"]
	var settlement_soldiers : int = result["settlement_soldiers"]

	if winning_faction == source.faction:
		target.set_garrison(source.faction, settlement_soldiers)
	else:
		if settlement_soldiers == 0:
			target.set_soldiers(0)
		else:
			target.set_soldiers(settlement_soldiers)

	print("Attack resolved.")

	_finish_successful_move(source, target)

func _finish_successful_move(source: Settlement, target: Settlement) -> void:
	var controller := _controller()
	if controller != null:
		controller.after_successful_move(source, target)

	_deselect()
