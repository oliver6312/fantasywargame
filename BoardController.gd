extends Node

@onready var ui: CanvasLayer = _find_ui()

@onready var move_dialog: AcceptDialog = ui.get_node("%MoveDialog") as AcceptDialog
@onready var amount_edit: LineEdit = ui.get_node("%AmountEdit") as LineEdit
@onready var prompt_label: Label = ui.get_node_or_null("%PromptLabel") as Label
@onready var deselect_button: Button = ui.get_node("%DeselectButton") as Button

@onready var building_panel: Control = ui.get_node("%BuildingPanel") as Control
@onready var recruitment_button: TextureButton = ui.get_node("%RecruitmentBuildingButton") as TextureButton

@export var recruitment_building_scene: PackedScene

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
	
	recruitment_button.pressed.connect(func(): _on_building_chosen("recruitment"))
	_refresh_building_panel()
	for s in get_tree().get_nodes_in_group("settlements"):
	# connect settlement clicks as you already do
	# now connect each settlement's slots
		for slot_node in s.get_children():
			if slot_node is BuildingSlot:
				slot_node.clicked.connect(_on_building_slot_clicked)

func _on_building_slot_clicked(slot: BuildingSlot) -> void:
	# slot belongs to some settlement; find it
	var slot_settlement := slot.get_parent() as Settlement
	# If your slot scene is nested, use get_parent().get_parent() etc.

	if slot_settlement == null:
		return

	# If you clicked a slot on a different settlement, select that settlement
	if selected != slot_settlement:
		_select(slot_settlement)

	# Select the slot (and deselect previous slot)
	_select_slot(slot)

func _select_slot(slot: BuildingSlot) -> void:
	if selected_slot != null:
		selected_slot.set_selected(false)

	selected_slot = slot
	selected_slot.set_selected(true)

	_refresh_building_panel()

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

	if selected_slot != null:
		selected_slot.set_selected(false)
		selected_slot = null
	selected_building_id = ""

	_apply_selection_visuals()
	_refresh_building_panel()
	print("Selected: %s (%s soldiers)" % [selected.name, selected.soldiers])
	_show_deselect_button(true)

func _deselect() -> void:
	selected = null
	pending_target = null

	if selected_slot != null:
		selected_slot.set_selected(false)
		selected_slot = null

	selected_building_id = ""
	_clear_all_highlights()
	_show_deselect_button(false)
	_refresh_building_panel()

func _can_build_recruitment() -> bool:
	if selected == null or selected_slot == null:
		return false
	if selected_slot.occupied:
		return false
	# Optional: only allow building on your turn
	if selected.faction != TurnState.current_turn:
		return false
	return true

func _refresh_building_panel() -> void:
	var can_recruit := _can_build_recruitment()
	recruitment_button.disabled = not can_recruit
	# If you have an “available circle” overlay, toggle it here too.

func _on_building_chosen(id: String) -> void:
	selected_building_id = id
	_try_place_selected_building()

func _try_place_selected_building() -> void:
	if selected_building_id == "":
		return
	if selected_building_id == "recruitment":
		if not _can_build_recruitment():
			return

		_place_recruitment_building(selected, selected_slot)
		_deselect() # optional: auto clear after building, feels boardgame-y

func _place_recruitment_building(_settlement: Settlement, slot: BuildingSlot) -> void:
	var b := recruitment_building_scene.instantiate() as Node2D
	slot.add_child(b)
	b.position = Vector2.ZERO
	slot.occupied = true

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
