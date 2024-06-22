extends Interactable
class_name PuzzleDecoration

@export var puzzle: Puzzle = null
## the dialogue to show when the player doesn't have the prerequisite story requirements. `dialogue` is for the "unsolved but passes prereqs" dialogue
@export var failedPrereqsDialogue: InteractableDialogue = null
## the dialogue to show when the player has already solved this puzzle. `dialogue` is for the "unsolved but passes prereqs" dialogue
@export var solvedDialogue: InteractableDialogue = null

@onready var animatedDecoration: AnimatedDecoration = get_node('AnimatedDecoration')
@onready var interactSprite: AnimatedSprite2D = get_node('InteractSprite')

var solved: bool = false
var playingSolvingAnim: bool = false
var queuedAnim: String = ''

func _ready():
	show_interact_sprite(false)
	PlayerResources.story_requirements_updated.connect(_story_reqs_updated)
	animatedDecoration.animSprite.sprite_frames = puzzle.puzzleSpriteFrames
	_story_reqs_updated(false)

func show_interact_sprite(showSprite: bool = true):
	interactSprite.visible = showSprite
	if showSprite:
		interactSprite.play('default')
	else:
		interactSprite.stop()

func select_choice(choice: DialogueChoice):
	if choice is PuzzleDialogueChoice:
		var puzzleChoice: PuzzleDialogueChoice = choice as PuzzleDialogueChoice
		if puzzleChoice.acceptsSolve:
			puzzle.solve()
	super.select_choice(choice)

func interact(_args: Array = []):
	var args: Array = []
	if puzzle.is_solved():
		args.append(solvedDialogue)
	elif not puzzle.passes_prereqs():
		args.append(failedPrereqsDialogue)
	
	super.interact(args)

func play_animation(animName: String):
	if not playingSolvingAnim:
		animatedDecoration.play_animation(animName)
	else:
		queuedAnim = animName

func _on_area_entered(area):
	if area.name == 'PlayerEventCollider':
		# add this puzzle to the list of interactables for the player
		enter_player_range()
		show_interact_sprite()

func _on_area_exited(area):
	if area.name == 'PlayerEventCollider' and self in PlayerFinder.player.interactables:
		# remove this puzzle from the list of interactable items for the player
		exit_player_range()
		show_interact_sprite(false)

func _story_reqs_updated(playSolving: bool = true):
	var updatedSolved = puzzle.is_solved()
	if updatedSolved:
		show_interact_sprite(false)
		if playSolving and not solved:
			animatedDecoration.play_animation(puzzle.solvingAnimation)
			playingSolvingAnim = true
			animatedDecoration.anim_finished.connect(_solving_anim_finished)
			if puzzle.updateAnimOnSolve:
				animatedDecoration.anim_finished.connect(play_solved_anim)
		else:
			play_solved_anim()
		if puzzle.disableCollisionOnSolve:
			animatedDecoration.collision.collision_layer = 0
	else:
		animatedDecoration.play_animation(puzzle.unsolvedAnimation)
		animatedDecoration.collision.collision_layer = 0b01
	solved = updatedSolved

func _solving_anim_finished():
	playingSolvingAnim = false
	if queuedAnim != '':
		play_animation(queuedAnim)
	queuedAnim = ''

func play_solved_anim():
	animatedDecoration.play_animation(puzzle.solvedAnimation)
