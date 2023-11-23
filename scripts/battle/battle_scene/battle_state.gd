extends Resource
class_name BattleState

enum Menu {
	SUMMON = 0,
	PRE_BATTLE = 1,
	ALL_COMMANDS = 2,
	MOVES = 3,
	ITEMS = 4,
	PICK_TARGETS = 5,
	PRE_ROUND = 6,
	RESULTS = 7,
	POST_ROUND = 8,
	BATTLE_COMPLETE = 9,
	LEVEL_UP = 10
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
@export var fobButtonEnabled: bool = true
@export var calcdStateStrings: Array[String] = []
@export var calcdStateIndex: int = 0

@export_category("BattleData - Turns")
@export var turnNumber: int = 1
@export var turnList: Array[Combatant] = []

@export_category("BattleData - Rewards")
@export var rewards: Array[Reward] = []

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
	i_fobBtnEnabled = true,
	i_turnNumber = 1,
	i_turnList: Array[Combatant] = [],
	i_rewards: Array[Reward] = [],
):
	playerCombatant = i_playerCombatant
	minionCombatant = i_minionCombatant
	enemyCombatant1 = i_enemyCombatant1
	enemyCombatant2 = i_enemyCombatant2
	enemyCombatant3 = i_enemyCombatant3
	menu = i_menu
	prevMenu = i_prevMenu
	commandingMinion = i_cmdMinion
	fobButtonEnabled = i_fobBtnEnabled
	turnNumber = i_turnNumber
	turnList = i_turnList
	rewards = i_rewards

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = load(save_path + save_file)
		if data != null:
			return data #.duplicate(true)
	return data

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("BattleState ResourceSaver error: ", err)

func delete_data(save_path):
	if FileAccess.file_exists(save_path + save_file):
		var err = DirAccess.remove_absolute(save_path + save_file)
		if err != 0:
			printerr("BattleState DirAccess remove error: ", err)
