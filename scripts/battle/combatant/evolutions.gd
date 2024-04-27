extends Resource
class_name Evolutions

@export var evolutionList: Array[Evolution] = []

func _init(i_list: Array[Evolution] = []):
	evolutionList = i_list
