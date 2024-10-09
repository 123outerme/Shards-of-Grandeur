extends WinCon
class_name WeakenEnemyWinCon

## The enemy whose HP determines if the player wins. Use `#opp` in the win/lose/escape text to specify the enemy selected
@export_enum('Center', 'Top', 'Bottom') var enemyPosition: String = 'Center'

## The amount of HP (in percent) the enemy should be reduced to for the win
@export_range(0, 1) var targetPercentHp: float = 0.5

func _init(
	i_winText: String = WinCon.DEFAULT_WIN_TEXT,
	i_loseText: String = WinCon.DEFAULT_LOSE_TEXT,
	i_escapeText: String = WinCon.DEFAULT_ESCAPE_TEXT,
	i_enemyPosition: String = 'Center',
	i_targetPercentHp: float = 0.5,
):
	super(i_winText, i_loseText, i_escapeText)
	enemyPosition = i_enemyPosition
	targetPercentHp = i_targetPercentHp

func get_target_combatant(combatants: Array[CombatantNode]) -> CombatantNode:
	for combatant in combatants:
		if combatant.battlePosition == enemyPosition:
			return combatant
			break
	return null

func get_result(combatants: Array[CombatantNode], battleState: BattleState) -> TurnResult:
	var target: CombatantNode = get_target_combatant(combatants)
	if target != null and target.combatant != null:
		var targetMaxHp: float = target.combatant.stats.maxHp
		if target.combatant.currentHp / targetMaxHp <= targetPercentHp:
			return TurnResult.PLAYER_WIN
	return super.get_result(combatants, battleState)

func get_win_text(combatants: Array[CombatantNode]) -> String:
	var targetCombatant: CombatantNode = get_target_combatant(combatants)
	var targetName: String = 'Enemy'
	if targetCombatant != null:
		targetName = targetCombatant.combatant.disp_name()
	return winText.replace('#opp', targetName)

func get_lose_text(combatants: Array[CombatantNode]) -> String:
	var targetCombatant: CombatantNode = get_target_combatant(combatants)
	var targetName: String = 'Enemy'
	if targetCombatant != null:
		targetName = targetCombatant.combatant.disp_name()
	return loseText.replace('#opp', targetName)
