extends Panel
class_name SavesPanel

signal game_saved
signal game_save_failed
signal back_pressed

@export var isLoading: bool = true

var fromSave: String = ''

@onready var savePanelVbox: VBoxContainer = get_node('ScrollContainer/VBoxContainer')
@onready var backButton: Button = get_node('BackButton')

const loadSaveItemPanelScene = preload('res://prefabs/ui/main_menu/load_save_item_panel.tscn')

func _ready():
	pass

func initial_focus():
	if isLoading:
		var firstPanel: LoadSaveItemPanel = savePanelVbox.get_children()[0]
		if firstPanel != null and firstPanel.playerInfo != null:
			firstPanel.loadButton.grab_focus()
		else:
			backButton.grab_focus()
	else:
		var children = savePanelVbox.get_children()
		var setFocus: bool = false
		for node in children:
			var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
			if panel.saveFolder == PlayerResources.saveFolder:
				panel.saveButton.grab_focus()
				setFocus = true
		if not setFocus:
			var firstPermanentSavePanel: LoadSaveItemPanel = children[1]
			firstPermanentSavePanel.saveButton.grab_focus()

func load_saves_panel():
	load_save_panels()
	initial_focus()

func load_save_panels():
	var panels = savePanelVbox.get_children()
	for idx in range(len(panels)):
		var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
		panel.parentPanel = self
		panel.load_save_item_panel()
	update_focus_neighbors()

func update_focus_neighbors():
	var panels = savePanelVbox.get_children().filter(_filter_out_no_button_panels)
	for idx in range(len(panels)):
		var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
		if idx == 0:
			panel.set_buttons_focus_neighbor_top(backButton)
			backButton.focus_neighbor_bottom = backButton.get_path_to(panel.loadButton if panel.loadBtnControl.visible else panel.copyButton)
		else:
			panel.set_buttons_focus_neighbor_top(panels[idx - 1])
			panels[idx - 1].set_buttons_focus_neighbor_bottom(panel)
		if idx < len(panels) - 1:
			panel.set_buttons_focus_neighbor_bottom(panels[idx + 1])
			panels[idx + 1].set_buttons_focus_neighbor_top(panel)
		if idx == len(panels) - 1:
			panel.set_buttons_focus_neighbor_bottom(backButton)
			backButton.focus_neighbor_top = backButton.get_path_to(panel.loadButton if panel.loadBtnControl.visible else panel.copyButton)

func save_to(saveFolder: String):
	if isLoading:
		return
	
	var success = SaveHandler.save_data(saveFolder)
	if success:
		game_saved.emit()
	else:
		game_save_failed.emit()
	load_save_panels()

func load_save(saveFolder: String):
	SaveHandler.load_data(saveFolder)
	SceneLoader.load_game(saveFolder)

func copy_save_pressed(saveFolder: String, isCopyTo: bool):
	if not isCopyTo:
		var panels = savePanelVbox.get_children()
		for idx in range(len(panels)):
			var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
			panel.isCopyFrom = saveFolder == panel.saveFolder
			panel.showCopyTo = true
			panel.update_buttons_visibility()
		fromSave = saveFolder
	else:
		var success: bool = true
		if fromSave != saveFolder:
			success = SaveHandler.copy_save(fromSave, saveFolder)
		var panels = savePanelVbox.get_children()
		for idx in range(len(panels)):
			var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
			panel.isCopyFrom = false
			panel.showCopyTo = false
			if panel.saveFolder == fromSave:
				panel.copyButton.grab_focus()
			panel.load_save_item_panel()
		fromSave = ''
	update_focus_neighbors()

func delete_save_pressed(saveFolder: String):
	# TODO: get confirmation first
	delete_save(saveFolder)

func delete_save(saveFolder):
	SaveHandler.delete_save(saveFolder)
	load_save_panels()

func _on_back_button_pressed():
	visible = false
	back_pressed.emit()

func _filter_out_no_button_panels(panel: LoadSaveItemPanel) -> bool:
	return panel.playerInfo != null or fromSave != ''
