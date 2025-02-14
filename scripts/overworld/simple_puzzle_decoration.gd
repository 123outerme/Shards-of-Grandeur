extends Interactable
class_name SimplePuzzleDecoration

@export var puzzle: SimplePuzzle = null

## the dialogue to show when the player doesn't have the prerequisite story requirements. `dialogue` is for the "unsolved but passes prereqs" dialogue
@export var failedPrereqsDialogue: InteractableDialogue = null

## the dialogue to show when the player has already solved this puzzle. `dialogue` is for the "unsolved but passes prereqs" dialogue
@export var solvedDialogue: InteractableDialogue = null

## the animation from the loaded SpriteFrames to use when the puzzle is/remains unsolved
@export var unsolvedAnimation: String = 'default'

## the animation from the loaded SpriteFrames to use when the puzzle was just solved (transition animation)
@export var solvingAnimation: String = ''

## the animation from the loaded SpriteFrames to use when the puzzle is/remains solved
@export var solvedAnimation: String = ''

## if true, the collision is disabled as soon as the puzzle is solved
@export var disableCollisionOnSolve: bool = false

## if true, the animation is updated to `solvedAnimation` immediately after finishing the `solvingAnimation`. By setting to false, you must manually update the animation to `solved` later in the solving dialogue sequence, if required
@export var updateAnimOnSolve: bool = true

## if true, the AnimatedDecoration nested in this object has its animation updates disabled (this object will handle it completely)
@export var disableAnimatedDecorationUpdates: bool = true

@onready var animatedDecoration: AnimatedDecoration = get_node('AnimatedDecoration')
@onready var interactSprite: AnimatedSprite2D = get_node('InteractSprite')

var solved: bool = false
var playingSolvingAnim: bool = false
var queuedAnim: String = ''

func _ready():
	super._ready()
	animatedDecoration.disableAnimUpdateOnLoad = disableAnimatedDecorationUpdates
	show_interact_sprite(false)
	PlayerResources.story_requirements_updated.connect(_puzzle_reqs_updated)
	_puzzle_reqs_updated(false)

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

func has_dialogue() -> bool:
	if puzzle.is_solved():
		return solvedDialogue != null and solvedDialogue.can_use_dialogue()
	elif not puzzle.passes_prereqs():
		return failedPrereqsDialogue != null and failedPrereqsDialogue.can_use_dialogue()
	
	return super.has_dialogue()

func play_animation(animName: String):
	if not playingSolvingAnim:
		animatedDecoration.play_animation(animName)
	else:
		queuedAnim = animName

func get_sprite_frames() -> SpriteFrames:
	return animatedDecoration.get_sprite_frames()

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

# puzzle's story requirements have changed; not to be confused with its Interactable requirements (to be visible)
func _puzzle_reqs_updated(playSolving: bool = true):
	var updatedSolved = puzzle.is_solved()
	if updatedSolved:
		show_interact_sprite(false)
		if playSolving and not solved:
			animatedDecoration.play_animation(solvingAnimation)
			playingSolvingAnim = true
			animatedDecoration.anim_finished.connect(_solving_anim_finished)
			if updateAnimOnSolve:
				animatedDecoration.anim_finished.connect(play_solved_anim)
		else:
			play_solved_anim()
		if disableCollisionOnSolve:
			animatedDecoration.collision.collision_layer = 0
			animatedDecoration.collision.collision_mask = 0
	else:
		animatedDecoration.play_animation(unsolvedAnimation)
		animatedDecoration.collision.collision_layer = 0b01
		animatedDecoration.collision.collision_mask = 0b01
	solved = updatedSolved

func _solving_anim_finished():
	playingSolvingAnim = false
	if queuedAnim != '':
		play_animation(queuedAnim)
	queuedAnim = ''
	if animatedDecoration.anim_finished.is_connected(_solving_anim_finished):
		animatedDecoration.anim_finished.disconnect(_solving_anim_finished)

func play_solved_anim():
	animatedDecoration.play_animation(solvedAnimation)
	if animatedDecoration.anim_finished.is_connected(play_solved_anim):
		animatedDecoration.anim_finished.disconnect(play_solved_anim)
