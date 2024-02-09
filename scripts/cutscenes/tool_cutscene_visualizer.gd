@tool
extends CutscenePlayer
class_name CutsceneVisualizer

@export var triggerOrNPC: Node

@export var startVisualizing: bool:
	get:
		return false
	set(value):
		if triggerOrNPC:
			mockPlayer.global_position = triggerOrNPC.position
		start_visualizing()

@onready var mockPlayer: Node = get_node('MockPlayer')

func _init():
	if not Engine.is_editor_hint():
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)

func fetch_actor_node(actorTreePath: String, isPlayer: bool) -> Node:
	var node = null
	if isPlayer:
		node = mockPlayer
	elif rootNode != null:
		var pathSegments = actorTreePath.split('/')
		node = get_node_or_null(pathSegments[len(pathSegments) - 1])
		if node == null:
			var origNode = rootNode.get_node_or_null(actorTreePath)
			if origNode != null:
				node = origNode.duplicate(1 + 2 + 4) # no instancing
				add_child(node)
	return node


func is_in_dialogue() -> bool:
	return false

func handle_hold_camera():
	pass

func queue_text(item: CutsceneDialogue):
	print(item.speaker + ' will say: ')
	for text in item.texts:
		print(text)

func handle_fade_out():
	pass
	
func handle_fade_in():
	pass

func handle_give_item():
	pass

func start_visualizing():
	start_cutscene(cutscene.duplicate(true))

func end_cutscene(force: bool = false):
	if cutscene == null or completeAfterFadeIn:
		return
	if cutscene.givesQuest != null:
		print('Given quest ' + cutscene.givesQuest.questName)
	complete_cutscene()

func complete_cutscene():
	lastFrame = null
	playing = false
	completeAfterFadeIn = false
	
	if playingFromTrigger != null:
		playingFromTrigger.cutscene_finished(cutscene)
		playingFromTrigger = null
	cutscene_completed.emit()
	for tween in tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	tweens = []
	for child in get_children():
		if child != mockPlayer:
			child.queue_free() # NOTE could be unsafe in editor
