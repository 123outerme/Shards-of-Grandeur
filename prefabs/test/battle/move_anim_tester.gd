extends Node2D

@export var anim: MoveAnimSprite = null


@onready var userNode: CombatantNode = get_node('UserNode')
@onready var targetNode: CombatantNode = get_node('TargetNode')
@onready var button: Button = get_node('Button')

@onready var globalMarker: Marker2D = get_node('GlobalMarker')
@onready var userTeamMarker: Marker2D = get_node('UserTeamMarker')
@onready var enemyTeamMarker: Marker2D = get_node('EnemyTeamMarker')

const moveSpriteScene = preload('res://prefabs/battle/move_sprite.tscn')

func _ready():
	userNode.load_combatant_node()
	targetNode.load_combatant_node()

func _on_button_pressed():
	var moveSprite: MoveSprite = moveSpriteScene.instantiate()
	moveSprite.user = userNode
	moveSprite.target = targetNode
	moveSprite.anim = anim
	moveSprite.globalMarker = globalMarker
	moveSprite.userTeam = userTeamMarker
	moveSprite.enemyTeam = enemyTeamMarker
	moveSprite.load_animation()
	moveSprite.play_sprite_animation()
	add_child(moveSprite)

func _on_move_sprite_move_sprite_complete():
	print('move sprite finished')
