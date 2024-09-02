extends Control
class_name MoveLearnAnimationController

signal battlefield_shade_finished_fading
signal combatant_finished_move_anim

@export var move: Move = null
@export var shard: Shard = null
@export var takeDmgSfx: AudioStream = null

@export_category('Custom Behavior Overrides')
@export var disableHpTags: bool = true
@export var customTarget: Combatant = null
@export var playAnimAfterLoad: bool = true
@export var delayAnimAfterLoad: bool = true
@export var swapUsersAndTargets: bool = false
@export var moveCombatantsIfAlone: bool = true

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

@onready var mockBattleController: MockBattleController = get_node('BattleScene/MockBattleController')

@onready var battlefieldShade: BattlefieldShade = get_node('BattleScene/BattlefieldBorder/BattlefieldShade')

func _ready() -> void:
	mockBattleController.playerCombatantNode = playerCombatantNode
	mockBattleController.combatantNodes = [playerCombatantNode, minionCombatantNode, enemy1CombatantNode, enemy2CombatantNode]

func load_move_learn_animation(playSurge: bool = false) -> void:
	moveEffect = move.surgeEffect if playSurge else move.chargeEffect
	
	var userNode: CombatantNode = playerCombatantNode if not swapUsersAndTargets else enemy1CombatantNode
	var userAllyNode: CombatantNode = minionCombatantNode if not swapUsersAndTargets else enemy2CombatantNode
	var targetNode: CombatantNode = enemy1CombatantNode if not swapUsersAndTargets else playerCombatantNode
	var targetAllyNode: CombatantNode = enemy2CombatantNode if not swapUsersAndTargets else minionCombatantNode
	
	var userSoloPos: Vector2 = playerSoloPos.position if not swapUsersAndTargets else enemy1SoloPos.position
	var userMultiPos: Vector2 = playerMultiPos.position if not swapUsersAndTargets else enemy1MultiPos.position
	var targetSoloPos: Vector2 = enemy1SoloPos.position if not swapUsersAndTargets else playerSoloPos.position
	var targetMultiPos: Vector2 = enemy1MultiPos.position if not swapUsersAndTargets else playerMultiPos.position
	var userSelfPos: Vector2 = playerSelfPos.position if not swapUsersAndTargets else mockBattleController.globalMarker.position
	
	var targetCombatant: Combatant = customTarget if customTarget != null else shard.get_combatant()
	
	userNode.combatant = PlayerResources.playerInfo.combatant if not swapUsersAndTargets else targetCombatant
	userNode.disableHpTag = disableHpTags
	userNode.load_combatant_node()
	mockBattleController.set_combatant_above_shade(userNode)
	
	if moveEffect.targets == BattleCommand.Targets.NON_SELF_ALLY or \
			moveEffect.targets == BattleCommand.Targets.ALLY or \
			moveEffect.targets == BattleCommand.Targets.ALL_ALLIES or \
			moveEffect.targets == BattleCommand.Targets.ALL_EXCEPT_SELF or \
			moveEffect.targets == BattleCommand.Targets.ALL:
		userAllyNode.visible = true
		userAllyNode.combatant = targetCombatant
		userAllyNode.disableHpTag = disableHpTags
		userAllyNode.load_combatant_node()
		mockBattleController.set_combatant_above_shade(userAllyNode)
		if moveCombatantsIfAlone:
			userNode.position = userMultiPos
	else:
		userAllyNode.visible = false
		if moveCombatantsIfAlone:
			if moveEffect.targets == BattleCommand.Targets.SELF:
				userNode.position = userSelfPos
			else:
				userNode.position = userSoloPos
	
	if moveEffect.targets == BattleCommand.Targets.ENEMY or \
			moveEffect.targets == BattleCommand.Targets.ALL_ENEMIES or \
			moveEffect.targets == BattleCommand.Targets.ALL_EXCEPT_SELF or \
			moveEffect.targets == BattleCommand.Targets.ALL:
		targetNode.visible = true
		targetNode.combatant = targetCombatant if not swapUsersAndTargets else PlayerResources.playerInfo.combatant
		targetNode.disableHpTag = disableHpTags
		targetNode.load_combatant_node()
		mockBattleController.set_combatant_above_shade(targetNode)
	else:
		targetNode.visible = false
	
	if moveEffect.targets == BattleCommand.Targets.ALL_ENEMIES or \
			moveEffect.targets == BattleCommand.Targets.ALL_EXCEPT_SELF or \
			moveEffect.targets == BattleCommand.Targets.ALL:
		targetAllyNode.visible = true
		targetAllyNode.combatant = targetCombatant
		targetAllyNode.disableHpTag = disableHpTags
		targetAllyNode.load_combatant_node()
		mockBattleController.set_combatant_above_shade(targetAllyNode)
		if moveCombatantsIfAlone:
			targetNode.position = targetMultiPos
	else:
		targetAllyNode.visible = false
		if moveCombatantsIfAlone:
			targetNode.position = targetSoloPos
	
	userNode.returnToPos = userNode.global_position
	targetNode.returnToPos = targetNode.global_position
	
	if delayAnimAfterLoad:
		await get_tree().create_timer(2).timeout
	if playAnimAfterLoad:
		play_move_animation(playSurge)

func play_move_animation(playSurge: bool = false) -> void:
	var userNode: CombatantNode = playerCombatantNode if not swapUsersAndTargets else enemy1CombatantNode
	var userAllyNode: CombatantNode = minionCombatantNode if not swapUsersAndTargets else enemy2CombatantNode
	var targetNode: CombatantNode = enemy1CombatantNode if not swapUsersAndTargets else playerCombatantNode
	var targetAllyNode: CombatantNode = enemy2CombatantNode if not swapUsersAndTargets else minionCombatantNode
	
	var userTeamGlobalPos: Vector2 = playerTeamPos.global_position if not swapUsersAndTargets else enemyTeamPos.global_position
	var targetTeamGlobalPos: Vector2 = enemyTeamPos.global_position if not swapUsersAndTargets else playerTeamPos.global_position
	var userSelfGlobalPos: Vector2 = playerSelfPos.global_position if not swapUsersAndTargets else mockBattleController.globalMarker.global_position 
	
	var targetCombatantNodes: Array[CombatantNode] = []
	var contactGlobalPos: Vector2 = userNode.global_position
	
	match moveEffect.targets:
		BattleCommand.Targets.ENEMY:
			targetCombatantNodes.append(targetNode)
			contactGlobalPos = targetNode.onAttackMarker.global_position
		BattleCommand.Targets.ALL_ENEMIES:
			targetCombatantNodes.append(targetNode)
			targetCombatantNodes.append(targetAllyNode)
			contactGlobalPos = targetTeamGlobalPos
		BattleCommand.Targets.ALLY, BattleCommand.Targets.NON_SELF_ALLY:
			targetCombatantNodes.append(userAllyNode)
			contactGlobalPos = userAllyNode.onAssistMarker.global_position
		BattleCommand.Targets.ALL_ALLIES:
			targetCombatantNodes.append(userNode)
			targetCombatantNodes.append(userAllyNode)
			contactGlobalPos = userTeamGlobalPos
		BattleCommand.Targets.SELF:
			targetCombatantNodes.append(userNode)
			contactGlobalPos = userSelfGlobalPos
		BattleCommand.Targets.ALL_EXCEPT_SELF:
			targetCombatantNodes.append(userAllyNode)
			targetCombatantNodes.append(targetNode)
			targetCombatantNodes.append(targetAllyNode)
			contactGlobalPos = mockBattleController.globalMarker.global_position
		BattleCommand.Targets.ALL:
			targetCombatantNodes.append(userNode)
			targetCombatantNodes.append(userAllyNode)
			targetCombatantNodes.append(targetNode)
			targetCombatantNodes.append(targetAllyNode)
			contactGlobalPos = mockBattleController.globalMarker.global_position
	
	userNode.play_animation(move.moveAnimation.combatantAnimation)
	userNode.play_particles(move.moveAnimation.userParticlePreset)
	userNode.moveSpriteTargets = targetCombatantNodes
	userNode.play_move_sprites(move.moveAnimation.surgeMoveSprites if playSurge else move.moveAnimation.chargeMoveSprites)
	for tNode: CombatantNode in targetCombatantNodes:
		tNode.play_particles(move.moveAnimation.targetsParticlePreset)
	
	var shadeAnim: BattlefieldShadeAnim = move.moveAnimation.surgeBattlefieldShade if playSurge else move.moveAnimation.chargeBattlefieldShade
	if shadeAnim != null:
		battlefieldShade.do_battlefield_shade_anim(shadeAnim)
	
	if move.moveAnimation.makesContact and contactGlobalPos != userNode.global_position:
		userNode.tween_to(contactGlobalPos)
		userNode.move_animation_callback(_on_move_anim_finish)
	else:
		userNode.move_animation_callback(_on_move_anim_finish)
		mockBattleController.combatant_finished_moving.emit(userNode)

func clean_up_animation() -> void:
	playerCombatantNode.stop_animation(true, true, true)
	minionCombatantNode.stop_animation(true, true, true)
	enemy1CombatantNode.stop_animation(true, true, true)
	enemy2CombatantNode.stop_animation(true, true, true)
	battlefieldShade.lift_battlefield_shade()

func _on_mock_battle_controller_combatants_play_hit(_combatant: CombatantNode) -> void:
	# if it deals damage: play the take damage SFX
	if moveEffect.power > 0:
		SceneLoader.audioHandler.play_sfx(takeDmgSfx)

func _on_move_anim_finish(_combatant: CombatantNode = null) -> void:
	battlefieldShade.lift_battlefield_shade()
	combatant_finished_move_anim.emit()

func _on_mock_battle_controller_combatant_returning_to_rest(combatant: CombatantNode) -> void:
	battlefieldShade.lift_battlefield_shade()

func _on_mock_battle_controller_battlefield_shade_finished_fading() -> void:
	battlefield_shade_finished_fading.emit()
