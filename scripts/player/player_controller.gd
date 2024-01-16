extends CharacterBody2D
class_name PlayerController

const SPEED = 80
@export var disableMovement: bool
@export var facingLeft: bool = false
var pickedUpItem: PickedUpItem = null
var inCutscene: bool = false
var cutsceneTexts: Array[CutsceneDialogue] = []
var cutsceneTextIndex: int = 0
var cutsceneLineIndex: int = 0
var holdingCamera: bool = false
var holdingCameraAt: Vector2
var makingChoice: bool = false
var pickedChoice: DialogueChoice = null
var actChanged: bool = false

@onready var collider: CollisionShape2D = get_node("ColliderShape")
@onready var sprite: AnimatedSprite2D = get_node("AnimatedPlayerSprite")
@onready var cam: PlayerCamera = get_node("Camera")
@onready var uiRoot: Node2D = get_node('UI')
@onready var textBox: TextBox = get_node("UI/TextBoxRoot")
@onready var inventoryPanel: InventoryMenu = get_node("UI/InventoryPanelNode")
@onready var questsPanel: QuestsMenu = get_node("UI/QuestsPanelNode")
@onready var statsPanel: StatsMenu = get_node("UI/StatsPanelNode")
@onready var pausePanel: PauseMenu = get_node("UI/PauseMenu")

var talkNPC: NPCScript = null
var talkNPCcandidates: Array[NPCScript] = []

func _unhandled_input(event):
	if event.is_action_pressed("game_pause"):
		if inCutscene:
			for cutscenePlayer in get_tree().get_nodes_in_group('CutscenePlayer'):
				cutscenePlayer.toggle_pause_cutscene()
			cam.toggle_cutscene_paused_shade()
		elif not statsPanel.visible and not inventoryPanel.visible and not questsPanel.visible:
			pausePanel.toggle_pause()
			if not pausePanel.isPaused and textBox.visible:
				textBox.refocus_choice(pickedChoice)
	
	if event.is_action_pressed("game_stats") and not inCutscene and not pausePanel.isPaused:
		statsPanel.stats = PlayerResources.playerInfo.stats
		statsPanel.curHp = PlayerResources.playerInfo.combatant.currentHp
		statsPanel.toggle()
		if statsPanel.visible:
			SceneLoader.pause_autonomous_movers()
		if inventoryPanel.visible:
			inventoryPanel.toggle()
		if questsPanel.visible:
			questsPanel.toggle()
		
	if (event.is_action_pressed("game_interact") or event.is_action_pressed("game_decline")) \
			and (len(talkNPCcandidates) > 0 or pickedUpItem != null or len(cutsceneTexts) > 0) \
			and not pausePanel.isPaused and not inventoryPanel.visible and not questsPanel.visible \
			and not statsPanel.visible and not makingChoice:
		if textBox.is_textbox_complete():
			advance_dialogue(event.is_action_pressed("game_interact"))
		else:
			textBox.show_text_instant()
			
	if event.is_action_pressed("game_inventory") and not inCutscene and not pausePanel.isPaused:
		inventoryPanel.inShop = false
		inventoryPanel.showPlayerInventory = false
		inventoryPanel.lockFilters = false
		inventoryPanel.toggle()
		if inventoryPanel.visible:
			SceneLoader.pause_autonomous_movers()
		if statsPanel.visible:
			statsPanel.toggle()
		if questsPanel.visible:
			questsPanel.toggle()
		
	if event.is_action_pressed("game_quests") and not inCutscene and not pausePanel.isPaused:
		questsPanel.turnInTargetName = ''
		questsPanel.lockFilters = false
		questsPanel.toggle()
		if questsPanel.visible:
			SceneLoader.pause_autonomous_movers()
		if statsPanel.visible:
			statsPanel.toggle()
		if inventoryPanel.visible:
			inventoryPanel.toggle()
		
func _physics_process(_delta):
	if not disableMovement:
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized() * SPEED
		if velocity.x < 0:
			facingLeft = true
		if velocity.x > 0:
			facingLeft = false
		sprite.flip_h = facingLeft
		if velocity.length() > 0:
			play_animation('walk')
		else:
			play_animation('stand')
		move_and_slide()
	if inCutscene and false:
		var vel = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized() * SPEED
		cam.position += vel * _delta
		
func _process(_delta):
	if holdingCamera:
		cam.position = holdingCameraAt - position
		uiRoot.position = holdingCameraAt - position

func set_sprite_frames(spriteFrames: SpriteFrames):
	sprite.sprite_frames = spriteFrames

func play_animation(animation: String):
	sprite.play(animation)

func face_horiz(xDirection: float):
	if xDirection > 0:
		facingLeft = false
		sprite.flip_h = false
	if xDirection < 0:
		facingLeft = true
		sprite.flip_h = true

func repeat_dialogue_item():
	if talkNPC == null:
		return
	talkNPC.repeat_dialogue_item()
	var dialogueText = talkNPC.get_cur_dialogue_item()
	textBox.advance_textbox(dialogueText)

func advance_dialogue(canStart: bool = true):
	if len(talkNPCcandidates) > 0 and not inCutscene: # if in NPC conversation
		if talkNPC == null:
			var minDistance: float = -1.0
			for npc in talkNPCcandidates:
				if npc.position.distance_to(position) < minDistance or minDistance == -1.0:
					minDistance = npc.position.distance_to(position)
					talkNPC = npc
		sprite.play('stand')
		if not canStart and not disableMovement: # if we are pressing game_decline, do not start conversation!
			talkNPC = null
			return
		var hasDialogue: bool = talkNPC.advance_dialogue()
		if not hasDialogue:
			talkNPC = null
			return
		
		var dialogueText = talkNPC.get_cur_dialogue_item()
		if dialogueText != null: # if there is NPC dialogue to display
			if talkNPC.data.dialogueIndex == 0: # if this is the beginning of the NPC dialogue
				SceneLoader.pause_autonomous_movers()
				SceneLoader.unpauseExcludedMover = talkNPC
				textBox.set_textbox_text(dialogueText, talkNPC.displayName)
				face_horiz(talkNPC.talkArea.global_position.x - global_position.x)
				for npc in talkNPCcandidates:
					if npc != talkNPC:
						npc.talkAlertSprite.visible = false
			else: # this is continuing the NPC dialogue
				textBox.advance_textbox(dialogueText)
		elif not inCutscene: # this is the end of NPC dialogue and it didn't start a cutscene
			textBox.hide_textbox()
			SceneLoader.unpause_autonomous_movers()
			for npc in talkNPCcandidates:
				npc.talkAlertSprite.visible = true
			talkNPC = null
			if PlayerResources.playerInfo.staticEncounter != null:
				SaveHandler.save_data()
				SceneLoader.load_battle()
			if actChanged:
				pause_movement()
				cam.play_new_act_animation(_new_act_callback)
		else:
			textBox.hide_textbox() # is this necessary??
			set_talk_npc(null, true) # is this necessary??
	elif pickedUpItem != null: # picked up dialogue
		pickedUpItem.savedTextIdx += 1
		put_pick_up_text()
	if len(cutsceneTexts) > 0: # cutscene dialogue
		cutsceneLineIndex += 1
		if cutsceneLineIndex >= len(cutsceneTexts[cutsceneTextIndex].texts): # if this dialogue item is done, move to the next
			cutsceneLineIndex = 0
			cutsceneTextIndex += 1
			if cutsceneTextIndex >= len(cutsceneTexts): # if there are no more dialogue items, close the textbox
				cutsceneTextIndex = 0
				cutsceneTexts = []
				textBox.hide_textbox()
				if not inCutscene: # cutscene is over now (ended while text box was still open)
					unpause_movement()
					cam.show_letterbox(false) # disable letterbox
			else: # otherwise show the new dialogue item
				textBox.set_textbox_text(cutsceneTexts[cutsceneTextIndex].texts[cutsceneLineIndex], cutsceneTexts[cutsceneTextIndex].speaker)
		else: # if it's not done, advance the textbox
			textBox.advance_textbox(cutsceneTexts[cutsceneTextIndex].texts[cutsceneLineIndex])

func select_choice(choice: DialogueChoice):
	if choice.opensShop:
		pickedChoice = choice
		_on_shop_button_pressed()
		return
	if choice.turnsInQuest:
		pickedChoice = choice
		_on_turn_in_button_pressed()
		return
	if choice.repeatsItem:
		makingChoice = false
		talkNPC.repeat_dialogue_item()
		var dialogueText = talkNPC.get_cur_dialogue_item()
		textBox.set_textbox_text(dialogueText, talkNPC.displayName)
		return
		
	if choice.leadsTo != null:
		var reused = talkNPC.add_dialogue_entry_in_dialogue(choice.leadsTo)
		if reused:
			var dialogueText = talkNPC.get_cur_dialogue_item()
			textBox.set_textbox_text(dialogueText, talkNPC.displayName)
			return
	
	makingChoice = false
	advance_dialogue()

func is_in_dialogue() -> bool:
	return textBox.visible

func set_talk_npc(npc: NPCScript, remove: bool = false):
	if npc == null:
		talkNPCcandidates = []
		talkNPC = null
		return
	
	if npc in talkNPCcandidates and remove:
			talkNPCcandidates.erase(npc)
			if not inCutscene:
				textBox.hide_textbox()
				disableMovement = false
	if not npc in talkNPCcandidates and not remove:
		talkNPCcandidates.append(npc)
	
func restore_dialogue(npc: NPCScript):
	var dialogueText = npc.get_cur_dialogue_item()
	if dialogueText != null and talkNPC == null:
		if not npc in talkNPCcandidates:
			talkNPCcandidates.append(npc)
		talkNPC = npc
		talkNPC.face_player()
		talkNPC.talkAlertSprite.visible = true
		SceneLoader.pause_autonomous_movers()
		pause_movement()
		textBox.set_textbox_text(dialogueText, talkNPC.displayName)
		textBox.show_text_instant()

func show_all_talk_alert_sprites():
	for candidate in talkNPCcandidates:
		candidate.talkAlertSprite.visible = true

func restore_picked_up_item_text(groundItem: PickedUpItem):
	pickedUpItem = groundItem
	if pickedUpItem != null:
		SceneLoader.pause_autonomous_movers()
		put_pick_up_text()
		textBox.show_text_instant()

func pause_movement():
	disableMovement = true

func unpause_movement():
	disableMovement = textBox.visible
	
func hold_camera_at(pos: Vector2):
	holdingCameraAt = pos
	holdingCamera = true

func snap_camera_back_to_player(duration: float = 0.5):
	if not holdingCamera:
		return # camera is already headed back to player
	holdingCamera = false
	if duration > 0:
		create_tween().tween_property(cam, 'position', Vector2(0, 0), duration)
		create_tween().tween_property(uiRoot, 'position', Vector2(0, 0), duration)
	else:
		cam.position = Vector2(0, 0)
		uiRoot.position = Vector2(0, 0)

func pick_up(groundItem: GroundItem):
	if PlayerResources.playerInfo.has_picked_up(groundItem.pickedUpItem.uniqueId):
		return
	
	pickedUpItem = groundItem.pickedUpItem
	pickedUpItem.wasPickedUp = PlayerResources.inventory.add_item(pickedUpItem.item)
	if pickedUpItem.wasPickedUp:
		PlayerResources.playerInfo.pickedUpItems.append(pickedUpItem.uniqueId)
		groundItem.queue_free()
		if PlayerResources.questInventory.can_start_quest(groundItem.startsQuest):
			PlayerResources.questInventory.accept_quest(groundItem.startsQuest)
	
	pickedUpItem.savedTextIdx = 0
	play_animation('stand')
	put_pick_up_text()

func put_pick_up_text():
	var hasNextDialogue: bool = true
	if not pickedUpItem.wasPickedUp:
		if pickedUpItem.savedTextIdx > 0:
			hasNextDialogue = false
		else:
			textBox.set_textbox_text('Your inventory is too full for this ' + pickedUpItem.item.itemName + '!', 'Inventory Full')
	else:
		if pickedUpItem.savedTextIdx >= len(pickedUpItem.pickUpTexts):
			hasNextDialogue = false
		else:
			textBox.set_textbox_text(pickedUpItem.pickUpTexts[pickedUpItem.savedTextIdx], 'Picked Up ' + pickedUpItem.item.itemName)
	
	if not hasNextDialogue:
		textBox.hide_textbox()
		SceneLoader.unpause_autonomous_movers()
		pickedUpItem = null
	else:
		SceneLoader.pause_autonomous_movers()

func queue_cutscene_texts(cutsceneDialogue: CutsceneDialogue):
	cutsceneTexts.append(cutsceneDialogue)
	if not textBox.visible:
		cutsceneTextIndex = len(cutsceneTexts) - 1
		cutsceneLineIndex = 0
		textBox.set_textbox_text(cutsceneTexts[cutsceneTextIndex].texts[cutsceneLineIndex], cutsceneTexts[cutsceneTextIndex].speaker)

func fade_in_unlock_cutscene(cutscene: Cutscene): # for use when faded-out cutscene must end after loading back in
	inCutscene = false
	cam.connect_to_fade_in(_fade_in_force_unlock_cutscene.bind(cutscene.saveName))

func get_collider(): # for use before full player initialization in MapLoader
	return get_node('ColliderShape')

func menu_closed():
	if not inventoryPanel.visible and not questsPanel.visible and not statsPanel.visible \
			and not textBox.visible and not pausePanel.visible:
		SceneLoader.unpause_autonomous_movers()

func _on_shop_button_pressed():
	#get_viewport().gui_release_focus()
	inventoryPanel.inShop = true
	inventoryPanel.showPlayerInventory = false
	inventoryPanel.shopInventory = talkNPC.inventory
	inventoryPanel.toggle()

func _on_turn_in_button_pressed():
	questsPanel.turnInTargetName = talkNPC.saveName
	get_viewport().gui_release_focus()
	questsPanel.toggle()
	disableMovement = true

func _on_inventory_panel_node_back_pressed():
	menu_closed()
	if textBox.visible:
		textBox.refocus_choice(pickedChoice)
		if pickedChoice != null and pickedChoice.opensShop:
			pickedChoice = null

func _on_quests_panel_node_back_pressed():
	menu_closed()
	if textBox.visible:
		textBox.refocus_choice(pickedChoice)
		if pickedChoice != null and pickedChoice.turnsInQuest != '':
			var questName = pickedChoice.turnsInQuest.split('#')[0]
			var stepName = pickedChoice.turnsInQuest.split('#')[1]
			var questTracker: QuestTracker = PlayerResources.questInventory.get_quest_tracker_by_name(questName)
			if questTracker != null:
				var step: QuestStep = questTracker.get_step_by_name(stepName)
				var status: QuestTracker.Status = questTracker.get_step_status(step)
				if status == QuestTracker.Status.COMPLETED:
					if pickedChoice.leadsTo != null:
						talkNPC.add_dialogue_entry_in_dialogue(pickedChoice.leadsTo)
					advance_dialogue()

func _on_stats_panel_node_attempt_equip_weapon_to(stats: Stats):
	inventoryPanel.selectedFilter = Item.Type.WEAPON
	equip_to_combatant_helper(stats)

func _on_stats_panel_node_attempt_equip_armor_to(stats: Stats):
	inventoryPanel.selectedFilter = Item.Type.ARMOR
	equip_to_combatant_helper(stats)

func equip_to_combatant_helper(stats: Stats):
	inventoryPanel.lockFilters = true
	inventoryPanel.equipContextStats = stats
	inventoryPanel.inShop = false
	inventoryPanel.shopInventory = null
	statsPanel.visible = false
	statsPanel.reset_panel_to_player()
	menu_closed()
	inventoryPanel.toggle()

func _on_stats_panel_node_back_pressed():
	statsPanel.levelUp = false
	menu_closed()
	if textBox.visible:
		if pickedChoice != null and pickedChoice.turnsInQuest != '':
			if pickedChoice.leadsTo != null:
				talkNPC.add_dialogue_entry_in_dialogue(pickedChoice.leadsTo)
			advance_dialogue()
		else:
			textBox.refocus_choice(pickedChoice)

func _on_quests_panel_node_turn_in_step_to(saveName):
	if saveName == talkNPC.saveName:
		talkNPC.fetch_quest_dialogue_info()

func _on_quests_panel_node_level_up(newLevels: int):
	if newLevels == 0:
		return
	statsPanel.levelUp = true
	statsPanel.stats = PlayerResources.playerInfo.stats
	statsPanel.curHp = PlayerResources.playerInfo.combatant.currentHp
	statsPanel.isPlayer = true
	SceneLoader.pause_autonomous_movers() # make sure autonomous movers are paused
	inventoryPanel.visible = false
	questsPanel.visible = false
	statsPanel.visible = false # show stats panel for sure
	statsPanel.toggle()

func _fade_in_force_unlock_cutscene(cutsceneSaveName: String):
	if not inCutscene:
		cam.show_letterbox(false)
		PlayerResources.playerInfo.set_cutscene_seen(cutsceneSaveName)
		PlayerResources.questInventory.auto_update_quests() # complete any quest steps that end on this cutscene
		unpause_movement()

func _on_quests_panel_node_act_changed():
	actChanged = true

func _new_act_callback():
	actChanged = false
	unpause_movement()
