extends Resource
class_name Inventory

@export var inventorySlots: Array[InventorySlot]

var save_name: String = "inventory.tres"

func _init(i_slots: Array[InventorySlot] = []):
	inventorySlots = i_slots
	
func add_item(item: Item) -> bool:
	for slot in inventorySlots:
		if slot.item == item:
			if slot.count < slot.item.maxCount or slot.item.maxCount == 0:
				slot.count += 1
				return true
			else:
				return false
	# if not found, add a new slot
	inventorySlots.append(
		InventorySlot.new(item)
	)
	return true
	
func use_item(item: Item, target):
	# TODO use item (based on type?)
	for slot in inventorySlots:
		if slot.item == item and item.usable:
			trash_item(slot) # remove one of the appropriate items
	
func equip_item(inventorySlot: InventorySlot):
	pass

func trash_item(inventorySlot: InventorySlot):
	inventorySlot.count -= 1
	if inventorySlot.count == 0:
		inventorySlots.erase(inventorySlot)
	
func load_data(save_path):
	if ResourceLoader.exists(save_path + save_name):
		return load(save_path + save_name)
	return null

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_name)
	if err != 0:
		printerr("Inventory ResourceSaver error: " + err)
