@tool
extends Interactable
class_name InteractableDecoration

## if non-empty, plays the specified animation of the nested AnimatedDecoration's sprite when interacted with
@export var interactAnim: String = ''

## a SpriteFrames representing all the combined animated decorations' sprites (if more than one). Overrides default `get_sprite_frames` logic of returning the first decoration's SpriteFrames
@export var combinedSpriteFrames: SpriteFrames = null

## ifi true, will start a fadeout animation that then 
@export var fadeOutOnRequirementsInvalidated: bool = false

var animatedDecorations: Array[AnimatedDecoration] = []
var fadeoutTween: Tween = null

@onready var interactSprite: AnimatedSprite2D = get_node('InteractSprite')

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
			SceneLoader.cutscenePlayer.cutscene_fadeout_done.connect(_story_requirements_updated)

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

func set_invisible(value: bool) -> void:
	super.set_invisible(value)
	for decoration: AnimatedDecoration in animatedDecorations:
		if decoration != null:
			decoration.invisible = value

func _story_requirements_updated(initializing: bool = false) -> void:
	if not StoryRequirements.list_is_valid(storyRequirements):
		if not initializing and fadeOutOnRequirementsInvalidated and fadeoutTween == null:
			fadeoutTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
			fadeoutTween.tween_property(self, 'modulate', Color(0,0,0,0), 1.0)
			fadeoutTween.tween_callback(deactivate)
		else:
			deactivate()
	
	## check if interact sprite can be shown
	if PlayerFinder.player != null and self in PlayerFinder.player.interactables and can_show_interact_sprite():
		show_interact_sprite()

func deactivate() -> void:
	invisible = true
	show_interact_sprite(false)
	modulate = Color(1, 1, 1, 1) # reset modulate if faded out
	fadeoutTween = null
