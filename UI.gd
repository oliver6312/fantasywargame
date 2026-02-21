extends CanvasLayer


@onready var turn_label: Label = $TurnLabel
@onready var next_turn_button: Button = $NextTurnButton


func _ready() -> void:
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	TurnState.turn_changed.connect(_on_turn_changed)

	# Initialize label immediately
	_on_turn_changed(TurnState.current_turn)

func _on_next_turn_pressed() -> void:
	TurnState.next_turn()

func _on_turn_changed(new_turn: Faction.Type) -> void:
	turn_label.text = "%s turn" % _turn_name(new_turn)

func _turn_name(t: Faction.Type) -> String:
	match t:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Unknown"
