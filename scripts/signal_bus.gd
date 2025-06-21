extends Node

signal player_run_toggled(running: bool)
var lastPlayerRunVal: bool = false

## emits once per Reward given during overworld processing (except Quest turnins)
signal overworld_rewards_given(rewardsTitle: String)

## Emit in the Quests UI when trying to see the location(s) for a quest
signal show_map_for_location(locations: Array[WorldLocation.MapLocation], quest: Quest)

## Emit in the Map UI when returning back to view the viewed quest's details
signal return_from_quest_map_location(quest: Quest)

func player_running(running: bool) -> void:
	lastPlayerRunVal = running
	player_run_toggled.emit(running)

func give_overworld_rewards(reward: Reward, rewardsTitle: String = 'Rewards') -> void:
	if reward != null:
		PlayerResources.playerInfo.queuedRewards.append(reward)
		await get_tree().process_frame # wait a frame,
		# ... until all rewards given on this frame/update are processed
		overworld_rewards_given.emit(rewardsTitle) # will still emit once-per reward, so listeners must
