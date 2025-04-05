extends Node2D

@export var moveAnimSprite: MoveAnimSprite = null
@export var targetCombatant: Combatant = null
@export var evolution: Evolution = null
@export var userIsTarget: bool = false

var targetCombatantNode: CombatantNode = null
var userCombatantNode: CombatantNode = null
var tempMove: Move = null

@onready var moveLearnAnimController: MoveLearnAnimationController = get_node('MoveLearnAnimControl')
@onready var playButton: Button = get_node('PlayButton')
@onready var swapButton: Button = get_node('SwapButton')

func _ready() -> void:
	SceneLoader.audioHandler = get_node('AudioHandler')
	PlayerResources.playerInfo = PlayerInfo.new()
	var tempEffect: MoveEffect = MoveEffect.new(
		MoveEffect.Role.OTHER,
		[],
		0,
		0,
		0,
		0,
		BattleCommand.Targets.ENEMY if not userIsTarget else BattleCommand.Targets.SELF
	)
	tempMove = Move.new('Temp Move', 1, Move.DmgCategory.PHYSICAL, Move.Element.NONE, tempEffect, tempEffect)
	moveLearnAnimController.move = tempMove
	moveLearnAnimController.customTarget = targetCombatant
	moveLearnAnimController.customTargetEvolution = evolution
	moveLearnAnimController.playAnimAfterLoad = false
	moveLearnAnimController.load_move_learn_animation()
	userCombatantNode = moveLearnAnimController.battleAnimManager.playerCombatantNode
	targetCombatantNode = moveLearnAnimController.battleAnimManager.enemy1CombatantNode
	userCombatantNode.move_sprites_finished.connect(_on_move_sprite_finished)
	targetCombatantNode.move_sprites_finished.connect(_on_move_sprite_finished)

func _on_play_button_pressed() -> void:
	if moveAnimSprite == null:
		return
	playButton.disabled = true
	swapButton.disabled = true
	if userIsTarget:
		userCombatantNode.moveSpriteTargets = [userCombatantNode]
	else:
		userCombatantNode.moveSpriteTargets = [targetCombatantNode]
	userCombatantNode.play_move_sprite(moveAnimSprite)

func _on_swap_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		userCombatantNode = moveLearnAnimController.battleAnimManager.enemy1CombatantNode
		targetCombatantNode = moveLearnAnimController.battleAnimManager.playerCombatantNode
	else:
		userCombatantNode = moveLearnAnimController.battleAnimManager.playerCombatantNode
		targetCombatantNode = moveLearnAnimController.battleAnimManager.enemy1CombatantNode

func _on_move_sprite_finished() -> void:
	playButton.disabled = false
	swapButton.disabled = false
