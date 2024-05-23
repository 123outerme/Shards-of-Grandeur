extends Area2D
class_name GroundItem

@export var pickedUpItem: PickedUpItem = null
@export var disguiseSprite: Texture = null
@export var storyRequirements: Array[StoryRequirements] = []
@export var startsQuest: Quest = null
@export var invisible: bool = false
@export var particleTextures: Array[Texture2D] = []

@onready var sprite: Sprite2D = get_node('Sprite2D')
@onready var particleEmitter: Particles = get_node('ParticleEmitter')
@onready var pickUpSprite: AnimatedSprite2D = get_node('PickUpSprite')

var disabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if pickedUpItem == null or pickedUpItem.item == null:
		printerr('GroundItem ERR: no item defined')
		queue_free()
		
	if PlayerResources.playerInfo.has_picked_up(pickedUpItem.uniqueId):
		queue_free()
	
	show_pick_up_sprite(false)
	PlayerResources.story_requirements_updated.connect(_story_reqs_updated)
	_story_reqs_updated()
	
	if invisible:
		sprite.texture = null
	elif disguiseSprite != null:
		sprite.texture = disguiseSprite
	else:
		sprite.texture = pickedUpItem.item.itemSprite
	
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

func _on_area_entered(area):
	if not disabled and area.name == 'PlayerEventCollider' and not PlayerResources.playerInfo.has_picked_up(pickedUpItem.uniqueId):
		# add this ground item to the list of ground items the player can pick up
		PlayerFinder.player.groundItems.append(self)
		show_pick_up_sprite()

func _on_area_exited(area):
	if area.name == 'PlayerEventCollider' and self in PlayerFinder.player.groundItems:
		# remove item from the running to be picked up
		var idx: int = PlayerFinder.player.groundItems.find(self)
		if idx != -1:
			PlayerFinder.player.groundItems.remove_at(idx)
		show_pick_up_sprite(false)

func _story_reqs_updated():
	visible = len(storyRequirements) == 0 # false if any requirements, otherwise true
	for requirement in storyRequirements:
		visible = requirement.is_valid() or visible
	disabled = not visible
	if disabled:
		show_pick_up_sprite(false)
		var idx: int = PlayerFinder.player.groundItems.find(self)
		if idx != -1:
			PlayerFinder.player.groundItems.remove_at(idx)
