extends Control
class_name BattleCompleteMenu

@export var battleUI: BattleUI
@export var itemDetailsPanel: ItemDetailsPanel
@export var winMusic: AudioStream = null
@export var loseMusic: AudioStream = null
@export var escapeMusic: AudioStream = null

var playerWins: bool = true
var playerEscapes: bool = false
var rewards: Array[Reward] = []
var gainedLevels: int = 0

var rewardPanel = preload("res://prefabs/ui/reward_panel.tscn")

@onready var rewardsVBox: VBoxContainer = get_node("RewardsVBox")
@onready var battleWinLabel: RichTextLabel = get_node("BattleWinLabel")
@onready var battleRewardsLabel: RichTextLabel = get_node("BattleRewardsLabel")
@onready var battleLoseLabel: RichTextLabel = get_node("BattleLoseLabel")
@onready var battleEscapeLabel: RichTextLabel = get_node("BattleEscapeLabel")
@onready var okBtn: Button = get_node("OkButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_battle_over_menu():
	rewardsVBox.visible = playerWins
	battleWinLabel.visible = playerWins
	battleRewardsLabel.visible = playerWins
	battleLoseLabel.visible = not playerWins and not playerEscapes
	battleEscapeLabel.visible = not playerWins and playerEscapes
	
	for panel in get_tree().get_nodes_in_group('RewardPanel'):
		panel.queue_free() # destroy all previously loaded reward panels (if any)
	
	if playerWins:
		for reward in rewards:
			var instantiatedPanel: RewardPanel = rewardPanel.instantiate()
			instantiatedPanel.reward = reward
			rewardsVBox.add_child(instantiatedPanel)
			instantiatedPanel.load_reward_panel()
			instantiatedPanel.show_item_details.connect(_on_item_details_clicked)
		SceneLoader.audioHandler.play_music(winMusic)
	elif playerEscapes:
		SceneLoader.audioHandler.play_music(escapeMusic)
	else:
		SceneLoader.audioHandler.play_music(loseMusic)
	
	okBtn.grab_focus()

func _on_ok_button_pressed():
	PlayerResources.copy_combatant_to_info(battleUI.battleController.playerCombatant.combatant)
	# copy player changes to PlayerResources
	if playerWins:
		gainedLevels = PlayerResources.accept_rewards(rewards)
	
	if PlayerResources.playerInfo.combatant.currentHp <= 0:
		if playerWins or playerEscapes: # revive with 10% HP if you win or the minion escapes
			PlayerResources.playerInfo.combatant.currentHp = roundi(0.1 * PlayerResources.playerInfo.combatant.stats.maxHp)
		else: # otherwise revive with full
			PlayerResources.playerInfo.combatant.currentHp = PlayerResources.playerInfo.combatant.stats.maxHp
		PlayerResources.playerInfo.combatant.downed = not (playerWins or playerEscapes) # stay downed if you lost
	if gainedLevels > 0:
		battleUI.set_menu_state(BattleState.Menu.LEVEL_UP)
	else:
		battleUI.end_battle()

func _on_item_details_clicked(item):
	itemDetailsPanel.item = item
	itemDetailsPanel.count = 0
	itemDetailsPanel.load_item_details()
	itemDetailsPanel.visible = true
	
func _on_item_details_panel_back_pressed():
	okBtn.grab_focus()
