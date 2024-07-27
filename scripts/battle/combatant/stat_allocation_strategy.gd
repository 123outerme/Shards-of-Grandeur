extends Resource
class_name StatAllocationStrategy

func _init():
	pass

## 2nd argument: pass -1 to allocate all stat points, otherwise this is the amount of stat points to allocate
func allocate_stats(stats: Stats, allocateAmount: int = -1):
	# base class does absolutely no allocation
	pass

func allocate_stat(stats: Stats, category: Stats.Category, amount: int = 1):
	if stats.statPts < amount:
		amount = max(stats.statPts, 0)

	if category == Stats.Category.PHYS_ATK:
		stats.physAttack += amount
	if category == Stats.Category.MAGIC_ATK:
		stats.magicAttack += amount
	if category == Stats.Category.RESISTANCE or category == Stats.Category.HP: # HP shouldn't be picked, but in case, just increase resistance
		stats.resistance += amount
	if category == Stats.Category.AFFINITY:
		stats.affinity += amount
	if category == Stats.Category.SPEED:
		stats.speed += amount
	stats.statPts -= amount
