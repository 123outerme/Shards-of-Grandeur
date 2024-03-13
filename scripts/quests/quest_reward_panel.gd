extends Control
class_name QuestRewardPanel

signal ok_pressed

@export var reward: Reward = null
@export var itemDetailsPanel: ItemDetailsPanel

@onready var rewardPanel: RewardPanel = get_node("Panel/RewardPanel")
@onready var noRewardsLabel: RichTextLabel = get_node("Panel/NoRewardsLabel")
@onready var fullAttuneLabel: RichTextLabel = get_node("Panel/FullAttuneLabel")
@onready var okButton: Button = get_node("Panel/OkButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_ok_button_pressed()

func load_quest_reward_panel():
	rewardPanel.reward = reward
	rewardPanel.load_reward_panel()
	noRewardsLabel.visible = reward == null
	
	if reward != null and reward.fullyAttuneCombatantSaveName != '':
		var combatant = Combatant.load_combatant_resource(reward.fullyAttuneCombatantSaveName)
		fullAttuneLabel.text = '[center]You have become fully Attuned with ' + combatant.disp_name() + '![/center]'
	fullAttuneLabel.visible = reward != null and reward.fullyAttuneCombatantSaveName != ''
	
	visible = true
	okButton.grab_focus()

func _on_ok_button_pressed():
	visible = false
	ok_pressed.emit()

func _on_show_item_details(item):
	itemDetailsPanel.item = item
	itemDetailsPanel.count = 0
	itemDetailsPanel.load_item_details()
	itemDetailsPanel.visible = true
