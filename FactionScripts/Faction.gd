extends Node
class_name Faction

enum Type { NEUTRAL, ORC, ELF, DWARF }

static func color_for(f: Type) -> Color:
	match f:
		Type.ORC: return Color("7e3f3f")      
		Type.ELF: return Color("6a7e3f")      
		Type.DWARF: return Color("3f5e7e")    
		_: return Color("#636363")            

#		Type.ORC: return Color("5d2323")      
#		Type.ELF: return Color("4c5c2d")      
#		Type.DWARF: return Color("2d475c")  
