extends Node2D
class_name ConnectionsDrawer

@export var line_width: float = 6.0
@export var line_color: Color = Color("202020") # dark grey, tweak later

func _ready() -> void:
	# Draw once on start and then periodically; also redraw when you move settlements later
	queue_redraw()

func _process(_delta: float) -> void:
	# If settlements never move, you can remove this and just call queue_redraw() when needed.
	queue_redraw()

func _draw() -> void:
	var settlements := get_tree().get_nodes_in_group("settlements")

	# Draw each undirected edge once (avoid double-drawing A->B and B->A)
	var drawn := {} # Dictionary used as a set of keys

	for s in settlements:
		if s == null:
			continue
		for n in s.neighbors:
			if n == null:
				continue

			var a_id := str(s.get_instance_id())
			var b_id := str(n.get_instance_id())
			var key := a_id + ":" + b_id
			var reverse := b_id + ":" + a_id

			if drawn.has(key) or drawn.has(reverse):
				continue

			drawn[key] = true

			# Node2D draws in its local space; convert global -> local
			var a := to_local(s.global_position)
			var b := to_local(n.global_position)
			draw_line(a, b, line_color, line_width, true)
