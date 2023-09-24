extends CharacterBody2D
class_name PlayerController

const SPEED = 80
@export var disableMovement: bool

@onready var textBox: TextBox = get_node("TextBoxRoot")
@onready var inventoryPanel: InventoryMenu = get_node("InventoryPanelNode")
@onready var npcTalkBtns: Node2D = get_node("/root/Overworld/NPCTalkButtons")
@onready var shopButton: Button = get_node("/root/Overworld/NPCTalkButtons/HBoxContainer/ShopButton")
@onready var turnInButton: Button = get_node("/root/Overworld/NPCTalkButtons/HBoxContainer/TurnInButton")

var talkNPC: NPCScript = null

func _input(event):
	if event.is_action_pressed("game_pause"):
		SaveHandler.save_data()

	if event.is_action_pressed("game_interact") and talkNPC != null:
		if textBox.is_textbox_complete():
			advance_dialogue()
		else:
			textBox.show_text_instant()
			
	if event.is_action_pressed("game_inventory"):
		inventoryPanel.inShop = false
		inventoryPanel.showPlayerInventory = false
		inventoryPanel.toggle()

func _physics_process(_delta):
	if not disableMovement:
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized() * SPEED
		move_and_slide()

func advance_dialogue():
	talkNPC.advance_dialogue()
	var dialogueText = talkNPC.get_cur_dialogue_item()
	if dialogueText != null:
		if talkNPC.data.dialogueIndex == 0:
			disableMovement = true
			npcTalkBtns.visible = false
			textBox.set_textbox_text(dialogueText, talkNPC.displayName)
		else:
			textBox.advance_textbox(dialogueText)
	else:
		disableMovement = false
		textBox.hide_textbox()
		npcTalkBtns.visible = true
		shopButton.visible = talkNPC.hasShop
		turnInButton.visible = false # TODO
		var conversationPosDiff: Vector2 = position - talkNPC.position # vector from NPC to player
		var newY = -10.0
		if conversationPosDiff.y > 0.1:
			newY *= -1
		conversationPosDiff.y = newY
		npcTalkBtns.position = talkNPC.position - conversationPosDiff

func set_talk_npc(npc: NPCScript):
	talkNPC = npc
	npcTalkBtns.visible = false
	
func restore_dialogue(npc: NPCScript):
	talkNPC = npc
	var dialogueText = talkNPC.get_cur_dialogue_item()
	if dialogueText != null:
		disableMovement = true
		textBox.set_textbox_text(dialogueText, talkNPC.displayName)
		textBox.show_text_instant()

func _on_shop_button_pressed():
	inventoryPanel.inShop = true
	inventoryPanel.showPlayerInventory = false
	inventoryPanel.shopInventory = talkNPC.inventory
	inventoryPanel.toggle()
	npcTalkBtns.visible = false

func _on_turn_in_button_pressed():
	# TODO
	npcTalkBtns.visible = false
