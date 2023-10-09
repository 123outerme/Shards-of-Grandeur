extends Resource
class_name BattleState

enum Menu {
	SUMMON = 0,
	ALL_COMMANDS = 1,
	MOVES = 2,
	ITEMS = 3,
	PICK_TARGETS = 4,
	RESULTS = 5,
	BATTLE_COMPLETE = 6,
	LEVEL_UP = 7
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

@export_category("BattleData - Turns")
@export var turnNumber: int = 1
@export var turnQueue: TurnQueue = TurnQueue.new()

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
	i_turnNumber = 1,
	i_turnQueue = TurnQueue.new(),
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
	turnNumber = i_turnNumber
	turnQueue = i_turnQueue
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
