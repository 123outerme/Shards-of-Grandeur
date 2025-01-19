extends Control
class_name OverworldRewardPanel

signal ok_button_pressed

@export var panelTitle: String = 'Rewards'
@export var rewards: Array[Reward] = []

var rewardPanelScene = load('res://prefabs/ui/reward_panel.tscn')

@onready var rewardPanelTitle: RichTextLabel = get_node('Panel/RewardPanelTitle')
@onready var rewardsVboxContainer: VBoxContainer = get_node('Panel/VBoxContainer/ScrollContainer/VBoxContainer')
@onready var okBtn: Button = get_node('Panel/OkButton')
@onready var itemDetailsPanel: ItemDetailsPanel = get_node('ItemDetailsPanel')

var detailsPressedPanel: RewardPanel = null

func initial_focus():
	if detailsPressedPanel != null:
		detailsPressedPanel.itemSpriteBtn.grab_focus()
	else:
		okBtn.grab_focus()

func load_overworld_reward_panel() -> void:
	if rewards == null or len(rewards) == 0:
		return
	
	visible = true
	rewardPanelTitle.text = '[center]' + panelTitle + '[/center]'
	
	for child: Node in rewardsVboxContainer.get_children():
		child.queue_free()
	
	var lastPanel: RewardPanel = null
	for reward: Reward in rewards:
		var instantiatedPanel: RewardPanel = rewardPanelScene.instantiate()
		instantiatedPanel.reward = reward
		instantiatedPanel.show_item_details.connect(_show_item_details.bind(instantiatedPanel))
		rewardsVboxContainer.add_child(instantiatedPanel)
		instantiatedPanel.load_reward_panel.call_deferred()
		connect_rewards_panels_focus.call_deferred(instantiatedPanel, lastPanel)
		lastPanel = instantiatedPanel
	
	await get_tree().process_frame # wait for the final panel to be loaded in
	if lastPanel != null:
		okBtn.focus_neighbor_top = okBtn.get_path_to(lastPanel.itemSpriteBtn)
		okBtn.focus_neighbor_right = okBtn.get_path_to(lastPanel.itemSpriteBtn)
		lastPanel.itemSpriteBtn.focus_neighbor_bottom = lastPanel.itemSpriteBtn.get_path_to(okBtn)
		lastPanel.itemSpriteBtn.focus_neighbor_left = lastPanel.itemSpriteBtn.get_path_to(okBtn)
	else:
		okBtn.focus_neighbor_top = '.'
		okBtn.focus_neighbor_right = '.'
	initial_focus()

func connect_rewards_panels_focus(instantiatedPanel: RewardPanel, lastPanel: RewardPanel):
	lastPanel.itemSpriteBtn.focus_neighbor_left = '.'
	lastPanel.itemSpriteBtn.focus_neighbor_right = '.'
	if lastPanel != null:
		lastPanel.itemSpriteBtn.focus_neighbor_bottom = lastPanel.itemSpriteBtn.get_path_to(instantiatedPanel.itemSpriteBtn)
		instantiatedPanel.itemSpriteBtn.focus_neighbor_top = instantiatedPanel.itemSpriteBtn.get_path_to(lastPanel.itemSpriteBtn)
	else:
		instantiatedPanel.itemSpriteBtn.focus_neighbor_top = '.'

func _show_item_details(panel: RewardPanel, item: Item) -> void:
	detailsPressedPanel = panel
	itemDetailsPanel.item = item
	itemDetailsPanel.load_item_details()
	itemDetailsPanel.visible = true

func _on_item_details_panel_back_pressed() -> void:
	initial_focus()
	detailsPressedPanel = null

func _on_ok_button_pressed() -> void:
	detailsPressedPanel = null
	visible = false
	ok_button_pressed.emit()
