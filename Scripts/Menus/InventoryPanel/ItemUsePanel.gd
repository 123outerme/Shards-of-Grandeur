extends Control
class_name ItemUsePanel

signal ok_pressed

@export var item: Item = null
@export var target: Combatant = null

@onready var itemSprite: Sprite2D = get_node("Panel/ItemSpriteControl/ItemSprite")
@onready var itemUsedTitle: RichTextLabel = get_node("Panel/ItemUsedTitle")
@onready var itemUsedEffects: RichTextLabel = get_node("Panel/ItemUsedEffects")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_item_use_panel():
	if item != null and item.get_as_subclass().get_use_message(target) != '':
		itemSprite.texture = item.itemSprite
		itemUsedTitle.text = '[center]Item Used - ' + item.itemName + '[/center]'
		itemUsedEffects.text = item.get_as_subclass().get_use_message(target)
		visible = true
	else:
		visible = false

func _on_ok_button_pressed():
	ok_pressed.emit()
	visible = false
