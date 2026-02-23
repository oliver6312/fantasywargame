extends Node

#real one

# Assign these in the inspector if you autoload this,
# or load them manually in _ready().
@export var orc_buildings: Array[BuildingDef] = []
@export var elf_buildings: Array[BuildingDef] = []
@export var dwarf_buildings: Array[BuildingDef] = []

func buildings_for_faction(f: Faction.Type) -> Array[BuildingDef]:
	match f:
		Faction.Type.ORC: return orc_buildings
		Faction.Type.ELF: return elf_buildings
		Faction.Type.DWARF: return dwarf_buildings
		_: return []
