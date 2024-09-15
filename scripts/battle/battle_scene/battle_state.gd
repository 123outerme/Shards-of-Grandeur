extends Resource
class_name BattleState

enum Menu {
	SUMMON = 0,
	PRE_BATTLE = 1,
	ALL_COMMANDS = 2,
	CHARGE_MOVES = 3,
	SURGE_MOVES = 4,
	ITEMS = 5,
	PICK_TARGETS = 6,
	SURGE_SPEND = 7,
	PRE_ROUND = 8,
	RESULTS = 9,
	POST_ROUND = 10,
	BATTLE_COMPLETE = 11,
	LEVEL_UP = 12
}

@export_category("BattleData - Combatants")
@export var playerCombatant: Combatant = null
@export var minionCombatant: Combatant = null
@export var enemyCombatant1: Combatant = null
@export var enemyCombatant2: Combatant = null
@export var enemyCombatant3: Combatant = null

@export_category("BattleData - Menu State")
@export var menu: Menu = Menu.SUMMON
@export var prevMenu: Menu = Menu.SUMMON
@export var commandingMinion: bool = false
@export var moveEffectType: Move.MoveEffectType = Move.MoveEffectType.NONE
@export var fobButtonEnabled: bool = true
@export var calcdStateStrings: Array[String] = []
@export var calcdStateCombatants: Array[Combatant] = []
@export var calcdStateDamage: Array[int] = []
@export var calcdStateStatBoosts: Array[StatChanges] = []
@export var calcdStateEquipmentProcd: Array = []
@export var statusEffDamagedCombatants: Array[Combatant] = []
@export var calcdStateIndex: int = 0
@export var battleMapPath: String = ''
@export var battleMusic: AudioStream = null

@export_category("BattleData - Turns")
@export var turnNumber: int = 1
@export var turnList: Array[Combatant] = []

@export_category("BattleData - Rewards")
@export var rewards: Array[Reward] = []
@export var usedShard: Item = null

var save_file: String = 'battle.tres'

func _init(
	i_playerCombatant = null,
	i_minionCombatant = null,
	i_enemyCombatant1 = null,
	i_enemyCombatant2 = null,
	i_enemyCombatant3 = null,
	i_menu = Menu.SUMMON,
	i_prevMenu = Menu.SUMMON,
	i_cmdMinion = false,
	i_moveEffectType = Move.MoveEffectType.NONE,
	i_fobBtnEnabled = true,
	i_battleMapPath = '',
	i_battleMusic = null,
	i_turnNumber = 1,
	i_turnList: Array[Combatant] = [],
	i_rewards: Array[Reward] = [],
	i_usedShard = null,
	i_calcdStateStrings: Array[String] = [],
	i_calcdStateDamage: Array[int] = [],
	i_calcdStateStatBoosts: Array[StatChanges] = [],
	i_calcdStateEquipmentProcd: Array = [],
	i_statusEffDamagedCombatants: Array[Combatant] = [],
	i_calcdStateIdx: int = 0
):
	playerCombatant = i_playerCombatant
	minionCombatant = i_minionCombatant
	enemyCombatant1 = i_enemyCombatant1
	enemyCombatant2 = i_enemyCombatant2
	enemyCombatant3 = i_enemyCombatant3
	menu = i_menu
	prevMenu = i_prevMenu
	commandingMinion = i_cmdMinion
	moveEffectType = i_moveEffectType
	fobButtonEnabled = i_fobBtnEnabled
	battleMapPath = i_battleMapPath
	battleMusic = i_battleMusic
	turnNumber = i_turnNumber
	turnList = i_turnList
	rewards = i_rewards
	usedShard = i_usedShard
	calcdStateStrings = i_calcdStateStrings
	calcdStateDamage = i_calcdStateDamage
	calcdStateStatBoosts = i_calcdStateStatBoosts
	calcdStateEquipmentProcd = i_calcdStateEquipmentProcd
	statusEffDamagedCombatants = i_statusEffDamagedCombatants
	calcdStateIndex = i_calcdStateIdx

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = ResourceLoader.load(save_path + save_file, '', ResourceLoader.CACHE_MODE_IGNORE)
		if data != null:
			return data #.duplicate(true)
	return data

func save_data(save_path, data) -> int:
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("BattleState ResourceSaver error: ", err)
	return err

func delete_data(save_path):
	if FileAccess.file_exists(save_path + save_file):
		var err = DirAccess.remove_absolute(save_path + save_file)
		if err != 0:
			printerr("BattleState DirAccess remove error: ", err)
