extends Node

var saved_scripts: Array
var save_file_location: String = "user://"

var subdirs: Array = ["npcs/"]

var save_exists_file: String = "user://playerInfo.tres"

# Called when the node enters the scene tree for the first time.
func _ready():
	fetch_saved_scripts()

func fetch_saved_scripts():
	saved_scripts = ["PlayerResources"]
	for item in len(saved_scripts):
		saved_scripts[item] = "/root/" + saved_scripts[item]
	
	var persist_nodes = get_tree().get_nodes_in_group("Persist")
	for node in persist_nodes:
		saved_scripts.append("/" + node.get_path().get_concatenated_names().c_escape())

func save_data():
	fetch_saved_scripts()
	for script_path in saved_scripts:
		var scr = get_node_or_null(NodePath(script_path))
		if scr != null and scr.has_method("save_data"):
			scr.call("save_data", save_file_location)

func load_data():
	fetch_saved_scripts()
	for script_path in saved_scripts:
		var scr = get_node_or_null(NodePath(script_path))
		if scr != null and scr.has_method("load_data"):
			scr.call("load_data", save_file_location)
			
func new_game():
	fetch_saved_scripts()
	for script_path in saved_scripts:
		var scr = get_node_or_null(NodePath(script_path))
		if scr != null and scr.has_method("new_game"):
			scr.call("new_game", save_file_location)
	for subdir in subdirs:
		DirAccess.remove_absolute(save_file_location + subdir)
			
func save_file_exists():
	return FileAccess.file_exists(save_exists_file)
