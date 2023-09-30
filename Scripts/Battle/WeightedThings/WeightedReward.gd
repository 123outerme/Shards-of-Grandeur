extends WeightedThing
class_name WeightedReward

@export var reward: Reward = Reward.new()

func _init(i_weight = 0.0, i_reward = Reward.new()):
	super(i_weight)
	reward = i_reward
