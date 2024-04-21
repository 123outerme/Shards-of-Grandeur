@tool
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
@onready var talkArea: Area2D = get_node('TalkArea')
@onready var talkAreaShape: CollisionShape2D = get_node('TalkArea/TalkAreaShape')
@onready var NavAgent: NPCMovement = get_node('NavAgent')

var invisible: bool:
	get:
		return not visible
	set(value):
		_set_invisible(value)
		
var flip_h: bool:
	get:
		return npcSprite.flip_h
	set(value):
		_set_flip_h(value)

var initialTalkAlertSprPos: Vector2 = Vector2()
var initialTalkAreaPos: Vector2 = Vector2()
var initialTalkAreaShapePos: Vector2 = Vector2()

var player: PlayerController = null
var npcsDir: String = "npcs/"

# Called when the node enters the scene tree for the first time.
func _ready():
	if not visible:
		invisible = not visible # set collision properly with visibility being loaded from scene tree
	initialTalkAlertSprPos = talkAlertSprite.position
	initialTalkAreaPos = talkArea.position
	initialTalkAreaShapePos = talkAreaShape.position
	data = NPCData.new()
	data.position = position
	data.inventory = inventory
	call_deferred("fetch_player")
	if spawnRequirements != null and not spawnRequirements.is_valid():
		queue_free() # or alternatively set visible to false?

func fetch_player():
	if not Engine.is_editor_hint():
		player = PlayerFinder.player

func save_data(save_path) -> int:
	if saveName == '' or Engine.is_editor_hint():
		return 0
	data.saveName = saveName
	data.animSet = npcSprite.sprite_frames
	data.flipH = flip_h
	data.position = position
	data.selectedTarget = NavAgent.selectedTarget
	data.loops = NavAgent.loops
	data.disableMovement = NavAgent.disableMovement
	data.inventory = inventory
	data.visible = visible
	return data.save_data(save_path + npcsDir, data)
	
func load_data(save_path):
	if Engine.is_editor_hint():
		return # don't do anything to the data if in engine
	data = NPCData.new()
	data.saveName = saveName
	if saveName == '':
		return
	var newData = data.load_data(save_path + npcsDir)
	if newData != null:
		data = newData
		# only load the new NPC data if it exists
		if data.animSet != null:
			npcSprite.set_sprite_frames(data.animSet)
		position = data.position
		_set_flip_h(data.flipH)
		NavAgent.selectedTarget = data.selectedTarget
		NavAgent.loops = data.loops
		NavAgent.disableMovement = data.previousDisableMove
		NavAgent.radius = max(spriteSize.x, spriteSize.y) / 2
		NavAgent.start_movement()
		fetch_player()
		fetch_quest_dialogue_info()
		if data.dialogueLine > -1 and data.dialogueIndex < len(data.dialogueItems) \
				and data.dialogueItemIdx < len(data.dialogueItems[data.dialogueIndex].items):
			player.restore_dialogue(self)
		else:
			reset_dialogue()
		if GameSettings.get_version_differences(data.version) < GameSettings.VersionDiffs.MINOR:
			inventory = data.inventory
		else:
			print('DEBUG: resetting NPC inventory for ', saveName)
		invisible = not data.visible

func _set_invisible(value: bool):
	visible = not value
	if value:
		collision_layer = 0
	else:
		collision_layer = 0b01

func _set_flip_h(value: bool):
	if value != facesRight:
		talkAlertSprite.position.x = initialTalkAlertSprPos.x
		talkArea.position.x = initialTalkAreaPos.x
		talkAreaShape.position.x = initialTalkAreaShapePos.x
	else:
		talkAlertSprite.position.x = -1.0 * initialTalkAlertSprPos.x
		talkArea.position.x = -1.0 * initialTalkAreaPos.x
		talkAreaShape.position.x = -1.0 * initialTalkAreaShapePos.x
	npcSprite.flip_h = value

func get_collision_size() -> Vector2:
	return (colliderShape.shape as RectangleShape2D).get_rect().size

func _on_move_trigger_area_entered(area):
	if area.name == "PlayerEventCollider":
		NavAgent.start_movement()

func _on_talk_area_area_entered(area):
	if area.name == "PlayerEventCollider" and data.dialogueLine < 0:
		player.set_talk_npc(self)
		reset_dialogue()
		if len(data.dialogueItems) > 0 and not player.inCutscene:
			talkAlertSprite.visible = true
			pause_movement()
			face_player()
		data.dialogueLine = -1

func _on_talk_area_area_exited(area):
	if area.name == "PlayerEventCollider":
		player.set_talk_npc(self, true)
		unpause_movement()
		talkAlertSprite.visible = false

func get_cur_dialogue_item():
	if data.dialogueIndex < 0 or data.dialogueIndex >= len(data.dialogueItems):
		player.textBox.dialogueItem = null
		return null
	
	player.textBox.dialogueItem = data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx]
	
	return data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].lines[data.dialogueLine]

func repeat_dialogue_item():
	data.dialogueLine = 0

func advance_dialogue() -> bool:
	if len(data.dialogueItems) == 0 or data.dialogueLine == -1: # if empty, try computing the dialogue
		reset_dialogue()
	
	if len(data.dialogueItems) == 0:
		return false
	
	var hasDialogue: bool = true
	data.dialogueLine += 1
	if data.dialogueLine >= len(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].lines): # if the last line of this dialogue item
		data.dialogueItemIdx += 1
		data.dialogueLine = 0
		if data.dialogueItemIdx >= len(data.dialogueItems[data.dialogueIndex].items): # if the last entry of this item
			if saveName != '' and data.dialogueItems[data.dialogueIndex].entryId != '':
				PlayerResources.playerInfo.set_dialogue_seen(saveName, data.dialogueItems[data.dialogueIndex].entryId)
			var startingCutscene: bool = false
			if data.dialogueItems[data.dialogueIndex].startsCutscene != null:
				SceneLoader.cutscenePlayer.start_cutscene(data.dialogueItems[data.dialogueIndex].startsCutscene)
				startingCutscene = true
			if data.dialogueItems[data.dialogueIndex].entryId != '':
				# attempt to progress Talk quest(s) that require this NPC and dialogue item
				PlayerResources.questInventory.progress_quest(saveName + '#' + data.dialogueItems[data.dialogueIndex].entryId, QuestStep.Type.TALK)
			if data.dialogueItems[data.dialogueIndex].givesItem:
				PlayerResources.inventory.add_item(data.dialogueItems[data.dialogueIndex].givesItem)
				PlayerFinder.player.cam.show_alert('Got Item:\n' + data.dialogueItems[data.dialogueIndex].givesItem.itemName)
			if data.dialogueItems[data.dialogueIndex].fullHealsPlayer:
				PlayerResources.playerInfo.combatant.currentHp = PlayerResources.playerInfo.combatant.stats.maxHp
				PlayerFinder.player.cam.show_alert('Fully Healed!')
			if data.dialogueItems[data.dialogueIndex].startsStaticEncounter != null: # if it starts a static encounter (auto-closes dialogue)
				PlayerResources.playerInfo.staticEncounter = data.dialogueItems[data.dialogueIndex].startsStaticEncounter
				data.dialogueIndex = len(data.dialogueItems) # set to the last entry
			elif data.dialogueItems[data.dialogueIndex].closesDialogue: # if no static encounter, if it still closes dialogue
				data.dialogueIndex = len(data.dialogueItems) # set to the last entry
			data.dialogueIndex += 1
			data.dialogueItemIdx = 0
			update_dialogues_in_between()
			while data.dialogueIndex < len(data.dialogueItems) and not data.dialogueItems[data.dialogueIndex].can_use_dialogue():
				data.dialogueIndex += 1 # skip dialogues that cannot be used
			if data.dialogueIndex >= len(data.dialogueItems): # if the last entry, dialogue is over
				fetch_quest_dialogue_info()
				for q in acceptableQuests:
					PlayerResources.questInventory.accept_quest(q)
					PlayerFinder.player.cam.show_alert('Started Quest:\n' + q.questName)
				if not startingCutscene:
					play_animation('stand')
				data.dialogueIndex = 0
				data.dialogueItemIdx = 0
				data.dialogueLine = -1
				data.dialogueItems = []
		elif data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animation != '':
			play_animation(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animation)
	if data.dialogueIndex == 0 and data.dialogueItemIdx == 0 and data.dialogueLine == 0: # conversation just started
		data.previousDisableMove = true # make sure NPC movement state is paused on save/load
		play_animation(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animation)
		face_player()
	return hasDialogue

func reset_dialogue():
	data.dialogueIndex = 0
	data.dialogueItemIdx = 0
	data.dialogueLine = -1
	data.dialogueItems = [] # clear before fetching quest info
	fetch_quest_dialogue_info()
	data.dialogueItems = fetch_all_dialogues()
	
func fetch_all_dialogues() -> Array[DialogueEntry]:
	var dialogueItems: Array[DialogueEntry] = []
	for questTracker in PlayerResources.questInventory.quests:
		if questTracker != null:
			var curStep = questTracker.get_current_step()
			if curStep.inProgressDialogue != null and len(curStep.inProgressDialogue) > 0 \
					and questTracker.get_step_status(curStep) == QuestTracker.Status.IN_PROGRESS \
					and (questTracker.quest.storyRequirements == null or questTracker.quest.storyRequirements.is_valid()):
				if saveName in questTracker.get_prev_step().turnInNames \
						or (questTracker.get_prev_step().turnInNames == [] and saveName in curStep.turnInNames):
					dialogueItems.append_array(curStep.inProgressDialogue)
	for s in turningInSteps:
		if s.turnInDialogue != null and len(s.turnInDialogue) > 0:
			dialogueItems.append_array(s.turnInDialogue)
	for dialogue in dialogueEntries:
		if dialogue != null and dialogue.can_use_dialogue() and not dialogue in dialogueItems:
			dialogueItems.append(dialogue)
	return dialogueItems

func is_dialogue_item_last() -> bool:
	if len(data.dialogueItems) == 0:
		return true
	if data.dialogueIndex == len(data.dialogueItems) - 1 and \
			data.dialogueItemIdx == len(data.dialogueItems[data.dialogueIndex].items) - 1 and \
			data.dialogueLine == len(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].lines) - 1:
		return true
	return false

func fetch_quest_dialogue_info():
	acceptableQuests = []
	turningInSteps = []
	PlayerResources.questInventory.auto_update_quests()
	for entry in data.dialogueItems:
		if entry.startsQuest != null and PlayerResources.questInventory.can_start_quest(entry.startsQuest):
			acceptableQuests.append(entry.startsQuest)

	for questTracker in PlayerResources.questInventory.quests:
		var curStep: QuestStep = questTracker.get_current_step()
		if questTracker.get_step_status(curStep) == QuestTracker.Status.READY_TO_TURN_IN_STEP \
				and saveName in curStep.turnInNames and (questTracker.quest.storyRequirements == null or questTracker.quest.storyRequirements.is_valid()):
			turningInSteps.append(curStep)

func update_dialogues_in_between():
	fetch_quest_dialogue_info()
	# TODO test
	for questTracker in PlayerResources.questInventory.quests:
		if questTracker != null:
			var curStep = questTracker.get_current_step()
			if curStep.inProgressDialogue != null and len(curStep.inProgressDialogue) > 0 \
					and questTracker.get_step_status(curStep) == QuestTracker.Status.IN_PROGRESS \
					and (questTracker.quest.storyRequirements == null or questTracker.quest.storyRequirements.is_valid()):
				if saveName in questTracker.get_prev_step().turnInNames \
						or (questTracker.get_prev_step().turnInNames == [] and saveName in curStep.turnInNames):
					for dialogue in curStep.inProgressDialogue:
						if dialogue.can_use_dialogue():
							add_dialogue_entry_in_dialogue(dialogue, false)
	for s in turningInSteps:
		if s.turnInDialogue != null and len(s.turnInDialogue) > 0:
			for dialogue in s.turnInDialogue:
				if dialogue.can_use_dialogue():
					add_dialogue_entry_in_dialogue(dialogue, false)
	# TODO test end
	for dialogue in dialogueEntries:
		if not dialogue in data.dialogueItems and dialogue.can_use_dialogue():
			add_dialogue_entry_in_dialogue(dialogue, false)

func add_dialogue_entry_in_dialogue(dialogueEntry: DialogueEntry, repeat: bool = true) -> bool:
	if dialogueEntry.can_use_dialogue():
		var index: int = data.dialogueItems.find(dialogueEntry, 0)
		if index != -1: # reuse entry if it exists to support going back in the dialogue tree
			if repeat:
				data.dialogueIndex = index
				data.dialogueItemIdx = 0
				data.dialogueLine = 0
			return true
		else:
			index = mini(data.dialogueIndex + 1, len(data.dialogueItems))
			data.dialogueItems.insert(index, dialogueEntry)
	return false

func pause_movement():
	NavAgent.disableMovement = true
	play_animation('stand')
	
func unpause_movement():
	NavAgent.disableMovement = false

func face_player():
	if facesPlayer:
		face_horiz(player.position.x - position.x)

func set_sprite_frames(spriteFrames: SpriteFrames):
	npcSprite.sprite_frames = spriteFrames

func play_animation(animation: String):
	if animation != '':
		npcSprite.play(animation)

func face_horiz(xDirection: float):
	if xDirection < 0:
		flip_h = facesRight
	if xDirection > 0:
		flip_h = not facesRight

func _on_npc_sprite_animation_finished():
	play_animation('stand')
