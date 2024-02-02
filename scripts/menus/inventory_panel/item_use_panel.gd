extends Control
class_name ItemUsePanel

signal ok_pressed

@export var item: Item = null
@export var target: Combatant = null
@export var learnedMove: Move = null

@onready var itemSprite: Sprite2D = get_node("Panel/ItemSpriteControl/ItemSprite")
@onready var itemUsedTitle: RichTextLabel = get_node("Panel/ItemUsedTitle")
@onready var itemUsedEffects: RichTextLabel = get_node("Panel/ItemUsedEffects")
@onready var okButton: Button = get_node('Panel/OkButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_item_use_panel():
	var itemUseText: String = ''
	if item != null:
		itemSprite.texture = item.itemSprite
		if PlayerResources.playerInfo.combatant.would_item_have_effect(item):
			itemUsedTitle.text = '[center]Item Used - ' + item.itemName + '[/center]'
			if learnedMove == null:
				itemUseText = item.get_as_subclass().get_use_message(target)
			else:
				var shard: Shard = item as Shard
				var combatant: Combatant = Combatant.load_combatant_resource(shard.combatantSaveName)
				itemUseText = 'You learned ' + learnedMove.moveName + ' from ' + combatant.disp_name() + ', absorbing its Shard in the process. ' + learnedMove.moveLearnedText
		else:
			itemUsedTitle.text = '[center]Has No Effect - ' + item.itemName + '[/center]'
			itemUseText = 'You attempted to use the ' + item.itemName + ', but it has no effect'
			if item.itemType == Item.Type.HEALING:
				itemUseText += ', because you are at full health already'
			itemUseText += '.'
		visible = true
		okButton.grab_focus()
	
	if itemUseText == '':
		visible = false
	else:
		itemUsedEffects.text = itemUseText

func _on_ok_button_pressed():
	ok_pressed.emit()
	visible = false
