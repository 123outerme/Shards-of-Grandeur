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

static func TypeToString(t: Type) -> String:
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
@export var battleUsable: bool = true
@export var consumable: bool = true
@export var equippable: bool = false
@export var battleTargets: BattleCommand.Targets = BattleCommand.Targets.SELF

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.HEALING,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 0,
	i_usable = true,
	i_battleUsable = true,
	i_consumable = true,
	i_equippable = false,
	i_targets = BattleCommand.Targets.SELF,
):
	itemSprite = i_sprite
	itemName = i_name
	itemDescription = i_itemDescription
	itemType = i_type
	cost = i_cost
	maxCount = i_maxCount
	usable = i_usable
	battleUsable = i_battleUsable
	consumable = i_consumable
	equippable = i_equippable
	battleTargets = i_targets

func use(_target: Combatant):
	print("If you're seeing this, implement Item.use() in item type:", Item.TypeToString(itemType))
	pass # "virtual" function - does nothing. Override in inherting classes!

func get_use_message(_target: Combatant) -> String:
	return "If you're seeing this, implement Item.get_use_message() in item type " + Item.TypeToString(itemType)

func get_effect_text(inBattle: bool = true) -> String:
	return "If you're seeing this, implement Item.get_effect_text() in item type " + Item.TypeToString(itemType) \
			+ ", or you forgot to fill in the effect text!"

# custom can be used logic
func can_be_used_now() -> bool:
	return true

func get_as_subclass():
	if itemType == Type.HEALING:
		return self as Healing
	if itemType == Type.SHARD:
		return self as Shard
	if itemType == Type.WEAPON:
		return self as Weapon
	if itemType == Type.ARMOR:
		return self as Armor
	if itemType == Type.KEY_ITEM:
		return (self as KeyItem).get_as_key_item_type()
	return self
