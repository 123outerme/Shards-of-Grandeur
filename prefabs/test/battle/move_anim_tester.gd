extends Node2D

signal combatant_finished_moving(combatant: CombatantNode)
signal combatants_play_hit(combatant: CombatantNode)
signal combatant_finished_animating(combatant: CombatantNode)

@export var move: Move = null
@export var playSurge: bool = false
@export var item: Item = null
@export var targetCombatant: Combatant = null
@export var evolution: Evolution = null
@export var moveCombatantsIfAlone: bool = false
@export var battleMap: PackedScene = null
@export_enum("Center", "Top", "Bottom") var enemyCombatantUser: String = 'Center'

@onready var tilemapParent: Node2D = get_node('TilemapParent')
@onready var moveLearnAnimController: MoveLearnAnimationController = get_node('MoveLearnAnimControl')
@onready var button: Button = get_node('Button')
@onready var surgeChargeToggle: Button = get_node('SurgeChargeToggle')
@onready var swapButton: Button = get_node('SwapButton')

var userNode: CombatantNode = null
var shadeDown: bool = false
var finishedMoving: bool = true
var useItemAnimation: MoveAnimation = load('res://gamedata/items/use_item_animation.tres') as MoveAnimation

func _ready():
	SceneLoader.audioHandler = get_node('AudioHandler')
	SettingsHandler.gameSettings.battleAnims = true # enable battle anims in case stored settings disable it
	PlayerResources.playerInfo = PlayerInfo.new()
	moveLearnAnimController.customTarget = targetCombatant
	moveLearnAnimController.customTargetEvolution = evolution
	moveLearnAnimController.move = move
	moveLearnAnimController.moveCombatantsIfAlone = moveCombatantsIfAlone
	moveLearnAnimController.useItem = item
	moveLearnAnimController.enemyCombatantUser = enemyCombatantUser
	moveLearnAnimController.load_move_learn_animation(playSurge)
	if playSurge:
		surgeChargeToggle.text = 'Surge'
	else:
		surgeChargeToggle.text = 'Charge'
	var battleMapScene: Node2D = battleMap.instantiate()
	tilemapParent.add_child(battleMapScene)
	userNode = moveLearnAnimController.battleAnimManager.playerCombatantNode

func _on_button_pressed():
	button.disabled = true
	surgeChargeToggle.disabled = true
	swapButton.disabled = true
	finishedMoving = false
	if item == null:
		moveLearnAnimController.playAnimAfterLoad = true
	moveLearnAnimController.load_move_learn_animation(playSurge)
	moveLearnAnimController.playAnimAfterLoad = false
	if item != null:
		moveLearnAnimController.play_item_animation(userNode)

func _on_swap_button_pressed():
	if userNode == moveLearnAnimController.battleAnimManager.playerCombatantNode:
		userNode = moveLearnAnimController.battleAnimManager.enemy1CombatantNode
		moveLearnAnimController.swapUsersAndTargets = true
	else:
		userNode = moveLearnAnimController.battleAnimManager.playerCombatantNode
		moveLearnAnimController.swapUsersAndTargets = false
	moveLearnAnimController.load_move_learn_animation(playSurge)

func _on_surge_charge_toggle_toggled(toggled_on: bool) -> void:
	playSurge = toggled_on
	if playSurge:
		surgeChargeToggle.text = 'Surge'
	else:
		surgeChargeToggle.text = 'Charge'
	moveLearnAnimController.load_move_learn_animation(playSurge)

func _on_move_learn_anim_control_combatant_finished_anim() -> void:
	button.disabled = false
	surgeChargeToggle.disabled = false
	swapButton.disabled = false

func _on_move_learn_anim_control_combatant_started_anim() -> void:
	pass # Replace with function body.
