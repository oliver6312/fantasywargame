extends Node
class_name FactionTurn

var faction : int

func start_turn():
	pass

func end_turn():
	pass

func can_move_from_settlement(_settlement):
	return true

func modify_attack_soldiers(amount:int):
	return amount

func modify_winter_loss(loss:int):
	return loss

func get_mercenary_multiplier():
	return 1

func get_building_bonus(_building):
	return 0
