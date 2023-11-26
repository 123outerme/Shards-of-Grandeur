extends Control
class_name BattleCompleteMenu

@export var battleUI: BattleUI
@export var itemDetailsPanel: ItemDetailsPanel

var playerWins: bool = true
var playerEscapes: bool = false
var rewards: Array[Reward] = []

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
		var rewardPanel = load("res://prefabs/ui/reward_panel.tscn")
		for reward in rewards:
			var instantiatedPanel: RewardPanel = rewardPanel.instantiate()
			instantiatedPanel.reward = reward
			rewardsVBox.add_child(instantiatedPanel)
			instantiatedPanel.load_reward_panel(itemDetailsPanel)
	okBtn.grab_focus()

func _on_ok_button_pressed():
	PlayerResources.copy_combatant_to_info(battleUI.battleController.playerCombatant.combatant)
	# copy player changes to PlayerResources
	var levels: int = PlayerResources.accept_rewards(rewards)
	# copy rewards changes back to battle combatant
	#battleUI.battleController.playerCombatant.combatant.save_from_object(PlayerResources.playerInfo.combatant.copy())
	
	if PlayerResources.playerInfo.combatant.currentHp <= 0:
		PlayerResources.playerInfo.combatant.currentHp = PlayerResources.playerInfo.combatant.stats.maxHp
		PlayerResources.playerInfo.combatant.downed = true
	if levels > 0:
		battleUI.set_menu_state(BattleState.Menu.LEVEL_UP)
	else:
		battleUI.end_battle()
