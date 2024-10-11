extends WinCon
class_name SurviveWinCon

## the minimum number of turns the player is to survive
@export var minTurns: int = 2

## the rewards the player will earn if they achieve a Total Defeat victory before time runs out. If empty, will ignore this and use the original rewards generated
@export var staticTotalDefeatRewards: Array[Reward] = []

func _init(
	i_winText: String = WinCon.DEFAULT_WIN_TEXT,
	i_loseText: String = WinCon.DEFAULT_LOSE_TEXT,
	i_escapeText: String = WinCon.DEFAULT_ESCAPE_TEXT,
	i_minTurns: int = 2,
	i_totalDefeatRewards: Array[Reward] = [],
):
	super(i_winText, i_loseText, i_escapeText)
	minTurns = i_minTurns
	staticTotalDefeatRewards = i_totalDefeatRewards.duplicate(true)

func get_result(combatants: Array[CombatantNode], battleState: BattleState) -> TurnResult:
	var turnNumber: int = battleState.turnNumber
	if battleState.menu == BattleState.Menu.POST_ROUND:
		turnNumber += 1
	if turnNumber >= minTurns:
		return TurnResult.PLAYER_WIN
	return super.get_result(combatants, battleState)
