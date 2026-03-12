extends FactionTurn
class_name ElfTurn

func modify_winter_loss(loss:int):
	# elves ignore winter losses
	return 0
