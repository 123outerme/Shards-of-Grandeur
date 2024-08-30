extends Node2D

signal combatant_finished_moving(combatant: CombatantNode)
signal combatants_play_hit(combatant: CombatantNode)
signal combatant_finished_animating(combatant: CombatantNode)

@export var move: Move = null
@export var playSurge: bool = false
@export var itemSprite: Texture2D = null
@export var targetCombatant: Combatant = null

@onready var moveLearnAnimController: MoveLearnAnimationController = get_node('MoveLearnAnimControl')
@onready var button: Button = get_node('Button')
@onready var surgeChargeToggle: Button = get_node('SurgeChargeToggle')

var userNode: CombatantNode = null

var useItemAnimation: MoveAnimation = load('res://gamedata/items/use_item_animation.tres') as MoveAnimation

func _ready():
	SceneLoader.audioHandler = get_node('AudioHandler')
	PlayerResources.playerInfo = PlayerInfo.new()
	moveLearnAnimController.customTarget = targetCombatant
	moveLearnAnimController.move = move
	moveLearnAnimController.load_move_learn_animation(playSurge)
	if playSurge:
		surgeChargeToggle.text = 'Surge'
	else:
		surgeChargeToggle.text = 'Charge'
	userNode = moveLearnAnimController.playerCombatantNode

func _on_button_pressed():
	button.disabled = true
	if itemSprite == null:
		moveLearnAnimController.playAnimAfterLoad = true
	moveLearnAnimController.load_move_learn_animation(playSurge)
	moveLearnAnimController.playAnimAfterLoad = false
	if itemSprite != null:
		userNode.useItemSprite = itemSprite
		userNode.play_move_sprites(useItemAnimation.chargeMoveSprites)
		userNode.play_animation(useItemAnimation.combatantAnimation)
		userNode.play_particles(useItemAnimation.userParticlePreset)
		userNode.moveSpriteTargets = [userNode]
		moveLearnAnimController.battlefieldShade.do_battlefield_shade_anim(useItemAnimation.chargeBattlefieldShade)
		userNode.move_animation_callback(_move_tween_done)
		combatant_finished_moving.emit(userNode)
	
func _move_tween_done(_combatantNode: CombatantNode):
	button.disabled = false

func _on_swap_button_pressed():
	if userNode == moveLearnAnimController.playerCombatantNode:
		userNode = moveLearnAnimController.enemy1CombatantNode
		moveLearnAnimController.swapUsersAndTargets = true
	else:
		userNode = moveLearnAnimController.playerCombatantNode
		moveLearnAnimController.swapUsersAndTargets = false
	moveLearnAnimController.load_move_learn_animation()


func _on_surge_charge_toggle_toggled(toggled_on: bool) -> void:
	playSurge = toggled_on
	if playSurge:
		surgeChargeToggle.text = 'Surge'
	else:
		surgeChargeToggle.text = 'Charge'
	moveLearnAnimController.load_move_learn_animation(playSurge)
