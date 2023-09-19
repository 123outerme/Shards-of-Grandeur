extends Node2D

@export var playerInfo: Resource

var player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func load_data(save_path):
	playerInfo = PlayerInfo.new()
	var newPlayerInfo = playerInfo.load_data(save_path)
	if newPlayerInfo != null:
		playerInfo = newPlayerInfo
	player = get_node("/root/" + playerInfo.scene + "/Player")
	player.position = playerInfo.position
	player.disableMovement = playerInfo.disableMovement

func save_data(save_path):
	playerInfo.position = player.position
	playerInfo.disableMovement = player.disableMovement
	playerInfo.save_data(save_path, playerInfo)
