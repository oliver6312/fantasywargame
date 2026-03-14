extends GameCommand
class_name TradeCommand

var sender_faction: int
var receiver_faction: int
var gold: int = 0
var armor: int = 0

func can_execute(context) -> bool:
	if sender_faction != context.current_faction:
		return false
	if receiver_faction == sender_faction:
		return false
	if gold < 0 or armor < 0:
		return false
	if gold > TurnState.get_gold(sender_faction):
		return false
	if armor > TurnState.get_armor(sender_faction):
		return false
	return true

func execute(_context) -> void:
	TurnState.add_gold(sender_faction, -gold)
	TurnState.add_gold(receiver_faction, gold)
	TurnState.add_armor(sender_faction, -armor)
	TurnState.add_armor(receiver_faction, armor)
