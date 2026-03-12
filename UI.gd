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

@onready var round_label: Label = %RoundLabel

@onready var settlement_panel: Control = %SettlementDetailPanel
@onready var settlement_name: Label = %SettlementNameLabel
@onready var settlement_faction: Label = %SettlementFactionLabel
@onready var settlement_soldiers: Label = %SettlementSoldiersLabel

func _ready() -> void:
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	TurnState.turn_changed.connect(_on_turn_changed)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_quit_game)

	# Initialize label immediately
	_on_turn_changed(TurnState.current_turn)

	TurnState.round_changed.connect(_on_round_changed)

	round_label.text = "Round %d" % TurnState.round

func show_settlement_details(s:Settlement):

	settlement_panel.visible = true

	settlement_name.text = s.get_display_name()
	settlement_soldiers.text = "Soldiers: %d" % s.soldiers

	match s.faction:
		Faction.Type.ORC:
			settlement_faction.text = "Faction: Orc"
		Faction.Type.ELF:
			settlement_faction.text = "Faction: Elf"
		Faction.Type.DWARF:
			settlement_faction.text = "Faction: Dwarf"
		_:
			settlement_faction.text = "Faction: Neutral"

func _on_round_changed(new_round:int):
	round_label.text = "Round %d" % new_round

func _open_settings():
	settings_dialog.popup_centered()

func hide_settlement_details():
	settlement_panel.visible = false

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
