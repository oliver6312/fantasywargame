extends RefCounted
class_name CombatResolver

static func _apply_precombat_damage(soldiers: int, armor: int, damage: int) -> Dictionary:
	var remaining_armor := armor - damage
	var remaining_soldiers := soldiers

	if remaining_armor < 0:
		remaining_soldiers += remaining_armor
		remaining_armor = 0

	remaining_soldiers = max(0, remaining_soldiers)

	return {
		"soldiers": remaining_soldiers,
		"armor": remaining_armor
	}

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

	if precombat_damage_to_attacker > 0:
		var atk_result := _apply_precombat_damage(atk_soldiers, atk_armor, precombat_damage_to_attacker)
		atk_soldiers = atk_result["soldiers"]
		atk_armor = atk_result["armor"]

	if precombat_damage_to_defender > 0:
		var def_result := _apply_precombat_damage(def_soldiers, def_armor, precombat_damage_to_defender)
		def_soldiers = def_result["soldiers"]
		def_armor = def_result["armor"]

	# If precombat wipes one side, combat may still continue if the other side survives.
	var attacker_power := atk_armor + atk_soldiers
	var defender_power := def_armor + def_soldiers

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
