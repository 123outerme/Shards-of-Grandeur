extends Area2D
class_name GroundItem

@export var pickedUpItem: PickedUpItem = null
@export var disguiseSprite: Texture = null
@export var storyRequirements: StoryRequirements = null
@export var startsQuest: Quest = null

@onready var sprite: Sprite2D = get_node('Sprite2D')

# Called when the node enters the scene tree for the first time.
func _ready():
	if pickedUpItem == null or pickedUpItem.item == null:
		printerr('GroundItem ERR: no item defined')
		queue_free()
		
	if PlayerResources.playerInfo.has_picked_up(pickedUpItem.uniqueId) or (storyRequirements != null and not storyRequirements.is_valid()):
		queue_free()
	
	if disguiseSprite != null:
		sprite.texture = disguiseSprite
	else:
		sprite.texture = pickedUpItem.item.itemSprite

func _on_area_entered(area):
	if area.name == 'PlayerEventCollider' and not PlayerResources.playerInfo.has_picked_up(pickedUpItem.uniqueId):
		PlayerFinder.player.pick_up(self)
