extends WinCon
class_name SurviveWinCon

@export var minTurns: int = 2

func _init(
	i_winText: String = WinCon.DEFAULT_WIN_TEXT,
	i_loseText: String = WinCon.DEFAULT_LOSE_TEXT,
	i_escapeText: String = WinCon.DEFAULT_ESCAPE_TEXT,
	i_minTurns: int = 2,
):
	super(i_winText, i_loseText, i_escapeText)
	minTurns = i_minTurns

func get_result(combatants: Array[CombatantNode], battleState: BattleState) -> TurnResult:
	if battleState.turnNumber >= minTurns:
		return TurnResult.PLAYER_WIN
	return super.get_result(combatants, battleState)
