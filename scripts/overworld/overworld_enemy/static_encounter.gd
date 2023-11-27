extends Resource
class_name StaticEncounter

@export var combatant1: Combatant = null
@export var combatant1Level: int = 1
@export var combatant2: Combatant = null
@export var combatant2Level: int = 1
@export var combatant3: Combatant = null
@export var combatant3Level: int = 1
@export var specialBattleId: String = ''
@export var bossBattle: bool = false
@export var rewards: Array[Reward] = []
@export var useStaticRewards: bool = false

func _init(
	i_combatant1 = null,
	i_combatant1Lv = 1,
	i_combatant2 = null,
	i_combatant2Lv = 1,
	i_combatant3 = null,
	i_combatant3Lv = 1,
	i_specialBattleId = '',
	i_bossBattle = false,
	i_storyRequirements = null,
	i_rewards: Array[Reward] = [],
	i_useRewards = false,
):
	combatant1 = i_combatant1
	combatant1Level = i_combatant1Lv
	combatant2 = i_combatant2
	combatant2Level = i_combatant2Lv
	combatant3 = i_combatant3
	combatant3Level = i_combatant3Lv
	specialBattleId = i_specialBattleId
	bossBattle = i_bossBattle
	rewards = i_rewards
	useStaticRewards = i_useRewards
