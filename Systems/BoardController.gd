extends Node

@export_node_path("BoardUI") var ui_path
@onready var ui: BoardUI = get_node(ui_path)

@onready var move_dialog: AcceptDialog = ui.move_dialog
@onready var amount_edit: LineEdit = ui.amount_edit
@onready var prompt_label: Label = ui.prompt_label
@onready var deselect_button: Button = ui.deselect_button

var selected: Settlement = null
var pending_target: Settlement = null

var rng := RandomNumberGenerator.new()

var pending_is_attack: bool = false

#ui.action_requested.connect(_on_action_requested)

@onready var attacker_armor_edit: LineEdit = ui.attacker_armor_edit
@onready var defender_armor_edit: LineEdit = ui.defender_armor_edit
@onready var attacker_armor_label: Label = ui.attacker_armor_label
@onready var defender_armor_label: Label = ui.defender_armor_label

func _ready() -> void:
	rng.randomize()
	# Connect all settlements
	for s in get_tree().get_nodes_in_group("settlements"):
		s.clicked.connect(_on_settlement_clicked)

	move_dialog.confirmed.connect(_on_move_confirmed)
	move_dialog.canceled.connect(_on_move_canceled)
	deselect_button.pressed.connect(_on_deselect_pressed)
	TurnState.turn_changed.connect(_on_turn_changed)
	ui.action_requested.connect(_on_action_requested)
	_show_deselect_button(false)
	_on_turn_changed(TurnState.current_turn)
	ui.dwarf_gold_action_chosen.connect(_on_dwarf_gold_action_chosen)
	ui.dwarf_gold_assignment_requested.connect(_on_dwarf_gold_assignment_requested)

func _on_dwarf_gold_assignment_requested(threshold: int) -> void:
	if TurnState.current_faction_controller is DwarfController:
		TurnState.current_faction_controller.request_gold_assignment(threshold)

func _on_dwarf_gold_action_chosen(threshold: int, action_type: String) -> void:

	if TurnState.current_faction_controller == null:
		return

	if TurnState.current_faction_controller is DwarfController:
		TurnState.current_faction_controller.assign_gold_action(threshold, action_type)

func _on_action_requested(action_id: String) -> void:
	if TurnState.current_faction_controller == null:
		return

	TurnState.current_faction_controller.handle_action(action_id)

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

func _make_command_context() -> CommandContext:
	var ctx := CommandContext.new()
	ctx.current_faction = TurnState.current_turn
	ctx.board = self
	ctx.ui = ui
	return ctx

func _on_turn_changed(new_turn: int) -> void:
	TurnState.current_faction_controller = _build_faction_controller(new_turn)
	TurnState.current_faction_controller.start_turn()
	ui.show_faction_actions(TurnState.current_faction_controller.get_action_list())

	for s in get_tree().get_nodes_in_group("settlements"):
		if s.faction == new_turn:
			s.reset_turn_limited_actions()

	if selected != null and ui != null:
		ui.show_settlement_details(selected)

func _faction_name(faction: int) -> String:
	match faction:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Neutral"

func _apply_season_effect_to_movement(amount: int) -> int:
	if TurnState.current_season == TurnState.Season.WINTER:
		var loss := rng.randi_range(1, 6)
		loss = min(loss, amount)
		print("Winter effect: lost %d soldiers to the cold." % loss)
		return amount - loss

	return amount

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
	for s in get_tree().get_nodes_in_group("settlements"):
		s.set_selected(false)
		s.set_available(false)

func _apply_selection_visuals() -> void:
	_clear_all_highlights()

	if selected == null:
		return

	selected.set_selected(true)

	for n in selected.neighbors:
		if n != null:
			n.set_available(true)

func _on_settlement_clicked(s: Settlement) -> void:
	# First click selects
	if selected == null:
		_select(s)
		return

	# Clicking same settlement just re-selects (or could deselect)
	if s == selected:
		_select(s)
		return

	# If not adjacent, switch selection
	if not selected.is_adjacent_to(s):
		_select(s)
		return

	# Adjacent: prompt for amount to send
	# Optional rule (very recommended): only move from current turn’s faction
	if selected.faction != TurnState.current_turn:
		print("Not your turn to move that faction.")
		_select(s) # or keep selection; your choice
		return
	if TurnState.current_faction_controller != null:
		if not TurnState.current_faction_controller.can_start_move_from_settlement(selected):
			print("You cannot move from that settlement right now.")
			return

	# Must have soldiers to send
	if selected.soldiers <= 0:
		print("No soldiers to move.")
		return

	pending_target = s
	_open_move_dialog(selected, pending_target)

func _select(s: Settlement) -> void:
	selected = s
	_apply_selection_visuals()
	ui.show_settlement_details(s)
	print("Selected: %s (%s soldiers)" % [selected.name, selected.soldiers])

	if TurnState.current_faction_controller != null:
		TurnState.current_faction_controller.on_settlement_selected(s)
	
	_show_deselect_button(true)

func _deselect() -> void:
	selected = null
	pending_target = null
	_clear_all_highlights()
	ui.hide_settlement_details()
	_show_deselect_button(false)

func _open_move_dialog(source: Settlement, target: Settlement) -> void:
	var max_send := source.soldiers
	var is_attack := target.faction != source.faction

	pending_is_attack = is_attack

	if prompt_label:
		prompt_label.text = "Send how many soldiers from %s to %s? (1-%d)" % [
			source.get_display_name(), target.get_display_name(), max_send
		]

	amount_edit.text = ""
	amount_edit.placeholder_text = "1-%d" % max_send

	attacker_armor_edit.text = ""
	defender_armor_edit.text = ""

	attacker_armor_label.text = "%s's armor used" % _faction_name(source.faction)
	defender_armor_label.text = "%s's armor used" % _faction_name(target.faction)

	if is_attack:
		attacker_armor_label.visible = true
		attacker_armor_edit.visible = true

		if target.faction == Faction.Type.NEUTRAL:
			defender_armor_label.visible = false
			defender_armor_edit.visible = false
		else:
			defender_armor_label.visible = true
			defender_armor_edit.visible = true
	else:
		attacker_armor_label.visible = false
		attacker_armor_edit.visible = false
		defender_armor_label.visible = false
		defender_armor_edit.visible = false

	amount_edit.grab_focus()
	move_dialog.popup_centered()

func _on_move_canceled() -> void:
	pending_target = null

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
		else:
			defender_armor = 0

		# Only check against armor stockpile here
		if attacker_armor > TurnState.get_armor(source.faction):
			print("Not enough attacker armor.")
			return

		if target.faction != Faction.Type.NEUTRAL and defender_armor > TurnState.get_armor(target.faction):
			print("Not enough defender armor.")
			return

	var arriving_amount := _apply_season_effect_to_movement(amount)

	# Clamp armor AFTER winter / soldier changes
	if pending_is_attack:
		attacker_armor = min(attacker_armor, arriving_amount)
		defender_armor = min(defender_armor, target.soldiers)

		_execute_attack(source, target, arriving_amount, amount, attacker_armor, defender_armor)
	else:
		_execute_move(source, target, arriving_amount, amount)

func _execute_move(source: Settlement, target: Settlement, arriving_amount: int, original_amount: int) -> void:
	source.set_soldiers(source.soldiers - original_amount)

	if target.faction == source.faction:
		target.set_soldiers(target.soldiers + arriving_amount)
	else:
		# Neutral capture / regular no-resistance behavior, adjust if you want
		var result := target.soldiers - arriving_amount

		if result > 0:
			target.set_soldiers(result)
		elif result == 0:
			target.set_soldiers(0)
		else:
			target.set_garrison(source.faction, -result)

	if TurnState.current_faction_controller != null:
		TurnState.current_faction_controller.after_successful_move(source, target)

	_deselect()

func _execute_attack(
	source: Settlement,
	target: Settlement,
	attacking_soldiers_after_season: int,
	original_sent_amount: int,
	attacker_armor_used: int,
	defender_armor_used: int
	) -> void:
	# Remove the originally sent soldiers from the source no matter what
	source.set_soldiers(source.soldiers - original_sent_amount)

	# Spend armor from both factions' pools
	if attacker_armor_used > 0:
		TurnState.add_armor(source.faction, -attacker_armor_used)

	if target.faction != Faction.Type.NEUTRAL and defender_armor_used > 0:
		TurnState.add_armor(target.faction, -defender_armor_used)

	# Battle values
	var atk_armor := attacker_armor_used
	var atk_soldiers := attacking_soldiers_after_season

	var def_armor := defender_armor_used
	var def_soldiers := target.soldiers

	# Defender damage taken from attacker:
	var attacker_power := atk_armor + atk_soldiers
	def_armor -= attacker_power

	if def_armor < 0:
		def_soldiers += def_armor # def_armor is negative, so this subtracts from soldiers
		def_armor = 0

	# Attacker damage taken from defender:
	var defender_power := defender_armor_used + target.soldiers
	atk_armor -= defender_power

	if atk_armor < 0:
		atk_soldiers += atk_armor # atk_armor is negative, so this subtracts from soldiers
		atk_armor = 0

	atk_soldiers = max(0, atk_soldiers)
	def_soldiers = max(0, def_soldiers)

	# Resolve result based on remaining soldiers only
	if def_soldiers > 0 and atk_soldiers <= 0:
		target.set_soldiers(def_soldiers)
	elif atk_soldiers > 0 and def_soldiers <= 0:
		target.set_garrison(source.faction, atk_soldiers)
	elif atk_soldiers <= 0 and def_soldiers <= 0:
		target.set_soldiers(0)
	else:
		# This should not normally happen with simultaneous resolution,
		# but keep the defender if both somehow still have soldiers.
		target.set_soldiers(def_soldiers)

	print("Attack resolved. Attacker remaining soldiers: %d, Defender remaining soldiers: %d" % [
		atk_soldiers, def_soldiers
	])

	if TurnState.current_faction_controller != null:
		TurnState.current_faction_controller.after_successful_move(source, target)

	_deselect()
