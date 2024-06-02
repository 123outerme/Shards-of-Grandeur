extends BaseButton
class_name SFXButton

var popupMenu: PopupMenu = null

@export var sfx: AudioStream = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if has_method('get_popup'):
		popupMenu = call('get_popup')
		if popupMenu != null and not popupMenu.id_pressed.is_connected(_popup_menu_item_picked):
			popupMenu.id_pressed.connect(_popup_menu_item_picked)

func _exit_tree():
	#if popupMenu != null and popupMenu.id_pressed.is_connected(_popup_menu_item_picked):
	#	popupMenu.id_pressed.disconnect(_popup_menu_item_picked)
	pass

func _on_pressed():
	SceneLoader.audioHandler.play_sfx(sfx)

func _popup_menu_item_picked(_id):
	SceneLoader.audioHandler.play_sfx(sfx)
