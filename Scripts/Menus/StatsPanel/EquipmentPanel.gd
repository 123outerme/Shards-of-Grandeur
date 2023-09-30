extends Panel
class_name EquipmentPanel

@export var weapon: Weapon = null
@export var armor: Armor = null

@onready var weaponSprite: Sprite2D = get_node("WeaponControl/WeaponSprite")
@onready var weaponName: RichTextLabel = get_node("WeaponControl/WeaponName")

@onready var armorSprite: Sprite2D = get_node("ArmorControl/ArmorSprite")
@onready var armorName: RichTextLabel = get_node("ArmorControl/ArmorName")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_equipment_panel():
	if weapon != null:
		weaponSprite.texture = weapon.itemSprite
		weaponName.text = weapon.itemName
	else:
		#weaponSprite.texture = # load "unequipped weapon" texture
		weaponName.text = 'None Equipped'
	
	if armor != null:
		armorSprite.texture = armor.itemSprite
		armorName.text = armor.itemName
	else:
		#armorSprite.texture = # load "unequipped armor" texture
		armorName.text = 'None Equipped'
	
