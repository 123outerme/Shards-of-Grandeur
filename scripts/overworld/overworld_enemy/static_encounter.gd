extends Resource
class_name StaticEncounter

@export var combatant1: Combatant = null
@export var combatant1Level: int = 1
@export var combatant1Moves: Array[Move] = []
@export var combatant2: Combatant = null
@export var combatant2Level: int = 1
@export var combatant2Moves: Array[Move] = []
@export var combatant3: Combatant = null
@export var combatant3Level: int = 1
@export var combatant3Moves: Array[Move] = []
@export var autoAlly: Combatant = null
@export var autoAllyLevel: int = 1
@export var autoAllyMoves: Array[Move] = []
@export var specialBattleId: String = ''
@export var bossBattle: bool = false
@export var canEscape: bool = true
@export var rewards: Array[Reward] = []
@export var useStaticRewards: bool = false

func _init(
	i_combatant1 = null,
	i_combatant1Lv = 1,
	i_combatant1Moves: Array[Move] = [],
	i_combatant2 = null,
	i_combatant2Lv = 1,
	i_combatant2Moves: Array[Move] = [],
	i_combatant3 = null,
	i_combatant3Lv = 1,
	i_combatant3Moves: Array[Move] = [],
	i_autoAlly = null,
	i_autoAllyLv = 1,
	i_autoAllyMoves: Array[Move] = [],
	i_specialBattleId = '',
	i_bossBattle = false,
	i_canEscape = true,
	i_rewards: Array[Reward] = [],
	i_useRewards = false,
):
	combatant1 = i_combatant1
	combatant1Level = i_combatant1Lv
	combatant1Moves = i_combatant1Moves
	combatant2 = i_combatant2
	combatant2Level = i_combatant2Lv
	combatant2Moves = i_combatant2Moves
	combatant3 = i_combatant3
	combatant3Level = i_combatant3Lv
	combatant3Moves = i_combatant3Moves
	autoAlly = i_autoAlly
	autoAllyLevel = i_autoAllyLv
	autoAllyMoves = i_autoAllyMoves
	specialBattleId = i_specialBattleId
	bossBattle = i_bossBattle
	canEscape = i_canEscape
	rewards = i_rewards
	useStaticRewards = i_useRewards
