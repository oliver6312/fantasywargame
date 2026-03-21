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
	precombat_damage_to_defender: int = 0,
	attacker_lord_strength: int = 0,
	defender_lord_strength: int = 0
) -> Dictionary:
	var atk_armor : int = max(0, attacker_armor)
	var atk_soldiers : int = max(0, attacker_soldiers)
	var atk_lord : int = max(0, attacker_lord_strength)

	var def_armor : int = max(0, defender_armor)
	var def_soldiers : int = max(0, defender_soldiers)
	var def_lord : int = max(0, defender_lord_strength)

	if precombat_damage_to_attacker > 0:
		var atk_pre := _apply_damage_to_lord_armor_soldiers(atk_lord, atk_armor, atk_soldiers, precombat_damage_to_attacker)
		atk_lord = atk_pre["lord_strength_remaining"]
		atk_armor = atk_pre["armor"]
		atk_soldiers = atk_pre["soldiers"]

	if precombat_damage_to_defender > 0:
		var def_pre := _apply_damage_to_lord_armor_soldiers(def_lord, def_armor, def_soldiers, precombat_damage_to_defender)
		def_lord = def_pre["lord_strength_remaining"]
		def_armor = def_pre["armor"]
		def_soldiers = def_pre["soldiers"]

	var attacker_power := atk_armor + atk_soldiers + atk_lord
	var defender_power := def_armor + def_soldiers + def_lord

	var def_result := _apply_damage_to_lord_armor_soldiers(def_lord, def_armor, def_soldiers, attacker_power)
	def_lord = def_result["lord_strength_remaining"]
	def_armor = def_result["armor"]
	def_soldiers = def_result["soldiers"]

	var atk_result := _apply_damage_to_lord_armor_soldiers(atk_lord, atk_armor, atk_soldiers, defender_power)
	atk_lord = atk_result["lord_strength_remaining"]
	atk_armor = atk_result["armor"]
	atk_soldiers = atk_result["soldiers"]

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
		"defender_remaining_soldiers": def_soldiers
	}

static func _apply_damage_to_lord_armor_soldiers(
	lord_strength: int,
	armor: int,
	soldiers: int,
	damage: int
) -> Dictionary:
	var lord_remaining := lord_strength
	var armor_remaining := armor
	var soldiers_remaining := soldiers
	var remaining_damage := damage

	var lord_absorbed : int = min(lord_remaining, remaining_damage)
	lord_remaining -= lord_absorbed
	remaining_damage -= lord_absorbed

	armor_remaining -= remaining_damage
	if armor_remaining < 0:
		soldiers_remaining += armor_remaining
		armor_remaining = 0

	soldiers_remaining = max(0, soldiers_remaining)

	return {
		"lord_strength_remaining": lord_remaining,
		"armor": armor_remaining,
		"soldiers": soldiers_remaining
	}
