extends CharacterBody2D
class_name NPCScript

@export_category("NPC Names")
@export var displayName: String
@export var saveName: String

@export_category("NPC Persistent Data")
@export var data: NPCData

@export_category("NPC Dialogue")
@export_multiline var stdDialogue: Array[String]

@export_category("NPC Quests")
@export var quests: Array[Quest] = []
var acceptableQuests: Array[Quest] = []
var turningInSteps: Array[QuestStep] = []

@export_category("NPC Shop")
@export var hasShop: bool = false
@export var inventory: Inventory

@onready var NavAgent: NPCMovement = get_node("NavAgent")

var player: PlayerController = null
var npcsDir: String = "npcs/"

# Called when the node enters the scene tree for the first time.
func _ready():
	data = NPCData.new()
	data.position = position
	data.inventory = inventory
	call_deferred("fetch_player")

func fetch_player():
	player = PlayerFinder.player

func save_data(save_path):
	data.saveName = saveName
	data.position = position
	data.selectedTarget = NavAgent.selectedTarget
	data.loops = NavAgent.loops
	data.disableMovement = NavAgent.disableMovement
	data.inventory = inventory
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
		fetch_player()
		player.restore_dialogue(self)
		inventory = data.inventory
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

func get_cur_dialogue_item():
	if data.dialogueIndex < 0 or data.dialogueIndex >= len(data.dialogueItems):
		return null
	
	return data.dialogueItems[data.dialogueIndex]

func advance_dialogue():
	if len(data.dialogueItems) == 0: # if empty, try computing the dialogue again
		reset_dialogue()
	
	data.dialogueIndex += 1
	if data.dialogueIndex >= len(data.dialogueItems): # conversation is over
		data.dialogueIndex = -1
		data.dialogueItems = []
		NavAgent.disableMovement = data.previousDisableMove
		for q in acceptableQuests:
			PlayerResources.questInventory.accept_quest(q)
		for tracker in PlayerResources.questInventory.get_cur_trackers_for_target(saveName):
			if tracker.get_current_step().type == QuestStep.Type.TALK:
				tracker.add_current_step_progress()
	
	if data.dialogueIndex == 0: # conversation just started
		data.previousDisableMove = NavAgent.disableMovement
		NavAgent.disableMovement = true

func reset_dialogue():
	data.dialogueIndex = -1
	data.dialogueItems = []
	#data.dialogueItems.append_array(stdDialogue) show base dialogue
	fetch_quest_dialogue_info()
	for q in acceptableQuests:
		data.dialogueItems.append_array(q.startDialogue)
	for q in quests:
		var questTracker: QuestTracker = PlayerResources.questInventory.get_quest_tracker_by_quest(q)
		if questTracker != null:
			var curStep = questTracker.get_current_step()
			if questTracker.get_step_status(curStep) == QuestTracker.Status.IN_PROGRESS:
				data.dialogueItems.append_array(curStep.inProgressDialogue)
	for s in turningInSteps:
		data.dialogueItems.append_array(s.turnInDialogue)
	if len(data.dialogueItems) == 0: # only show base dialogue if no other dialogue is present (?)
		data.dialogueItems.append_array(stdDialogue)

func fetch_quest_dialogue_info():
	acceptableQuests = []
	turningInSteps = []
	for q in quests:
		var questTracker: QuestTracker = PlayerResources.questInventory.get_quest_tracker_by_quest(q)
		if questTracker == null:
			if PlayerResources.questInventory.has_completed_prereqs(q.prerequisiteQuestNames):
				acceptableQuests.append(q)
		else:
			var curStep: QuestStep = questTracker.get_current_step()
			if questTracker.get_step_status(curStep) == QuestTracker.Status.READY_TO_TURN_IN_STEP \
					and curStep.turnInName == saveName:
				turningInSteps.append(curStep)
