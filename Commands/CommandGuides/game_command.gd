extends RefCounted
class_name GameCommand

func validate(_context: CommandContext) -> bool:
	return true

func get_error(_context: CommandContext) -> String:
	return ""

func execute(_context: CommandContext) -> void:
	pass
