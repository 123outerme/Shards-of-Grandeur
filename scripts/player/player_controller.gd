extends CharacterBody2D
class_name PlayerController

const BASE_SPEED = 80
const RUN_SPEED = 120
# cooldowns calculated from animation framerate and "step" frame timings
const BASE_STEP_SFX_COOLDOWN: float = 0.5714
const RUN_STEP_SFX_COOLDOWN: float = 0.3636

@export var disableMovement: bool
@export var facingLeft: bool = false
@export var teleportSfx: AudioStream = null
@export var stepSfx: Array[AudioStream] = []

var speed = BASE_SPEED
var pickedUpItem: PickedUpItem = null
var inCutscene: bool = false
var cutsceneTexts: Array[CutsceneDialogue] = []
var cutsceneTextIndex: int = 0
var cutsceneLineIndex: int = 0
var holdCameraX: bool = false
var holdCameraY: bool = false
var holdingCameraAt: Vector2
var makingChoice: bool = false
var pickedChoice: DialogueChoice = null
var actChanged: bool = false
var pauseDisabled: bool = false
var cutscenePaused: bool = false
var startingBattle: bool = false

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
var groundItems: Array[GroundItem] = []
var running: bool = false
var useTeleportStone: TeleportStone = null
# play a step immediately when moving the next time
var stepSfxTimer: float = BASE_STEP_SFX_COOLDOWN
var lastStepIdx: int = -1

func _unhandled_input(event):
	if event.is_action_pressed('game_decline') and SettingsHandler.gameSettings.toggleRun \
			and not ((len(talkNPCcandidates) > 0 or pickedUpItem != null or len(cutsceneTexts) > 0)) \
			and not pausePanel.isPaused and not inventoryPanel.visible and not questsPanel.visible \
			and not statsPanel.visible and not makingChoice and not cutscenePaused and not inCutscene \
			and SceneLoader.curMapEntry.isRecoverLocation and (SceneLoader.mapLoader == null or not SceneLoader.mapLoader.loading):
		running = not running # toggle running when press decline and not in a menu/dialogue/cutscene and in a runnable place
	
	if (not pauseDisabled and event.is_action_pressed("game_pause")) or \
			(cutscenePaused and event.is_action_pressed('game_decline')) and \
			(SceneLoader.mapLoader == null or not SceneLoader.mapLoader.loading):
		if inCutscene:
			# if awaiting player, don't even check if the pause panel can be opened, just stop here
			if not SceneLoader.cutscenePlayer.awaitingPlayer:
				SceneLoader.cutscenePlayer.toggle_pause_cutscene()
				cam.toggle_cutscene_paused_shade()
				cutscenePaused = cam.cutscenePaused
		elif not statsPanel.visible and not inventoryPanel.visible and not questsPanel.visible:
			pausePanel.toggle_pause()
	
	if event.is_action_pressed("game_stats") and not inCutscene and not pausePanel.isPaused and \
			(SceneLoader.mapLoader == null or not SceneLoader.mapLoader.loading) and \
			not inventoryPanel.inShardLearnTutorial:
		statsPanel.stats = PlayerResources.playerInfo.combatant.stats
		statsPanel.curHp = PlayerResources.playerInfo.combatant.currentHp
		statsPanel.toggle()
		if statsPanel.visible:
			SceneLoader.pause_autonomous_movers()
		if inventoryPanel.visible:
			inventoryPanel.toggle()
		if questsPanel.visible:
			questsPanel.toggle()
		
	if (event.is_action_pressed("game_interact") or event.is_action_pressed("game_decline") \
			or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed())) \
			and (len(talkNPCcandidates) > 0 or len(groundItems) > 0 or pickedUpItem != null or len(cutsceneTexts) > 0) \
			and not pausePanel.isPaused and not inventoryPanel.visible and not questsPanel.visible \
			and not statsPanel.visible and not makingChoice and not cutscenePaused and \
			not startingBattle and (SceneLoader.mapLoader == null or not SceneLoader.mapLoader.loading):
		if len(groundItems) > 0 and event.is_action_pressed("game_interact"):
			var closestGroundItem: GroundItem = null
			# find the closest ground item (using squared distance bc faster; the distance only matters relative to other ground items)
			groundItems = groundItems.filter(_filter_out_null)
			for groundItem: GroundItem in groundItems:
				if (closestGroundItem == null or \
						(groundItem.global_position - global_position).length_squared() < (closestGroundItem.global_position - global_position).length_squared()):
					closestGroundItem = groundItem
			if closestGroundItem != null:
				pick_up(closestGroundItem)
		elif textBox.is_textbox_complete():
			advance_dialogue(event.is_action_pressed("game_interact") or event is InputEventMouseButton)
		elif textBox.visible:
			textBox.show_text_instant()
	
	if event.is_action_pressed("game_inventory") and not inCutscene and not pausePanel.isPaused and \
			(SceneLoader.mapLoader == null or not SceneLoader.mapLoader.loading) and \
			not inventoryPanel.inShardLearnTutorial:
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
		
	if event.is_action_pressed("game_quests") and not inCutscene and not pausePanel.isPaused and \
			(SceneLoader.mapLoader == null or not SceneLoader.mapLoader.loading) and \
			not inventoryPanel.inShardLearnTutorial:
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
	if (Input.is_action_pressed("game_decline") or running) and (SceneLoader.mapLoader != null and SceneLoader.mapLoader.mapEntry.isRecoverLocation):
		if speed != RUN_SPEED:
			# play a step sound the next frame (for animation change when moving and switching run status)
			stepSfxTimer = RUN_STEP_SFX_COOLDOWN
		speed = RUN_SPEED
	elif speed != BASE_SPEED:
		speed = BASE_SPEED
		# play a step sound the next frame (for animation change when moving and switching run status) 
		stepSfxTimer = BASE_STEP_SFX_COOLDOWN
	
	if not disableMovement:
		# omni-directional movement
		#velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized() * speed
		# eight-directional movement (smart - snap to nearest 45 deg line)
		velocity = eight_dir_movement(Input.get_vector("move_left", "move_right", "move_up", "move_down")) * speed
		if velocity.x < 0:
			facingLeft = true
		if velocity.x > 0:
			facingLeft = false
		sprite.flip_h = facingLeft
		if velocity.length() > 0:
			if speed == RUN_SPEED:
				play_animation('run')
			else:
				play_animation('walk')
		else:
			play_animation('stand')
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	if inCutscene and false: # debug mode move camera in cutscene
		var vel = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized() * speed
		cam.position += vel * _delta
		
func _process(delta):
	if holdCameraX:
		cam.position.x = holdingCameraAt.x - position.x
		uiRoot.position.x = holdingCameraAt.x - position.x
	if holdCameraY:
		cam.position.y = holdingCameraAt.y - position.y
		uiRoot.position.y = holdingCameraAt.y - position.y
	
	# placed here instead of _physics_process because graphics are updated in sync with _process
	if velocity.length_squared() > 0:
		stepSfxTimer += delta
		if stepSfxTimer > (RUN_STEP_SFX_COOLDOWN if speed == RUN_SPEED else BASE_STEP_SFX_COOLDOWN):
			# don't choose the SFX we last picked
			var stepChoiceIdxs: Array = range(len(stepSfx))
			if lastStepIdx != -1:
				stepChoiceIdxs.remove_at(lastStepIdx)
			if len(stepChoiceIdxs) > 0:
				lastStepIdx = stepChoiceIdxs.pick_random() as int
			else:
				lastStepIdx = 0
			SceneLoader.audioHandler.play_sfx(stepSfx[lastStepIdx])
			stepSfxTimer = 0
	else:
		# play a step sound the next time the player moves
		stepSfxTimer = BASE_STEP_SFX_COOLDOWN

func eight_dir_movement(input: Vector2) -> Vector2:
	var output: Vector2 = Vector2.ZERO
	if input == output:
		return output
	
	var dirNum = ceili((input.angle() - PI / 8) / (PI / 4))
	# angle is [-180, -180] degrees
	# x - 22.5 degrees / 45 degrees => [-4, 4]
	if dirNum > -2 and dirNum < 2: # -1, 0, 1 => +x
		output.x = 1
	if abs(dirNum) == 3 or abs(dirNum) == 4 or dirNum == 3: # -3, -4, 4, 3 => -x
		output.x = -1
	if dirNum > 0 and dirNum < 4: # 1, 2, 3 => +y
		output.y = 1
	if dirNum < 0 and dirNum > -4: # -1, -2, -3 => -y
		output.y = -1
	
	return output.normalized()

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
	textBox.advance_textbox(dialogueText, talkNPC.is_dialogue_item_last())

func advance_dialogue(canStart: bool = true):
	if len(talkNPCcandidates) > 0 and not inCutscene: # if in NPC conversation
		if talkNPC == null:
			var minDistance: float = -1.0
			for npc in talkNPCcandidates:
				if npc == null:
					continue
				npc.reset_dialogue()
				if (npc.position.distance_to(position) < minDistance or minDistance == -1.0) and \
						len(npc.data.dialogueItems) > 0 and npc.visible: # if the NPC has dialogue and is the closest visible NPC, speak to this one
					minDistance = npc.position.distance_to(position)
					talkNPC = npc
					PlayerResources.playerInfo.encounter = null # reset static encounter in case game crash
		play_animation('stand')
		if not canStart and not disableMovement or talkNPC == null: # if we are pressing game_decline, or there is no talk NPC, do not start conversation!
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
				#SceneLoader.unpauseExcludedMover = talkNPC
				textBox.set_textbox_text(dialogueText, talkNPC.displayName, talkNPC.is_dialogue_item_last())
				face_horiz(talkNPC.talkArea.global_position.x - global_position.x)
				for npc in talkNPCcandidates:
					if npc != talkNPC:
						npc.talkAlertSprite.visible = false
			else: # this is continuing the NPC dialogue
				textBox.advance_textbox(dialogueText, talkNPC.is_dialogue_item_last())
		elif not inCutscene: # this is the end of NPC dialogue and it didn't start a cutscene
			textBox.hide_textbox()
			SceneLoader.unpause_autonomous_movers()
			for npc in talkNPCcandidates:
				if len(npc.data.dialogueItems) > 0:
					npc.talkAlertSprite.visible = true
			talkNPC = null
			if PlayerResources.playerInfo.encounter != null:
				start_battle()
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
				textBox.set_textbox_text(cutsceneTexts[cutsceneTextIndex].texts[cutsceneLineIndex], cutsceneTexts[cutsceneTextIndex].speaker, cutsceneLineIndex == len(cutsceneTexts[cutsceneTextIndex].texts) - 1 and cutsceneTextIndex == len(cutsceneTexts) - 1)
				SceneLoader.audioHandler.play_sfx(cutsceneTexts[cutsceneTextIndex].textboxSfx)
		else: # if it's not done, advance the textbox
			textBox.advance_textbox(cutsceneTexts[cutsceneTextIndex].texts[cutsceneLineIndex], cutsceneLineIndex == len(cutsceneTexts[cutsceneTextIndex].texts) - 1 and cutsceneTextIndex == len(cutsceneTexts) - 1)

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
		textBox.set_textbox_text(dialogueText, talkNPC.displayName, talkNPC.is_dialogue_item_last())
		return
		
	if choice.leadsTo != null:
		var reused = talkNPC.add_dialogue_entry_in_dialogue(choice.leadsTo)
		# skip any remaining dialogue we might have here
		talkNPC.data.dialogueItemIdx = len(talkNPC.data.dialogueItems[talkNPC.data.dialogueIndex].items) - 1
		talkNPC.data.dialogueLine = len(talkNPC.data.dialogueItems[talkNPC.data.dialogueIndex].items[talkNPC.data.dialogueItemIdx].lines) - 1
		if reused:
			talkNPC.data.dialogueLine = 0
			var dialogueText = talkNPC.get_cur_dialogue_item()
			textBox.set_textbox_text(dialogueText, talkNPC.displayName, talkNPC.is_dialogue_item_last())
			return
	
	makingChoice = false
	advance_dialogue()

func is_in_dialogue() -> bool:
	return textBox.visible

func set_talk_npc(npc: NPCScript, remove: bool = false):
	if npc == null:
		for candidate in talkNPCcandidates:
			candidate.reset_dialogue()
		talkNPCcandidates = []
		talkNPC = null
		return
	
	if npc in talkNPCcandidates and remove:
			talkNPCcandidates.erase(npc)
			npc.reset_dialogue()
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
		textBox.set_textbox_text(dialogueText, talkNPC.displayName, talkNPC.is_dialogue_item_last())
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
	disableMovement = textBox.visible or inCutscene
	
func hold_camera_at(pos: Vector2, holdX = true, holdY = true):
	if holdCameraX or holdCameraY:
		return
	if cam.position != Vector2(0, 0):
		return
	holdingCameraAt = pos
	holdCameraX = holdX
	holdCameraY = holdY

func snap_camera_back_to_player(duration: float = 0.5):
	if not holdCameraX and not holdCameraY:
		return # camera is already headed back to player
	holdCameraX = false
	holdCameraY = false
	if duration > 0:
		create_tween().tween_property(cam, 'position', Vector2(0, 0), duration)
		create_tween().tween_property(uiRoot, 'position', Vector2(0, 0), duration)
	else:
		cam.position = Vector2(0, 0)
		uiRoot.position = Vector2(0, 0)

func pick_up(groundItem: GroundItem):
	var idx: int = groundItems.find(groundItem)
	if idx != -1:
		groundItems.remove_at(idx)
	
	groundItem.show_pick_up_sprite(false)
	
	if PlayerResources.playerInfo.has_picked_up(groundItem.pickedUpItem.uniqueId):
		return
	
	pickedUpItem = groundItem.pickedUpItem
	pickedUpItem.wasPickedUp = PlayerResources.inventory.add_item(pickedUpItem.item)
	if pickedUpItem.wasPickedUp:
		PlayerResources.playerInfo.pickedUpItems.append(pickedUpItem.uniqueId)
		groundItem.queue_free()
		if PlayerResources.questInventory.can_start_quest(groundItem.startsQuest):
			PlayerResources.questInventory.accept_quest(groundItem.startsQuest)
			cam.show_alert('Started Quest:\n' + groundItem.startsQuest.questName)
	
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
			textBox.set_textbox_text(pickedUpItem.pickUpTexts[pickedUpItem.savedTextIdx], 'Picked Up ' + pickedUpItem.item.itemName, pickedUpItem.savedTextIdx == len(pickedUpItem.pickUpTexts) - 1)
	
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
		textBox.set_textbox_text(cutsceneTexts[cutsceneTextIndex].texts[cutsceneLineIndex], cutsceneTexts[cutsceneTextIndex].speaker, cutsceneLineIndex == len(cutsceneTexts[cutsceneTextIndex].texts) - 1 and cutsceneTextIndex == len(cutsceneTexts) - 1)
		SceneLoader.audioHandler.play_sfx(cutsceneTexts[cutsceneTextIndex].textboxSfx)

func fade_in_unlock_cutscene(cutscene: Cutscene): # for use when faded-out cutscene must end after loading back in
	inCutscene = false
	cam.connect_to_fade_in(_fade_in_force_unlock_cutscene.bind(cutscene.saveName))

func get_collider(): # for use before full player initialization in MapLoader
	return get_node('ColliderShape')

func menu_closed():
	if not inventoryPanel.visible and not questsPanel.visible and not statsPanel.visible \
			and not textBox.visible and not pausePanel.visible:
		SceneLoader.unpause_autonomous_movers()
		if useTeleportStone != null:
			play_animation('teleport')
			SceneLoader.audioHandler.play_sfx(teleportSfx)
			disableMovement = true
			await get_tree().create_timer(0.5).timeout
			if not SceneLoader.mapLoader.loading:
				SceneLoader.mapLoader.entered_warp(useTeleportStone.targetMap, useTeleportStone.targetPos, position)

func start_battle():
	if startingBattle:
		return
	startingBattle = true
	# save to auto-save
	cam.fade_out(_after_start_battle_fade_out)
	PlayerResources.battleSaveFolder = ''
	var playingBattleMusic = SceneLoader.mapLoader.mapEntry.battleMusic.pick_random()
	if PlayerResources.playerInfo.encounter is StaticEncounter and (PlayerResources.playerInfo.encounter as StaticEncounter).battleMusic != null:
		playingBattleMusic = (PlayerResources.playerInfo.encounter as StaticEncounter).battleMusic
	SceneLoader.audioHandler.play_music(playingBattleMusic, -1)

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
	if textBox.visible and not inventoryPanel.visible and not questsPanel.visible \
			and not statsPanel.visible and not pausePanel.visible:
		textBox.refocus_choice(pickedChoice)
		if pickedChoice != null and pickedChoice.opensShop:
			pickedChoice = null

func _on_quests_panel_node_back_pressed():
	menu_closed()
	if textBox.visible and not inventoryPanel.visible and not questsPanel.visible \
			and not statsPanel.visible and not pausePanel.visible:
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
	if statsPanel.levelUp and questsPanel.visible:
		questsPanel.toggle()
	statsPanel.levelUp = false
	statsPanel.newLvs = 0
	menu_closed()
	if textBox.visible and not inventoryPanel.visible and not questsPanel.visible \
			and not statsPanel.visible and not pausePanel.visible:
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
	statsPanel.newLvs = newLevels
	statsPanel.stats = PlayerResources.playerInfo.combatant.stats
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
		SceneLoader.cutscenePlayer.complete_cutscene()

func _on_quests_panel_node_act_changed():
	actChanged = true

func _new_act_callback():
	actChanged = false
	unpause_movement()

func _after_start_battle_fade_out():
	SceneLoader.load_battle()

func _on_pause_menu_resume_game():
	if textBox.visible and not inventoryPanel.visible and not questsPanel.visible \
			and not statsPanel.visible and not pausePanel.visible:
		textBox.refocus_choice(pickedChoice)

func _filter_out_null(value):
	return value != null
