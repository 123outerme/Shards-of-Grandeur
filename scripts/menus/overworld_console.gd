extends Node2D
class_name OverworldConsole

signal console_closed

@onready var consoleOutput: RichTextLabel = get_node('Panel/ConsoleOutput')
@onready var lineEdit: LineEdit = get_node('Panel/LineEdit')

@onready var virtualKeyboard: VirtualKeyboard = get_node('Panel/VirtualKeyboard')

@onready var logsPanel: GameLogsPanel = get_node('Panel/LogsPanel')
@onready var backButton: Button = get_node('Panel/LogsPanel/BackButton')

const HELP_COMMAND_LIST: Array[String] = [
	'help: Prints this message.',
	'exit / quit / q: Exits the console and returns to the game',
	'clear: Clear the console output',
	'giveitem <item name>: Gives the player 1x the specified item (not case sensitive)',
	'giveitems <count> <item name>: Gives the player the specified amount of the specified item (not case sensitive)',
	'removeitem <item name>: Removes 1x of the specified item from the player\'s inventory, even if it can\'t be trashed',
	'removeitems <count> <item name>: Removes at most the specified amount of the specified item from the player\'s inventory, even if it can\'t be trashed',
	'givegold <amount>: Gives the player the specified amount of gold',
	'givexp <amount>: Gives the player the specified amount of Exp',
	'setlevel <level>: Sets the player\'s level to the given amount, resetting stat points if it would be a lv decrease',
	'puzzle <set|clear> <puzzle ID>: Sets or clears the specified puzzle\'s solved status',
	'cutscene <set|clear> <cutscene ID>: Sets or clears the specified cutscene\'s seen status',
	'dialogue <set|clear> <NPC ID>#<dialogue ID>: Sets or clears the specified NPC\'s dialogue\'s status',
	'specialbattle <set|clear> <static encounter ID>: Sets or clears the specified static encounter\'s completed status',
	'setact <X>: Sets the current story Act to the specified number',
	'grounditem <set|clear> <GroundItem ID>: Sets or clears the specified GroundItem\'s picked-up status',
	'tp <map name>: Teleports to the specified map',
	'extp <x> <y> <mapname>: Teleports to the specified position and the specified map',
	'position <x> <y>: Moves the player to the specified position',
	'noclip <true|false>: enable/disable noclip',
	'logs [logfile]: show the Godot logs in a panel',
	'listlogs: prints the list of log files in the user://logs directory',
	'experimental <true|false>: enable/disable experimental features'
]

const MAX_CONSOLE_LINES = 50
const MAX_COMMAND_HISTORY = 20
var nextConsoleLine: int = 0
var consoleOutputLines: Array[String] = []
var lastCommands: Array[String] = []
var commandHistoryIdx: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	SettingsHandler.settings_changed.connect(_settings_changed)
	_settings_changed.call_deferred()
	clear_console()

func load_overworld_console():
	visible = true
	lineEdit.grab_focus()

func hide_overworld_console():
	visible = false
	console_closed.emit()

func _on_line_edit_text_submitted(new_text: String):
	if new_text != '':
		print_to_console('> ' + new_text)
		lastCommands.push_front(new_text)
		while len(lastCommands) >= MAX_COMMAND_HISTORY:
			lastCommands.remove_at(len(lastCommands) - 1)
		commandHistoryIdx = 0
		parse_command(new_text)
		lineEdit.text = ''

func parse_command(command: String):
	var cmdLower: String = command.to_lower()
	if cmdLower == 'clear':
		clear_console()
		return
	if cmdLower == 'exit' || cmdLower == 'quit' || cmdLower == 'q':
		hide_overworld_console()
		return
	if cmdLower == 'help':
		print_help()
		return
	if cmdLower.begins_with('giveitem '):
		var itemName: String = command.substr(9)
		give_item(itemName)
		return
	if cmdLower.begins_with('giveitems '):
		var pieces: PackedStringArray = command.split(' ')
		var itemName: String = ''
		for idx: int in range(2, len(pieces)):
			itemName += pieces[idx]
			if idx < len(pieces) - 1:
				itemName += ' '
		give_item(itemName, pieces[1].to_int())
		return
	if cmdLower.begins_with('removeitem '):
		var itemName: String = command.substr(11)
		remove_item(itemName)
		return
	if cmdLower.begins_with('removeitems '):
		var pieces: PackedStringArray = command.split(' ')
		var itemName: String = ''
		for idx: int in range(2, len(pieces)):
			itemName += pieces[idx]
			if idx < len(pieces) - 1:
				itemName += ' '
		remove_item(itemName, pieces[1].to_int())
		return
	if cmdLower.begins_with('givegold '):
		var amount: int = command.substr(9).to_int()
		give_gold(amount)
		return
	if cmdLower.begins_with('setlevel '):
		var lv: int = command.substr(9).to_int()
		set_level(lv)
		return
	if cmdLower.begins_with('givexp '):
		var xp: int = command.substr(7).to_int()
		give_exp(xp)
		return
	if cmdLower.begins_with('puzzle '):
		# "puzzle set puzzle_name" or "puzzle clear puzzle_name"
		var pieces: PackedStringArray = command.split(' ')
		if len(pieces) < 3:
			print_to_console('Syntax error. Command is: puzzle <set|clear> <puzzle name>')
			return
		if pieces[1].to_lower() != 'set' and pieces[1].to_lower() != 'clear':
			print_to_console('Syntax error: First argument should be either "set" or "clear". Command is: puzzle <set|clear> <puzzle name>.')
			return
		var puzzleName: String = ''
		for idx: int in range(2, len(pieces)):
			puzzleName += pieces[idx]
		puzzle_update(puzzleName, pieces[1] == 'clear')
		return
	if cmdLower.begins_with('cutscene '):
		# "cutscene set cutscene_id" or "cutscene clear cutscene_id"
		var pieces: PackedStringArray = command.split(' ')
		if len(pieces) < 3:
			print_to_console('Syntax error. Command is: cutscene <set|clear> <cutscene ID>')
			return
		if pieces[1].to_lower() != 'set' and pieces[1].to_lower() != 'clear':
			print_to_console('Syntax error: First argument should be either "set" or "clear". Command is: cutscene <set|clear> <cutscene ID>.')
			return
		var cutsceneId: String = ''
		for idx: int in range(2, len(pieces)):
			cutsceneId += pieces[idx]
		cutscene_update(cutsceneId, pieces[1] == 'clear')
		return
	if cmdLower.begins_with('dialogue '):
		# "dialogue set npc#dialogue_id" or "puzzle clear npc#dialogue_id"
		var pieces: PackedStringArray = command.split(' ')
		if len(pieces) < 3:
			print_to_console('Syntax error. Command is: puzzle dialogue <set|clear> <NPC ID>#<dialogue ID>')
			return
		if pieces[1].to_lower() != 'set' and pieces[1].to_lower() != 'clear':
			print_to_console('Syntax error: First argument should be either "set" or "clear". Command is: dialogue <set|clear> <NPC ID>#<dialogue ID>.')
			return
		var dialogueId: String = ''
		for idx: int in range(2, len(pieces)):
			dialogueId += pieces[idx]
		if not dialogueId.contains('#'):
			print_to_console('Syntax error: Second argument missing "#" separator. Command is: dialogue <set|clear> <NPC ID>#<dialogue ID>.')
		else:
			var npcSaveName: String = dialogueId.split('#')[0]
			var dialogue: String = dialogueId.split('#')[1]
			dialogue_update(npcSaveName, dialogue, pieces[1] == 'clear')
		return
	if cmdLower.begins_with('setact '):
		var pieces: PackedStringArray = command.split(' ')
		if len(pieces) != 2 or not pieces[1].is_valid_int():
			print_to_console('Syntax error. Command is: setact <X>')
			return
		PlayerResources.questInventory.currentAct = pieces[1].to_int()
		print_to_console('Story Act set to ' + pieces[1] + '.')
		return
	if cmdLower.begins_with('specialbattle '):
		# "specialbattle set encounter_id" or "specialbattle clear encounter_id"
		var pieces: PackedStringArray = command.split(' ')
		if len(pieces) < 3:
			print_to_console('Syntax error. Command is: specialbattle <set|clear> <static encounter ID>')
			return
		if pieces[1].to_lower() != 'set' and pieces[1].to_lower() != 'clear':
			print_to_console('Syntax error: First argument should be either "set" or "clear". Command is: specialbattle <set|clear> <static encounter ID>.')
			return
		var encounterId: String = ''
		for idx: int in range(2, len(pieces)):
			encounterId += pieces[idx]
		special_battle_update(encounterId, pieces[1] == 'clear')
		return
	if cmdLower.begins_with('grounditem '):
		# "grounditem set grounditem_id" or "specialbattle clear grounditem_id"
		var pieces: PackedStringArray = command.split(' ')
		if len(pieces) < 3:
			print_to_console('Syntax error. Command is: grounditem <set|clear> <GroundItem ID>')
			return
		if pieces[1].to_lower() != 'set' and pieces[1].to_lower() != 'clear':
			print_to_console('Syntax error: First argument should be either "set" or "clear". Command is: grounditem <set|clear> <GroundItem ID>.')
			return
		var groundItemId: String = ''
		for idx: int in range(2, len(pieces)):
			groundItemId += pieces[idx]
		ground_item_update(groundItemId, pieces[1] == 'clear')
		return
	if cmdLower.begins_with('tp '):
		var mapName: String = command.substr(3)
		if mapName != '':
			teleport_to(mapName)
		else:
			print_to_console('Syntax error: Provide a map name. Command is: tp <mapname>')
		return
	if cmdLower.begins_with('extp '):
		var args: PackedStringArray = command.split(' ')
		if len(args) != 4:
			print_to_console('Syntax error: Two numerical arguments and one string argument are required. Command is: extp <x> <y> <mapname>.')
		else:
			var mapName: String = args[3]
			if mapName != '':
				ex_teleport_to(Vector2(args[1].to_float(), args[2].to_float()), mapName)
			else:
				print_to_console('Syntax error: Provide a map name. Command is: extp <x> <y> <mapname>')
		return
	if cmdLower.begins_with('position '):
		var args: PackedStringArray = command.split(' ')
		if len(args) != 3:
			print_to_console('Syntax error: Two numerical arguments are required. Command is: position <x> <y>.')
		else:
			move_player_to(Vector2(args[1].to_float(), args[2].to_float()))
		return
	if cmdLower.begins_with('noclip'):
		var args: PackedStringArray = command.split(' ')
		if len(args) == 2 and (args[1].to_lower() == 'true' or args[1].to_lower() == 'false'):
			set_noclip(args[1].to_lower() == 'true')
			print_to_console('Noclip was set ' + args[1].to_lower() + '.')
		else:
			print_to_console('Syntax error: true or false argument required. Command is: noclip <true|false>.')
		return
	if cmdLower.begins_with('logs'):
		var args: PackedStringArray = command.split(' ')
		if len(args) < 2:
			show_game_logs()
		elif len(args) == 2:
			show_game_logs(args[1])
		else:
			print_to_console('Syntax error: too many arguments. Command is: logs [logfile]')
		return
	if cmdLower == 'listlogs':
		list_log_files()
		return
	if cmdLower.begins_with('experimental '):
		var args: PackedStringArray = command.split(' ')
		if len(args) != 2 or (args[1].to_lower() != 'true' and args[1].to_lower() != 'false'):
			print_to_console('Syntax error: true or false argument required. Command is: experimental <true|false>.')
			return
		SettingsHandler.gameSettings.enableExperimentalFeatures = args[1].to_lower() == 'true'
		print_to_console('Experimental features were set ' + args[1].to_lower() + '.')
		return
	# if none of the above match, the command is not recognized.
	print_to_console('Command not recognized.')

func print_to_console(text: String):
	var rebuildConsole: bool = false
	if nextConsoleLine >= MAX_CONSOLE_LINES:
		nextConsoleLine = MAX_CONSOLE_LINES - 1
		consoleOutputLines.pop_front()
		rebuildConsole = true
	
	consoleOutputLines.insert(nextConsoleLine, text)
	nextConsoleLine += 1
	
	if rebuildConsole:
		consoleOutput.text = ''
		for line: String in consoleOutputLines:
			consoleOutput.text += line + '\n'
	else:
		consoleOutput.text += text + '\n'
	
	var textScrollbar: VScrollBar = consoleOutput.get_v_scroll_bar()
	if textScrollbar != null:
		await get_tree().process_frame
		textScrollbar.value = textScrollbar.max_value

func update_console_size(halfSize: bool):
	# 560px height
	var sizeMultiplier: float = 0.5 if halfSize else 1.0
	var newHeight: float = 560 * sizeMultiplier
	
	consoleOutput.position.y += consoleOutput.size.y - newHeight
	consoleOutput.size.y = newHeight

func clear_console():
	consoleOutputLines = []
	nextConsoleLine = 0
	consoleOutput.text = ''

func print_help():
	print_to_console('Command list:')
	for command: String in HELP_COMMAND_LIST:
		print_to_console(command)

func give_item(itemName: String, count: int = 1):
	var itemsDir: String = 'res://gamedata/items/'
	var typeDirs: PackedStringArray = DirAccess.get_directories_at(itemsDir)
	for type: String in typeDirs:
		var items: PackedStringArray = DirAccess.get_files_at(itemsDir + type)
		for itemFile: String in items:
			var item: Item = load(itemsDir + type + '/' + itemFile) as Item
			if item != null:
				if item.itemName.to_lower() == itemName.to_lower():
					var countGave: int = 0
					for i: int in range(count):
						var gave: bool = PlayerResources.inventory.add_item(item)
						if gave:
							countGave += 1
					if countGave == count:
						print_to_console('Gave player ' + String.num_int64(count) + 'x "' + item.itemName + '".')
					else:
						print_to_console('Only gave player ' + String.num_int64(countGave) + 'x "' + item.itemName + '". That item slot could be full.')
					return
	print_to_console('Could not find item "' + itemName + '".')

func remove_item(itemName: String, count: int = 1):
	var inventorySlot: InventorySlot = null
	var inventorySlotIdx: int = -1
	for slotIdx: int in range(len(PlayerResources.inventory.inventorySlots)):
		var slot: InventorySlot = PlayerResources.inventory.inventorySlots[slotIdx]
		if slot.item.itemName == itemName:
			inventorySlot = slot
			inventorySlotIdx = slotIdx
			break
	
	if inventorySlot != null:
		inventorySlot.count -= count
		if inventorySlot.count <= 0:
			PlayerResources.inventory.inventorySlots.remove_at(inventorySlotIdx)
			print_to_console('Removed all of item "' + inventorySlot.item.itemName + '".')
		else:
			print_to_console('Removed ' + String.num_int64(count) + 'x of item "' + inventorySlot.item.itemName + '".')
		PlayerResources.story_requirements_updated.emit()
	else:
		print_to_console('Item "' + itemName + '" not found in player inventory.')

func give_gold(amount: int):
	PlayerResources.playerInfo.gold += amount
	print_to_console('Gave player ' + String.num_int64(amount) + ' gold.')

func set_level(lv: int):
	var lvDiff: int = lv - PlayerResources.playerInfo.combatant.stats.level
	if lvDiff > 0:
		PlayerResources.playerInfo.combatant.stats.level_up(lvDiff)
		PlayerResources.minions.level_up_minions(PlayerResources.playerInfo.combatant.stats.level)
		print_to_console('Increased player level to ' + String.num_int64(lv) + '.')
	elif lvDiff < 0:
		PlayerResources.playerInfo.combatant.stats.set_level(lv)
		print_to_console('Set player level to ' + String.num_int64(lv) + '. Allocated stat points were reset.')
	else:
		print_to_console('The player is already at level ' + String.num_int64(lv) + '. Nothing was done.')

func give_exp(xp: int):
	var lvDiff: int = PlayerResources.playerInfo.combatant.stats.add_exp(xp)
	if lvDiff > 0:
		PlayerResources.minions.level_up_minions(PlayerResources.playerInfo.combatant.stats.level)
		print_to_console('Added ' + String.num_int64(xp) + ' Exp and leveled up ' + String.num_int64(lvDiff) + ' level(s)!')
	else:
		print_to_console('Added ' + String.num_int64(xp) + ' Exp.')

func puzzle_update(puzzleName: String, clear: bool):
	if clear:
		var idx: int = PlayerResources.playerInfo.puzzlesSolved.find(puzzleName)
		if idx != -1:
			PlayerResources.playerInfo.puzzlesSolved.remove_at(idx)
			print_to_console('Cleared solved state on puzzle "' + puzzleName + '".')
			PlayerResources.story_requirements_updated.emit()
		else:
			print_to_console('Puzzle "' + puzzleName + '" was already not solved. No operation performed.')
	else:
		PlayerResources.playerInfo.set_puzzle_solved(puzzleName)
		print_to_console('Set puzzle "' + puzzleName + '" as solved.')
		PlayerResources.story_requirements_updated.emit()

func cutscene_update(cutsceneId: String, clear: bool):
	if clear:
		var idx: int = PlayerResources.playerInfo.cutscenesPlayed.find(cutsceneId)
		if idx != -1:
			PlayerResources.playerInfo.cutscenesPlayed.remove_at(idx)
			print_to_console('Cleared seen state on cutscene "' + cutsceneId + '".')
			PlayerResources.story_requirements_updated.emit()
		else:
			print_to_console('Cutscene "' + cutsceneId + '" was already not seen. No operation performed.')
	else:
		PlayerResources.playerInfo.set_cutscene_seen(cutsceneId)
		print_to_console('Set cutscene "' + cutsceneId + '" as seen.')
		PlayerResources.story_requirements_updated.emit()

func dialogue_update(npcSaveName: String, dialogueId: String, clear: bool):
	if clear:
		if PlayerResources.playerInfo.dialoguesSeen.has(npcSaveName):
			var idx: int = PlayerResources.playerInfo.dialoguesSeen[npcSaveName].find(dialogueId)
			if idx != -1:
				PlayerResources.playerInfo.dialoguesSeen[npcSaveName].remove_at(idx)
				print_to_console('Cleared seen state on dialogue "' + dialogueId + '" with NPC "' + npcSaveName + '".')
				PlayerResources.story_requirements_updated.emit()
			else:
				print_to_console('Dialogue "' + dialogueId + '" was already not seen with NPC "' + npcSaveName + '". No operation performed.')
		else:
			print_to_console('NPC' + npcSaveName + 'has not been encountered yet. No operation performed.')
	else:
		PlayerResources.playerInfo.set_dialogue_seen(npcSaveName, dialogueId)
		print_to_console('Set dialogue "' + dialogueId + '" from NPC "' + npcSaveName + '" as seen.')
		PlayerResources.story_requirements_updated.emit()

func special_battle_update(encounterId: String, clear: bool):
	if clear:
		var idx: int = PlayerResources.playerInfo.completedSpecialBattles.find(encounterId)
		if idx != -1:
			PlayerResources.playerInfo.completedSpecialBattles.remove_at(idx)
			print_to_console('Cleared completed state on static encounter "' + encounterId + '".')
			PlayerResources.story_requirements_updated.emit()
		else:
			print_to_console('Static encounter "' + encounterId + '" was already not seen. No operation performed.')
	else:
		PlayerResources.playerInfo.set_special_battle_completed(encounterId)
		print_to_console('Set static encounter "' + encounterId + '" as completed.')
		PlayerResources.story_requirements_updated.emit()

func ground_item_update(groundItemId: String, clear: bool):
	var idx: int = PlayerResources.playerInfo.pickedUpItems.find(groundItemId)
	if clear:
		if idx != -1:
			PlayerResources.playerInfo.pickedUpItems.remove_at(idx)
			print_to_console('Cleared acquired state on ground item "' + groundItemId + '".')
			PlayerResources.story_requirements_updated.emit()
		else:
			print_to_console('Ground item "' + groundItemId + '" was already not picked up. No operation performed.')
	else:
		if idx == -1:
			PlayerResources.playerInfo.pickedUpItems.append(groundItemId)
			print_to_console('Set ground item "' + groundItemId + '" as picked up.')
			PlayerResources.story_requirements_updated.emit()
		else:
			print_to_console('Ground item "' + groundItemId + '" was already picked up. No operation performed.')

func teleport_to(mapName: String):
	if MapLoader.get_world_location_for_name(mapName) != null:
		SceneLoader.mapLoader.entered_warp(mapName, PlayerFinder.player.position, PlayerFinder.player.position)
		print_to_console('Teleported to map "' + mapName + '".')
	else:
		print_to_console('The map "' + mapName + '" does not exist.')

func ex_teleport_to(pos: Vector2, mapName: String):
	if MapLoader.get_world_location_for_name(mapName) != null:
		SceneLoader.mapLoader.entered_warp(mapName, pos, PlayerFinder.player.position)
		print_to_console('Teleported to (' + String.num(pos.x) + ', ' + String.num(pos.y) + ') at map "' + mapName + '".')
	else:
		print_to_console('The map "' + mapName + '" does not exist.')

func move_player_to(pos: Vector2):
	PlayerFinder.player.position = pos
	print_to_console('Moved player to (' + String.num(pos.x) + ', ' + String.num(pos.y) + ').')

func set_noclip(enable: bool):
	if enable:
		PlayerFinder.player.disable_collision()
		print_to_console('Noclip enabled.')
	else:
		PlayerFinder.player.enable_collision()
		print_to_console('Noclip disabled.')

func show_game_logs(logFile: String = 'godot.log'):
	var success: bool = logsPanel.show_game_logs(logFile)
	if success:
		print_to_console('Game logs were opened.')
	else:
		print_to_console('Game logs could not be opened. FileAccess error code: ' + String.num_int64(FileAccess.get_open_error()))

func list_log_files():
	var dir: DirAccess = DirAccess.open('user://logs')
	if dir != null:
		var filenames: PackedStringArray = dir.get_files()
		for filename: String in filenames:
			print_to_console(filename)
	else:
		print_to_console('Game logs directory could not be opened. DirAccess error code: ' + String.num_int64(DirAccess.get_open_error()))

func _on_line_edit_gui_input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_UP:
			history_up()
		if event.keycode == KEY_DOWN:
			history_down()

func history_up():
	lineEdit.grab_focus()
	if commandHistoryIdx < len(lastCommands):
		lineEdit.text = lastCommands[commandHistoryIdx]
		commandHistoryIdx += 1

func history_down():
	lineEdit.grab_focus()
	if commandHistoryIdx > 0:
		commandHistoryIdx -= 1
		lineEdit.text = lastCommands[commandHistoryIdx]
	else:
		lineEdit.text = ''
		commandHistoryIdx = 0

func _on_logs_back_button_pressed() -> void:
	lineEdit.grab_focus()

func _settings_changed():
	virtualKeyboard.enabled = SettingsHandler.gameSettings.useVirtualKeyboard
	lineEdit.virtual_keyboard_enabled = not virtualKeyboard.enabled
	update_console_size(virtualKeyboard.enabled)
	if virtualKeyboard.visible and not virtualKeyboard.enabled:
		virtualKeyboard.visible = false

func _on_virtual_keyboard_key_pressed(character: String) -> void:
	lineEdit.text += character

func _on_virtual_keyboard_enter_pressed() -> void:
	_on_line_edit_text_submitted(lineEdit.text)

func _on_virtual_keyboard_backspace_pressed() -> void:
	lineEdit.text = lineEdit.text.substr(0, len(lineEdit.text) - 1)

func _on_virtual_keyboard_keyboard_hidden() -> void:
	hide_overworld_console()
