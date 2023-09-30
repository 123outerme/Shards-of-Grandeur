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
