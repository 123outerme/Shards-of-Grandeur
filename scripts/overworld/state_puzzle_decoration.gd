extends Interactable
class_name StatePuzzleDecoration

## the state-based puzzle to use for this decoration
@export var puzzle: StatePuzzle = null

## the index in the states that this decoration corresponds to (for multi-decoration puzzles)
@export var puzzleStateIndex: int = 0

## a dictionary String -> String, where key is the state string, and value is the animation to play at that state
@export var stateAnimations: Dictionary[String, String] = {
	'default': 'default'
}

## a dictionary String -> String, where key is `state1>state2` for a transition from `state1` to `state2`, and value is the animation to play for that transition
@export var stateTransitionAnimations: Dictionary[String, String] = {}

## a dictionary String -> AudioStream, where key is `state1>state2` for a transition from `state1` to `state2`, where `state1` can be a state string or *. * matches all unmatched start states. Value is the SFX to play for that transition
@export var stateTransitionSfxs: Dictionary[String, AudioStream] = {}

## dictionary of String -> InteractableDialogue objects. Each key is a state of the StatePuzzle, each InteractableDialogue the dialogue that will be played when interacting with this decoration in that puzzle state
@export var stateDialogues: Dictionary[String, InteractableDialogue] = {}

## the dialogue to show when the player doesn't have the prerequisite story requirements. `dialogue` is for the "unsolved but passes prereqs" dialogue
@export var failedPrereqsDialogue: InteractableDialogue = null

@export var disableDialogueSpeakerSprite: bool = false

## if true, the collision is disabled as soon as the puzzle is solved
@export var disableCollisionInStates: Array[String] = []

## if true, the animation is updated to the current state's `stateAnimations` entry animation immediately after finishing the `stateTransitionAnimations` entry animation. By setting to false, you must manually update the animation later in the solving dialogue sequence, if required
@export var updateAnimOnTransitionAnimEnd: bool = true

## if true, the AnimatedDecoration nested in this object has its animation updates disabled (this object will handle it completely)
@export var disableAnimatedDecorationUpdates: bool = true

@onready var animatedDecoration: AnimatedDecoration = get_node('AnimatedDecoration')
@onready var interactSprite: AnimatedSprite2D = get_node('InteractSprite')

var playingTransitionAnim: bool = false
var queuedAnim: String = ''
var currentState: String = ''

func _ready():
	if puzzle == null:
		printerr('StatePuzzleDecoration ERROR: puzzle is null for decoration ', get_path())
		queue_free()
		return
	if puzzleStateIndex < 0:
		printerr('StatePuzzleDecoration ERROR: puzzle state index is negative, ', puzzleStateIndex)
		queue_free()
		return
	
	super._ready()
	animatedDecoration.disableAnimUpdateOnLoad = disableAnimatedDecorationUpdates
	show_interact_sprite(false)
	PlayerResources.story_requirements_updated.connect(_puzzle_reqs_updated)
	_puzzle_reqs_updated(false)

func get_decoration_state() -> String:
	if puzzle == null:
		return ''
	
	puzzle.fix_empty_puzzle_states()
	var puzzleStates: Array[String] = PlayerResources.playerInfo.get_puzzle_states(puzzle.id)
	if puzzleStateIndex < len(puzzleStates):
		return puzzleStates[puzzleStateIndex]
	elif puzzleStateIndex < len(puzzle.defaultStates):
		return puzzle.defaultStates[puzzleStateIndex]
	else:
		printerr('StatePuzzleDecoration ERROR: puzzle ', puzzle.id, ' does not have default states set up for index ', puzzleStateIndex)
		return ''

func show_interact_sprite(showSprite: bool = true):
	interactSprite.visible = showSprite
	if showSprite:
		interactSprite.play('default')
	else:
		interactSprite.stop()

func select_choice(choice: DialogueChoice):
	if choice is PuzzleDialogueChoice:
		var puzzleChoice: PuzzleDialogueChoice = choice as PuzzleDialogueChoice
		if puzzleChoice.setsState != currentState and puzzleChoice.setsState != '':
			puzzle.transition_state(puzzleChoice.setsState, puzzleStateIndex, currentState)
		if puzzleChoice.acceptsSolve:
			puzzle.solve()
	super.select_choice(choice)

func interact(_args: Array = []):
	var args: Array = []
	if not puzzle.passes_prereqs():
		args.append(failedPrereqsDialogue)
	else:
		var state: String = get_decoration_state()
		if stateDialogues.has(state):
			args.append(stateDialogues[state] as InteractableDialogue)
	
	super.interact(args)

func has_dialogue() -> bool:
	if not puzzle.passes_prereqs():
		return failedPrereqsDialogue != null and failedPrereqsDialogue.can_use_dialogue() and not invisible
	else:
		var state: String = get_decoration_state()
		if stateDialogues.has(state):
			var stateDialogue: InteractableDialogue = stateDialogues[state] as InteractableDialogue
			return stateDialogue != null and stateDialogue.can_use_dialogue() and not invisible
		return false
	#return super.has_dialogue()

func play_animation(animName: String):
	if not playingTransitionAnim:
		animatedDecoration.play_animation(animName)
	else:
		queuedAnim = animName

func get_sprite_frames() -> SpriteFrames:
	if disableDialogueSpeakerSprite:
		return null
	return animatedDecoration.get_sprite_frames()

func get_interact_animation() -> String:
	if not disableDialogueSpeakerSprite and stateAnimations.has(currentState):
		return stateAnimations[currentState]
	return ''

func set_invisible(value: bool) -> void:
	super.set_invisible(value)
	animatedDecoration.invisible = value

func _on_area_entered(area):
	if area.name == 'PlayerEventCollider':
		# add this puzzle to the list of interactables for the player
		enter_player_range()
		var state: String = get_decoration_state()
		# if invalid (using invalid-dialogue) or has a dialogue for the current state:
		if not puzzle.passes_prereqs() or stateDialogues.has(state):
			show_interact_sprite()

func _on_area_exited(area):
	if area.name == 'PlayerEventCollider' and self in PlayerFinder.player.interactables:
		# remove this puzzle from the list of interactable items for the player
		exit_player_range()
		show_interact_sprite(false)

# puzzle's story requirements have changed; not to be confused with its Interactable requirements (to be visible)
func _puzzle_reqs_updated(playTransition: bool = true):
	var state: String = get_decoration_state()
	if currentState != state:
		show_interact_sprite(false)
		var animation: String = stateAnimations[state]
		if playTransition:
			if stateTransitionAnimations.has(currentState + '>' + state):
				animation = stateTransitionAnimations[currentState + '>' + state]
			if stateTransitionSfxs.has(currentState + '>' + state):
				SceneLoader.audioHandler.play_sfx(stateTransitionSfxs[currentState + '>' + state])
			elif stateTransitionSfxs.has('*>' + state):
				SceneLoader.audioHandler.play_sfx(stateTransitionSfxs['*>' + state])
		if not animatedDecoration.anim_finished.is_connected(_transition_anim_finished):
			animatedDecoration.anim_finished.connect(_transition_anim_finished)
		if updateAnimOnTransitionAnimEnd and not animatedDecoration.anim_finished.is_connected(play_current_state_animation):
			animatedDecoration.anim_finished.connect(play_current_state_animation)
		animatedDecoration.play_animation(animation)
		if state in disableCollisionInStates:
			animatedDecoration.collision.collision_layer = 0
			animatedDecoration.collision.collision_mask = 0
		else:
			animatedDecoration.collision.collision_layer = 0b01
			animatedDecoration.collision.collision_mask = 0b01
	currentState = state

func _transition_anim_finished():
	animatedDecoration.anim_finished.disconnect(_transition_anim_finished)
	playingTransitionAnim = false
	if queuedAnim != '':
		play_animation(queuedAnim)
	queuedAnim = ''

func play_current_state_animation():
	if animatedDecoration.anim_finished.is_connected(play_current_state_animation):
		animatedDecoration.anim_finished.disconnect(play_current_state_animation)
	animatedDecoration.play_animation(stateAnimations[get_decoration_state()])
