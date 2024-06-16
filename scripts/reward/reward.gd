extends Resource
class_name Reward

@export var experience: int
@export var gold: int
@export var item: Item
@export var fullyAttuneCombatantSaveName: String = ''

func _init(i_exp = 0, i_gold = 0, i_item = null, i_fullAttuneCombatant = ''):
	experience = i_exp
	gold = i_gold
	item = i_item
	fullyAttuneCombatantSaveName = i_fullAttuneCombatant

func copy() -> Reward:
	var copiedReward: Reward = Reward.new()
	copiedReward.experience = experience
	copiedReward.gold = gold
	copiedReward.item = item
	copiedReward.fullyAttuneCombatantSaveName = fullyAttuneCombatantSaveName
	return copiedReward

func scale_reward_by_level(initialLv: int, currentLv: int) -> Reward:
	var scaledReward: Reward = copy()
	# c = current, i = initial
	# scale factor = 1 + (0.007 * (c-i)^2) + (0.1 * (c-i))
	var scaleFactor: float = 1.0 + (0.007 * pow(currentLv - initialLv, 2)) + (0.1 * currentLv - initialLv)
	scaledReward.experience = roundi(scaledReward.experience * scaleFactor)
	scaledReward.gold = roundi(scaledReward.gold * scaleFactor)
	# can't really scale the item reward!! or the full attunement!
	return scaledReward
