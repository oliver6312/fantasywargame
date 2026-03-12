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

func _ready() -> void:
	rng.randomize()
	# Connect all settlements
	for s in get_tree().get_nodes_in_group("settlements"):
		s.clicked.connect(_on_settlement_clicked)

	move_dialog.confirmed.connect(_on_move_confirmed)
	move_dialog.canceled.connect(_on_move_canceled)
	deselect_button.pressed.connect(_on_deselect_pressed)
	_show_deselect_button(false)

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
	_show_deselect_button(true)

func _deselect() -> void:
	selected = null
	pending_target = null
	_clear_all_highlights()
	ui.hide_settlement_details()
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

	# Apply season effect ONCE
	var arriving_amount := _apply_season_effect_to_movement(amount)

	# Remove the ORIGINAL sent amount from source ONCE
	source.set_soldiers(source.soldiers - amount)

	# If nobody survives the journey, stop here
	if arriving_amount <= 0:
		print("All moving soldiers were lost on the way.")
		_deselect()
		return

	# Resolve the move using ONLY the survivors
	_execute_move(source, target, arriving_amount)

func _execute_move(source: Settlement, target: Settlement, arriving_amount: int) -> void:
	# Same faction = merge
	if target.faction == source.faction:
		target.set_soldiers(target.soldiers + arriving_amount)
		_deselect()
		return

	# Different faction = fight
	var result := target.soldiers - arriving_amount

	if result > 0:
		# Defender survives
		target.set_soldiers(result)
	elif result == 0:
		# Tie: empty but still owned by current faction, if that's your rule
		target.set_soldiers(0)
	else:
		# Attacker wins
		target.set_garrison(source.faction, -result)

	_deselect()
