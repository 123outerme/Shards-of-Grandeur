extends Control

@export var combatant: Combatant = null
@export var level: int = 1

var testCombatant: Combatant = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	testCombatant = combatant.copy()
	testCombatant.stats.set_level(level)
	testCombatant.assign_moves_nonplayer()
	for moveIdx: int in range(Stats.MAX_MOVES):
		var printStr: String = 'Move ' + String.num(moveIdx) + ' set to: '
		if moveIdx >= len(testCombatant.stats.moves) or testCombatant.stats.moves[moveIdx] == null:
			printStr += 'Empty'
		else:
			printStr += testCombatant.stats.moves[moveIdx].moveName
		print(printStr)
