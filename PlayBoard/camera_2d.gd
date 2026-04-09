extends Camera2D

@export var pan_speed := 1800.0            # keyboard pan speed (px/s)
@export var drag_pan_speed := 2.0         # mouse drag multiplier
@export var zoom_step := 0.2
@export var min_zoom := 0.25
@export var max_zoom := 0.7

@export_node_path("Sprite2D") var map_path
@onready var map_sprite: Sprite2D = get_node(map_path)

var _dragging := false
var _last_mouse := Vector2.ZERO

func _ready() -> void:
	make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(zoom - Vector2.ONE * zoom_step, get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(zoom + Vector2.ONE * zoom_step, get_global_mouse_position())

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
			_last_mouse = get_viewport().get_mouse_position()

	if event is InputEventMouseMotion and _dragging:
		var mpos := get_viewport().get_mouse_position()
		var delta := mpos - _last_mouse
		_last_mouse = mpos

		global_position -= delta * zoom.x * drag_pan_speed


func _process(delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	if dir != Vector2.ZERO:
		global_position += dir * pan_speed * delta * zoom.x


func _set_zoom(new_zoom: Vector2, zoom_anchor_world: Vector2) -> void:
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = new_zoom.x

	var before := zoom_anchor_world
	var old_zoom := zoom
	zoom = new_zoom
	var after := before  

	var mouse_screen := get_viewport().get_mouse_position()
	var anchor_screen_before := (before - global_position) / old_zoom + get_viewport_rect().size * 0.5
	var anchor_screen_after := (before - global_position) / zoom + get_viewport_rect().size * 0.5
	var screen_delta := anchor_screen_after - anchor_screen_before
	global_position += screen_delta * zoom.x
