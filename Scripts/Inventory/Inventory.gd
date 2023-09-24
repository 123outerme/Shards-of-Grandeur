extends Resource
class_name Inventory

@export var inventorySlots: Array[InventorySlot]

var save_name: String = "inventory.tres"

func _init(i_slots: Array[InventorySlot] = []):
	inventorySlots = i_slots
	
func load_data(save_path):
	if ResourceLoader.exists(save_path + save_name):
		return load(save_path + save_name)
	return null

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_name)
	if err != 0:
		printerr("Inventory ResourceSaver error: " + err)
