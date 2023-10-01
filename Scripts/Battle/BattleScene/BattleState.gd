extends Resource
class_name BattleState

enum Menu {
	SUMMON = 0,
	ALL_COMMANDS = 1,
	MOVES = 2,
	ITEMS = 3,
	PICK_TARGETS = 4,
	RESULTS = 5,
	REWARDS = 6,
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
@export var commandingMinion: bool = false

var save_file: String = 'battle.tres'

func _init():
	pass # TODO

func load_data(save_path):
	if ResourceLoader.exists(save_path + save_file):
		return load(save_path + save_file)
	return null

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("BattleState ResourceSaver error: " + err)

func delete_data(save_path):
	var err = DirAccess.remove_absolute(save_path + save_file)
	if err != 0:
		printerr("BattleState DirAccess remove error: " + err)
