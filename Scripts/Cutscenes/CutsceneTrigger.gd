extends Area2D
class_name CutsceneTrigger

@export var cutscene: Cutscene
@export var playing: bool = false
@export var disabled: bool = false

var timer: float = 0
var lastFrame: CutsceneFrame = null
var nextKeyframeTime: float = 0
var tweens: Array = []
var isPaused: bool = false

func _ready():
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
		
		if frame == null:
			SceneLoader.unpause_autonomous_movers()
			disabled = true
			playing = false
			PlayerFinder.player.show_letterbox(false)
			return
		
		if lastFrame == frame:
			return
		
		lastFrame = frame
		tweens = []
		for animation in frame.actorAnims:
			var node = animation.actor
			if animation.isPlayer:
				node = PlayerFinder.player
			if node.has_method('play_animation'):
				node.call('play_animation', animation.animation)
		for actorTween in frame.actorTweens:
			var node = actorTween.actor
			if actorTween.isPlayer:
				node = PlayerFinder.player
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

func _on_area_entered(area):
	if area.name == "PlayerEventCollider" and not disabled and not playing:
		playing = true
		start_cutscene()
