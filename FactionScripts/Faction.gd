extends Node
class_name Faction

enum Type { NEUTRAL, ORC, ELF, DWARF }

static func color_for(f: Type) -> Color:
	match f:
		Type.ORC: return Color("701705")      
		Type.ELF: return Color("#609C07")      
		Type.DWARF: return Color("#092FC8")    
		_: return Color("#636363")            
