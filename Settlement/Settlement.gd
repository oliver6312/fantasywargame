extends Area2D
class_name Settlement

#real one

signal clicked(settlement: Settlement)

@export var resource_type: ResourceClass.Type = ResourceClass.Type.FOOD : set = set_resource_type

@onready var lumber_icon: Sprite2D = $Lumber
@onready var mineral_icon: Sprite2D = $Mineral
@onready var food_icon: Sprite2D = $Food

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

#thegoodkind
@onready var soldier_label: Label = $SoldierLabel
#thegoodkind
@export_range(1, 3, 1) var building_slots: int = 1

@export var buildings: Array[String] = ["", "", ""]

@onready var slot_sprites: Array[Sprite2D] = [
	%Slot1Sprite,
	%Slot2Sprite,
	%Slot3Sprite
]

@onready var slot_icons: Array[Sprite2D] = [
	%Slot1Icon,
	%Slot2Icon,
	%Slot3Icon
]



func _ready() -> void:
	name_label.visible = false
	name_label.text = get_display_name()
	add_to_group("settlements")
	_make_neighbors_two_way()
	_refresh_visuals()
	_refresh_resource_icon()
	_validate_neighbors()
	selection_circle.visible = false
	available_circle.visible = false
	_refresh_slot_sprites()
	_refresh_building_icons()

func _refresh_building_icons() -> void:
	var slots : int = clamp(building_slots, 1, 3)
	var db := _building_db()
	print("DB node:", db)

	for i in range(3):
		# Only show icons for active slots
		slot_icons[i].visible = (i < slots)

		if i >= slots:
			continue

		var b_id := buildings[i]
		if b_id == "":
			slot_icons[i].texture = null
			continue

		if db == null:
			# If DB not found, fail gracefully
			slot_icons[i].texture = null
			continue

		var def: BuildingDef = db.get_def_by_id(b_id)
		slot_icons[i].texture = def.icon if def != null else null

func _building_db() -> Node:
	# Try common autoload names (case-sensitive)
	var db := get_node_or_null("/root/BuildingDB")
	if db != null:
		return db
	db = get_node_or_null("/root/Buildingdb")
	if db != null:
		return db
	db = get_node_or_null("/root/buildingdb")
	return db

func _refresh_slot_sprites() -> void:
	var slots : int = clamp(building_slots, 1, 3)
	for i in range(3):
		slot_sprites[i].visible = (i < slots)

func set_building(slot_index: int, building_id: String) -> void:
	# slot_index: 0..2
	if slot_index < 0 or slot_index >= 3:
		return
	if slot_index >= building_slots:
		return
	buildings[slot_index] = building_id
	_refresh_building_icons()

func building_in_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= 3:
		return ""
	return buildings[slot_index]

func set_resource_type(value: ResourceClass.Type) -> void:
	resource_type = value
	_refresh_resource_icon()

func _refresh_resource_icon() -> void:
	# Hide all first
	if lumber_icon: lumber_icon.visible = false
	if food_icon: food_icon.visible = false
	if mineral_icon: mineral_icon.visible = false

	# Show the correct one
	match resource_type:
		ResourceClass.Type.LUMBER:
			if lumber_icon: lumber_icon.visible = true
		ResourceClass.Type.FOOD:
			if food_icon: food_icon.visible = true
		ResourceClass.Type.MINERALS:
			if mineral_icon: mineral_icon.visible = true

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
