extends FactionTurn
class_name DwarfTurn

var normal_actions_remaining = 2

func start_turn():
	normal_actions_remaining = 2
	print("Dwarf turn begins")

func count_buildings(building_name):

	var total = 0

	for s in get_tree().get_nodes_in_group("settlements"):

		if s.faction != Faction.Type.DWARF:
			continue

		for slot in s.building_slots:
			if slot == building_name:
				total += 1

	return total

func action_mine():

	if normal_actions_remaining <= 0:
		print("No actions remaining")
		return

	var mines = count_buildings("Gold Mine")

	if mines == 0:
		print("No gold mines")
		return

	var gold_gain = mines * 20

	TurnState.add_gold(Faction.Type.DWARF, gold_gain)

	normal_actions_remaining -= 1

	print("Dwarves gained ", gold_gain, " gold")

func action_train():

	if normal_actions_remaining <= 0:
		return

	for s in get_tree().get_nodes_in_group("settlements"):

		if s.faction != Faction.Type.DWARF:
			continue

		for slot in s.building_slots:

			if slot == "Training Grounds":
				s.set_soldiers(s.soldiers + 1)

	normal_actions_remaining -= 1

func action_smith():

	if normal_actions_remaining <= 0:
		return

	var smiths = count_buildings("Armor Smith")

	var armor_gain = smiths * 2

	TurnState.add_armor(Faction.Type.DWARF, armor_gain)

	normal_actions_remaining -= 1

func action_march():

	if normal_actions_remaining <= 0:
		return

	var stables = count_buildings("Goat Stable")

	print("Dwarves can make ", stables, " moves")

	normal_actions_remaining -= 1

	# BoardController now allows that many moves
