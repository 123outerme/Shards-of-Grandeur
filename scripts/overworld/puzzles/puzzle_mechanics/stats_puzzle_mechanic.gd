extends PuzzleMechanic
class_name StatsPuzzleMechanic

@export var minStats: Stats = null

func _init(
	i_minStats: Stats = null,
):
	minStats = i_minStats

func can_solve() -> bool:
	return stat_check(PlayerResources.playerInfo.combatant.stats)

func solve() -> bool:
	return can_solve()

func stat_check(stats: Stats) -> bool:
	if stats == null:
		return false
	
	return (
		stats.physAttack >= minStats.physAttack and
		stats.magicAttack >= minStats.magicAttack and
		stats.affinity >= minStats.affinity and
		stats.resistance >= minStats.resistance and
		stats.speed >= minStats.speed and
		stats.maxHp >= minStats.maxHp and
		stats.statPts >= minStats.statPts and
		stats.level >= minStats.level
	)
