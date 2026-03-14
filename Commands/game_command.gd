extends RefCounted
class_name GameCommand

func can_execute(_context) -> bool:
	return true

func get_error(_context) -> String:
	return ""

func execute(_context) -> void:
	pass
