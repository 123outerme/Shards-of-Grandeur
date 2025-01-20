extends Control
class_name BattleCompleteMenu

@export var battleUI: BattleUI
@export var itemDetailsPanel: ItemDetailsPanel
@export var winMusic: AudioStream = null
@export var loseMusic: AudioStream = null
@export var escapeMusic: AudioStream = null

var playerWins: bool = false
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
	battleUI.update_hp_tags()
	# there are rewards to claim if there is more than one reward, and it is not an array with only entry, and it's null
	var hasRewards: bool = len(battleUI.battleController.state.rewards) > 0 and not (battleUI.battleController.state.rewards[0] == null and len(battleUI.battleController.state.rewards) == 1)
	rewardsVBox.visible = hasRewards or playerWins
	if playerWins and PlayerResources.playerInfo.encounter.customWinText != '':
		battleUI.customWinText.customText = PlayerResources.playerInfo.encounter.customWinText
		battleUI.customWinText.load_custom_win_text_panel()
	if PlayerResources.playerInfo.encounter.winCon != null:
		battleWinLabel.text = PlayerResources.playerInfo.encounter.winCon.get_win_text(battleUI.battleController.get_all_combatant_nodes()) \
				if playerWins else \
				PlayerResources.playerInfo.encounter.winCon.get_lose_text(battleUI.battleController.get_all_combatant_nodes())
		battleLoseLabel.text = '[center]' + PlayerResources.playerInfo.encounter.winCon.get_lose_text(battleUI.battleController.get_all_combatant_nodes()) + '[/center]'
		battleEscapeLabel.text = '[center]' + PlayerResources.playerInfo.encounter.winCon.get_escape_text(battleUI.battleController.get_all_combatant_nodes()) + '[/center]'
	else:
		battleWinLabel.text = WinCon.DEFAULT_WIN_TEXT if playerWins else WinCon.DEFAULT_LOSE_TEXT
		battleLoseLabel.text = '[center]' + WinCon.DEFAULT_LOSE_TEXT + '[/center]'
		battleEscapeLabel.text = '[center]' + WinCon.DEFAULT_ESCAPE_TEXT + '[/center]'
	battleWinLabel.visible = hasRewards or playerWins
	battleRewardsLabel.visible = hasRewards or playerWins
	battleLoseLabel.visible = not (hasRewards or playerWins) and not playerEscapes
	battleEscapeLabel.visible = not (hasRewards or playerWins) and playerEscapes
	
	for panel in get_tree().get_nodes_in_group('RewardPanel'):
		panel.queue_free() # destroy all previously loaded reward panels (if any)
	
	if hasRewards or playerWins:
		for reward in rewards:
			var instantiatedPanel: RewardPanel = rewardPanel.instantiate()
			instantiatedPanel.reward = reward
			rewardsVBox.add_child(instantiatedPanel)
			instantiatedPanel.load_reward_panel()
			instantiatedPanel.show_item_details.connect(_on_item_details_clicked)
		SceneLoader.audioHandler.play_music(winMusic, -1)
	elif playerEscapes:
		SceneLoader.audioHandler.play_music(escapeMusic, -1)
	else:
		SceneLoader.audioHandler.play_music(loseMusic, 0)
	
	okBtn.grab_focus()

func _on_ok_button_pressed():
	okBtn.disabled = true
	PlayerResources.copy_combatant_to_info(battleUI.battleController.playerCombatant.combatant)
	# copy player changes to PlayerResources
	gainedLevels = PlayerResources.accept_rewards(rewards)
	
	if PlayerResources.playerInfo.combatant.downed:
		if (playerWins or playerEscapes) and gainedLevels == 0: # revive with 10% HP if you win or the minion escapes
			# if the "Restand on Defeat" special rule is not enabled, revive with 10% HP
			if not PlayerResources.playerInfo.encounter.has_special_rule(EnemyEncounter.SpecialRules.RESTAND_ON_DEFEAT):
				PlayerResources.playerInfo.combatant.currentHp = roundi(0.1 * PlayerResources.playerInfo.combatant.stats.maxHp)
			else:
				# if "Restand on Defeat" is enabled, restand with full HP
				PlayerResources.playerInfo.combatant.currentHp = PlayerResources.playerInfo.combatant.stats.maxHp
		else: # otherwise revive with full
			PlayerResources.playerInfo.combatant.currentHp = PlayerResources.playerInfo.combatant.stats.maxHp
		# disable downed flag if you win, escape, or (lose but "Restand on Defeat" is enabled)
		PlayerResources.playerInfo.combatant.downed = not (playerWins or playerEscapes or \
				PlayerResources.playerInfo.encounter.has_special_rule(EnemyEncounter.SpecialRules.RESTAND_ON_DEFEAT) \
		)
	battleUI.battleController.clean_up_minion_combatant()
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
