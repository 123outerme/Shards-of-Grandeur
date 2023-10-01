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
	
func use_item(item: Item, target: Combatant):
	item.use(target)
	for slot in inventorySlots:
		if slot.item == item and item.usable:
			trash_item(slot) # remove one of the appropriate items
	
func equip_item(inventorySlot: InventorySlot, equip: bool = true):
	var item: Item = inventorySlot.item
	if not equip:
		item = null
	
	if inventorySlot.item is Weapon:
		PlayerResources.playerInfo.stats.equippedWeapon = item
	if inventorySlot.item is Armor:
		PlayerResources.playerInfo.stats.equippedArmor = item

func is_equipped(item: Item) -> bool:
	if item is Weapon:
		return PlayerResources.playerInfo.stats.equippedWeapon == item
	if item is Armor:
		return PlayerResources.playerInfo.stats.equippedArmor == item
	return false

func trash_item(inventorySlot: InventorySlot):
	inventorySlot.count -= 1
	if inventorySlot.count <= 0:
		inventorySlots.erase(inventorySlot)

func get_sorted_slots() -> Array[InventorySlot]:
	var slots: Array[InventorySlot] = []
	slots.append_array(inventorySlots)
	slots.sort_custom(sort_by_equipped)
	return slots

func sort_by_equipped(a: InventorySlot, b: InventorySlot) -> bool:
	var aEquipped: bool = PlayerResources.playerInfo.stats.equippedArmor == a.item \
			or PlayerResources.playerInfo.stats.equippedWeapon == a.item
	var bEquipped: bool = PlayerResources.playerInfo.stats.equippedArmor == b.item \
			or PlayerResources.playerInfo.stats.equippedWeapon == b.item
	if aEquipped and not bEquipped:
		return true
	if bEquipped and not aEquipped:
		return false	
	return a.item.itemName.naturalnocasecmp_to(b.item.itemName) < 0 # compare names (including natural number comparisons)
	

func load_data(save_path):
	if ResourceLoader.exists(save_path + save_name):
		return load(save_path + save_name)
	return null

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_name)
	if err != 0:
		printerr("Inventory ResourceSaver error: " + err)
