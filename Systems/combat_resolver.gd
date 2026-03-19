extends RefCounted

static func resolve_battle(
	attacker_faction: int,
	defender_faction: int,
	attacker_soldiers: int,
	defender_soldiers: int,
	attacker_armor: int,
	defender_armor: int,
	precombat_damage_to_attacker: int = 0,
	precombat_damage_to_defender: int = 0
) -> Dictionary:
	var atk_armor : int = max(0, attacker_armor)
	var atk_soldiers : int = max(0, attacker_soldiers)

	var def_armor : int = max(0, defender_armor)
	var def_soldiers : int = max(0, defender_soldiers)

	var attacker_power : int = atk_armor + atk_soldiers
	var defender_power : int = def_armor + def_soldiers

	def_armor -= attacker_power
	if def_armor < 0:
		def_soldiers += def_armor
		def_armor = 0

	atk_armor -= defender_power
	if atk_armor < 0:
		atk_soldiers += atk_armor
		atk_armor = 0

	atk_soldiers = max(0, atk_soldiers)
	def_soldiers = max(0, def_soldiers)

	var winning_faction := defender_faction
	var settlement_soldiers := def_soldiers

	if atk_soldiers > 0 and def_soldiers <= 0:
		winning_faction = attacker_faction
		settlement_soldiers = atk_soldiers
	elif atk_soldiers <= 0 and def_soldiers <= 0:
		winning_faction = defender_faction
		settlement_soldiers = 0
	else:
		winning_faction = defender_faction
		settlement_soldiers = def_soldiers

	return {
		"winning_faction": winning_faction,
		"settlement_soldiers": settlement_soldiers,
		"attacker_remaining_soldiers": atk_soldiers,
		"defender_remaining_soldiers": def_soldiers,
		"attacker_remaining_armor": atk_armor,
		"defender_remaining_armor": def_armor
	}
