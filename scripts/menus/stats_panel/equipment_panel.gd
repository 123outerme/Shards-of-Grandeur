extends Panel
class_name EquipmentPanel

signal attempt_equip_weapon
signal attempt_equip_armor

@export var weapon: Weapon = null
@export var armor: Armor = null
@export var notEquippedSprite: Texture = null
var statsPanel: StatsMenu = null

@onready var weaponSprite: TextureButton = get_node("WeaponControl/WeaponSprite")
@onready var weaponName: RichTextLabel = get_node("WeaponControl/WeaponName")
@onready var weaponEffects: RichTextLabel = get_node("WeaponControl/WeaponEffects")

@onready var armorSprite: TextureButton = get_node("ArmorControl/ArmorSprite")
@onready var armorName: RichTextLabel = get_node("ArmorControl/ArmorName")
@onready var armorEffects: RichTextLabel = get_node("ArmorControl/ArmorEffects")

@onready var itemDetailsPanel: ItemDetailsPanel = get_node("ItemDetailsPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_equipment_panel():
	if weapon != null:
		weaponSprite.texture_normal = weapon.itemSprite
		weaponName.text = weapon.itemName
		weaponEffects.text = '[center]' + weapon.get_effect_text() + '[/center]'
	else:
		weaponSprite.texture_normal = notEquippedSprite
		weaponName.text = 'None Equipped'
		weaponEffects.text = ''
	
	if armor != null:
		armorSprite.texture_normal = armor.itemSprite
		armorName.text = armor.itemName
		armorEffects.text = '[center]' + armor.get_effect_text() + '[/center]'
	else:
		armorSprite.texture_normal = notEquippedSprite
		armorName.text = 'None Equipped'
		armorEffects.text = ''

func hide_panel():
	itemDetailsPanel.visible = false

func _on_weapon_sprite_pressed():
	if weapon != null:
		itemDetailsPanel.item = weapon
		itemDetailsPanel.visible = true
		itemDetailsPanel.load_item_details()
		if statsPanel != null:
			statsPanel.backButton.disabled = true
	else:
		attempt_equip_weapon.emit()

func _on_armor_sprite_pressed():
	if armor != null:
		itemDetailsPanel.item = armor
		itemDetailsPanel.visible = true
		itemDetailsPanel.load_item_details()
		if statsPanel != null:
			statsPanel.backButton.disabled = true
	else:
		attempt_equip_armor.emit()

func _on_item_details_panel_back_pressed():
	if itemDetailsPanel.item == armor:
		armorSprite.grab_focus()
	else:
		weaponSprite.grab_focus()
	if statsPanel != null:
		statsPanel.backButton.disabled = false
