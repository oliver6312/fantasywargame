extends Area2D
class_name Settlement

signal clicked(settlement: Settlement)

@onready var selection_circle: Sprite2D = $SelectionCircle
@onready var available_circle: Sprite2D = $AvailableCircle

@export var settlement_id: String = ""  # optional, useful later

@export var settlement_name: String = ""
@onready var name_label: Label = $NameLabel

@export var faction: Faction.Type = Faction.Type.NEUTRAL : set = set_faction
@export var soldiers: int = 0 : set = set_soldiers

# Connections: store references to other settlements.
# We'll fill this in manually in the editor at first (simple + reliable).
@export var neighbors: Array[Settlement] = []

@onready var soldier_label: Label = $SoldierLabel

@export_range(1, 3, 1) var building_slot_count: int = 1 : set = set_building_slot_count

# For now, each slot just stores a string.
# Empty string = no building in that slot.
@export var building_slots: Array[String] = []

@onready var building_slot_1: Sprite2D = $BuildingSlot1
@onready var building_slot_2: Sprite2D = $BuildingSlot2
@onready var building_slot_3: Sprite2D = $BuildingSlot3

func _ready() -> void:
	name_label.text = get_display_name()
	add_to_group("settlements")
	_make_neighbors_two_way()
	_refresh_visuals()
	_refresh_building_slot_visuals()
	_validate_neighbors()
	selection_circle.visible = false
	available_circle.visible = false
	name_label.visible = false

func get_building_in_slot(index: int) -> String:
	if index < 0 or index >= building_slots.size():
		return ""
	return building_slots[index]

func set_building_in_slot(index: int, building_name: String) -> void:
	if index < 0 or index >= building_slots.size():
		return
	building_slots[index] = building_name

func get_building_slot_display_name(index: int) -> String:
	var building := get_building_in_slot(index)
	if building == "":
		return "Empty"
	return building

func _refresh_building_slot_visuals() -> void:
	if building_slot_1 == null:
		return

	building_slot_1.visible = building_slot_count >= 1
	building_slot_2.visible = building_slot_count >= 2
	building_slot_3.visible = building_slot_count >= 3

func set_building_slot_count(value: int) -> void:
	building_slot_count = clamp(value, 1, 3)
	_resize_building_slots()
	_refresh_building_slot_visuals()

func _resize_building_slots() -> void:
	while building_slots.size() < building_slot_count:
		building_slots.append("")

	while building_slots.size() > building_slot_count:
		building_slots.remove_at(building_slots.size() - 1)

func get_display_name() -> String:
	return settlement_name if settlement_name != "" else name

func set_selected(is_selected: bool) -> void:
	selection_circle.visible = is_selected
	name_label.visible = is_selected
	if is_selected:
		name_label.text = get_display_name()

func set_available(is_available: bool) -> void:
	available_circle.visible = is_available

func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", self)
		print("settlement clicked")
		$SelectionCircle.show()

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
	_refresh_visuals()

func set_garrison(new_faction: Faction.Type, amount: int) -> void:
	soldiers = max(0, amount)
	faction = new_faction
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

func is_adjacent_to(other: Settlement) -> bool:
	return neighbors.has(other)

func can_receive_faction(incoming: Faction.Type) -> bool:
	# Placeholder rule. You might later restrict neutral-only movement etc.
	return true
