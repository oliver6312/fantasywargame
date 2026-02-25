extends Resource
class_name BuildingDef

@export var id: String = ""                 # e.g. "recruitment_camp"
@export var display_name: String = ""       # e.g. "Recruitment Camp"
@export var icon: Texture2D                 # your sprite
@export var cost_lumber: int = 0
@export var cost_food: int = 0
@export var cost_minerals: int = 0

# NEW: building combat metadata
@export var grants_trait: String = ""        # e.g. "Armor" (empty = none)
@export var counters_trait: String = ""      # e.g. "Armor" (empty = none)

# Start-of-turn effects (applied when the owning faction's turn begins)
@export var sot_add_soldiers: int = 0

@export var sot_add_lumber: int = 0
@export var sot_add_food: int = 0
@export var sot_add_minerals: int = 0

func cost_dict() -> Dictionary:
	return {
		ResourceClass.Type.LUMBER: cost_lumber,
		ResourceClass.Type.FOOD: cost_food,
		ResourceClass.Type.MINERALS: cost_minerals
	}
