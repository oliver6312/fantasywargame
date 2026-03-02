extends CanvasLayer

@onready var next_turn_button: Button = %NextTurnButton
@onready var faction_turn_label: Label = $RightPanel/HBoxContainerTop/VBoxContainer/FactionTurnLabel

@onready var round_label: Label = $RightPanel/HBoxContainerTop/VBoxContainer/RoundLabel

@onready var trade_button: Button = %TradeButton
@onready var trading_menu: TradingMenu = %TradingMenu

@onready var actions_label: Label = %ActionsLabel

func _ready() -> void:
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	TurnState.turn_changed.connect(_on_turn_changed)
	TurnState.round_changed.connect(_on_round_changed)

	# Initialize label immediately
	_on_turn_changed(TurnState.current_turn)
	_on_round_changed(TurnState.round)
	
	trade_button.pressed.connect(_on_trade_pressed)
	
	TurnState.actions_changed.connect(_on_actions_changed)
	_on_actions_changed(TurnState.current_turn, TurnState.actions_left)

func _on_actions_changed(_f: Faction.Type, left: int) -> void:
	actions_label.text = "Actions: %d/%d" % [left, TurnState.ACTIONS_PER_TURN]

func _on_round_changed(r: int) -> void:
	round_label.text = "Round: %d" % r

func _on_trade_pressed() -> void:
	trading_menu.open_for_current_turn()

func _on_next_turn_pressed() -> void:
	TurnState.next_turn()

func _on_turn_changed(new_turn: Faction.Type) -> void:
	faction_turn_label.text = "%s turn" % _turn_name(new_turn)

func _turn_name(t: Faction.Type) -> String:
	match t:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Unknown"
