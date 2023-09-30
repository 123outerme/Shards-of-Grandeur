extends Resource
class_name BattleState

enum State {
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
@export var currentState: State = State.SUMMON
@export var commandingMinion: bool = false

func _init():
	pass # TODO
