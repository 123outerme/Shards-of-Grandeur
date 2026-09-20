extends BattleController

@export var playerWins: bool = true
@export var escapes: bool = false
@export var encounter: EnemyEncounter = null
@export var enemyCombatant1Alive: bool = false
@export var enemyCombatant2Alive: bool = false
@export var enemyCombatant3Alive: bool = false
@export var ignoreStaticRewards: bool = false
@export var activeBoons: Array[BattleModifierItem] = []

const rewardPanelScene: PackedScene = preload('res://prefabs/ui/reward_panel.tscn')

@onready var rewardsVBox: VBoxContainer = get_node('BattleCam/RewardsVBox')

func _ready():
	battleUI.playerWins = playerWins
	battleUI.escapes = escapes
	PlayerResources.playerInfo.encounter = encounter.duplicate()
	if ignoreStaticRewards and PlayerResources.playerInfo.encounter is StaticEncounter:
		(PlayerResources.playerInfo.encounter as StaticEncounter).useStaticRewards = false
	
	PlayerResources.playerInfo.activeBattleModifierItems = activeBoons.duplicate()
	PlayerResources.playerInfo.combatant = state.playerCombatant
	
	battleAnimationManager.playerCombatantNode.combatant = state.playerCombatant
	battleAnimationManager.playerCombatantNode.load_combatant_node()
	
	battleAnimationManager.minionCombatantNode.combatant = state.minionCombatant
	battleAnimationManager.minionCombatantNode.load_combatant_node()
	
	if encounter != null:
		battleAnimationManager.enemy1CombatantNode.combatant = encounter.combatant1.duplicate()
		state.enemyCombatant1 = battleAnimationManager.enemy1CombatantNode.combatant
		var level: int = 1
		if PlayerResources.playerInfo.encounter is StaticEncounter:
			level = (PlayerResources.playerInfo.encounter as StaticEncounter).combatant1Level
		elif PlayerResources.playerInfo.encounter is RandomEncounter:
			level = (PlayerResources.playerInfo.encounter as RandomEncounter).get_combatant_level()
		state.enemyCombatant1.level_up_nonplayer(level)
	else:
		battleAnimationManager.enemy1CombatantNode.combatant = state.enemyCombatant1
	state.enemyCombatant1.downed = not enemyCombatant1Alive
	enemyCombatant1.combatant = battleAnimationManager.enemy1CombatantNode.combatant
	enemyCombatant1.combatant.downed = not enemyCombatant1Alive
	battleAnimationManager.enemy1CombatantNode.load_combatant_node()
	
	if PlayerResources.playerInfo.encounter is StaticEncounter:
		if encounter.combatant2:
			battleAnimationManager.enemy2CombatantNode.combatant = encounter.combatant2.duplicate()
		else:
			battleAnimationManager.enemy2CombatantNode.combatant = null
		state.enemyCombatant2 = battleAnimationManager.enemy1CombatantNode.combatant
		if encounter.combatant3:
			battleAnimationManager.enemy3CombatantNode.combatant = encounter.combatant3.duplicate()
		else:
			battleAnimationManager.enemy3CombatantNode.combatant = null
		state.enemyCombatant3 = battleAnimationManager.enemy1CombatantNode.combatant
	else:
		battleAnimationManager.enemy2CombatantNode.combatant = state.enemyCombatant2
		battleAnimationManager.enemy3CombatantNode.combatant = state.enemyCombatant3
		
	var level2: int = 1
	if PlayerResources.playerInfo.encounter is StaticEncounter:
		level2 = (PlayerResources.playerInfo.encounter as StaticEncounter).combatant2Level
	elif PlayerResources.playerInfo.encounter is RandomEncounter:
		level2 = (PlayerResources.playerInfo.encounter as RandomEncounter).get_combatant_level()
	
	var level3: int = 1
	if PlayerResources.playerInfo.encounter is StaticEncounter:
		level3 = (PlayerResources.playerInfo.encounter as StaticEncounter).combatant3Level
	elif PlayerResources.playerInfo.encounter is RandomEncounter:
		level3 = (PlayerResources.playerInfo.encounter as RandomEncounter).get_combatant_level()
	
	enemyCombatant2.combatant = battleAnimationManager.enemy2CombatantNode.combatant
	enemyCombatant3.combatant = battleAnimationManager.enemy3CombatantNode.combatant
	if state.enemyCombatant2 != null:
		enemyCombatant2.combatant.level_up_nonplayer(level2)
		enemyCombatant2.combatant.downed = not enemyCombatant2Alive
		state.enemyCombatant2.downed = not enemyCombatant2Alive
	if state.enemyCombatant3 != null:
		enemyCombatant3.combatant.level_up_nonplayer(level3)
		enemyCombatant3.combatant.downed = not enemyCombatant3Alive
		state.enemyCombatant3.downed = not enemyCombatant3Alive
	battleAnimationManager.enemy2CombatantNode.load_combatant_node()
	battleAnimationManager.enemy3CombatantNode.load_combatant_node()
	
	var rewards: Array[Reward] = battleUI.build_rewards()
	for reward: Reward in rewards:
		var panel: RewardPanel = rewardPanelScene.instantiate()
		panel.reward = reward
		rewardsVBox.add_child(panel)
		panel.load_reward_panel.call_deferred()
