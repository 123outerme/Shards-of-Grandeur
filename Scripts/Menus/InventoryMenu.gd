extends Node2D
class_name InventoryMenu

@export var selectedFilter: String
@export var lockFilters: bool

@onready var vboxViewport = get_node("InventoryPanel/Panel/ScrollContainer/VBoxContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	prepare_inventory_panel()
	pass # Replace with function body.

func prepare_inventory_panel():
	pass

func use_item(item):
	pass
	
func trash_item(item):
	pass

func view_item_details(item):
	pass

func filter_by():
	prepare_inventory_panel()
