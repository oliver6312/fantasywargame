extends PanelContainer
class_name BuildingMenu

signal building_chosen(building: BuildingDef)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var list_container: VBoxContainer = $VBoxContainer/ListContainer


func open_for_faction(f: Faction.Type) -> void:
	visible = true

	title_label.text = "%s Buildings" % _faction_name(f)

	# Clear previous
	for c in list_container.get_children():
		c.queue_free()

	# Populate
	for b in BuildingDB.buildings_for_faction(f):
		var btn := Button.new()
		btn.text = _button_text(b)
		btn.pressed.connect(func(): emit_signal("building_chosen", b))
		list_container.add_child(btn)

func close() -> void:
	visible = false

func _button_text(b: BuildingDef) -> String:
	return "%s  (L:%d F:%d M:%d)" % [
		b.display_name,
		b.cost_lumber,
		b.cost_food,
		b.cost_minerals
	]

func _faction_name(f: Faction.Type) -> String:
	match f:
		Faction.Type.ORC: return "Orc"
		Faction.Type.ELF: return "Elf"
		Faction.Type.DWARF: return "Dwarf"
		_: return "Unknown"
