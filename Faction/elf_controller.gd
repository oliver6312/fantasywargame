extends FactionController
class_name ElfController

var phase: String = "start"

func get_action_list() -> Array:
	var actions: Array = []

	var migrate := ActionDefinition.new()
	migrate.id = "forest_step"
	migrate.label = "Forest Step"
	actions.append(migrate)

	var trade := ActionDefinition.new()
	trade.id = "trade"
	trade.label = "Trade"
	actions.append(trade)

	return actions
