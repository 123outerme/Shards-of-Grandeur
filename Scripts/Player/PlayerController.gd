extends CharacterBody2D
class_name PlayerController

const SPEED = 80
@export var disableMovement: bool

@onready var SaveHandler: SaveHandler = get_node("/root/SaveHandler")
@onready var textBox: TextBox = get_node("TextBoxRoot")

var talkNPC: NPCScript = null

func _input(event):
		if event.is_action_pressed("game_pause"):
			SaveHandler.save_data()
	
		if event.is_action_pressed("game_interact") and talkNPC != null:
			if textBox.is_textbox_complete():
				advance_dialogue()
			else:
				textBox.show_text_instant()

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
			textBox.set_textbox_text(dialogueText, talkNPC.displayName)
		else:
			textBox.advance_textbox(dialogueText)
	else:
		disableMovement = false
		textBox.hide_textbox()

func set_talk_npc(npc: NPCScript):
	talkNPC = npc
	
func restore_dialogue(npc: NPCScript):
	talkNPC = npc
	var dialogueText = talkNPC.get_cur_dialogue_item()
	if dialogueText != null:
		disableMovement = true
		textBox.set_textbox_text(dialogueText, talkNPC.displayName)
		textBox.show_text_instant()
