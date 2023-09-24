extends Resource
class_name Item

enum Type {
	HEALING = 0,
	SHARD = 1,
	WEAPON = 2,
	ARMOR = 3,
	KEY_ITEM = 4,
	ALL = -1,
}

static func TypeToString(t: Type):
	match t:
		Type.HEALING:
			return "Healing"
		Type.SHARD:
			return "Shard"
		Type.WEAPON:
			return "Weapon"
		Type.ARMOR:
			return "Armor"
		Type.KEY_ITEM:
			return "Key Item"
		Type.ALL:
			return "All"
	return "Unknown"

@export var itemSprite: Texture2D
@export var itemName: String
@export var itemType: Type
@export_multiline var itemDescription: String
@export var cost: int
@export var maxCount: int
@export var usable: bool = true
@export var consumable: bool = true
@export var equippable: bool = false

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.HEALING,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 0,
	i_usable = true,
	i_consumable = true,
	i_equippable = false,
):
	itemSprite = i_sprite
	itemName = i_name
	itemType = i_type
	cost = i_cost
	maxCount = i_maxCount
	usable = i_usable
	consumable = i_consumable
	equippable = i_equippable
	
