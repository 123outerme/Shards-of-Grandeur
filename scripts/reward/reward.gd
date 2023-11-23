extends Resource
class_name Reward

@export var experience: int
@export var gold: int
@export var item: Item

func _init(i_exp = 0, i_gold = 0, i_item = null):
	experience = i_exp
	gold = i_gold
	item = i_item

func copy() -> Reward:
	var copiedReward: Reward = Reward.new()
	copiedReward.experience = experience
	copiedReward.gold = gold
	copiedReward.item = item
	return copiedReward

func scale_reward_by_level(initialLv: int, currentLv: int) -> Reward:
	var scaledReward: Reward = copy()
	var scaleFactor: float = 1.0 + ((currentLv - initialLv) * 0.05) # +5% more gains per level
	scaledReward.experience = roundi(scaledReward.experience * scaleFactor)
	scaledReward.gold = roundi(scaledReward.gold * scaleFactor)
	# can't really scale the item reward!!
	return scaledReward
