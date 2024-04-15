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

var disabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if pickedUpItem == null or pickedUpItem.item == null:
		printerr('GroundItem ERR: no item defined')
		queue_free()
		
	if PlayerResources.playerInfo.has_picked_up(pickedUpItem.uniqueId):
		queue_free()
		
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

func _on_area_entered(area):
	if not disabled and area.name == 'PlayerEventCollider' and not PlayerResources.playerInfo.has_picked_up(pickedUpItem.uniqueId):
		PlayerFinder.player.pick_up(self)

func _story_reqs_updated():
	visible = len(storyRequirements) == 0 # false if any requirements, otherwise true
	for requirement in storyRequirements:
		visible = requirement.is_valid() or visible
	disabled = not visible
