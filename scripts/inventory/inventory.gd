extends Resource
class_name Inventory

@export var inventorySlots: Array[InventorySlot]
@export var isPlayerInventory: bool = false

var save_name: String = "inventory.tres"

func _init(i_playerInv = false, i_slots: Array[InventorySlot] = []):
	inventorySlots = i_slots
	isPlayerInventory = i_playerInv

func add_slot(slot: InventorySlot) -> bool:
	if slot == null:
		return false
	var found: bool = false
	for existingSlot in inventorySlots:
		if existingSlot.item == slot.item:
			found = true # if there's a slot with this item, either it has capacity, or it doesn't,
			# either way we aren't creating a new slot
			if existingSlot.count < slot.item.maxCount or slot.item.maxCount == 0:
				if slot.count < 0:
					return true # if negative (infinite-size shop slot), don't do anything
				# combine stacks of this item, capping at max count for this item
				existingSlot.count = min(existingSlot.item.maxCount, existingSlot.count + slot.count)
				add_shard_minion_entry(existingSlot.item)
				var updatedQuests: bool = PlayerResources.questInventory.auto_update_quests()
				if not updatedQuests:
					PlayerResources.story_requirements_updated.emit()
				return true
	# if not found, add the slot as a new one
	if not found:
		inventorySlots.append(slot)
		add_shard_minion_entry(slot.item)
		var updatedQuests: bool = PlayerResources.questInventory.auto_update_quests()
		if not updatedQuests:
			PlayerResources.story_requirements_updated.emit()
		return true
	return false

func add_item(item: Item, count: int = 1) -> bool:
	if item == null:
		return false
	var found: bool = false
	# assumption: count is withing the range [1, item.maxCount]
	for slot in inventorySlots:
		if slot.item == item:
			found = true # if there's a slot with this item, either it has capacity, or it doesn't,
			# either way we aren't creating a new slot
			if slot.count + count <= slot.item.maxCount or slot.item.maxCount <= 0:
				if slot.count < 0:
					return true # if negative (infinite-size shop slot), don't do anything
				slot.count += count
				add_shard_minion_entry(item)
				var updatedQuests: bool = PlayerResources.questInventory.auto_update_quests()
				if not updatedQuests:
					PlayerResources.story_requirements_updated.emit()
				return true
	# if not found, add a new slot
	if not found:
		inventorySlots.append(InventorySlot.new(item, count))
		add_shard_minion_entry(item)
		var updatedQuests: bool = PlayerResources.questInventory.auto_update_quests()
		if not updatedQuests:
			PlayerResources.story_requirements_updated.emit()
		return true
	return false

func can_add_item(item: Item) -> bool:
	if item == null:
		return false
	var found: bool = false
	for slot in inventorySlots:
		if slot.item == item:
			found = true # if there's a slot with this item, either it has capacity, or it doesn't,
			# either way we aren't creating a new slot
			if slot.count < slot.item.maxCount or slot.item.maxCount <= 0:
				return true
	# if not found, add a new slot
	return not found

func has_item(item: Item) -> bool:
	for slot in inventorySlots:
		if slot.item == item:
			return true
	return false

func get_slot_for_item(item: Item) -> InventorySlot:
	for slot in inventorySlots:
		if slot.item == item:
			return slot
	return null

func add_shard_minion_entry(item: Item):
	if isPlayerInventory and item.itemType == Item.Type.SHARD:
		var shard: Shard = item as Shard
		if shard.combatantSaveName != '':
			PlayerResources.minions.get_minion(shard.combatantSaveName) # if it does not exist, this will create it
		
func use_item(item: Item, target: Combatant) -> bool:
	var last: bool = false
	item.use(target)
	for slot in inventorySlots:
		if slot.item == item and item.consumable:
			last = trash_item(slot) # remove one of the appropriate items
	return last

func use_item_from_slot(inventorySlot: InventorySlot, target: Combatant) -> bool:
	inventorySlot.item.use(target)
	return trash_item(inventorySlot)

func equip_item(inventorySlot: InventorySlot, equip: bool, contextStats: Stats = null):
	var item: Item = inventorySlot.item
	if contextStats == null:
		contextStats = PlayerResources.playerInfo.combatant.stats
	
	var minionEquipped: String = PlayerResources.minions.which_minion_equipped(item)
	if item is Weapon:
		if equip:
			contextStats.equippedWeapon = item
		else:
			if minionEquipped != '':
				contextStats = PlayerResources.minions.get_minion(minionEquipped).stats
			contextStats.equippedWeapon = null
	if item is Armor:
		if equip:
			contextStats.equippedArmor = item
		else:
			if minionEquipped != '':
				contextStats = PlayerResources.minions.get_minion(minionEquipped).stats
			contextStats.equippedArmor = null
	if item is Accessory:
		if equip:
			contextStats.equippedAccessory = item
		else:
			if minionEquipped != '':
				contextStats = PlayerResources.minions.get_minion(minionEquipped).stats
			contextStats.equippedAccessory = null


func is_equipped(item: Item) -> bool:
	if item is Weapon:
		return PlayerResources.playerInfo.combatant.stats.equippedWeapon == item or PlayerResources.minions.which_minion_equipped(item) != ''
	if item is Armor:
		return PlayerResources.playerInfo.combatant.stats.equippedArmor == item or PlayerResources.minions.which_minion_equipped(item) != ''
	if item is Accessory:
		return PlayerResources.playerInfo.combatant.stats.equippedAccessory == item or  PlayerResources.minions.which_minion_equipped(item) != ''
	return false

func is_slot_for_item_full(item: Item) -> bool:
	for slot in inventorySlots:
		if slot.item == item:
			return slot.count >= slot.item.maxCount
	return false

func count_of(itemType: Item.Type) -> int:
	var count = 0
	for slot in inventorySlots:
		if slot.item.itemType == itemType:
			count += 1
	return count

func get_shard_slot_for_minion(saveName: String) -> InventorySlot:
	for slot in inventorySlots:
		if slot.item is Shard:
			var shard = slot.item as Shard
			if shard.combatantSaveName == saveName:
				return slot
	return null

func trash_item(inventorySlot: InventorySlot, count: int = 1) -> bool:
	if inventorySlot.count < 0: # if negative (infinite), don't bother
		return false
	var lastInSlot: bool = false
	inventorySlot.count = max(0, inventorySlot.count - count)
	if inventorySlot.count <= 0:
		if isPlayerInventory:
			inventorySlots.erase(inventorySlot)
		lastInSlot = true
	if isPlayerInventory:
		var updatedQuests: bool = PlayerResources.questInventory.auto_update_quests()
		if not updatedQuests:
			PlayerResources.story_requirements_updated.emit()
	return lastInSlot

func trash_items_by_name(itemName: String, count: int = 1):
	for slot in inventorySlots:
		if slot.item.itemName == itemName:
			trash_item(slot, count)

func get_sorted_slots() -> Array[InventorySlot]:
	var slots: Array[InventorySlot] = []
	slots.append_array(inventorySlots)
	slots.sort_custom(sort_inventory)
	return slots

func sort_inventory(a: InventorySlot, b: InventorySlot) -> bool:
	#'''
	var aEquipped: bool = is_equipped(a.item)
	var bEquipped: bool = is_equipped(b.item)
	if aEquipped and not bEquipped:
		return true
	if bEquipped and not aEquipped:
		return false
	if (a.item.usable or a.item.battleUsable or a.item.equippable) and not (b.item.usable or b.item.battleUsable or b.item.equippable):
		return true
	if not (a.item.usable or a.item.battleUsable or a.item.equippable) and (b.item.usable or b.item.battleUsable or b.item.equippable):
		return false
	#'''
	return a.item.itemName.naturalnocasecmp_to(b.item.itemName) < 0 # compare names (including natural number comparisons)

func get_shard_slot_for_combatant(combatantSaveName: String) -> InventorySlot:
	for slot in inventorySlots:
		if slot.item is Shard:
			var shard: Shard = slot.item as Shard
			if shard.combatantSaveName == combatantSaveName:
				return slot
	return null

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_name):
		data = ResourceLoader.load(save_path + save_name, '', ResourceLoader.CACHE_MODE_IGNORE)
		if data != null:
			return data #.duplicate(true)
	return data

func save_data(save_path, data) -> int:
	var err = ResourceSaver.save(data, save_path + save_name)
	if err != 0:
		printerr("Inventory ResourceSaver error: ", err)
	return err
