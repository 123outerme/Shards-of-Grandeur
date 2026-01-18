@tool
extends Interactable
class_name GroundItem

## don't fill in the `dialogue` property of GroundItem, leave it blank and use `pickedUpItem` instead. 
@export var pickedUpItem: PickedUpItem = null

## the texture the GroundItem will appear as. If null, uses the texture of the Item
@export var disguiseSprite: Texture = null

## if true, the item will be invisible on the ground (except for particles)
@export var spriteInvisible: bool = false

## define up to 4 particle textures to be emitted to draw attention to the item. If empty, default gold particles will appear
@export var particleTextures: Array[Texture2D] = []

## dialogue speaker sprite for picking-up dialogue
@export var speakerSprite: SpriteFrames = null

@export var speakerSpriteAnimation: String = ''

@onready var sprite: Sprite2D = get_node('Sprite2D')
@onready var staticBody: StaticBody2D = get_node('StaticBody2D')
@onready var particleEmitter: Particles = get_node('ParticleEmitter')
@onready var pickUpSprite: AnimatedSprite2D = get_node('PickUpSprite')

var disabled: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		if pickedUpItem == null or pickedUpItem.item == null or pickedUpItem.dialogueEntry == null or saveName == '':
			printerr('GroundItem ERR: PickedUpItem not defined properly')
			queue_free()
			return
		
		if PlayerResources.playerInfo.has_picked_up(saveName):
			set_disabled(true)
		
		show_pick_up_sprite(false)
		super._ready()
	
	if spriteInvisible:
		sprite.texture = null
	elif disguiseSprite != null:
		sprite.texture = disguiseSprite
	elif pickedUpItem != null and pickedUpItem.item != null:
		sprite.texture = pickedUpItem.item.itemSprite
	if not Engine.is_editor_hint():
		if len(particleTextures) > 0:
			var newPreset: ParticlePreset = particleEmitter.preset.duplicate(false)
			newPreset.particleTextures = particleTextures
			particleEmitter.preset = newPreset
		particleEmitter.set_make_particles(true)

func show_pick_up_sprite(showSprite: bool = true):
	pickUpSprite.visible = showSprite
	if showSprite:
		pickUpSprite.play('default')
	else:
		pickUpSprite.stop()

func interact(_args: Array = []):
	if not PlayerResources.playerInfo.has_picked_up(saveName):
		if interactSfx != null:
			SceneLoader.audioHandler.play_sfx(interactSfx)
		PlayerFinder.player.pick_up(self)

func has_dialogue() -> bool:
	if pickedUpItem != null and pickedUpItem.dialogueEntry != null and not PlayerResources.playerInfo.has_picked_up(saveName):
		return pickedUpItem.dialogueEntry.can_use_dialogue()
	
	return false

func get_sprite_frames() -> SpriteFrames:
	return speakerSprite

func get_interact_animation() -> String:
	return speakerSpriteAnimation

func get_max_sprite_size() -> Vector2i:
	var interactableAnimTexture: Texture2D = get_sprite_frames().get_frame_texture(get_interact_animation(), 0)
	if interactableAnimTexture != null:
		return Vector2i(interactableAnimTexture.get_width(), interactableAnimTexture.get_height())
	return Vector2i()

func set_disabled(value: bool):
	disabled = value
	invisible = value
	if disabled:
		staticBody.collision_layer = 0b00
	else:
		staticBody.collision_layer = 0b01

func _on_area_entered(area):
	if not disabled and area.name == 'PlayerEventCollider':
		# add this ground item to the list of ground items the player can pick up
		enter_player_range()
		show_pick_up_sprite()

func _on_area_exited(area):
	if area.name == 'PlayerEventCollider' and self in PlayerFinder.player.interactables:
		# remove item from the running to be picked up
		exit_player_range()
		show_pick_up_sprite(false)

func _story_requirements_updated(initializing: bool = false):
	var shouldDisable: bool = false
	if not StoryRequirements.list_is_valid(storyRequirements) or PlayerResources.playerInfo.has_picked_up(saveName):
		shouldDisable = true
	set_disabled(shouldDisable)
	if disabled:
		exit_player_range()
		show_pick_up_sprite(false)
		deactivate()

func finished_dialogue():
	var playerPickedUp: bool = false
	if PlayerFinder.player.interactableDialogues[0] is PickedUpItem:
		var pickedUp: PickedUpItem = PlayerFinder.player.interactableDialogues[0] as PickedUpItem
		PlayerResources.inventory.add_item(pickedUp.item)
		playerPickedUp = pickedUp.wasPickedUp
		
	if playerPickedUp:
		PlayerResources.playerInfo.pickedUpItems.append(saveName)
		set_disabled(true)
		exit_player_range()

func deactivate() -> void:
	super.deactivate()
	queue_free()
