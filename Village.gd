extends Area2D
class_name Settlement

signal clicked(settlement: Settlement)

@export var settlement_id: String = ""  # optional, useful later

@export var faction: Faction.Type = Faction.Type.NEUTRAL : set = set_faction
@export var soldiers: int = 0 : set = set_soldiers

# Connections: store references to other settlements.
# We'll fill this in manually in the editor at first (simple + reliable).
@export var neighbors: Array[Settlement] = []

@onready var soldier_label: Label = $SoldierLabel

func _ready() -> void:
	add_to_group("settlements")
	_make_neighbors_two_way()
	_refresh_visuals()
	_validate_neighbors()

func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", self)
		print("settlement clicked")

func _make_neighbors_two_way() -> void:
	# Ensure neighbor list has no nulls or self references
	neighbors = neighbors.filter(func(n): return n != null and n != self)

	# Ensure two-way
	for n in neighbors:
		if not n.neighbors.has(self):
			n.neighbors.append(self)

func set_faction(value: Faction.Type) -> void:
	faction = value
	_refresh_visuals()

func set_soldiers(value: int) -> void:
	soldiers = max(0, value)
	# Rule: ownership follows soldiers. If 0 => neutral (for now).
	if soldiers == 0:
		faction = Faction.Type.NEUTRAL
	_refresh_visuals()

func set_garrison(new_faction: Faction.Type, amount: int) -> void:
	# "Only one faction’s soldiers can be here" enforced here.
	if amount <= 0:
		soldiers = 0
		faction = Faction.Type.NEUTRAL
	else:
		faction = new_faction
		soldiers = amount
	_refresh_visuals()

func _refresh_visuals() -> void:
	if soldier_label == null:
		return

	soldier_label.text = str(soldiers)
	soldier_label.add_theme_color_override("font_color", Faction.color_for(faction))

func _validate_neighbors() -> void:
	for n in neighbors:
		if n == null: 
			continue
		if not n.neighbors.has(self):
			push_warning("%s has neighbor %s but not vice versa" % [name, n.name])
