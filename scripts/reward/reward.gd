extends Resource
class_name Reward

const CUSTOM_WIN_SCALE = 1.0
const CUSTOM_LOSE_SCALE = 0.7

@export var experience: int
@export var gold: int
@export var item: Item
@export var itemCount: int = 1
@export var fullyAttuneCombatantSaveName: String = ''

func _init(
	i_exp: int = 0,
	i_gold: int = 0,
	i_item: Item = null,
	i_itemCount: int = 1,
	i_fullAttuneCombatant: String = ''
):
	experience = i_exp
	gold = i_gold
	item = i_item
	itemCount = i_itemCount
	fullyAttuneCombatantSaveName = i_fullAttuneCombatant

func copy() -> Reward:
	return Reward.new(experience, gold, item, itemCount, fullyAttuneCombatantSaveName)

func scale_reward_by_level(initialLv: int, currentLv: int, playerLv: int, customScale: float = 1.0) -> Reward:
	var scaledReward: Reward = copy()
	# c = current, i = initial
	# exp scale factor = 1 + (0.004 * (c-i)^2) + (0.03 * (c-i))
	var expScaleFactor: float = 1.0 + (0.004 * pow(currentLv - initialLv, 2)) + (0.03 * (currentLv - initialLv))
	# gold scale factor = 1 + (0.02 * (c-i))
	var goldScaleFactor: float = 1.0 + (0.02 * (currentLv - initialLv))
	scaledReward.experience = roundi(scaledReward.experience * expScaleFactor * customScale)
	
	# if the player is 5+ levels over the reward level: scale the intended XP gains back (min bound at 25%, 15 lv difference) 
	if playerLv > currentLv + 4:
		scaledReward.experience = roundi(scaledReward.experience * ( 1 - min(0.25, 0.075 * (playerLv - currentLv - 4)) ))
	
	scaledReward.gold = roundi(scaledReward.gold * goldScaleFactor * customScale)
	# no scaling on the item reward or the full attunement!
	return scaledReward

func scale_reward_by_modifiers(expScale: float, goldScale: float, itemCountScale: float) -> Reward:
	var scaledReward: Reward = copy()
	
	scaledReward.experience *= expScale
	scaledReward.gold *= goldScale
	scaledReward.itemCount = roundi(scaledReward.itemCount * itemCountScale)
	
	return scaledReward
