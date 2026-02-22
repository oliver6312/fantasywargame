extends Area2D
class_name BuildingSlot

signal clicked(slot: BuildingSlot)

@export_range(1, 3, 1) var slot_index: int = 1

@onready var select_circle: Sprite2D = $SlotSelectCircle

var occupied: bool = false

func _ready() -> void:
	input_pickable = true
	select_circle.visible = false

func set_selected(is_selected: bool) -> void:
	select_circle.visible = is_selected

func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", self)
