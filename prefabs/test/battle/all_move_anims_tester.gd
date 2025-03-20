extends Node2D

signal combatant_finished_moving(combatant: CombatantNode)
signal combatants_play_hit(combatant: CombatantNode)
signal combatant_finished_animating(combatant: CombatantNode)
signal move_anim_complete

@export var targetCombatant: Combatant = null
@export var evolution: Evolution = null
@export var moveCombatantsIfAlone: bool = false

@onready var moveLearnAnimController: MoveLearnAnimationController = get_node('MoveLearnAnimControl')
@onready var moveNameLabel: RichTextLabel = get_node('MoveNameLabel')
@onready var startButton: Button = get_node('StartButton')

var userNode: CombatantNode = null
var shadeDown: bool = false
var finishedMoving: bool = true


func _ready():
	SceneLoader.audioHandler = get_node('AudioHandler')
	PlayerResources.playerInfo = PlayerInfo.new()
	moveLearnAnimController.customTarget = targetCombatant
	moveLearnAnimController.customTargetEvolution = evolution
	await startButton.pressed
	startButton.visible = false
	play_all_moves()

func play_all_moves():
	var movesPath = 'res://gamedata/moves/'
	var moveDirs: PackedStringArray = DirAccess.get_directories_at(movesPath)
	await get_tree().create_timer(5).timeout
	for dir: String in moveDirs:
		var move: Move = load(movesPath + dir + '/' + dir + '.tres') as Move
		if move != null:
			for playSurge: bool in [false, true]:
				await get_tree().create_timer(1).timeout
				finishedMoving = false
				moveLearnAnimController.move = move
				moveNameLabel.text = '[center]' + move.moveName + '[/center]\n[center](' + \
					('Surge' if playSurge else 'Charge') + ')[/center]'
				moveLearnAnimController.moveCombatantsIfAlone = moveCombatantsIfAlone
				moveLearnAnimController.useItem = null
				moveLearnAnimController.playAnimAfterLoad = true
				moveLearnAnimController.load_move_learn_animation(playSurge)
				moveLearnAnimController.playAnimAfterLoad = false
				userNode = moveLearnAnimController.battleAnimManager.playerCombatantNode
				await move_anim_complete

func _on_move_learn_anim_control_combatant_finished_anim() -> void:
	move_anim_complete.emit()

func _on_move_learn_anim_control_combatant_started_anim() -> void:
	pass # Replace with function body.
