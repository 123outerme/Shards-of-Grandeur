extends Control

@onready var SaveHandler: SaveHandler = get_node("/root/SaveHandler")
@onready var resumeGameButton: Button = get_node("VBoxContainer/ResumeGameButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	resumeGameButton.visible = SaveHandler.save_file_exists()
	pass # Replace with function body

func _on_quit_button_pressed():
	get_tree().quit()
	pass # Replace with function body.

func _on_settings_button_pressed():
	pass # Replace with function body.

func _on_resume_game_button_pressed():
	SaveHandler.load_data()
	load_overworld()
	pass # Replace with function body.

func _on_new_game_button_pressed():
	SaveHandler.new_game()
	load_overworld()
	pass # Replace with function body.

func load_overworld():
	var overworldScene = load("res://GameScenes/Overworld.tscn")
	var overworldInstance = overworldScene.instantiate()
	add_sibling.call_deferred(overworldInstance)
	var mainMenu = get_node("/root/MainMenu")
	mainMenu.queue_free()
