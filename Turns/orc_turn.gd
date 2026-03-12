extends FactionTurn
class_name OrcTurn

func start_turn():
	print("Orc turn begins")

func modify_attack_soldiers(amount:int):
	# Orcs attack harder
	return amount + 2

func get_mercenary_multiplier():
	return 2
