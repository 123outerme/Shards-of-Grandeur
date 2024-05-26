extends Resource
class_name WinCon

enum TurnResult {
	NOTHING = 0,
	PLAYER_WIN = 1,
	ENEMY_WIN = 2,
	ESCAPE = 3,
}

func _init():
	pass

func get_result(combatants: Array[CombatantNode], _battleState: BattleState) -> TurnResult:
	print('WinCondition warning: WinCondition should be treated as an abstract class. Did you forget to instantiate a subclass of WinCondition?')
	var alliesDown: int = 0
	var enemiesDown: int = 0
	for combatantNode in combatants:
		if not combatantNode.is_alive(): # if combatant is not alive (after being updated)
			if combatantNode.role == CombatantNode.Role.ALLY:
				alliesDown += 1 # ally down
			else:
				enemiesDown += 1 # enemy down
	if alliesDown == 2: # all allies are down:
		return WinCon.TurnResult.ENEMY_WIN
	if enemiesDown == 3: # all enemies are down:
		return WinCon.TurnResult.PLAYER_WIN
	return WinCon.TurnResult.NOTHING
