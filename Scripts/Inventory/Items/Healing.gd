extends Item
class_name Healing

@export_category("Healing")
@export var healBy: int = 50

func _init(i_healBy = 50):
	healBy = i_healBy
	super._init()

func use(target):
	pass # todo heal target
