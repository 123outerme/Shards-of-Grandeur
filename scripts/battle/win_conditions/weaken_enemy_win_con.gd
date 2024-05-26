extends WinCon
class_name WeakenEnemyWinCon

@export_enum('Center', 'Top', 'Bottom') var enemyPosition: String = 'Center'
@export_range(0, 1) var targetPercentHp: float = 0.5

func _init(
	i_enemyPosition = 'Center',
	i_targetPercentHp = 0.5,
):
	enemyPosition = i_enemyPosition
	targetPercentHp = i_targetPercentHp

func get_result(combatants: Array[CombatantNode], battleState: BattleState):
	var target: CombatantNode = null
	for combatant in combatants:
		if combatant.battlePosition == enemyPosition:
			target = combatant
			break
	if target != null and target.combatant != null:
		var targetMaxHp: float = target.combatant.stats.maxHp
		if target.combatant.currentHp / targetMaxHp <= targetPercentHp:
			return TurnResult.PLAYER_WIN
	return super.get_result(combatants, battleState)
