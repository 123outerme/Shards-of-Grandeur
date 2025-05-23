extends Control
class_name ItemDetailsPanel
signal back_pressed

@export var item: Item
@export var count: int = 0

@onready var itemName: RichTextLabel = get_node("Panel/ItemName")
@onready var itemSprite: Sprite2D = get_node("Panel/ItemSprite")
@onready var itemType: RichTextLabel = get_node("Panel/ItemType")
@onready var itemEffect: RichTextLabel = get_node("Panel/ItemEffect")
@onready var equipmentDetailsPanel: EquipmentDetailsPanel = get_node('Panel/EquipmentDetailsPanel')
@onready var itemDescription: RichTextLabel = get_node("Panel/ItemDescription")
@onready var itemCostGroup: Control = get_node("Panel/ItemCostGroup")
@onready var itemCost: RichTextLabel = get_node("Panel/ItemCostGroup/ItemCost")
@onready var itemCount: RichTextLabel = get_node("Panel/ItemCount")
@onready var backButton: Button = get_node("Panel/BackButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_item_details()

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func load_item_details():
	if item == null:
		return
	
	itemName.text = '[center]' + item.itemName + '[/center]'
	itemSprite.texture = item.itemSprite
	itemType.text = '[center]' + Item.type_to_string(item.itemType) + '[/center]'
	if item.itemType == Item.Type.WEAPON or item.itemType == Item.Type.ARMOR:
		equipmentDetailsPanel.item = item
		equipmentDetailsPanel.load_equipment_details_panel()
		itemEffect.visible = false
	else:
		equipmentDetailsPanel.visible = false
		itemEffect.visible = true
		itemEffect.text = '[center]' + item.get_effect_text()
		if item.battleUsable:
			itemEffect.text += '\nIn Battle, usable on ' + BattleCommand.targets_to_string(item.battleTargets) + '.'
		itemEffect.text += '[/center]'
	
	itemDescription.text = item.itemDescription
	
	if item.cost >= 0:
		itemCost.text = String.num_int64(item.cost)
		itemCostGroup.visible = true
	else:
		itemCostGroup.visible = false
	
	if count > 0:
		itemCount.visible = true
		itemCount.text = 'x' + String.num_int64(count) + ' / ' + String.num_int64(item.maxCount)
	else:
		itemCount.visible = false
	backButton.grab_focus()

func _on_back_button_pressed():
	visible = false
	back_pressed.emit()
