extends Node

@onready var deselect_button: Button = %DeselectButton

@export_node_path("CanvasLayer") var ui_path
@onready var ui: CanvasLayer = get_node(ui_path)

@onready var move_dialog: AcceptDialog = ui.get_node("MoveDialog")
@onready var amount_edit: LineEdit = move_dialog.get_node("AmountEdit")
@onready var prompt_label: Label = move_dialog.get_node_or_null("PromptLabel")

var selected: Settlement = null
var pending_target: Settlement = null

func _ready() -> void:
	# Connect all settlements
	for s in get_tree().get_nodes_in_group("settlements"):
		s.clicked.connect(_on_settlement_clicked)

	move_dialog.confirmed.connect(_on_move_confirmed)
	move_dialog.canceled.connect(_on_move_canceled)
	deselect_button.pressed.connect(_on_deselect_pressed)
	_show_deselect_button(false)

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

func _deselect() -> void:
	selected = null
	pending_target = null
	_clear_all_highlights()
	_show_deselect_button(false)

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
	TurnState.recalculate_control_from_board()
	_deselect()
