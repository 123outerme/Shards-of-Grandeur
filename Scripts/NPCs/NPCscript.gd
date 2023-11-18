extends CharacterBody2D
class_name NPCScript

@export_category("NPC General Data")
@export var displayName: String
@export var saveName: String
@export var facesRight: bool = true
@export var spriteSize: Vector2i = Vector2i(16, 16)
@export var spawnRequirements: StoryRequirements = null

@export_category("NPC Persistent Data")
@export var data: NPCData

@export_category("NPC Dialogue")
@export var dialogueEntries: Array[DialogueEntry] = []
@export var facesPlayer: bool = true

@export_category("NPC Shop")
@export var hasShop: bool = false
@export var inventory: Inventory

var acceptableQuests: Array[Quest] = []
var turningInSteps: Array[QuestStep] = []

@onready var npcSprite: AnimatedSprite2D = get_node("NPCSprite")
@onready var talkAlertSprite: Sprite2D = get_node("NPCSprite/TalkAlertSprite")
@onready var colliderShape: CollisionShape2D = get_node('ColliderShape')
@onready var NavAgent: NPCMovement = get_node("NavAgent")

var player: PlayerController = null
var npcsDir: String = "npcs/"

# Called when the node enters the scene tree for the first time.
func _ready():
	data = NPCData.new()
	data.position = position
	data.inventory = inventory
	call_deferred("fetch_player")
	if spawnRequirements != null and not spawnRequirements.is_valid():
		queue_free() # or alternatively set visible to false?

func fetch_player():
	player = PlayerFinder.player

func save_data(save_path):
	if saveName == '':
		return
	data.saveName = saveName
	data.flipH = npcSprite.flip_h
	data.position = position
	data.selectedTarget = NavAgent.selectedTarget
	data.loops = NavAgent.loops
	data.disableMovement = NavAgent.disableMovement
	data.inventory = inventory
	data.save_data(save_path + npcsDir, data)
	
func load_data(save_path):
	data = NPCData.new()
	data.saveName = saveName
	if saveName == '':
		return
	var newData = data.load_data(save_path + npcsDir)
	if newData != null:
		data = newData
		# only load the new NPC data if it exists
		position = data.position
		npcSprite.flip_h = data.flipH
		NavAgent.selectedTarget = data.selectedTarget
		NavAgent.loops = data.loops
		NavAgent.disableMovement = data.previousDisableMove
		NavAgent.start_movement()
		fetch_player()
		fetch_quest_dialogue_info()
		if data.dialogueLine > -1:
			player.restore_dialogue(self)
		inventory = data.inventory

func get_collision_size() -> Vector2:
	return (colliderShape.shape as RectangleShape2D).get_rect().size

func _on_move_trigger_area_entered(area):
	if area.name == "PlayerEventCollider":
		NavAgent.start_movement()

func _on_talk_area_area_entered(area):
	if area.name == "PlayerEventCollider" and data.dialogueLine < 0:
		player.set_talk_npc(self)
		talkAlertSprite.visible = true
		data.dialogueLine = -1

func _on_talk_area_area_exited(area):
	if area.name == "PlayerEventCollider":
		if player.talkNPC == self:
			player.set_talk_npc(null)
		if len(data.dialogueItems) == 0: # if dialogue is over when the player leaves
			data.previousDisableMove = false # ensure movement is unpaused no matter what
			unpause_movement()
		talkAlertSprite.visible = false

func get_cur_dialogue_item():
	if data.dialogueIndex < 0 or data.dialogueIndex >= len(data.dialogueItems):
		player.textBox.dialogueItem = null
		return null
	
	player.textBox.dialogueItem = data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx]
	
	return data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].lines[data.dialogueLine]

func advance_dialogue():
	if len(data.dialogueItems) == 0 or data.dialogueLine == -1: # if empty, try computing the dialogue
		reset_dialogue()
	
	data.dialogueLine += 1
	if data.dialogueLine >= len(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].lines): # if the last line of this dialogue item
		data.dialogueItemIdx += 1
		data.dialogueLine = 0
		if data.dialogueItemIdx >= len(data.dialogueItems[data.dialogueIndex].items): # if the last entry of this item
			if saveName != '':
				PlayerResources.playerInfo.set_dialogue_seen(saveName, data.dialogueItems[data.dialogueIndex].entryId)
			data.dialogueIndex += 1
			data.dialogueItemIdx = 0
			if data.dialogueIndex >= len(data.dialogueItems): # if the last entry, dialogue is over
				PlayerResources.questInventory.progress_quest(saveName, QuestStep.Type.TALK)
				fetch_quest_dialogue_info()
				for q in acceptableQuests:
					PlayerResources.questInventory.accept_quest(q)
				play_animation('stand')
				data.dialogueIndex = 0
				data.dialogueLine = -1
				data.dialogueItems = []
				talkAlertSprite.visible = true
		elif data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animation != '':
			play_animation(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animation)
	
	if data.dialogueIndex == 0 and data.dialogueItemIdx == 0 and data.dialogueLine == 0: # conversation just started
		data.previousDisableMove = true # make sure NPC movement state is paused on save/load
		face_player()
		talkAlertSprite.visible = false


func reset_dialogue():
	data.dialogueIndex = 0
	data.dialogueItemIdx = 0
	data.dialogueLine = -1
	data.dialogueItems = []
	fetch_quest_dialogue_info()
	for questTracker in PlayerResources.questInventory.quests:
		if questTracker != null:
			var curStep = questTracker.get_current_step()
			if questTracker.get_step_status(curStep) == QuestTracker.Status.IN_PROGRESS \
					and questTracker.get_prev_step().turnInName == saveName and questTracker.quest.storyRequirements.is_valid():
				data.dialogueItems.append_array(curStep.inProgressDialogue)
	for s in turningInSteps:
		data.dialogueItems.append_array(s.turnInDialogue)
	for dialogue in dialogueEntries:
		if dialogue.can_use_dialogue():
			data.dialogueItems.append(dialogue)

func fetch_quest_dialogue_info():
	acceptableQuests = []
	turningInSteps = []
	PlayerResources.questInventory.update_collect_quests()
	for entry in data.dialogueItems:
		if entry.startsQuest != null and PlayerResources.questInventory.can_start_quest(entry.startsQuest):
			acceptableQuests.append(entry.startsQuest)

	for questTracker in PlayerResources.questInventory.quests:
		var curStep: QuestStep = questTracker.get_current_step()
		if questTracker.get_step_status(curStep) == QuestTracker.Status.READY_TO_TURN_IN_STEP \
				and curStep.turnInName == saveName and questTracker.quest.storyRequirements.is_valid():
			turningInSteps.append(curStep)

func add_dialogue_entry_in_dialogue(dialogueEntry: DialogueEntry):
	if dialogueEntry.can_use_dialogue():
		data.dialogueItems.insert(data.dialogueIndex + 1, dialogueEntry)

func pause_movement():
	NavAgent.disableMovement = true
	
func unpause_movement():
	NavAgent.disableMovement = data.previousDisableMove # unpause if previously was unpaused

func face_player():
	if facesPlayer:
		face_horiz(player.position.x - position.x)

func play_animation(animation: String):
	npcSprite.play(animation)

func face_horiz(xDirection: float):
	if xDirection < 0:
		npcSprite.flip_h = facesRight
	if xDirection > 0:
		npcSprite.flip_h = not facesRight

func _on_npc_sprite_animation_finished():
	play_animation('stand')
