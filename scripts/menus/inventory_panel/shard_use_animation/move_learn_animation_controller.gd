extends Control
class_name MoveLearnAnimationController

@export var move: Move = null
@export var shard: Shard = null
@export var takeDmgSfx: AudioStream = null

var moveEffect: MoveEffect = null

@onready var playerCombatantNode: CombatantNode = get_node('BattleScene/PlayerCombatantNode')
@onready var minionCombatantNode: CombatantNode = get_node('BattleScene/MinionCombatantNode')
@onready var enemy1CombatantNode: CombatantNode = get_node('BattleScene/Enemy1CombatantNode')
@onready var enemy2CombatantNode: CombatantNode = get_node('BattleScene/Enemy2CombatantNode')

@onready var playerSelfPos: Marker2D = get_node('BattleScene/PlayerSelfPos')
@onready var playerSoloPos: Marker2D = get_node('BattleScene/PlayerSoloPos')
@onready var playerMultiPos: Marker2D = get_node('BattleScene/PlayerMultiPos')
@onready var playerTeamPos: Marker2D = get_node('BattleScene/PlayerTeamMarker')

@onready var enemy1SoloPos: Marker2D = get_node('BattleScene/Enemy1SoloPos')
@onready var enemy1MultiPos: Marker2D = get_node('BattleScene/Enemy1MultiPos')
@onready var enemyTeamPos: Marker2D = get_node('BattleScene/EnemyTeamMarker')

@onready var mockBattleController: Node2D = get_node('BattleScene/MockBattleController')

func _ready() -> void:
	mockBattleController.playerCombatantNode = playerCombatantNode

func load_move_learn_animation(playSurge: bool = false) -> void:
	moveEffect = move.surgeEffect if playSurge else move.chargeEffect
	
	playerCombatantNode.combatant = PlayerResources.playerInfo.combatant
	playerCombatantNode.disableHpTag = true
	playerCombatantNode.load_combatant_node()
	
	if moveEffect.targets == BattleCommand.Targets.NON_SELF_ALLY or \
			moveEffect.targets == BattleCommand.Targets.ALLY or \
			moveEffect.targets == BattleCommand.Targets.ALL_ALLIES or \
			moveEffect.targets == BattleCommand.Targets.ALL_EXCEPT_SELF or \
			moveEffect.targets == BattleCommand.Targets.ALL:
		minionCombatantNode.visible = true
		minionCombatantNode.combatant = shard.get_combatant()
		minionCombatantNode.disableHpTag = true
		minionCombatantNode.load_combatant_node()
		playerCombatantNode.position = playerMultiPos.position
	else:
		minionCombatantNode.visible = false
		if moveEffect.targets == BattleCommand.Targets.SELF:
			playerCombatantNode.position = playerSelfPos.position
		else:
			playerCombatantNode.position = playerSoloPos.position
	
	if moveEffect.targets == BattleCommand.Targets.ENEMY or \
			moveEffect.targets == BattleCommand.Targets.ALL_ENEMIES or \
			moveEffect.targets == BattleCommand.Targets.ALL_EXCEPT_SELF or \
			moveEffect.targets == BattleCommand.Targets.ALL:
		enemy1CombatantNode.visible = true
		enemy1CombatantNode.combatant = shard.get_combatant()
		enemy1CombatantNode.disableHpTag = true
		enemy1CombatantNode.load_combatant_node()
	else:
		enemy1CombatantNode.visible = false
	
	if moveEffect.targets == BattleCommand.Targets.ALL_ENEMIES or \
			moveEffect.targets == BattleCommand.Targets.ALL_EXCEPT_SELF or \
			moveEffect.targets == BattleCommand.Targets.ALL:
		enemy2CombatantNode.visible = true
		enemy2CombatantNode.combatant = shard.get_combatant()
		enemy2CombatantNode.disableHpTag = true
		enemy2CombatantNode.load_combatant_node()
		enemy1CombatantNode.position = enemy1MultiPos.position
	else:
		enemy2CombatantNode.visible = false
		enemy1CombatantNode.position = enemy1SoloPos.position

	await get_tree().create_timer(2).timeout
	play_move_animation(playSurge)

func play_move_animation(playSurge: bool = false) -> void:
	var targetCombatantNodes: Array[CombatantNode] = []
	var contactGlobalPos: Vector2 = playerCombatantNode.global_position
	
	match moveEffect.targets:
		BattleCommand.Targets.ENEMY:
			targetCombatantNodes.append(enemy1CombatantNode)
			contactGlobalPos = enemy1CombatantNode.global_position
		BattleCommand.Targets.ALL_ENEMIES:
			targetCombatantNodes.append(enemy1CombatantNode)
			targetCombatantNodes.append(enemy2CombatantNode)
			contactGlobalPos = enemyTeamPos.global_position
		BattleCommand.Targets.ALLY, BattleCommand.Targets.NON_SELF_ALLY:
			targetCombatantNodes.append(minionCombatantNode)
			contactGlobalPos = minionCombatantNode.onAssistMarker.global_position
		BattleCommand.Targets.ALL_ALLIES:
			targetCombatantNodes.append(playerCombatantNode)
			targetCombatantNodes.append(minionCombatantNode)
			contactGlobalPos = playerTeamPos.global_position
		BattleCommand.Targets.SELF:
			targetCombatantNodes.append(playerCombatantNode)
			contactGlobalPos = playerSelfPos.global_position
		BattleCommand.Targets.ALL_EXCEPT_SELF:
			targetCombatantNodes.append(minionCombatantNode)
			targetCombatantNodes.append(enemy1CombatantNode)
			targetCombatantNodes.append(enemy2CombatantNode)
			contactGlobalPos = mockBattleController.globalMarker.global_position
		BattleCommand.Targets.ALL:
			targetCombatantNodes.append(playerCombatantNode)
			targetCombatantNodes.append(minionCombatantNode)
			targetCombatantNodes.append(enemy1CombatantNode)
			targetCombatantNodes.append(enemy2CombatantNode)
			contactGlobalPos = mockBattleController.globalMarker.global_position
	
	playerCombatantNode.play_animation(move.moveAnimation.combatantAnimation)
	playerCombatantNode.play_particles(move.moveAnimation.userParticlePreset)
	playerCombatantNode.moveSpriteTargets = targetCombatantNodes
	playerCombatantNode.play_move_sprites(move.moveAnimation.surgeMoveSprites if playSurge else move.moveAnimation.chargeMoveSprites)
	for targetNode: CombatantNode in targetCombatantNodes:
		targetNode.play_particles(move.moveAnimation.targetsParticlePreset)
	
	if move.moveAnimation.makesContact and contactGlobalPos != playerCombatantNode.global_position:
		playerCombatantNode.tween_to(contactGlobalPos)
		playerCombatantNode.move_animation_callback(mockBattleController._move_tween_done)
	else:
		playerCombatantNode.move_animation_callback(mockBattleController._move_tween_done)
		mockBattleController.combatant_finished_moving.emit(playerCombatantNode)

func clean_up_animation() -> void:
	playerCombatantNode.stop_animation(true, true, true)
	minionCombatantNode.stop_animation(true, true, true)
	enemy1CombatantNode.stop_animation(true, true, true)
	enemy2CombatantNode.stop_animation(true, true, true)

func _on_mock_battle_controller_combatants_play_hit(_combatant: CombatantNode) -> void:
	# if it deals damage: play the take damage SFX
	if moveEffect.power > 0:
		SceneLoader.audioHandler.play_sfx(takeDmgSfx)

func _on_mock_battle_controller_combatant_finished_moving(_combatant: CombatantNode) -> void:
	pass # When the move animation is ENTIRELY done... do something?
