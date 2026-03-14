extends FactionController
class_name OrcController

var phase: String = "start"

func start_turn() -> void:
	print("Orc turn begins")

func get_action_list() -> Array:
	var actions: Array = []

	var raid := ActionDefinition.new()
	raid.id = "raid"
	raid.label = "Raid"
	actions.append(raid)

	var recruit := ActionDefinition.new()
	recruit.id = "hire_mercs"
	recruit.label = "Hire Mercenaries"
	actions.append(recruit)

	return actions
