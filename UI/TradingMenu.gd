extends PanelContainer
class_name TradingMenu

@onready var faction_option: OptionButton = $VBoxContainer/FactionOption
@onready var food_edit: LineEdit = $VBoxContainer/FoodRow/FoodEdit
@onready var lumber_edit: LineEdit = $VBoxContainer/LumberRow/LumberEdit
@onready var minerals_edit: LineEdit = $VBoxContainer/MineralsRow/MineralsEdit

@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var accept_button: Button = $VBoxContainer/ButtonsRow/AcceptButton
@onready var cancel_button: Button = $VBoxContainer/ButtonsRow/CancelButton

var _index_to_faction: Array[Faction.Type] = []

func _ready() -> void:
	accept_button.pressed.connect(_on_accept_pressed)
	cancel_button.pressed.connect(close)

	visible = false
	message_label.text = ""

func open_for_current_turn() -> void:
	visible = true
	message_label.text = ""

	# Reset fields
	lumber_edit.text = "0"
	food_edit.text = "0"
	minerals_edit.text = "0"

	# Populate faction choices excluding current
	_rebuild_faction_options(TurnState.current_turn)

func close() -> void:
	visible = false

func _rebuild_faction_options(current: Faction.Type) -> void:
	faction_option.clear()
	_index_to_faction.clear()

	var choices: Array[Faction.Type] = [Faction.Type.ORC, Faction.Type.ELF, Faction.Type.DWARF]
	for f in choices:
		if f == current:
			continue
		faction_option.add_item(_faction_name(f))
		_index_to_faction.append(f)

	faction_option.select(0)

func _on_accept_pressed() -> void:
	message_label.text = ""

	var from_f := TurnState.current_turn
	var to_f : int = _get_selected_trade_partner()
	if to_f == null:
		return

	var offer := {
		ResourceClass.Type.LUMBER: _read_int_or_zero(lumber_edit.text),
		ResourceClass.Type.FOOD: _read_int_or_zero(food_edit.text),
		ResourceClass.Type.MINERALS: _read_int_or_zero(minerals_edit.text),
	}

	# Optional: prevent “empty trade”
	if offer[ResourceClass.Type.LUMBER] == 0 and offer[ResourceClass.Type.FOOD] == 0 and offer[ResourceClass.Type.MINERALS] == 0:
		message_label.text = "Enter amounts to trade."
		return

	var ok := TurnState.try_trade(from_f, to_f, offer)
	if not ok:
		message_label.text = "Not enough resources to trade"
		return

	# Success: close menu (or leave open if you prefer)
	close()

func _get_selected_trade_partner() -> Variant:
	var idx := faction_option.selected
	if idx < 0 or idx >= _index_to_faction.size():
		return null
	return _index_to_faction[idx]

func _read_int_or_zero(s: String) -> int:
	# Simple safe parse
	var t := s.strip_edges()
	if t == "":
		return 0
	var n := int(t)
	return max(0, n)

func _faction_name(f: Faction.Type) -> String:
	match f:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Unknown"
