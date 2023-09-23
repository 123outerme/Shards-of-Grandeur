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
