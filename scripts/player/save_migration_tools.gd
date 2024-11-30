class_name SaveMigrationTools

static var stringMigrationTools: Array[SaveStringMigrationTool] = [
	preload('res://gamedata/migration/file_migrations.tres')
]

static var playerInfoFilepath: String = 'playerinfo.tres'

static func migrate_save_contents(saveFolder: String = 'save') -> void:
	var saveDirectory: String = SaveHandler.get_save_file_location(saveFolder)
	if not DirAccess.dir_exists_absolute(saveDirectory):
		printerr('Save folder ', saveDirectory, ' does not exist!')
		return
	if not saveDirectory.ends_with('/'):
		saveDirectory += '/'
	#''' temporarily disabling checking if there's a version difference, for testing
	var playerInfo: PlayerInfo = ResourceLoader.load(saveDirectory + playerInfoFilepath) as PlayerInfo
	if playerInfo != null and GameSettings.get_version_differences(playerInfo.version) == GameSettings.VersionDiffs.NONE:
		return
	#'''
	migrate_save_helper(saveDirectory)

static func migrate_save_helper(directory: String) -> void:
	if not directory.ends_with('/'):
		directory += '/'
	#print('migrate at ', directory)
	var dirs: PackedStringArray = DirAccess.get_directories_at(directory)
	for dir: String in dirs:
		#print('dir: ', dir)
		migrate_save_helper(directory + dir)
	
	var files: PackedStringArray = DirAccess.get_files_at(directory)
	for filepath: String in files:
		var dirFilepath: String = directory + filepath
		#print('File: ', dirFilepath)
		var fileContents: String  = FileAccess.get_file_as_string(dirFilepath)
		if FileAccess.get_open_error() != Error.OK:
			printerr('Could not open ', dirFilepath, ' for migration. Error: ', error_string(FileAccess.get_open_error()))
			continue
		var newContents: String = fileContents
		for stringMigrationTool: SaveStringMigrationTool in stringMigrationTools:
			newContents = stringMigrationTool.migrate_file_contents(newContents)
		var file: FileAccess = FileAccess.open(dirFilepath, FileAccess.WRITE_READ)
		if file != null and FileAccess.get_open_error() == Error.OK:
			file.store_string(newContents)
		else:
			printerr('Could not migrate ', dirFilepath, '. Error: ', error_string(FileAccess.get_open_error()))
			continue
