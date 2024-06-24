extends Node2D
class_name OverworldConsole

signal console_closed

@onready var consoleOutput: RichTextLabel = get_node('Panel/ConsoleOutput')
@onready var lineEdit: LineEdit = get_node('Panel/LineEdit')

const HELP_COMMAND_LIST: Array[String] = [
	'help: Prints this message.',
	'exit / quit / q: Exits the console and returns to the game',
	'echo: The console responds with an "Echo!"',
	'clear: Clear the console output',
	'giveitem <item name>: Gives the player 1x the specified item (not case sensitive)',
	'removeitem <item name>: Removes 1x of the specified item from the player\'s inventory, even if it can\'t be trashed',
	'givegold <amount>: Gives the player the specified amount of gold',
	'givexp <amount>: Gives the player the specified amount of Exp',
	'setlevel <level>: Sets the player\'s level to the given amount, resetting stat points if it would be a lv decrease',
	'puzzle <set|clear> <puzzle name>: Sets or clears the specified puzzle\'s solved status',
	'tp <map name>: Teleports to the specified map',
	'position <x> <y>: Moves the player to the specified position'
]

const MAX_CONSOLE_LINES = 20
const MAX_COMMAND_HISTORY = 20
var consoleOutputLines: Array[String] = []
var nextConsoleLine = 0
var lastCommands: Array[String] = []
var commandHistoryIdx: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
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
	if command.to_lower() == 'clear':
		clear_console()
		return
	if command.to_lower() == 'exit' || command.to_lower() == 'quit' || command.to_lower() == 'q':
		hide_overworld_console()
		return
	if command.to_lower() == 'echo':
		print_to_console('Echo!')
		return
	if command.to_lower() == 'help':
		print_help()
		return
	if command.to_lower().begins_with('giveitem '):
		var itemName: String = command.substr(9)
		give_item(itemName)
		return
	if command.to_lower().begins_with('removeitem '):
		var itemName: String = command.substr(11)
		remove_item(itemName)
		return
	if command.to_lower().begins_with('givegold '):
		var amount: int = command.substr(9).to_int()
		give_gold(amount)
		return
	if command.to_lower().begins_with('setlevel '):
		var lv: int = command.substr(9).to_int()
		set_level(lv)
		return
	if command.to_lower().begins_with('givexp '):
		var xp: int = command.substr(7).to_int()
		give_exp(xp)
		return
	if command.to_lower().begins_with('puzzle '):
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
	if command.to_lower().begins_with('tp '):
		var mapName: String = command.substr(3)
		teleport_to(mapName)
		return
	if command.to_lower().begins_with('position '):
		var args: PackedStringArray = command.split(' ')
		if len(args) != 3:
			print_to_console('Syntax error: Two numerical arguments are required. Command is: position <x> <y>.')
		else:
			move_player_to(Vector2(args[1].to_float(), args[2].to_float()))
		return
	# if none of the above match, the command is not recognized.
	print_to_console('Command not recognized.')

func print_to_console(text: String):
	var rebuildConsole: bool = false
	if nextConsoleLine > MAX_CONSOLE_LINES:
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

func clear_console():
	consoleOutputLines = []
	nextConsoleLine = 0
	consoleOutput.text = ''

func print_help():
	print_to_console('Command list:')
	for command: String in HELP_COMMAND_LIST:
		print_to_console(command)

func give_item(itemName: String):
	var itemsDir: String = 'res://gamedata/items/'
	var typeDirs: PackedStringArray = DirAccess.get_directories_at(itemsDir)
	for type: String in typeDirs:
		var items: PackedStringArray = DirAccess.get_files_at(itemsDir + type)
		for itemFile: String in items:
			var item: Item = load(itemsDir + type + '/' + itemFile) as Item
			if item != null:
				if item.itemName.to_lower() == itemName.to_lower():
					var gave: bool = PlayerResources.inventory.add_item(item)
					if gave:
						print_to_console('Gave player 1x "' + item.itemName + '".')
					else:
						print_to_console('Could not give player 1x "' + item.itemName + '". That item slot could be full.')
					return
	print_to_console('Could not find item "' + itemName + '".')

func remove_item(itemName: String):
	var inventorySlot: InventorySlot = null
	var inventorySlotIdx: int = -1
	for slotIdx: int in range(len(PlayerResources.inventory.inventorySlots)):
		var slot: InventorySlot = PlayerResources.inventory.inventorySlots[slotIdx]
		if slot.item.itemName == itemName:
			inventorySlot = slot
			inventorySlotIdx = slotIdx
			break
	
	if inventorySlot != null:
		inventorySlot.count -= 1
		if inventorySlot.count <= 0:
			PlayerResources.inventory.inventorySlots.remove_at(inventorySlotIdx)
			print_to_console('Removed all of item "' + inventorySlot.item.itemName + '".')
		else:
			print_to_console('Removed 1x of item "' + inventorySlot.item.itemName + '".')
		PlayerResources.story_requirements_updated.emit()
	else:
		print_to_console('Item "' + itemName + '" not found in player inventory.')

func give_gold(amount: int):
	PlayerResources.playerInfo.gold += amount
	print_to_console('Gave player ' + String.num(amount) + ' gold.')

func set_level(lv: int):
	var lvDiff: int = lv - PlayerResources.playerInfo.combatant.stats.level
	if lvDiff > 0:
		PlayerResources.playerInfo.combatant.stats.level_up(lvDiff)
		print_to_console('Increased player level to ' + String.num(lv) + '.')
	elif lvDiff < 0:
		PlayerResources.playerInfo.combatant.stats.set_level(lv)
		print_to_console('Set player level to ' + String.num(lv) + '. Allocated stat points were reset.')
	else:
		print_to_console('The player is already at level ' + String.num(lv) + '. Nothing was done.')

func give_exp(xp: int):
	var lvDiff: int = PlayerResources.playerInfo.combatant.stats.add_exp(xp)
	if lvDiff > 0:
		print_to_console('Added ' + String.num(xp) + ' Exp and leveled up ' + String.num(lvDiff) + ' level(s)!')
	else:
		print_to_console('Added ' + String.num(xp) + ' Exp.')

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

func teleport_to(mapName: String):
	if MapLoader.get_world_location_for_name(mapName) != null:
		SceneLoader.mapLoader.entered_warp(mapName, PlayerFinder.player.position, PlayerFinder.player.position)
		print_to_console('Teleported to map "' + mapName + '".')
	else:
		print_to_console('The map "' + mapName + '" does not exist.')

func move_player_to(pos: Vector2):
	PlayerFinder.player.position = pos
	print_to_console('Moved player to (' + String.num(pos.x) + ', ' + String.num(pos.y) + ').')

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
