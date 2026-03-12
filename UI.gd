extends CanvasLayer
class_name BoardUI

@onready var next_turn_button: Button = $LeftPanel/HBoxContainerBottom/VBoxContainer/NextTurnButton
@onready var turn_label: Label = $LeftPanel/HBoxContainerTop/VBoxContainer/TurnLabel

@onready var move_dialog: AcceptDialog = %MoveDialog
@onready var amount_edit: LineEdit = %AmountEdit
@onready var prompt_label: Label = %PromptLabel
@onready var deselect_button: Button = %DeselectButton

@onready var settings_button: Button = %SettingsButton
@onready var settings_dialog: Window = %SettingsDialog
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	TurnState.turn_changed.connect(_on_turn_changed)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_quit_game)

	# Initialize label immediately
	_on_turn_changed(TurnState.current_turn)

func _open_settings():
	settings_dialog.popup_centered()

func _quit_game():
	get_tree().quit()

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
