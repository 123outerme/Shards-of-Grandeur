extends Resource
class_name OverworldEnemyData

@export var combatant: Combatant = null
@export var position: Vector2 = Vector2()
@export var disableMovement: bool = false
@export var encounter: EnemyEncounter = null
@export var runningChase: bool = false
@export var disabled: bool = true

# NOTE: for saving data, the complete filepath comes from the EnemySpawner itself to preserve spawner state
# so all that needs to be used for save/load functionality is the save_path coming through

func _init(
	i_combatant: Combatant = null,
	i_pos: Vector2 = Vector2(),
	i_disableMove: bool = false,
	i_encounter: EnemyEncounter = null,
	i_runningChase: bool = false,
	i_disabled: bool = true
):
	combatant = i_combatant
	position = i_pos
	disableMovement = i_disableMove
	encounter = i_encounter
	runningChase = i_runningChase
	disabled = i_disabled
