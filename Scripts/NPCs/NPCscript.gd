extends CharacterBody2D

@export var displayName: String
@export var saveName: String
@export var data: NPCData

@onready var NavAgent: NPCMovement = get_node("NavAgent")

var npcsDir: String = "npcs/"

# Called when the node enters the scene tree for the first time.
func _ready():
	data = NPCData.new()
	data.position = position
	pass # Replace with function body.

func save_data(save_path):
	if not DirAccess.dir_exists_absolute(save_path + npcsDir):
		var err = DirAccess.make_dir_absolute(save_path + npcsDir)
		if err > 0:
			print("DirAccess open create dir error " + String.num(err))
			
	data.saveName = saveName
	data.position = position
	data.selectedTarget = NavAgent.selectedTarget
	data.loops = NavAgent.loops
	data.disableMovement = NavAgent.disableMovement
	data.save_data(save_path + npcsDir, data)
	return
	
func load_data(save_path):
	data = NPCData.new()
	data.saveName = saveName
	var newData = data.load_data(save_path + npcsDir)
	if newData != null:
		data = newData
		# only load the new NPC data if we've 
		position = data.position
		NavAgent.selectedTarget = data.selectedTarget
		NavAgent.loops = data.loops
		NavAgent.disableMovement = data.disableMovement
		NavAgent.start_movement()
	return
