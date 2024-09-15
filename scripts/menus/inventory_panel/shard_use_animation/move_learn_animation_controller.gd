extends Control
class_name MoveLearnAnimationController

signal combatant_started_anim
signal combatant_finished_anim

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
@export var useItem: Item = null

var targetNodes: Array[CombatantNode] = []
var moveEffect: MoveEffect = null

@onready var playerSoloPos: Marker2D = get_node('PlayerSoloPos')
@onready var playerMultiPos: Marker2D = get_node('PlayerMultiPos')

@onready var enemy1SoloPos: Marker2D = get_node('Enemy1SoloPos')
@onready var enemy1MultiPos: Marker2D = get_node('Enemy1MultiPos')

@onready var battleAnimManager: BattleAnimationManager = get_node('BattlefieldBorder/BattleAnimationManager')


func _ready() -> void:
	battleAnimManager.playerCombatantNode.leftSide = true
	battleAnimManager.playerCombatantNode.role = CombatantNode.Role.ALLY
	battleAnimManager.minionCombatantNode.leftSide = true
	battleAnimManager.minionCombatantNode.role = CombatantNode.Role.ALLY
	
	battleAnimManager.enemy1CombatantNode.role = CombatantNode.Role.ENEMY
	battleAnimManager.enemy2CombatantNode.role = CombatantNode.Role.ENEMY
	
	battleAnimManager.enemy3CombatantNode.visible = false
	battleAnimManager.enemy3CombatantNode.role = CombatantNode.Role.ENEMY

func load_move_learn_animation(playSurge: bool = false) -> void:
	moveEffect = move.surgeEffect if playSurge else move.chargeEffect
	
	var userNode: CombatantNode = battleAnimManager.playerCombatantNode if not swapUsersAndTargets else battleAnimManager.enemy1CombatantNode
	var userAllyNode: CombatantNode = battleAnimManager.minionCombatantNode if not swapUsersAndTargets else battleAnimManager.enemy2CombatantNode
	var targetNode: CombatantNode = battleAnimManager.enemy1CombatantNode if not swapUsersAndTargets else battleAnimManager.playerCombatantNode
	var targetAllyNode: CombatantNode = battleAnimManager.enemy2CombatantNode if not swapUsersAndTargets else battleAnimManager.minionCombatantNode
	
	var userSoloPos: Vector2 = playerSoloPos.global_position if not swapUsersAndTargets else enemy1SoloPos.global_position
	var userMultiPos: Vector2 = playerMultiPos.global_position if not swapUsersAndTargets else enemy1MultiPos.global_position
	var targetSoloPos: Vector2 = enemy1SoloPos.global_position if not swapUsersAndTargets else playerSoloPos.global_position
	var targetMultiPos: Vector2 = enemy1MultiPos.global_position if not swapUsersAndTargets else playerMultiPos.global_position
	var userSelfPos: Vector2 = battleAnimManager.globalMarker.global_position
	
	var targetCombatant: Combatant = customTarget if customTarget != null else shard.get_combatant()
	
	userNode.combatant = PlayerResources.playerInfo.combatant if not swapUsersAndTargets else targetCombatant
	userNode.disableHpTag = disableHpTags
	userNode.load_combatant_node()
	
	var targets: BattleCommand.Targets = moveEffect.targets
	if useItem != null:
		targets = useItem.battleTargets
	
	targetNodes = []
	
	if targets == BattleCommand.Targets.SELF or \
			targets == BattleCommand.Targets.ALL_ALLIES or \
			targets == BattleCommand.Targets.ALL:
		targetNodes.append(userNode)
	
	if targets == BattleCommand.Targets.NON_SELF_ALLY or \
			targets == BattleCommand.Targets.ALLY or \
			targets == BattleCommand.Targets.ALL_ALLIES or \
			targets == BattleCommand.Targets.ALL_EXCEPT_SELF or \
			targets == BattleCommand.Targets.ALL:
		userAllyNode.visible = true
		userAllyNode.combatant = targetCombatant
		userAllyNode.disableHpTag = disableHpTags
		userAllyNode.load_combatant_node()
		targetNodes.append(userAllyNode)
		if moveCombatantsIfAlone:
			userNode.global_position = userMultiPos
	else:
		userAllyNode.visible = false
		if moveCombatantsIfAlone:
			if moveEffect.targets == BattleCommand.Targets.SELF:
				userNode.global_position = userSelfPos
			else:
				userNode.global_position = userSoloPos
	
	if targets == BattleCommand.Targets.ENEMY or \
			targets == BattleCommand.Targets.ALL_ENEMIES or \
			targets == BattleCommand.Targets.ALL_EXCEPT_SELF or \
			targets == BattleCommand.Targets.ALL:
		targetNodes.append(targetNode)
		targetNode.visible = true
		targetNode.combatant = targetCombatant if not swapUsersAndTargets else PlayerResources.playerInfo.combatant
		targetNode.disableHpTag = disableHpTags
		targetNode.load_combatant_node()
	else:
		targetNode.visible = false
	
	if targets == BattleCommand.Targets.ALL_ENEMIES or \
			targets == BattleCommand.Targets.ALL_EXCEPT_SELF or \
			targets == BattleCommand.Targets.ALL:
		targetNodes.append(targetAllyNode)
		targetAllyNode.visible = true
		targetAllyNode.combatant = targetCombatant
		targetAllyNode.disableHpTag = disableHpTags
		targetAllyNode.load_combatant_node()
		if moveCombatantsIfAlone:
			targetNode.global_position = targetMultiPos
	else:
		targetAllyNode.visible = false
		if moveCombatantsIfAlone:
			targetNode.global_position = targetSoloPos
	
	userNode.returnToPos = userNode.global_position
	targetNode.returnToPos = targetNode.global_position
	
	if delayAnimAfterLoad:
		await get_tree().create_timer(2).timeout
	if playAnimAfterLoad:
		play_move_animation(userNode, playSurge)

func play_move_animation(userNode: CombatantNode, playSurge: bool = false):
	moveEffect = move.surgeEffect if playSurge else move.chargeEffect 
	
	var targets: Array[String] = []
	var targetsDealtDmg: Array[int] = []
	var afflictedStatuses: Array[bool] = []
	var wasBoosted: Array[bool] = []
	for cNode: CombatantNode in targetNodes:
		targets.append(cNode.battlePosition)
		var mockDmg: int = 0
		if moveEffect.power > 0:
			mockDmg = 10
		elif moveEffect.power < 0:
			mockDmg = -10
		targetsDealtDmg.append(mockDmg)
		if moveEffect.statusEffect != null and \
				moveEffect.statusEffect.potency != StatusEffect.Potency.NONE and \
				moveEffect.statusEffect.type != StatusEffect.Type.NONE and \
				not (moveEffect.selfGetsStatus and cNode != userNode) and \
				moveEffect.statusChance > 0:
			afflictedStatuses.append(true)
		else:
			afflictedStatuses.append(false)
		if moveEffect.targetStatChanges != null and moveEffect.targetStatChanges.has_stat_changes():
			wasBoosted.append(true)
		else:
			wasBoosted.append(false)
	
	var commandResult: CommandResult = CommandResult.new(
		targetsDealtDmg,
		[],
		afflictedStatuses,
		wasBoosted,
		[],
		moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes()
	)
	
	var command: BattleCommand = BattleCommand.new(
		BattleCommand.Type.MOVE,
		move,
		Move.MoveEffectType.SURGE if playSurge else Move.MoveEffectType.CHARGE,
		0,
		null,
		targets,
		[],
		-1,
		commandResult
	)
	command.get_targets_from_combatant_nodes(battleAnimManager.get_all_combatant_nodes())
	
	battleAnimManager.play_turn_animation(userNode, command, [])

func play_item_animation(userNode: CombatantNode) -> void:
	var targets: Array[String] = []
	var targetsDealtDmg: Array[int] = []
	var afflictedStatuses: Array[bool] = []
	var wasBoosted: Array[bool] = []
	var orbs: int = 0

	var healing: Healing = null
	if useItem.itemType == Item.Type.HEALING:
		healing = useItem as Healing
		#orbs = healing.orbs
	
	for cNode: CombatantNode in targetNodes:
		targets.append(cNode.battlePosition)
		if healing != null:
			targetsDealtDmg.append(-1 * healing.healBy)
			afflictedStatuses.append(healing.statusStrengthHeal != StatusEffect.Potency.NONE)
			wasBoosted.append(healing.statChanges != null and healing.statChanges.has_stat_changes())
		else:
			targetsDealtDmg.append(0)
			afflictedStatuses.append(false)
			wasBoosted.append(false)

	var commandResult: CommandResult = CommandResult.new(
		targetsDealtDmg,
		[],
		afflictedStatuses,
		wasBoosted,
		[],
		userNode.battlePosition in targets
	)
	
	var slot: InventorySlot = InventorySlot.new(useItem, 1)
	
	var command: BattleCommand = BattleCommand.new(
		BattleCommand.Type.USE_ITEM,
		null,
		Move.MoveEffectType.NONE,
		orbs,
		slot,
		targets,
		[],
		-1,
		commandResult
	)
	command.get_targets_from_combatant_nodes(battleAnimManager.get_all_combatant_nodes())
	
	battleAnimManager.play_turn_animation(userNode, command, [])

func clean_up_animation() -> void:
	battleAnimManager.playerCombatantNode.stop_animation(true, true, true)
	battleAnimManager.minionCombatantNode.stop_animation(true, true, true)
	battleAnimManager.enemy1CombatantNode.stop_animation(true, true, true)
	battleAnimManager.enemy2CombatantNode.stop_animation(true, true, true)
	battleAnimManager.battlefieldShade.lift_battlefield_shade()

func _on_battle_animation_manager_combatant_animation_start() -> void:
	combatant_started_anim.emit()

func _on_battle_animation_manager_combatant_animation_complete() -> void:
	combatant_finished_anim.emit()
