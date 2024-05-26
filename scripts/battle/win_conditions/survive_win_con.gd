extends WinCon
class_name SurviveWinCon

@export_range(2, INF) var minTurns: int = 2

func get_result(combatants: Array[CombatantNode], battleState: BattleState) -> TurnResult:
	if battleState.turnNumber >= minTurns:
		return TurnResult.PLAYER_WIN
	return super.get_result(combatants, battleState)
