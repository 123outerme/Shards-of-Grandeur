extends Resource
class_name OverworldEnemyData

@export var combatant: Combatant = null
@export var setReward: Reward = null
@export var position: Vector2 = Vector2()
@export var disableMovement: bool = false
@export var combatantLevel: int = 1
@export var bossBattle: bool = false
@export var specialBattleId: String = ''

# NOTE: for saving data, the complete filepath comes from the EnemySpawner itself to preserve spawner state
# so all that needs to be used for save/load functionality is the save_path coming through

func _init(
	i_combatant = null,
	i_reward = null,
	i_pos = Vector2(),
	i_disableMove = false,
	i_combatantLv = 1,
	i_boss = false,
	i_specialBattleId = '',
):
	combatant = i_combatant
	setReward = i_reward
	position = i_pos
	disableMovement = i_disableMove
	combatantLevel = i_combatantLv
	bossBattle = i_boss
	specialBattleId = i_specialBattleId
