extends Puzzle
class_name StatCheckPuzzle

@export var minStats: Stats = null

func _init(
	i_id = '',
	i_prereqRequirements: Array[StoryRequirements] = [],
	i_minStats: Stats = null,
):
	super(i_id, i_prereqRequirements)
	minStats = i_minStats

func passes_prereqs() -> bool:
	if is_solved():
		return true
	if not super.passes_prereqs():
		return false
	return stat_check(PlayerResources.playerInfo.combatant.stats)

func solve():
	if stat_check(PlayerResources.playerInfo.combatant.stats):
		super.solve()

func stat_check(stats: Stats) -> bool:
	if stats == null:
		return false
	
	return (
		stats.physAttack >= minStats.physAttack and \
		stats.magicAttack >= minStats.magicAttack and \
		stats.affinity >= minStats.affinity and \
		stats.resistance >= minStats.resistance and \
		stats.speed >= minStats.speed and \
		stats.maxHp >= minStats.maxHp and \
		stats.statPts >= minStats.statPts
	)
