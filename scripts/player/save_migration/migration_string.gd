extends Resource
class_name MigrationString

@export_multiline var oldStrings: Array[String] = []
@export_multiline var newString: String = ''

func _init(
	i_oldStrings: Array[String] = [],
	i_newString: String = ''
):
	oldStrings = i_oldStrings
	newString = i_newString

func migrate_file_contents(fileContents: String) -> String:
	var newContents: String = fileContents
	for oldString: String in oldStrings:
		newContents = newContents.replace(oldString, newString)
	return newContents
