extends Resource
class_name SaveStringMigrationTool

@export var strings: Array[MigrationString] = []

func _init(i_strings: Array[MigrationString] = []):
	strings = i_strings

func migrate_file_contents(fileContents: String) -> String:
	var newContents: String = fileContents
	for migrationString: MigrationString in strings:
		newContents = migrationString.migrate_file_contents(newContents)
	return newContents
