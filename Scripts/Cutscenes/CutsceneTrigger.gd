extends Area2D
class_name CutsceneTrigger

@export var cutscene: Cutscene
@export var playing: bool = false
@export var disabled: bool = false
@export var rootNode: Node = null

var timer: float = 0
var lastFrame: CutsceneFrame = null
var nextKeyframeTime: float = 0
var tweens: Array = []
var isPaused: bool = false

func _ready():
	if PlayerResources.playerInfo.has_seen_cutscene(cutscene.saveName):
		queue_free() # delete self if player has seen cutscene
	start_cutscene()

func _process(delta):
	if playing and not disabled:
		timer += delta
		
		var frame: CutsceneFrame = cutscene.get_keyframe_at_time(timer)
		
		if PlayerFinder.player.is_in_dialogue():
			return
		
		if lastFrame != null and frame != lastFrame and lastFrame.endTextBoxTexts != null \
				and len(lastFrame.endTextBoxTexts) > 0 and not lastFrame.get_text_was_triggered():
			PlayerFinder.player.set_cutscene_texts(lastFrame.endTextBoxTexts, lastFrame.endTextBoxSpeaker)
			lastFrame.set_text_was_triggered()
			return
		
		if frame == null: # end of cutscene
			end_cutscene()
			return
		
		if lastFrame == frame:
			return
		
		lastFrame = frame
		tweens = []
		for animation in frame.actorAnims:
			var node = null
			if animation.isPlayer:
				node = PlayerFinder.player
			else:
				node = rootNode.get_node(animation.actorTreePath)
			if node != null and node.has_method('play_animation'):
				node.call('play_animation', animation.animation)
		for actorTween in frame.actorTweens:
			var node = null
			if actorTween.isPlayer:
				node = PlayerFinder.player
			else:
				node = rootNode.get_node(actorTween.actorTreePath)
			var tween = create_tween().set_ease(actorTween.easeType).set_trans(actorTween.transitionType)
			if not actorTween is TweenCallback:
				tween.tween_property(node, actorTween.propertyName, actorTween.value, frame.frameLength)
				if actorTween.propertyName == 'position' and node.has_method('face_horiz'):
					node.call('face_horiz', actorTween.value.x - node.position.x)
			else:
				tween.tween_callback(actorTween.value)
			tweens.append(tween)

func start_cutscene():
	timer = 0
	nextKeyframeTime = cutscene.cutsceneFrames[0].frameLength
	cutscene.calc_total_time()
	if playing:
		PlayerFinder.player.show_letterbox()
		SceneLoader.pause_autonomous_movers()
		PlayerResources.playerInfo.set_cutscene_seen(cutscene.saveName)

func pause_cutscene():
	for tween in tweens:
		tween.pause()
	isPaused = true

func resume_cutscene():
	for tween in tweens:
		tween.play()
	isPaused = false

func toggle_pause_cutscene():
	isPaused = not isPaused
	if isPaused:
		pause_cutscene()
	else:
		resume_cutscene()

func end_cutscene():
	SceneLoader.unpause_autonomous_movers()
	disabled = true
	playing = false
	PlayerFinder.player.show_letterbox(false)
	queue_free() # delete self

func _on_area_entered(area):
	if area.name == "PlayerEventCollider" and not disabled and not playing:
		playing = true
		start_cutscene()
