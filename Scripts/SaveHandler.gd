extends Node

var saved_scripts: Array = ["PlayerResources"]
var save_file_location: String = "user://"

var save_exists_file: String = "user://playerInfo.tres"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func save_data():
	for script in saved_scripts:
		var scr = get_node_or_null("/root/" + script)
		if scr != null and scr.has_method("save_data"):
			scr.call("save_data", save_file_location)

func load_data():
	for script in saved_scripts:
		var scr = get_node_or_null("/root/" + script)
		if scr != null and scr.has_method("load_data"):
			scr.call("load_data", save_file_location)
			
func new_game():
	for script in saved_scripts:
		var scr = get_node_or_null("/root/" + script)
		if scr != null and scr.has_method("new_game"):
			scr.call("new_game", save_file_location)
			
func save_file_exists():
	return FileAccess.file_exists(save_exists_file)
