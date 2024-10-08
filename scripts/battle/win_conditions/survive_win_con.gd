extends WinCon
class_name SurviveWinCon

@export var minTurns: int = 2

func _init(
	i_minTurns: int = 2,
):
	super()
	minTurns = i_minTurns

func get_result(combatants: Array[CombatantNode], battleState: BattleState) -> TurnResult:
	if battleState.turnNumber >= minTurns:
		return TurnResult.PLAYER_WIN
	return super.get_result(combatants, battleState)
