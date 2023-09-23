extends Node2D

@export var playerInfo: Resource

var player = null

# Called when the node enters the scene tree for the first time.
func _ready():	
	pass # Replace with function body.

func load_data(save_path):
	playerInfo = PlayerInfo.new()
	var newPlayerInfo = playerInfo.load_data(save_path)
	if newPlayerInfo != null:
		playerInfo = newPlayerInfo
	player = get_node_or_null("/root/" + playerInfo.scene + "/Player")
	if player != null:
		player.position = playerInfo.position
		player.disableMovement = playerInfo.disableMovement

func save_data(save_path):
	if player != null:
		playerInfo.position = player.position
		playerInfo.disableMovement = player.disableMovement
		playerInfo.save_data(save_path, playerInfo)
	
func new_game(save_path):
	playerInfo = PlayerInfo.new()
	playerInfo.save_data(save_path, playerInfo)
