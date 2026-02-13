extends Node

var saved_scripts: Array
var save_exists_file: String = "playerinfo.tres" # this file should always exist if a save game exists
var battle_file = "battle.tres" # this file should exist if the game was saved in battle
var battle_node_path = '/root/Battle' # this node should exist in the saved scripts if the Battle scene is loaded

var subdirs: Array[String] = ["npcs/", "enemies/", "minions/", "sharedshops/", ""] # last one is root save folder

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().set_auto_accept_quit(false) # handle quit requests manually
	fetch_saved_scripts()
	
# handle quit requests: save game before quitting
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if get_node_or_null("/root/MainMenu") == null:
			if PlayerFinder.player == null or not PlayerFinder.player.inCutscene:
				save_data() # if not in the main menu or in a cutscene, save the game!
		SettingsHandler.save_data() # save settings
		get_tree().quit() # then quit

func get_save_file_location(saveFolder: String) -> String:
	return 'user://' + saveFolder + '/'

func fetch_saved_scripts():
	saved_scripts = ["PlayerResources"] # singletons to be saved
	for idx in range(len(saved_scripts)):
		saved_scripts[idx] = "/root/" + saved_scripts[idx]
	
	var persist_nodes = get_tree().get_nodes_in_group("Persist") # all objects in the group to be saved (persisted)
	for node in persist_nodes:
		saved_scripts.append("/" + node.get_path().get_concatenated_names().c_escape())

func save_data(saveFolder: String = 'save') -> bool:
	# first save to the auto-save file
	var saveFileLocation: String = get_save_file_location('save')
	create_save_subdirs(saveFileLocation)
	fetch_saved_scripts()
	for script_path in saved_scripts:
		#print(script_path)
		var scr = get_node_or_null(NodePath(script_path))
		if scr != null and scr.has_method("save_data"):
			var err = scr.call("save_data", saveFileLocation)
			if err is int and err != 0:
				printerr('SaveHandler save_data error on ', script_path, ': error ', err)
				return false
		else:
			printerr('WARNING: No save_data function for ', script_path)
	if not (battle_node_path in saved_scripts) and FileAccess.file_exists(saveFileLocation + battle_file):
		var err = DirAccess.remove_absolute(saveFileLocation + battle_file)
		if err != 0:
			printerr('SaveHandler save_data error on removing Battle file after no longer needed: error' , err)
	# then if not only saving to the auto-save file, copy over the auto-save to the destination
	if saveFolder != 'save':
		var success = copy_save('save', saveFolder)
		if not success:
			printerr('SaveHandler save_data error on copying auto-save to ', saveFolder)
			return false
	return true

func load_data(saveFolder: String = 'save'):
	if saveFolder != 'save':
		var success: bool = copy_save(saveFolder, 'save')
		if not success:
			printerr('Error clearing out auto-save to load ', saveFolder)
			#return
	var saveFileLocation: String = get_save_file_location('save')
	create_save_subdirs(saveFileLocation)
	SaveMigrationTools.migrate_save_contents('save')
	fetch_saved_scripts()
	for script_path in saved_scripts:
		var scr = get_node_or_null(NodePath(script_path))
		if scr != null and scr.has_method("load_data"):
			scr.call("load_data", saveFileLocation)

func new_game(characterName: String, saveFolder: String = 'save'):
	var saveFileLocation: String = get_save_file_location(saveFolder)
	fetch_saved_scripts()
	for subdir in subdirs: # for each save subdirectory
		if DirAccess.dir_exists_absolute(saveFileLocation + subdir):
			var files = DirAccess.get_files_at(saveFileLocation + subdir)
			for filepath in files: # remove all files inside the subdir
				DirAccess.remove_absolute(saveFileLocation + subdir + filepath)
			var err = DirAccess.remove_absolute(saveFileLocation + subdir) # then remove the subdir itself
			if err > 0:
				printerr("Remove save subdir ", subdir, " error ", err)
	
	create_save_subdirs(saveFileLocation)
	for script_path in saved_scripts:
		var scr = get_node_or_null(NodePath(script_path))
		if scr != null and scr.has_method("new_game"):
			scr.call("new_game", saveFileLocation)
		if scr != null and scr.has_method("name_player"):
			scr.call("name_player", saveFileLocation, characterName)
	
func save_file_exists(saveFolder: String = 'save'):
	var saveFileLocation: String = get_save_file_location(saveFolder)
	return FileAccess.file_exists(saveFileLocation + save_exists_file)

func get_save_player_info(saveFolder: String = 'save') -> PlayerInfo:
	var saveFileLocation: String = get_save_file_location(saveFolder)
	if not save_file_exists(saveFolder):
		return null
	
	var playerInfo: PlayerInfo = ResourceLoader.load(saveFileLocation + save_exists_file, '', ResourceLoader.CACHE_MODE_IGNORE)
	return playerInfo

func is_save_in_battle(saveFolder: String = 'save'):
	var saveFileLocation: String = get_save_file_location(saveFolder)
	return FileAccess.file_exists(saveFileLocation + battle_file)

func create_save_subdirs(saveFileLocation: String):
	if not DirAccess.dir_exists_absolute(saveFileLocation):
		var err = DirAccess.make_dir_absolute(saveFileLocation)
		if err > 0:
			printerr("DirAccess create root save dir error ", err)
	
	for subdir in subdirs:
		if not DirAccess.dir_exists_absolute(saveFileLocation + subdir):
			var err = DirAccess.make_dir_absolute(saveFileLocation + subdir)
			if err > 0:
				printerr("DirAccess create dir ", subdir, " error ", err)

func copy_save(fromFolder: String, toFolder: String) -> bool:
	if not save_file_exists(fromFolder):
		printerr('Copy save file ', fromFolder, ' does not exist')
		return false
	
	var fromSaveFileLocation: String = get_save_file_location(fromFolder).trim_suffix('/')
	var toSaveFileLocation: String = get_save_file_location(toFolder).trim_suffix('/')
	# clear out save file destination first
	var err = 0
	if save_file_exists(toFolder):
		err = delete_directory_recursive(toSaveFileLocation)
	if err != 0:
		printerr('DirAccess delete dir for copy ', toFolder, ' error ', err)
		return false
	err = copy_directory_recursive(fromSaveFileLocation, toSaveFileLocation)
	if err != 0:
		printerr('DirAccess copy dir ', fromFolder, ' to ', toFolder, ' error ', err)
	return err == 0

# Credit: https://www.reddit.com/r/godot/comments/qtre01/i_want_to_drop_a_folder_onto_godot_and_open_it_to/
func copy_directory_recursive(p_from: String, p_to: String) -> int:
	var directory = DirAccess.open(p_from)
	if not DirAccess.dir_exists_absolute(p_to):
		DirAccess.make_dir_recursive_absolute(p_to)
	if directory != null:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != '' and file_name != '.' and file_name != '..':
			var err = 0
			if directory.current_is_dir():
				err = copy_directory_recursive(p_from + '/' + file_name, p_to + '/' + file_name)
			else:
				err = directory.copy(p_from + '/' + file_name, p_to + '/' + file_name)
			if err != 0:
				printerr('DirAccess error in copy_directory_recursive ', file_name, \
						', from ', p_from, ' to ', p_to, ', error ', err)
				return err
			file_name = directory.get_next()
		directory.list_dir_end()
		return 0
	else:
		printerr('Error copying ', p_from, ' to ', p_to)
		return -1

func delete_save(saveFolder: String) -> bool:
	if not save_file_exists(saveFolder):
		printerr('Delete save file ', saveFolder, ' does not exist')
		return false
	
	var saveFileLocation: String = get_save_file_location(saveFolder).trim_suffix('/')
	var err = delete_directory_recursive(saveFileLocation)
	if err != 0:
		printerr('DirAccess delete dir ', saveFileLocation, ' error ', err)
	return err == 0

func delete_directory_recursive(path: String) -> int:
	var directory = DirAccess.open(path)
	if directory != null:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != '' and file_name != '.' and file_name != '..':
			var err = 0
			if directory.current_is_dir():
				err = delete_directory_recursive(path + '/' + file_name)
			else:
				err = directory.remove(path + '/' + file_name)
			if err != 0:
				printerr('DirAccess error in delete_directory_recursive ', file_name, \
						', at path ', path, ', error ', err)
				return err
			file_name = directory.get_next()
		var pathErr = directory.remove(path)
		if pathErr != 0:
			printerr('DirAccess error in delete_directory_recursive at path ', path, ', error ', pathErr)
		directory.list_dir_end()
		return pathErr
	else:
		printerr('Error deleting ', path)
		return -1

func create_zip_of_save_file(saveFolder: String, zipPath: String) -> bool:
	if not save_file_exists(saveFolder):
		printerr('Zipping save file: ', saveFolder, ' does not exist')
		return false
	
	var writer := ZIPPacker.new()
	var err := writer.open(zipPath)
	if err != OK:
		printerr('Could not start writing ZIP file targeted at ', zipPath, ': Error ', err, ' (', error_string(err), ')')
		return false
	
	var saveFileLocation: String = get_save_file_location(saveFolder).trim_suffix('/')
	var success: bool = _write_save_zip_recursive_helper(saveFileLocation, '/', writer)
	err = writer.close()
	return success

func _write_save_zip_recursive_helper(saveFileLocation: String, path: String, writer: ZIPPacker) -> bool:
	var savePath: String = saveFileLocation + path
	var files: PackedStringArray = DirAccess.get_files_at(savePath)
	for filename: String in files:
		# just in case there's a ".remap" in the path that's not at the end (although this should never be the case):
		# get everything except the LAST file extension present
		var resourceFilename: String = filename.get_basename()
			# if it doesn't have ".tres" at the end (only if being played in the editor): add it
		if not resourceFilename.ends_with('.tres'):
			resourceFilename += '.tres'
		var file := FileAccess.open(savePath + resourceFilename, FileAccess.READ)
		if file == null:
			printerr('Could not open save file for ', savePath + resourceFilename, ': Error ', FileAccess.get_open_error(), ' (', error_string(FileAccess.get_open_error()), ')')
			return false
		var fileContents: String = file.get_as_text()
		var err := writer.start_file(path + resourceFilename)
		if err != OK:
			printerr('Could not start file in zip for ', path, ': Error ', err, ' (', error_string(err), ')')
			return false
		err = writer.write_file(fileContents.to_utf8_buffer())
		if err != OK:
			printerr('Could not write file into zip for ', path, ': Error ', err, ' (', error_string(err), ')')
			return false
		err = writer.close_file()
		if err != OK:
			printerr('Could not close file in zip for ', path, ': Error ', DirAccess.get_open_error(), ' (', error_string(err), ')')
			return false
	var directories: PackedStringArray = DirAccess.get_directories_at(savePath)
	for dir: String in directories:
		var success := _write_save_zip_recursive_helper(saveFileLocation, path + '/' + dir + '/', writer)
		if not success:
			return false
	return true

func import_zip_of_save_file(saveFolder: String, zipPath: String) -> bool:
	var reader := ZIPReader.new()
	var err := reader.open(zipPath)
	if err != OK:
		printerr('Could not start reading ZIP file at ', zipPath, ': Error ', err, ' (', error_string(err), ')')
		return false
	
	var saveFileLocation: String = get_save_file_location(saveFolder).trim_suffix('/')
	if save_file_exists(saveFolder):
		var success := delete_save(saveFolder)
		if not success:
			printerr('Import failed: Deleting save ', saveFolder, 'failed')
			return false
	err = DirAccess.make_dir_recursive_absolute(saveFileLocation)
	if err != OK:
		printerr('Could not create new save directory at ', saveFileLocation, ': Error ', err, ' (', error_string(err), ')')
		return false
	
	var saveDir := DirAccess.open(saveFileLocation)
	if saveDir == null:
		printerr('Could not start reading ZIP file at ', zipPath, ': Error ', DirAccess.get_open_error(), ' (', error_string(DirAccess.get_open_error()), ')')
		return false
	
	## From the Godot docs for ZIPReader class
	var files := reader.get_files()
	for filepath: String in files:
		if filepath.ends_with('/'):
			err = saveDir.make_dir_recursive(filepath)
			if err != OK:
				printerr('Could not create new save subdirectory at ', filepath, ' for ', saveFolder, ': Error ', err, ' (', error_string(err), ')')
				return false
			continue
		
		err = saveDir.make_dir_recursive(saveDir.get_current_dir().path_join(filepath).get_base_dir())
		if err != OK:
			printerr('Could not create new save subdirectory at ', saveDir.get_current_dir().path_join(filepath).get_base_dir(), ' for ', saveFolder, ': Error ', err, ' (', error_string(err), ')')
			return false
		var file := FileAccess.open(saveDir.get_current_dir().path_join(filepath), FileAccess.WRITE)
		if file == null:
			printerr('Could not start writing save file at ', saveDir.get_current_dir().path_join(filepath), ': Error ', FileAccess.get_open_error(), ' (', error_string(FileAccess.get_open_error()), ')')
			return false
		
		var buffer := reader.read_file(filepath)
		var storeBufferSuccess: bool = file.store_buffer(buffer)
		if not storeBufferSuccess:
			printerr('Writing file ', saveDir.get_current_dir().path_join(filepath).get_base_dir(), ' with contents from zip ', filepath, ' failed')
			return false
	
	return true
