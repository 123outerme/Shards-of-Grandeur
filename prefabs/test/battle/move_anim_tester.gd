extends Node2D

signal combatant_finished_moving
signal combatant_finished_animating

@export var moveAnimation: MoveAnimation = null

@onready var userNode: CombatantNode = get_node('UserNode')
@onready var targetNode: CombatantNode = get_node('TargetNode')
@onready var button: Button = get_node('Button')

@onready var globalMarker: Marker2D = get_node('GlobalMarker')
@onready var userTeamMarker: Marker2D = get_node('UserTeamMarker')
@onready var enemyTeamMarker: Marker2D = get_node('EnemyTeamMarker')

const moveSpriteScene = preload('res://prefabs/battle/move_sprite.tscn')

func _ready():
	SceneLoader.audioHandler = get_node('AudioHandler')
	userNode.load_combatant_node()
	targetNode.load_combatant_node()

func _on_button_pressed():
	'''
	for spriteAnim in moveAnimation.moveSprites:
		var moveSprite: MoveSprite = moveSpriteScene.instantiate()
		moveSprite.user = userNode
		moveSprite.target = targetNode
		moveSprite.anim = spriteAnim
		moveSprite.globalMarker = globalMarker
		moveSprite.userTeam = userTeamMarker
		moveSprite.enemyTeam = enemyTeamMarker
		moveSprite.load_animation()
		moveSprite.play_sprite_animation()
		add_child(moveSprite)
	'''
	
	userNode.play_animation(moveAnimation.combatantAnimation)
	userNode.play_particles(moveAnimation.userParticlePreset)
	userNode.moveSpriteTargets = [targetNode]
	userNode.play_move_sprites(moveAnimation.moveSprites)
	targetNode.play_particles(moveAnimation.targetsParticlePreset)
	if moveAnimation.makesContact:
		userNode.tween_to(targetNode.onAttackMarker.global_position, _move_tween_done)
		
func _move_tween_done():
	pass
