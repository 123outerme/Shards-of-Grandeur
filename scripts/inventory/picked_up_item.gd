extends Resource
class_name PickedUpItem

@export_category("PickedUpItem - Overworld data")
@export var uniqueId: String = ''
@export var item: Item
@export_multiline var pickUpTexts: Array[String] = []

@export_category("PickedUpItem - Save Data: Do Not Modify")
@export var savedTextIdx: int = 0
@export var wasPickedUp: bool = false
