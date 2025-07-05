extends Resource
class_name Evolutions

## In cases of disjoint evolution requirements, evolutions at the start of this list have priority
@export var evolutionList: Array[Evolution] = []

func _init(i_list: Array[Evolution] = []):
	evolutionList = i_list
