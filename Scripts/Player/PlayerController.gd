extends CharacterBody2D
class_name PlayerController

const SPEED = 80
@export var disableMovement: bool
@export var facingLeft: bool = false
var pickedUpItem: PickedUpItem = null
var inCutscene: bool = false
var cutsceneTexts: Array[String] = []
var cutsceneSpeaker: String = ''
var cutsceneTextBoxIndex: int = 0
var holdingCamera: bool = false
var holdingCameraAt: Vector2
var fadeInReady: bool = false
var fadeInTween = null

@onready var sprite: AnimatedSprite2D = get_node("AnimatedPlayerSprite")
@onready var cam: Camera2D = get_node("Camera")
@onready var letterbox: Control = get_node("Camera/Letterbox")
@onready var shade: Control = get_node("Camera/Shade")
@onready var uiRoot: Node2D = get_node('UI')
@onready var textBox: TextBox = get_node("UI/TextBoxRoot")
@onready var inventoryPanel: InventoryMenu = get_node("UI/InventoryPanelNode")
@onready var questsPanel: QuestsMenu = get_node("UI/QuestsPanelNode")
@onready var statsPanel: StatsMenu = get_node("UI/StatsPanelNode")
@onready var npcTalkBtns: Node2D = get_node("/root/Overworld/NPCTalkButtons")
@onready var shopButton: Button = get_node("/root/Overworld/NPCTalkButtons/HBoxContainer/ShopButton")
@onready var turnInButton: Button = get_node("/root/Overworld/NPCTalkButtons/HBoxContainer/TurnInButton")

var talkNPC: NPCScript = null

func _unhandled_input(event):
	if event.is_action_pressed("game_pause"):
		if inCutscene:
			var cutsceneTrigger: CutsceneTrigger = get_tree().get_first_node_in_group('CutsceneTrigger') as CutsceneTrigger
			cutsceneTrigger.toggle_pause_cutscene()
		else:
			pass #SceneLoader.pause_autonomous_movers() # or unpause
		# todo open pause menu
	
	if event.is_action_pressed("game_stats") and not inCutscene:
		statsPanel.stats = PlayerResources.playerInfo.stats
		statsPanel.curHp = PlayerResources.playerInfo.combatant.currentHp
		statsPanel.toggle()
		if statsPanel.visible:
			SceneLoader.pause_autonomous_movers()
		else:
			SceneLoader.unpause_autonomous_movers()
		inventoryPanel.visible = true
		inventoryPanel.toggle()
		questsPanel.visible = false
		npcTalkBtns.visible = (not statsPanel.visible) and PlayerResources.playerInfo.talkBtnsVisible

	if (event.is_action_pressed("game_interact") or event.is_action_pressed("game_decline")) \
			and (talkNPC != null or pickedUpItem != null or len(cutsceneTexts) > 0):
		if textBox.is_textbox_complete():
			advance_dialogue(event.is_action_pressed("game_interact"))
		else:
			textBox.show_text_instant()
			
	if event.is_action_pressed("game_inventory") and not inCutscene:
		inventoryPanel.inShop = false
		inventoryPanel.showPlayerInventory = false
		inventoryPanel.lockFilters = false
		inventoryPanel.toggle()
		if inventoryPanel.visible:
			SceneLoader.pause_autonomous_movers()
		else:
			SceneLoader.unpause_autonomous_movers()
		statsPanel.visible = false
		questsPanel.visible = false
		npcTalkBtns.visible = (not inventoryPanel.visible) and PlayerResources.playerInfo.talkBtnsVisible
		
	if event.is_action_pressed("game_quests") and not inCutscene:
		questsPanel.turnInTargetName = ''
		questsPanel.lockFilters = false
		questsPanel.toggle()
		if questsPanel.visible:
			SceneLoader.pause_autonomous_movers()
		else:
			SceneLoader.unpause_autonomous_movers()
		statsPanel.visible = false
		inventoryPanel.visible = true
		inventoryPanel.toggle()
		npcTalkBtns.visible = (not questsPanel.visible) and PlayerResources.playerInfo.talkBtnsVisible

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
		
func _process(delta):
	if npcTalkBtns.visible and talkNPC != null:
		position_talk_btns()
	if holdingCamera:
		cam.position = holdingCameraAt - position
		uiRoot.position = holdingCameraAt - position
	if fadeInReady and fadeInTween != null and cam.position == Vector2(0, 0):
		fadeInReady = false
		fadeInTween.play()

func show_letterbox(showing: bool = true):
	letterbox.visible = showing
	inCutscene = showing

func fade_out(callback: Callable, duration: float = 0.5):
	shade.modulate = Color(0, 0, 0, 0)
	var tween = create_tween().tween_property(shade, 'modulate', Color(0, 0, 0, 1.0), duration)
	tween.finished.connect(callback)

func fade_in(callback: Callable, duration: float = 0.5):
	fadeInReady = true
	shade.modulate = Color(0, 0, 0, 1.0)
	if fadeInTween != null:
		fadeInTween.kill()
	fadeInTween = create_tween()
	fadeInTween.tween_property(shade, 'modulate', Color(0, 0, 0, 0), duration)
	fadeInTween.finished.connect(callback)
	fadeInTween.pause()

func play_animation(animation: String):
	sprite.play(animation)

func face_horiz(xDirection: int):
	if xDirection > 0:
		sprite.flip_h = false
	if xDirection < 0:
		sprite.flip_h = true

func advance_dialogue(canStart: bool = true):
	if talkNPC != null:
		sprite.play('stand')
		if not canStart and not disableMovement: # if we are pressing game_decline, do not start conversation!
			return
		talkNPC.advance_dialogue()
		var dialogueText = talkNPC.get_cur_dialogue_item()
		if dialogueText != null: # if there is dialogue to display
			if talkNPC.data.dialogueIndex == 0: # if this is the beginning of the dialogue
				SceneLoader.pause_autonomous_movers()
				SceneLoader.unpauseExcludedMover = talkNPC
				set_talk_btns_vis(false)
				textBox.set_textbox_text(dialogueText, talkNPC.displayName)
			else: # this is continuing the dialogue
				textBox.advance_textbox(dialogueText)
		else:
			SceneLoader.unpause_autonomous_movers()
			textBox.hide_textbox()
			set_talk_btns_vis(true)
			position_talk_btns()
	elif pickedUpItem != null:
		pickedUpItem.savedTextIdx += 1
		put_pick_up_text()
	elif len(cutsceneTexts) > 0:
		cutsceneTextBoxIndex += 1
		if cutsceneTextBoxIndex < len(cutsceneTexts):
			textBox.advance_textbox(cutsceneTexts[cutsceneTextBoxIndex])
		else:
			cutsceneTextBoxIndex = 0
			cutsceneTexts = []
			textBox.hide_textbox()
			if not inCutscene: # cutscene is over now (ended while text box was still open)
				disableMovement = false # re-enable movement
				show_letterbox(false) # disable letterbox

func is_in_dialogue() -> bool:
	return textBox.visible

func set_talk_btns_vis(vis: bool):
	npcTalkBtns.visible = vis
	PlayerResources.playerInfo.talkBtnsVisible = vis
	if talkNPC != null:
		shopButton.visible = talkNPC.hasShop
		turnInButton.visible = len(talkNPC.turningInSteps) > 0

func position_talk_btns():
	var conversationPosDiff: Vector2 = position - talkNPC.position # vector from NPC to player
	var newY = -1.0 * talkNPC.get_collision_size().y
	if conversationPosDiff.y > 0.1:
		newY *= -1
	conversationPosDiff.y = newY
	npcTalkBtns.position = Vector2(talkNPC.position.x, talkNPC.position.y - newY) #talkNPC.position - conversationPosDiff

func set_talk_npc(npc: NPCScript):
	talkNPC = npc
	if npc == null:
		set_talk_btns_vis(false)
		shopButton.visible = false
		turnInButton.visible = false
	
func restore_dialogue(npc: NPCScript):
	var dialogueText = npc.get_cur_dialogue_item()
	if dialogueText != null and talkNPC == null:
		talkNPC = npc
		talkNPC.face_player()
		SceneLoader.pause_autonomous_movers()
		textBox.set_textbox_text(dialogueText, talkNPC.displayName)
		textBox.show_text_instant()
		set_talk_btns_vis(PlayerResources.playerInfo.talkBtnsVisible)
		position_talk_btns()

func restore_picked_up_item_text(groundItem: PickedUpItem):
	pickedUpItem = groundItem
	if pickedUpItem != null:
		SceneLoader.pause_autonomous_movers()
		put_pick_up_text()
		textBox.show_text_instant()

func pause_movement():
	disableMovement = true

func unpause_movement():
	disableMovement = false
	
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
	pickedUpItem.savedTextIdx = 0
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
		SceneLoader.unpause_autonomous_movers()
		textBox.hide_textbox()
		pickedUpItem = null
	else:
		SceneLoader.pause_autonomous_movers()

func set_cutscene_texts(texts: Array[String], speaker: String):
	cutsceneTexts = texts
	cutsceneSpeaker = speaker
	cutsceneTextBoxIndex = 0
	textBox.set_textbox_text(texts[0], speaker)
	
func _on_shop_button_pressed():
	inventoryPanel.inShop = true
	inventoryPanel.showPlayerInventory = false
	inventoryPanel.shopInventory = talkNPC.inventory
	inventoryPanel.toggle()
	npcTalkBtns.visible = false

func _on_turn_in_button_pressed():
	questsPanel.turnInTargetName = talkNPC.saveName
	questsPanel.toggle()
	npcTalkBtns.visible = false

func _on_inventory_panel_node_back_pressed():
	npcTalkBtns.visible = PlayerResources.playerInfo.talkBtnsVisible
	SceneLoader.unpause_autonomous_movers()

func _on_quests_panel_node_back_pressed():
	npcTalkBtns.visible = PlayerResources.playerInfo.talkBtnsVisible
	SceneLoader.unpause_autonomous_movers()

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
	SceneLoader.pause_autonomous_movers()
	inventoryPanel.toggle()

func _on_stats_panel_node_back_pressed():
	statsPanel.levelUp = false
	npcTalkBtns.visible = PlayerResources.playerInfo.talkBtnsVisible
	SceneLoader.unpause_autonomous_movers()

func _on_quests_panel_node_turn_in_step_to(saveName):
	if saveName == talkNPC.saveName:
		talkNPC.fetch_quest_dialogue_info()
		turnInButton.visible = len(talkNPC.turningInSteps) > 0 # recompute if turn in button still needs to be shown

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
	npcTalkBtns.visible = false # make sure talk buttons are hidden
	statsPanel.visible = false # show stats panel for sure
	statsPanel.toggle()
