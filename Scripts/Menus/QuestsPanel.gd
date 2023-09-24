extends Node2D

@onready var questsTitle: RichTextLabel = get_node("QuestsPanel/Panel/QuestsTitle")
@onready var inProgressButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/InProgressButton")
@onready var readyToTurnInButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/ReadyToTurnInButton")
@onready var completedButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/CompletedButton")
@onready var notCompletedButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/NotCompletedButton")
@onready var backButton: Button = get_node("QuestsPanel/Panel/BackButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle():
	visible = not visible
	if visible:
		load_quests_panel()
		
func load_quests_panel():
	pass # TODO

func _on_back_button_pressed():
	toggle()
