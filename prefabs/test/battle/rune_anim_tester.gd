extends Node2D

signal combatant_finished_moving(combatant: CombatantNode)
signal combatants_play_hit(combatant: CombatantNode)
signal combatant_finished_animating(combatant: CombatantNode)

@export var move: Move = null
@export var playSurge: bool = false
@export var targetCombatant: Combatant = null
@export var evolution: Evolution = null
@export var moveCombatantsIfAlone: bool = false
@export var battleMap: PackedScene = null
@export_enum("Center", "Top", "Bottom") var enemyCombatantUser: String = 'Center'

@onready var tilemapParent: Node2D = get_node('TilemapParent')
@onready var moveLearnAnimController: MoveLearnAnimationController = get_node('MoveLearnAnimControl')
@onready var playButton: Button = get_node('PlayButton')
@onready var playTriggerButton: Button = get_node('PlayTriggerButton')
@onready var surgeChargeToggle: Button = get_node('SurgeChargeToggle')
@onready var swapButton: Button = get_node('SwapButton')

var userNode: CombatantNode = null
var shadeDown: bool = false
var useItemAnimation: MoveAnimation = load('res://gamedata/items/use_item_animation.tres') as MoveAnimation

func _ready():
	SceneLoader.audioHandler = get_node('AudioHandler')
	SettingsHandler.gameSettings.battleAnims = true # enable battle anims in case stored settings disable it
	PlayerResources.playerInfo = PlayerInfo.new()
	moveLearnAnimController.customTarget = targetCombatant
	moveLearnAnimController.customTargetEvolution = evolution
	moveLearnAnimController.move = move
	moveLearnAnimController.moveCombatantsIfAlone = moveCombatantsIfAlone
	moveLearnAnimController.useItem = null
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
	playButton.disabled = true
	playTriggerButton.disabled = true
	surgeChargeToggle.disabled = true
	swapButton.disabled = true
	var rune: Rune = move.chargeEffect.rune if not playSurge else move.surgeEffect.rune
	if rune == null:
		return
	var newRune: Rune = rune.copy()
	newRune.init_rune_state(userNode.combatant, [userNode.combatant], BattleState.new())
	userNode.combatant.runes.append(newRune)
	userNode.update_rune_sprites(true, false)
	await get_tree().create_timer(3.0).timeout
	rune_anim_finished()

func _on_play_trigger_button_pressed() -> void:
	playButton.disabled = true
	playTriggerButton.disabled = true
	surgeChargeToggle.disabled = true
	swapButton.disabled = true
	var rune: Rune = move.chargeEffect.rune if not playSurge else move.surgeEffect.rune
	if rune == null:
		return
	var newRune: Rune = rune.copy()
	newRune.init_rune_state(userNode.combatant, [userNode.combatant], BattleState.new())
	newRune.caster = userNode.combatant
	userNode.combatant.runes.append(newRune)
	userNode.combatant.apply_rune_effect(rune)
	moveLearnAnimController.battleAnimManager.play_triggered_rune_animations()
	await moveLearnAnimController.battleAnimManager.rune_animation_complete
	rune_anim_finished()

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

func rune_anim_finished() -> void:
	userNode.combatant.runes = []
	userNode.combatant.triggeredRunes = []
	for sprite: MoveSprite in userNode.loadedRuneSprites:
		sprite.queue_free()
	userNode.loadedRuneSprites = []
	for sprite: MoveSprite in userNode.playingRuneSprites:
		sprite.queue_free()
	userNode.playingRuneSprites = []
	userNode.update_rune_sprites(false)
	playButton.disabled = false
	playTriggerButton.disabled = false
	surgeChargeToggle.disabled = false
	swapButton.disabled = false
