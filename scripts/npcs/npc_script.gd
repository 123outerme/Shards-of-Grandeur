@tool
extends CharacterBody2D
class_name NPCScript

@export_category("NPC General Data")

## name used in dialogue
@export var displayName: String

## name used in saving NPC data
@export var saveName: String

## name used for determining whether this NPC acts as a follower (separate from saveName for consistency between maps)
@export var followerId: String = ''

## if true, this NPC's sprite faces right by default (without flipping)
@export var facesRight: bool = true

## if true, the NPC's first load (before any save data exist) will load the sprite flipped
@export var loadFlipH: bool = false

## if true, flips the walking animation to walk backwards
@export var walkBackwards: bool = false

## sprite state to use when first loading the NPC (w/o save data for this NPC)
@export var spriteState: String = 'default'

## String -> SpriteFrames: maps NPC sprite state string to the SpriteFrames for that state
@export var stateSpritesDict: Dictionary[String, SpriteFrames] = {
	'default': null
}

## visual size of sprite (used for determining NavAgent radius, etc.)
@export var spriteSize: Vector2i = Vector2i(16, 16)

## if not null, will be the sprite used as the dialogue speaker for this NPC
@export var overrideSpeakerSprite: SpriteFrames = null

## if `overrideSpeakerSprite` is not null, will be used for scaling the dialogue speaker with the override sprite
@export var overrideSpeakerSpriteSize: Vector2i = Vector2i(16, 16)

## how to offset the NPC's sprite when displaying as the speaker in the text box 
@export var speakerSpriteOffset: Vector2 = Vector2.ZERO

## if the provided requirements are invalid, the NPC will be freed from the scene
@export var spawnRequirements: StoryRequirements = null

## StoryRequirement results or'd together: if all of the provided requirements are invalid, the NPC will be freed from the scene. `spawnRequirements` is processed first so it will override these
@export var orSpawnRequirements: Array[StoryRequirements] = []

@export_category("NPC Persistent Data")
@export var data: NPCData

@export_category("NPC Dialogue")

## dialogue that the NPC will have available
@export var dialogueEntries: Array[DialogueEntry] = []

## if true, turns to face the player when starting dialogue
@export var facesPlayer: bool = true

@export_category("NPC Shop")

## current NPC inventory
@export var inventory: Inventory

## the NPC shop object to create/update the inventory from
@export var npcShop: NpcShop = null

var acceptableQuests: Array[Quest] = []
var turningInSteps: Array[QuestStep] = []

@onready var npcSprite: AnimatedSprite2D = get_node("NPCSprite")
@onready var talkAlertSprite: Sprite2D = get_node("NPCSprite/TalkAlertSprite")
@onready var colliderShape: CollisionShape2D = get_node('ColliderShape')
@onready var talkArea: Area2D = get_node('TalkArea')
@onready var talkAreaShape: CollisionShape2D = get_node('TalkArea/TalkAreaShape')
@onready var moveAreaShape: CollisionShape2D = get_node('MoveTrigger/MoveTriggerShape')
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


var sprite_modulate: Color:
	get:
		if npcSprite == null:
			return Color()
		return npcSprite.self_modulate
	set(c):
		if npcSprite != null:
			npcSprite.self_modulate = c

var follower_home_pos: Vector2:
	get:
		if data != null:
			return data.followerHomePosition
		return Vector2.ZERO
	set(p):
		if data != null:
			data.followerHomePosition = p

var combatMode: bool = false

var initialTalkAlertSprPos: Vector2 = Vector2()
var initialTalkAreaPos: Vector2 = Vector2()
var initialTalkAreaShapePos: Vector2 = Vector2()

## if true, will make the current position the NPC's new follower home when being unset as a follower. Used in cutscenes to have more control over followers
var unfollowMakeNewHome: bool = false

var player: PlayerController = null
var npcsDir: String = "npcs/"

# Called when the node enters the scene tree for the first time.
func _ready():
	if not visible:
		invisible = not visible # set collision properly with visibility being loaded from scene tree
	initialTalkAlertSprPos = talkAlertSprite.position
	initialTalkAreaPos = talkArea.position
	initialTalkAreaShapePos = talkAreaShape.position
	#print(name, ' ', spriteState)
	set_sprite_state(spriteState)
	
	data = NPCData.new()
	data.position = position
	if npcShop != null and inventory == null and not Engine.is_editor_hint():
		inventory = Inventory.new()
	data.inventory = inventory
	data.spriteState = spriteState
	call_deferred("fetch_player")
	
	if not Engine.is_editor_hint():
		if spawnRequirements != null and not spawnRequirements.is_valid():
			queue_free() # or alternatively set visible to false?
		var allowedToSpawn: bool = StoryRequirements.list_is_valid(orSpawnRequirements)
		if not allowedToSpawn:
			queue_free()

		flip_h = loadFlipH
		PlayerResources.story_requirements_updated.connect(_story_reqs_updated)

func fetch_player():
	if not Engine.is_editor_hint():
		player = PlayerFinder.player

func save_data(save_path) -> int:
	if saveName == '' or Engine.is_editor_hint():
		return 0
	data.saveName = saveName
	data.spriteState = spriteState
	data.animation = npcSprite.animation
	data.flipH = flip_h
	if NavAgent.returnToFollowerHome:
		data.animation = get_stand_animation()
		data.position = data.followerHomePosition # make the NPC automatically jump to the follower home if trying to go back there now
	else:
		data.animation = npcSprite.animation
		data.position = position
	data.combatMode = combatMode
	data.selectedTarget = NavAgent.selectedTarget
	data.loops = NavAgent.loops
	data.disableMovement = NavAgent.disableMovement
	data.afterMoveWaitAccum = NavAgent.afterMoveWaitAccum
	# in case we're saving the frame the nav agent reached its target, add a little offset
	# this is so on load, reachedTarget will be set to be true
	if NavAgent.reachedTarget:
		data.afterMoveWaitAccum += 0.0001
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
		set_sprite_state(data.spriteState)
		npcSprite.play(data.animation)
		position = data.position
		combatMode = data.combatMode
		_set_flip_h(data.flipH)
		NavAgent.selectedTarget = data.selectedTarget
		NavAgent.loops = data.loops
		NavAgent.disableMovement = data.previousDisableMove
		NavAgent.radius = max(spriteSize.x, spriteSize.y) / 2
		NavAgent.afterMoveWaitAccum = data.afterMoveWaitAccum
		NavAgent.reachedTarget = NavAgent.afterMoveWaitAccum > 0
		NavAgent.start_movement()
		fetch_player()
		fetch_quest_dialogue_info()
		if data.dialogueLine > -1 and data.dialogueIndex < len(data.dialogueItems) \
				and data.dialogueItemIdx < len(data.dialogueItems[data.dialogueIndex].items):
			player.restore_dialogue(self)
		else:
			reset_dialogue()
		inventory = data.inventory
		if inventory == null:
			inventory = Inventory.new()
		if npcShop != null:
			add_shop_items_to_inventory()
			inventory.inventorySlots.sort_custom(_sort_shop_items)
		invisible = not data.visible
	else:
		if npcShop != null and inventory == null:
			inventory = Inventory.new()
		add_shop_items_to_inventory()
		if inventory != null and npcShop != null:
			inventory.inventorySlots.sort_custom(_sort_shop_items)
	if not data.followerHomeSet:
		data.followerHomePosition = position
		data.followerHomeSet = true
	if followerId != '':
		set_following_player(PlayerResources.playerInfo.has_active_follower(followerId), true)

func add_shop_items_to_inventory():
	if not npcShop != null or inventory == null:
		return
	
	# for each item in the NPC's shop, if it's a shop slot and the NPC shop object has no record of it: remove it
	var removeSlots: Array[int] = []
	for idx in range(len(inventory.inventorySlots)):
		var itemSlot: InventorySlot = inventory.inventorySlots[idx]
		if itemSlot is ShopInventorySlot and not (npcShop.has_item_in_shop(itemSlot.item)):
			removeSlots.append(idx)
			print('NPC ' + saveName + ' no longer carries ' + itemSlot.item.itemName + '. Removing')

	# for each recorded index to remove, remove that slot
	for idx in removeSlots:
		inventory.inventorySlots.remove_at(idx)

	# for each shop item slot in the NPC shop object:
	for shopItemSlot: ShopInventorySlot in npcShop.shopItemSlots:
		var existingSlot: InventorySlot = inventory.get_slot_for_item(shopItemSlot.item)
		# if there is no slot for this object: add it to the inventory
		if existingSlot == null: #or shopItemSlot.should_add(data.version):
			inventory.add_slot(shopItemSlot.copy())

func _sort_shop_items(a: InventorySlot, b: InventorySlot) -> bool:
	if npcShop == null:
		return false
	# return true if a should go before b, when a's index in the shop definition is before b's
	var aIdx: int = -1
	var bIdx: int = -1
	for idx: int in range(len(npcShop.shopItemSlots)):
		if a.item == npcShop.shopItemSlots[idx].item:
			aIdx = idx
		if b.item == npcShop.shopItemSlots[idx].item:
			bIdx = idx
	return aIdx < bIdx

func _set_invisible(value: bool):
	visible = not value
	update_collision_layer(not value)

func update_collision_layer(enabled: bool):
	if not enabled:
		# not calling disable_collision() so cutscenes don't re-enable NPC collision after they are made invisible/followers
		collision_layer = 0
	else:
		# not calling enable_collision() for same reasoning as above
		collision_layer = 0b01

func disable_collision():
	colliderShape.set_deferred('disabled', true)

func enable_collision():
	colliderShape.set_deferred('disabled', false)

func is_collision_enabled():
	return not colliderShape.disabled

func disable_event_collisions():
	talkAreaShape.disabled = true
	moveAreaShape.disabled = true

func enable_event_collisions():
	talkAreaShape.disabled = false
	moveAreaShape.disabled = false

func _set_flip_h(value: bool):
	if value:
		talkAlertSprite.position.x = -1.0 * initialTalkAlertSprPos.x
		talkArea.position.x = -1.0 * initialTalkAreaPos.x
		talkAreaShape.position.x = -1.0 * initialTalkAreaShapePos.x
	else:
		talkAlertSprite.position.x = initialTalkAlertSprPos.x
		talkArea.position.x = initialTalkAreaPos.x
		talkAreaShape.position.x = initialTalkAreaShapePos.x
		
	npcSprite.flip_h = value

func get_collision_size() -> Vector2:
	return (colliderShape.shape as RectangleShape2D).get_rect().size

func _on_move_trigger_area_entered(area):
	if area.name == "PlayerEventCollider":
		NavAgent.start_movement()

func _on_talk_area_area_entered(area):
	if area.name == "PlayerEventCollider" and data.dialogueLine < 0:
		reset_dialogue()
		player.set_talk_npc(self)
		if len(data.dialogueItems) > 0 and not player.inCutscene:
			talkAlertSprite.visible = true
			#if not data.followingPlayer:
			pause_movement()
			face_player()
		data.dialogueLine = -1

func _on_talk_area_area_exited(area):
	if area.name == "PlayerEventCollider":
		player.set_talk_npc(self, true)
		unpause_movement()
		talkAlertSprite.visible = false

func get_cur_dialogue_entry() -> DialogueEntry:
	if data.dialogueIndex < 0 or data.dialogueIndex >= len(data.dialogueItems):
		return null
		
	return data.dialogueItems[data.dialogueIndex]

func get_cur_dialogue_item(updateTextBox: bool = true) -> DialogueItem:
	if data.dialogueIndex < 0 or data.dialogueIndex >= len(data.dialogueItems):
		if updateTextBox:
			player.textBox.dialogueItem = null
			player.textBox.dialogueItemIdx = -1
		return null
	
	if updateTextBox:
		player.textBox.dialogueItem = data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx]
		player.textBox.dialogueItemIdx = data.dialogueItemIdx
	
	return data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx]

func get_cur_dialogue_string() -> String:
	if data.dialogueIndex < 0 or data.dialogueIndex >= len(data.dialogueItems):
		player.textBox.dialogueItem = null
		player.textBox.dialogueItemIdx = -1
		return ''
	
	player.textBox.dialogueItem = data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx]
	player.textBox.dialogueItemIdx = data.dialogueItemIdx
	
	return data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].get_lines()[data.dialogueLine]

func repeat_dialogue_item():
	data.dialogueLine = 0

func advance_dialogue() -> bool:
	if len(data.dialogueItems) == 0 or data.dialogueLine == -1: # if empty, try computing the dialogue
		reset_dialogue()
	
	if len(data.dialogueItems) == 0:
		return false
	
	var hasDialogue: bool = true
	data.dialogueLine += 1
	if data.dialogueLine >= len(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].get_lines()): # if the last line of this dialogue item
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
				PlayerFinder.player.cam.show_alert('Got Item:\n' + data.dialogueItems[data.dialogueIndex].givesItem.itemName, data.dialogueItems[data.dialogueIndex].givesItem.itemSprite)
			if data.dialogueItems[data.dialogueIndex].fullHealsPlayer:
				PlayerResources.playerInfo.combatant.currentHp = PlayerResources.playerInfo.combatant.stats.maxHp
				PlayerFinder.player.cam.show_alert('Fully Healed!')
			if data.dialogueItems[data.dialogueIndex].startsStaticEncounter != null: # if it starts a static encounter (auto-closes dialogue)
				PlayerResources.playerInfo.encounter = data.dialogueItems[data.dialogueIndex].startsStaticEncounter
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
					var accepted: bool = PlayerResources.questInventory.accept_quest(q)
					if accepted:
						PlayerFinder.player.cam.show_alert('Started Quest:\n' + q.questName)
				if not startingCutscene:
					play_animation(get_stand_animation())
				data.dialogueIndex = 0
				data.dialogueItemIdx = 0
				data.dialogueLine = -1
				data.dialogueItems = []
			else:
				if data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animation != '':
					play_animation(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animation)
		else:
			if data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animation != '':
				play_animation(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animation)
			if data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].actorAnimation != '':
				var node: Node = SceneLoader.cutscenePlayer.fetch_actor_node(
					data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animateActorTreePath,
					data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].animateActorIsPlayer
				)
				if node != null:
					if node.has_method('play_animation'):
						node.play_animation(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].actorAnimation)
					else:
						print('Actor ' , node.name, ' was asked to play an animation but it doesn\'t implement play_animation()')

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
						or (len(questTracker.get_prev_step().turnInNames) == 0 and saveName in curStep.turnInNames):
					dialogueItems.append_array(curStep.inProgressDialogue)
	for s in turningInSteps:
		if s.turnInDialogue != null and len(s.turnInDialogue) > 0:
			dialogueItems.append_array(s.turnInDialogue)
	for dialogue in dialogueEntries:
		if dialogue != null and dialogue.can_use_dialogue() and not dialogue in dialogueItems:
			dialogueItems.append(dialogue)
	return dialogueItems.filter(_filter_out_null)

func is_dialogue_item_last() -> bool:
	if len(data.dialogueItems) == 0:
		return true
	if data.dialogueIndex == len(data.dialogueItems) - 1 and \
			data.dialogueItemIdx == len(data.dialogueItems[data.dialogueIndex].items) - 1 and \
			data.dialogueLine == len(data.dialogueItems[data.dialogueIndex].items[data.dialogueItemIdx].get_lines()) - 1:
		return true
	return false

func is_dialogue_entry_last() -> bool:
	if len(data.dialogueItems) == 0:
		return true
	return data.dialogueIndex == len(data.dialogueItems) - 1

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
						if dialogue == null:
							continue
						if dialogue.can_use_dialogue():
							add_dialogue_entry_in_dialogue(dialogue, false)
	for s in turningInSteps:
		if s.turnInDialogue != null and len(s.turnInDialogue) > 0:
			for dialogue in s.turnInDialogue:
				if dialogue == null:
					continue
				if dialogue.can_use_dialogue():
					add_dialogue_entry_in_dialogue(dialogue, false)
	# TODO test end
	for dialogue in dialogueEntries:
		if dialogue == null:
			continue
		if not dialogue in data.dialogueItems and dialogue.can_use_dialogue():
			add_dialogue_entry_in_dialogue(dialogue, false)

func add_dialogue_entry_in_dialogue(dialogueEntry: DialogueEntry, repeat: bool = true) -> bool:
	if dialogueEntry == null:
		return false
	if dialogueEntry.can_use_dialogue():
		var index: int = data.dialogueItems.find(dialogueEntry, 0)
		if index != -1: # reuse entry if it exists to support going back in the dialogue tree
			if repeat:
				# remove it and stick it at the end of the dialogue stack, so dialogue traversal doesn't reuse any items we've already seen
				data.dialogueItems.erase(dialogueEntry)
				data.dialogueItems.append(dialogueEntry)
				
				data.dialogueIndex = len(data.dialogueItems) - 1
				data.dialogueItemIdx = 0
				data.dialogueLine = 0
			return true
		else:
			index = mini(data.dialogueIndex + 1, len(data.dialogueItems))
			data.dialogueItems.insert(index, dialogueEntry)
	return false

func pause_movement():
	NavAgent.disableMovement = true
	if self != PlayerFinder.player.talkNPC:
		play_animation(get_stand_animation())
	
func unpause_movement():
	NavAgent.disableMovement = false

func face_player():
	if facesPlayer:
		face_horiz(player.position.x - position.x)

func set_sprite_state(state: String):
	if stateSpritesDict.has(state):
		if stateSpritesDict[state] != null:
			npcSprite.sprite_frames = stateSpritesDict[state]
		spriteState = state
	else:
		printerr('NPC sprite state error: NPC at ', get_path(), ' (save name ', saveName, ') does not have sprite state "', state, '"')

func play_animation(animation: String):
	if animation != '':
		npcSprite.play(animation)

func get_sprite_frames() -> SpriteFrames:
	if overrideSpeakerSprite != null:
		return overrideSpeakerSprite
	return npcSprite.sprite_frames

func get_max_sprite_size() -> Vector2i:
	if overrideSpeakerSprite != null:
		return overrideSpeakerSpriteSize
	return spriteSize

func get_stand_animation() -> String:
	return 'stand' if not combatMode else 'battle_idle'

func face_horiz(xDirection: float):
	if xDirection < 0:
		flip_h = facesRight
	if xDirection > 0:
		flip_h = not facesRight
	if walkBackwards:
		flip_h = not flip_h

func set_following_player(following: bool, onLoad: bool = false):
	if not visible:
		return
	
	update_collision_layer(not following)
	
	var navToHomeFirst: bool = false
	# the NPC is being set to follow/unfollow while already being loaded
	if following:
		if onLoad:
			# the follower NPC is loading in (almost done); snap the NPC to the player's position
			position = PlayerFinder.player.position
			unpause_movement()
		else:
			# if the NPC is just being set as a follower after being loaded: let the follower nav to the player
			if not data.followingPlayer:
				data.followerHomePosition = position
				data.followerHomeSet = true
				unpause_movement()
	else:
		# the NPC is not a follower now
		if onLoad:
			if data.followingPlayer:
				position = data.followerHomePosition # TODO: this NPC has been unset to follow the player while unloaded; snap it back to its home
		else:
			if data.followingPlayer:
				# if the NPC should make this place their new home when unfollowing instead of going back to their old home
				if unfollowMakeNewHome:
					data.followerHomePosition = position
				else:
					navToHomeFirst = true
	data.followingPlayer = following
	NavAgent.set_follower_mode(following, navToHomeFirst)

func _on_npc_sprite_animation_finished():
	play_animation(get_stand_animation())

func _story_reqs_updated():
	# NOTE: being spawned not automatically updated here because if the NPC is onscreen, it would look strange
	# this logic is already being depended on by the King Rat in Hilltop Forest
	if player != null and self in player.talkNPCcandidates and not self == player.talkNPC:
		reset_dialogue()
		if len(data.dialogueItems) > 0 and not player.inCutscene:
			talkAlertSprite.visible = true
			pause_movement()
			face_player()
		data.dialogueLine = -1
		player.update_interact_touch_ui()
	
	var setFollower: bool = PlayerResources.playerInfo.has_active_follower(followerId)
	if setFollower != data.followingPlayer and visible:
		set_following_player(setFollower)

func _filter_out_null(v) -> bool:
	return v != null
