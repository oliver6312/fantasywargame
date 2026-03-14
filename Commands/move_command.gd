extends GameCommand
class_name MoveCommand

var source: Settlement
var target: Settlement
var soldiers_sent: int
var attacker_armor: int = 0
var defender_armor: int = 0

func can_execute(context) -> bool:
	if source == null or target == null:
		return false
	if soldiers_sent < 1:
		return false
	if soldiers_sent > source.soldiers:
		return false
	if not source.is_adjacent_to(target):
		return false
	if source.faction != context.current_faction:
		return false
	return true

func get_error(context) -> String:
	if source == null or target == null:
		return "Missing source or target."
	if soldiers_sent < 1:
		return "Must send at least 1 soldier."
	if soldiers_sent > source.soldiers:
		return "Not enough soldiers."
	if not source.is_adjacent_to(target):
		return "Settlements are not connected."
	if source.faction != context.current_faction:
		return "That settlement is not yours."
	return ""

func execute(context) -> void:
	context.board.resolve_move_or_attack(
		source,
		target,
		soldiers_sent,
		attacker_armor,
		defender_armor
	)
