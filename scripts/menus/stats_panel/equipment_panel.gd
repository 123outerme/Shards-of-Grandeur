extends Panel
class_name EquipmentPanel

signal attempt_equip_weapon
signal attempt_equip_armor

@export var weapon: Weapon = null
@export var armor: Armor = null
@export var notEquippedSprite: Texture = null
## If true, will use `EquipmentDetailsPanel` instances instead of generating a text description of each equipment's effects
@export var showEquipmentDetailsPanels: bool = false
var statsPanel: StatsMenu = null

@onready var weaponSprite: TextureButton = get_node("WeaponControl/WeaponSprite")
@onready var weaponName: RichTextLabel = get_node("WeaponControl/WeaponName")
@onready var weaponEffects: RichTextLabel = get_node("WeaponControl/WeaponEffects")
@onready var weaponDetailsPanel: EquipmentDetailsPanel = get_node('WeaponControl/WeaponDetailsPanel')

@onready var armorSprite: TextureButton = get_node("ArmorControl/ArmorSprite")
@onready var armorName: RichTextLabel = get_node("ArmorControl/ArmorName")
@onready var armorEffects: RichTextLabel = get_node("ArmorControl/ArmorEffects")
@onready var armorDetailsPanel: EquipmentDetailsPanel = get_node('ArmorControl/ArmorDetailsPanel')

@onready var itemDetailsPanel: ItemDetailsPanel = get_node("ItemDetailsPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_equipment_panel():
	if weapon != null:
		weaponSprite.texture_normal = weapon.itemSprite
		weaponName.text = weapon.itemName
		if showEquipmentDetailsPanels:
			weaponEffects.text = ''
			weaponDetailsPanel.visible = true
			weaponDetailsPanel.item = weapon
			weaponDetailsPanel.load_equipment_details_panel()
		else:
			weaponEffects.text = '[center]' + weapon.get_effect_text() + '[/center]'
			weaponDetailsPanel.visible = false
	else:
		weaponSprite.texture_normal = notEquippedSprite
		weaponName.text = 'None Equipped'
		weaponEffects.text = ''
		weaponDetailsPanel.visible = false
	
	if armor != null:
		armorSprite.texture_normal = armor.itemSprite
		armorName.text = armor.itemName
		if showEquipmentDetailsPanels:
			armorEffects.text = ''
			armorDetailsPanel.visible = true
			armorDetailsPanel.item = armor
			armorDetailsPanel.load_equipment_details_panel()
		else:
			armorEffects.text = '[center]' + armor.get_effect_text() + '[/center]'
			armorDetailsPanel.visible = false
	else:
		armorSprite.texture_normal = notEquippedSprite
		armorName.text = 'None Equipped'
		armorEffects.text = ''
		armorDetailsPanel.visible = false

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
