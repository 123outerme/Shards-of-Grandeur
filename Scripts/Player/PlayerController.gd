extends CharacterBody2D
class_name PlayerController

const SPEED = 80
@export var disableMovement: bool

@onready var textBox: TextBox = get_node("UI/TextBoxRoot")
@onready var inventoryPanel: InventoryMenu = get_node("UI/InventoryPanelNode")
@onready var questsPanel: QuestsMenu = get_node("UI/QuestsPanelNode")
@onready var statsPanel: StatsMenu = get_node("UI/StatsPanelNode")
@onready var npcTalkBtns: Node2D = get_node("/root/Overworld/NPCTalkButtons")
@onready var shopButton: Button = get_node("/root/Overworld/NPCTalkButtons/HBoxContainer/ShopButton")
@onready var turnInButton: Button = get_node("/root/Overworld/NPCTalkButtons/HBoxContainer/TurnInButton")

var talkNPC: NPCScript = null

func _input(event):
	if event.is_action_pressed("game_pause"): # TODO replace with pause menu
		statsPanel.stats = PlayerResources.playerInfo.stats
		statsPanel.toggle()
		inventoryPanel.visible = false
		questsPanel.visible = false
		npcTalkBtns.visible = (not statsPanel.visible) and PlayerResources.playerInfo.talkBtnsVisible

	if event.is_action_pressed("game_interact") and talkNPC != null:
		if textBox.is_textbox_complete():
			advance_dialogue()
		else:
			textBox.show_text_instant()
			
	if event.is_action_pressed("game_inventory"):
		inventoryPanel.inShop = false
		inventoryPanel.showPlayerInventory = false
		inventoryPanel.lockFilters = false
		inventoryPanel.toggle()
		statsPanel.visible = false
		questsPanel.visible = false
		npcTalkBtns.visible = (not inventoryPanel.visible) and PlayerResources.playerInfo.talkBtnsVisible
		
	if event.is_action_pressed("game_quests"):
		questsPanel.turnInTargetName = ''
		questsPanel.lockFilters = false
		questsPanel.toggle()
		statsPanel.visible = false
		inventoryPanel.visible = false
		npcTalkBtns.visible = (not questsPanel.visible) and PlayerResources.playerInfo.talkBtnsVisible

func _physics_process(_delta):
	if not disableMovement:
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized() * SPEED
		move_and_slide()
		
func _process(delta):
	if npcTalkBtns.visible and talkNPC != null:
		position_talk_btns()

func advance_dialogue():
	talkNPC.advance_dialogue()
	var dialogueText = talkNPC.get_cur_dialogue_item()
	if dialogueText != null: # if there is dialogue to display
		if talkNPC.data.dialogueIndex == 0: # if this is the beginning of the dialogue
			disableMovement = true
			set_talk_btns_vis(false)
			textBox.set_textbox_text(dialogueText, talkNPC.displayName)
		else: # this is continuing the dialogue
			textBox.advance_textbox(dialogueText)
	else:
		disableMovement = false
		textBox.hide_textbox()
		set_talk_btns_vis(true)
		position_talk_btns()

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
	npcTalkBtns.position = talkNPC.position - conversationPosDiff

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
		disableMovement = true
		textBox.set_textbox_text(dialogueText, talkNPC.displayName)
		textBox.show_text_instant()
	set_talk_btns_vis(PlayerResources.playerInfo.talkBtnsVisible)
	position_talk_btns()

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
	
func _on_inventory_back_button_pressed():
	npcTalkBtns.visible = PlayerResources.playerInfo.talkBtnsVisible

func _on_quests_back_button_pressed():
	npcTalkBtns.visible = PlayerResources.playerInfo.talkBtnsVisible
