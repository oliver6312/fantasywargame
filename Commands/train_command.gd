extends RefCounted
class_name TrainCommand

var faction: int
var building_name: String = "Training Grounds"

func validate(context: CommandContext) -> bool:
	if faction != context.current_faction:
		return false

	if context.board == null:
		return false

	return true

func get_error(context: CommandContext) -> String:
	if faction != context.current_faction:
		return "It is not that faction's turn."
	if context.board == null:
		return "Missing board context."
	return "Could not train."

func execute(context: CommandContext) -> void:
	var trained_settlements := 0

	for settlement in context.board.get_tree().get_nodes_in_group("settlements"):
		print("Settlement:", settlement.name)
		print("soldiers:", settlement.soldiers)
		

#		if settlement.faction != faction:
#			continue
#			print("i love cher")

		if _settlement_has_building(settlement, building_name):
			settlement.set_soldiers(settlement.soldiers + 1)
			trained_settlements += 1

	print("%s trained soldiers in %d settlement(s)." % [
		context.turn_state.get_faction_name(faction),
		trained_settlements
	])

func _settlement_has_building(settlement: Settlement, target_building: String) -> bool:
	for slot in settlement.building_slots:
		if slot == target_building:
			return true
	return false
