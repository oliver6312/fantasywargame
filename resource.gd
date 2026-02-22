extends Node
class_name ResourceClass

enum Type { LUMBER, FOOD, MINERALS }

static func name_for(t: Type) -> String:
	match t:
		Type.LUMBER: return "Lumber"
		Type.FOOD: return "Food"
		Type.MINERALS: return "Minerals"
		_: return "Unknown"
