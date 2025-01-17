extends Node

signal player_run_toggled(running: bool)
var lastPlayerRunVal: bool = false

## emits once per Reward given during overworld processing (except Quest turnins)
signal overworld_rewards_given(rewardsTitle: String)

func player_running(running: bool) -> void:
	lastPlayerRunVal = running
	player_run_toggled.emit(running)

func give_overworld_rewards(reward: Reward, rewardsTitle: String = 'Rewards') -> void:
	PlayerResources.playerInfo.queuedRewards.append(reward)
	await get_tree().process_frame # wait a frame,
	# ... until all rewards given on this frame/update are processed
	overworld_rewards_given.emit(rewardsTitle) # will still emit once-per reward, so listeners must
