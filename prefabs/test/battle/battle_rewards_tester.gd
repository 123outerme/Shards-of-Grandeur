extends BattleController

@export var playerWins: bool = true
@export var escapes: bool = false
@export var encounter: EnemyEncounter = null
@export var enemyCombatant1Alive: bool = false
@export var enemyCombatant2Alive: bool = false
@export var enemyCombatant3Alive: bool = false
@export var activeBoons: Array[BattleModifierItem] = []

const rewardPanelScene: PackedScene = preload('res://prefabs/ui/reward_panel.tscn')

@onready var rewardsVBox: VBoxContainer = get_node('BattleCam/RewardsVBox')

func _ready():
	battleUI.playerWins = playerWins
	battleUI.escapes = escapes
	PlayerResources.playerInfo.encounter = encounter
	PlayerResources.playerInfo.activeBattleModifierItems = activeBoons.duplicate()
	PlayerResources.playerInfo.combatant = state.playerCombatant
	
	battleAnimationManager.playerCombatantNode.combatant = state.playerCombatant
	battleAnimationManager.playerCombatantNode.load_combatant_node()
	
	battleAnimationManager.minionCombatantNode.combatant = state.minionCombatant
	battleAnimationManager.minionCombatantNode.load_combatant_node()
	
	battleAnimationManager.enemy1CombatantNode.combatant = state.enemyCombatant1
	state.enemyCombatant1.downed = not enemyCombatant1Alive
	battleAnimationManager.enemy1CombatantNode.load_combatant_node()
	
	battleAnimationManager.enemy2CombatantNode.combatant = state.enemyCombatant2
	if state.enemyCombatant2 != null:
		state.enemyCombatant2.downed = not enemyCombatant2Alive
	battleAnimationManager.enemy2CombatantNode.load_combatant_node()
	
	battleAnimationManager.enemy3CombatantNode.combatant = state.enemyCombatant3
	if state.enemyCombatant3 != null:
		state.enemyCombatant3.downed = not enemyCombatant3Alive
	battleAnimationManager.enemy3CombatantNode.load_combatant_node()
	
	var rewards: Array[Reward] = battleUI.build_rewards()
	for reward: Reward in rewards:
		var panel: RewardPanel = rewardPanelScene.instantiate()
		panel.reward = reward
		rewardsVBox.add_child(panel)
		panel.load_reward_panel.call_deferred()
