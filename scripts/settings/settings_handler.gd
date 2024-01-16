extends Node

@export var gameSettings: GameSettings = GameSettings.new()
var save_path = 'user://'

func _init():
	load_data()

func save_data():
	gameSettings.save_data(save_path, gameSettings)
	
func load_data():
	var newGameSettings: GameSettings = gameSettings.load_data(save_path)
	if newGameSettings != null:
		gameSettings = newGameSettings
	gameSettings.apply_from_stored_inputs()
