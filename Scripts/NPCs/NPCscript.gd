extends CharacterBody2D
class_name NPCScript

@export_category("NPC Names")
@export var displayName: String
@export var saveName: String

@export_category("NPC Persistent Data")
@export var data: NPCData

@export_category("NPC Dialogue")
@export_multiline var stdDialogue: Array[String]

@onready var NavAgent: NPCMovement = get_node("NavAgent")
@onready var player: PlayerController = get_node("/root/Overworld/Player")

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
		if data.dialogueIndex >= 0:
			player.restore_dialogue(self)
	return

func _on_move_trigger_area_entered(area):
	if area.name == "PlayerEventCollider":
		NavAgent.start_movement()

func _on_talk_area_area_entered(area):
	if area.name == "PlayerEventCollider" and data.dialogueIndex < 0:
		player.set_talk_npc(self)
		reset_dialogue()

func _on_talk_area_area_exited(area):
	if area.name == "PlayerEventCollider":
		player.set_talk_npc(null)
		pass # Replace with function body.

func get_cur_dialogue_item():
	if data.dialogueIndex < 0 or data.dialogueIndex >= len(data.dialogueItems):
		return null
	
	return data.dialogueItems[data.dialogueIndex]

func advance_dialogue():
	data.dialogueIndex += 1
	if data.dialogueIndex >= len(data.dialogueItems):
		reset_dialogue()
		NavAgent.disableMovement = data.previousDisableMove
	else:
		data.previousDisableMove = NavAgent.disableMovement
		NavAgent.disableMovement = true

func reset_dialogue():
	data.dialogueIndex = -1
	data.dialogueItems = []
	data.dialogueItems.append_array(stdDialogue)
	# TODO: gather quest-related dialogue
