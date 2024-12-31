extends Node

signal player_run_toggled(running: bool)
var lastPlayerRunVal: bool = false

signal overworld_reward_given(reward: Reward)

func player_running(running: bool) -> void:
	lastPlayerRunVal = running
	player_run_toggled.emit(running)
