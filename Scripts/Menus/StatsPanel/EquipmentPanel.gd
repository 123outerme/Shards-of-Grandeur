extends Panel
class_name EquipmentPanel

@export var weapon: Weapon = null
@export var armor: Armor = null
var statsPanel: StatsMenu = null

@onready var weaponSprite: TextureButton = get_node("WeaponControl/WeaponSprite")
@onready var weaponName: RichTextLabel = get_node("WeaponControl/WeaponName")

@onready var armorSprite: TextureButton = get_node("ArmorControl/ArmorSprite")
@onready var armorName: RichTextLabel = get_node("ArmorControl/ArmorName")

@onready var itemDetailsPanel: ItemDetailsPanel = get_node("ItemDetailsPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_equipment_panel():
	if weapon != null:
		weaponSprite.disabled = false
		weaponSprite.texture_normal = weapon.itemSprite
		weaponName.text = weapon.itemName
	else:
		weaponSprite.disabled = true
		weaponName.text = 'None Equipped'
	
	if armor != null:
		armorSprite.disabled = false
		armorSprite.texture_normal = armor.itemSprite
		armorName.text = armor.itemName
	else:
		armorSprite.disabled = true
		armorName.text = 'None Equipped'

func hide_panel():
	itemDetailsPanel.visible = false

func _on_weapon_sprite_pressed():
	if weapon != null:
		itemDetailsPanel.item = weapon
		itemDetailsPanel.visible = true
		itemDetailsPanel.load_item_details()
		statsPanel.backButton.disabled = true

func _on_armor_sprite_pressed():
	if armor != null:
		itemDetailsPanel.item = armor
		itemDetailsPanel.visible = true
		itemDetailsPanel.load_item_details()
		statsPanel.backButton.disabled = true

func _on_item_details_back_button_pressed():
	statsPanel.backButton.disabled = false
