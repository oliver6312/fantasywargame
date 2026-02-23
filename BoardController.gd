extends Node

@onready var ui: CanvasLayer = _find_ui()

@onready var move_dialog: AcceptDialog = ui.get_node("%MoveDialog") as AcceptDialog
@onready var amount_edit: LineEdit = ui.get_node("%AmountEdit") as LineEdit
@onready var prompt_label: Label = ui.get_node_or_null("%PromptLabel") as Label
@onready var deselect_button: Button = ui.get_node("%DeselectButton") as Button

@export var recruitment_building_scene: PackedScene

@onready var info_panel: Panel = ui.get_node("%SettlementInfoPanel") as Panel

@onready var building_menu: PanelContainer = ui.get_node("%BuildingMenu") as PanelContainer

var selected_slot_index: int = -1

var selected_slot: BuildingSlot = null
var selected_building_id: String = ""  # e.g. "recruitment"

func _find_ui() -> CanvasLayer:
	var nodes := get_tree().get_nodes_in_group("ui_root")
	if nodes.size() == 0:
		push_error("No UI root found. Add the UI CanvasLayer to group 'ui_root'.")
		return null
	return nodes[0] as CanvasLayer

var selected: Settlement = null
var pending_target: Settlement = null

func _ready() -> void:
	#safety check
	if ui == null:
		return
	# Connect all settlements
	for s in get_tree().get_nodes_in_group("settlements"):
		s.clicked.connect(_on_settlement_clicked)

	move_dialog.confirmed.connect(_on_move_confirmed)
	move_dialog.canceled.connect(_on_move_canceled)
	deselect_button.pressed.connect(_on_deselect_pressed)
	_show_deselect_button(false)
	
	info_panel.slot_clicked.connect(_on_building_slot_clicked)
	building_menu.building_chosen.connect(_on_building_chosen)

func _on_building_chosen(b: BuildingDef) -> void:
	if selected == null or selected_slot_index < 0:
		return

	# 2) settlement faction must match current turn
	if selected.faction != TurnState.current_turn:
		print("You can only build in settlements of the current turn’s faction.")
		return

	# Must be a valid slot
	if selected_slot_index >= selected.building_slots:
		return

	# Optional: prevent overwriting non-empty slots
	if selected.building_in_slot(selected_slot_index) != "":
		print("That slot is not empty.")
		return

	# 2) check resources
	var cost := b.cost_dict()
	if not TurnState.can_afford(selected.faction, cost):
		print("Not enough resources.")
		return

	# 3) spend and register building
	if not TurnState.spend_resources(selected.faction, cost):
		return

	selected.set_building(selected_slot_index, b.id)

	# Update panel text immediately
	info_panel.show_for_settlement(selected)

	# Close menu + clear slot selection (optional)
	building_menu.close()
	selected_slot_index = -1

func _on_building_slot_clicked(settlement: Settlement, slot_index: int) -> void:
	# Slot is clicked => selected
	selected_slot_index = slot_index

	# Open menu depending on settlement faction (as requested)
	building_menu.open_for_faction(settlement.faction)

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

	# Must have soldiers to send
	if selected.soldiers <= 0:
		print("No soldiers to move.")
		return

	pending_target = s
	_open_move_dialog(selected, pending_target)

func _select(s: Settlement) -> void:
	selected = s

	_apply_selection_visuals()
	print("Selected: %s (%s soldiers)" % [selected.name, selected.soldiers])
	_show_deselect_button(true)
	info_panel.show_for_settlement(selected)

func _deselect() -> void:
	selected = null
	pending_target = null
	selected_building_id = ""
	_clear_all_highlights()
	_show_deselect_button(false)
	info_panel.hide_panel()

func _open_move_dialog(source: Settlement, target: Settlement) -> void:
	var max_send := source.soldiers
	if prompt_label:
		prompt_label.text = "Send how many soldiers from %s to %s? (1-%d)" % [source.name, target.name, max_send]

	amount_edit.text = ""
	amount_edit.placeholder_text = "1-%d" % max_send
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

	_execute_move(source, target, amount)

func _execute_move(source: Settlement, target: Settlement, amount: int) -> void:
	# Remove from source first
	source.set_soldiers(source.soldiers - amount)

	# Same faction: merge
	if target.faction == source.faction and target.faction != Faction.Type.NEUTRAL:
		target.set_soldiers(target.soldiers + amount)
		return

	# Different faction (including neutral): fight / capture
	var result := target.soldiers - amount

	if result > 0:
		# Defender survives
		target.set_soldiers(result)
		# faction unchanged
	elif result == 0:
		target.set_soldiers(0) # keep faction as-is
	else:
		# Attacker wins: flip faction and survivors = abs(result)
		target.set_garrison(source.faction, -result)
	_deselect()
