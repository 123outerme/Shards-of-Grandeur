extends Panel
class_name EquipmentIconsPanel

@export var weapon: Weapon = null
@export var armor: Armor = null

@export var notEquippedSprite: Texture = null

@onready var weaponSprite: TextureButton = get_node('HBoxContainer/WeaponControl/WeaponSprite')
@onready var weaponName: RichTextLabel = get_node('HBoxContainer/WeaponControl/WeaponName')

@onready var armorSprite: TextureButton = get_node('HBoxContainer/ArmorControl/ArmorSprite')
@onready var armorName: RichTextLabel = get_node('HBoxContainer/ArmorControl/ArmorName')

@onready var accessorySprite: TextureButton = get_node('HBoxContainer/AccessoryControl/AccessorySprite')
@onready var accessoryName: RichTextLabel = get_node('HBoxContainer/AccessoryControl/AccessoryName')

@onready var itemDetailsPanel: ItemDetailsPanel = get_node('ItemDetailsPanel')

func load_equipment_icons_panel() -> void:
	if weapon != null:
		weaponSprite.texture_normal = weapon.itemSprite
		weaponName.text = weapon.itemName
	else:
		weaponSprite.texture_normal = notEquippedSprite
		weaponName.text = 'None Equipped'
	
	if armor != null:
		armorSprite.texture_normal = armor.itemSprite
		armorName.text = armor.itemName
	else:
		armorSprite.texture_normal = notEquippedSprite
		armorName.text = 'None Equipped'
	
	'''
	if accessory != null:
		accessorySprite.texture_normal = accessory.itemSprite
		accessoryName.text = accessory.itemName
	else:
		accessorySprite.texture_normal = notEquippedSprite
		accessoryName.text = 'None Equipped'
	#'''

func _on_weapon_sprite_pressed():
	if weapon != null:
		itemDetailsPanel.item = weapon
		itemDetailsPanel.visible = true
		itemDetailsPanel.load_item_details()

func _on_armor_sprite_pressed():
	if armor != null:
		itemDetailsPanel.item = armor
		itemDetailsPanel.visible = true
		itemDetailsPanel.load_item_details()

func _on_accessory_sprite_pressed() -> void:
	'''
	if accessory != null:
		itemDetailsPanel.item = accessory
		itemDetailsPanel.visible = true
		itemDetailsPanel.load_item_details()
	#'''

func _on_item_details_panel_back_pressed() -> void:
	if itemDetailsPanel.item == armor:
		armorSprite.grab_focus()
	elif itemDetailsPanel.item == weapon:
		weaponSprite.grab_focus()
	else:
		accessorySprite.grab_focus()
