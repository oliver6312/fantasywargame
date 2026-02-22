extends Panel

# Maps faction → panel node
var faction_panels := {}

func _ready() -> void:
	# Cache panel references
	faction_panels[Faction.Type.ORC] = $OrcPanel
	faction_panels[Faction.Type.ELF] = $ElfPanel
	faction_panels[Faction.Type.DWARF] = $DwarfPanel

	# Connect to TurnState
	TurnState.resources_changed.connect(_on_resources_changed)
	TurnState.turn_changed.connect(_on_turn_changed)

	# Initialize display
	_refresh_all()

func _on_resources_changed(_faction: Faction.Type) -> void:
	_refresh_all()

func _on_turn_changed(_faction: Faction.Type) -> void:
	_refresh_all()

func _refresh_all() -> void:
	for f in faction_panels.keys():
		_update_faction_display(f)

func _update_faction_display(f: Faction.Type) -> void:
	var panel: Control = faction_panels[f]
	if panel == null:
		return

	var res_dict = TurnState.resources[f]

	panel.get_node("LumberLabel").text = \
		"Lumber: %d" % res_dict[ResourceClass.Type.LUMBER]

	panel.get_node("FoodLabel").text = \
		"Food: %d" % res_dict[ResourceClass.Type.FOOD]

	panel.get_node("MineralsLabel").text = \
		"Minerals: %d" % res_dict[ResourceClass.Type.MINERALS]
