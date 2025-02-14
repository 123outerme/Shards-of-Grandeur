@tool
extends Interactable
class_name InteractableDecoration

## if non-empty, plays the specified animation of the nested AnimatedDecoration's sprite when interacted with
@export var interactAnim: String = ''

## a SpriteFrames representing all the combined animated decorations' sprites (if more than one)
@export var combinedSpriteFrames: SpriteFrames = null

var animatedDecorations: Array[AnimatedDecoration] = []

@onready var interactSprite: AnimatedSprite2D = get_node('InteractSprite')

var invisible: bool:
	set(i):
		visible = not i
		for decoration: AnimatedDecoration in animatedDecorations:
			if decoration != null:
				decoration.invisible = i
	get:
		return not visible

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		for child: Node in get_children():
			if child is AnimatedDecoration:
				animatedDecorations.append(child)
		super._ready()
		
		for animatedDecoration: AnimatedDecoration in animatedDecorations:
			animatedDecoration.anim_finished.connect(animatedDecoration.play_animation.bind(animatedDecoration.animName))
		show_interact_sprite(false)
		if SceneLoader.cutscenePlayer != null:
			SceneLoader.cutscenePlayer.cutscene_fadeout_done.connect(_check_enable_interact_sprite)
		PlayerResources.story_requirements_updated.connect(_check_enable_interact_sprite)

func show_interact_sprite(showSprite: bool = true):
	interactSprite.visible = showSprite
	if showSprite:
		interactSprite.play('default')
	else:
		interactSprite.stop()

func play_animation(animName: String):
	if animName != '':
		for animatedDecoration: AnimatedDecoration in animatedDecorations:
			animatedDecoration.play_animation(animName)

func get_sprite_frames() -> SpriteFrames:
	if combinedSpriteFrames != null:
		return combinedSpriteFrames
	if len(animatedDecorations) > 0:
		return animatedDecorations[0].get_sprite_frames()
	return null

func get_interact_animation() -> String:
	return interactAnim

func interact(args: Array = []):
	if interactAnim != '':
		for animatedDecoration: AnimatedDecoration in animatedDecorations:
			animatedDecoration.play_animation(interactAnim)
	super.interact(args)

func can_show_interact_sprite() -> bool:
	return not PlayerFinder.player.inCutscene and has_dialogue()

func _on_area_entered(area):
	if area.name == 'PlayerEventCollider':
		if can_show_interact_sprite():
			show_interact_sprite()
		enter_player_range()

func _on_area_exited(area):
	if area.name == 'PlayerEventCollider' and self in PlayerFinder.player.interactables:
		show_interact_sprite(false)
		exit_player_range()

func _check_enable_interact_sprite():
	if self in PlayerFinder.player.interactables and can_show_interact_sprite():
		show_interact_sprite()
