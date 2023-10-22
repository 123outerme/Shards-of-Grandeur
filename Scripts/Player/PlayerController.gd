extends CharacterBody2D
class_name PlayerController

const SPEED = 80
@export var disableMovement: bool
var pickedUpItem: PickedUpItem = null

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
		pass # TODO replace with pause menu
	
	if event.is_action_pressed("game_stats"):
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
			and (talkNPC != null or pickedUpItem != null):
		if textBox.is_textbox_complete():
			advance_dialogue(event.is_action_pressed("game_interact"))
		else:
			textBox.show_text_instant()
			
	if event.is_action_pressed("game_inventory"):
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
		
	if event.is_action_pressed("game_quests"):
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
		move_and_slide()
		
func _process(delta):
	if npcTalkBtns.visible and talkNPC != null:
		position_talk_btns()

func advance_dialogue(canStart: bool = true):
	if talkNPC != null:
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

func set_talk_btns_vis(vis: bool):
	npcTalkBtns.visible = vis
	PlayerResources.playerInfo.talkBtnsVisible = vis
	if talkNPC != null:
		shopButton.visible = talkNPC.hasShop
		turnInButton.visible = len(talkNPC.turningInSteps) > 0

func position_talk_btns():
	var conversationPosDiff: Vector2 = position - talkNPC.position # vector from NPC to player
	var newY = -10.0
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
	talkNPC = npc
	var dialogueText = talkNPC.get_cur_dialogue_item()
	if dialogueText != null:
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
	inventoryPanel.lockFilters = true
	inventoryPanel.equipContextStats = stats
	statsPanel.visible = false
	statsPanel.reset_panel_to_player()
	SceneLoader.pause_autonomous_movers()
	inventoryPanel.toggle()

func _on_stats_panel_node_attempt_equip_armor_to(stats: Stats):
	inventoryPanel.selectedFilter = Item.Type.ARMOR
	inventoryPanel.lockFilters = true
	inventoryPanel.equipContextStats = stats
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
