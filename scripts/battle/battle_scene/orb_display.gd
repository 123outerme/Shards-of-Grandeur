extends Control
class_name OrbDisplay

@export var alignedLeft: bool = true
@export var currentOrbs: int = 0

const orbUnitDisplayScene: PackedScene = preload('res://prefabs/battle/orb_unit_display.tscn')

@onready var hboxContainer: HBoxContainer = get_node('HBoxContainer')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_orb_display()

func load_orb_display():
	hboxContainer.alignment = BoxContainer.ALIGNMENT_BEGIN if alignedLeft else BoxContainer.ALIGNMENT_END
	for i in range(Combatant.MAX_ORBS):
		var orbUnit: OrbUnitDisplay = orbUnitDisplayScene.instantiate()
		hboxContainer.add_child(orbUnit)
	update_orb_display()

func update_orb_display():
	var orbUnits = hboxContainer.get_children()
	for idx in range(len(orbUnits)):
		var unit: OrbUnitDisplay = orbUnits[idx] as OrbUnitDisplay
		unit.filledOrb = idx < currentOrbs if alignedLeft else Combatant.MAX_ORBS - idx <= currentOrbs
		unit.load_orb_unit_display()

func update_orb_count(orbs: int):
	currentOrbs = orbs
	update_orb_display()
