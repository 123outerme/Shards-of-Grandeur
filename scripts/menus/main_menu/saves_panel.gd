extends Panel
class_name SavesPanel

signal game_saved
signal game_save_failed
signal back_pressed

@export var isLoading: bool = true

var fromSave: String = ''
var toSave: String = ''
var deleteSaveFolder: String = ''
var savingFolder: String = ''

@onready var savesPanelLabel: RichTextLabel = get_node('SavesPanelLabel')
@onready var savePanelVbox: VBoxContainer = get_node('ScrollContainer/VBoxContainer')
@onready var backButton: Button = get_node('BackButton')
@onready var confirmPanel: ItemConfirmPanel = get_node('ItemConfirmPanel')

const loadSaveItemPanelScene = preload('res://prefabs/ui/main_menu/load_save_item_panel.tscn')

func _ready():
	savesPanelLabel.text = '[center]' + ('Load' if isLoading else 'Save') + ' Game[/center]'

func _unhandled_input(event):
	if visible:
		if event.is_action_pressed('game_decline'):
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()

func initial_focus():
	if isLoading:
		var setFocus: bool = false
		var children = savePanelVbox.get_children()
		for node in children:
			var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
			if panel.playerInfo != null and not setFocus:
				panel.loadButton.grab_focus()
				setFocus = true
		if not setFocus:
			backButton.grab_focus()
	else:
		var children = savePanelVbox.get_children()
		var setFocus: bool = false
		for node in children:
			var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
			if panel.saveFolder == PlayerResources.saveFolder and not panel.saveFolder == 'save' and not setFocus:
				panel.saveButton.grab_focus()
				setFocus = true
		if not setFocus:
			var firstPermanentSavePanel: LoadSaveItemPanel = children[1]
			firstPermanentSavePanel.saveButton.grab_focus()

func load_saves_panel():
	fromSave = ''
	toSave = ''
	load_save_item_panels()
	initial_focus()

func toggle_saves_panel(showing: bool) -> void:
	if showing:
		visible = true
		load_saves_panel()
	else:
		_on_back_button_pressed()

func load_save_item_panels():
	var panels = savePanelVbox.get_children()
	for idx in range(len(panels)):
		var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
		panel.isCopyFrom = false
		panel.showCopyTo = false
		panel.parentPanel = self
		panel.load_save_item_panel()
	update_focus_neighbors()

func update_focus_neighbors():
	var panels = savePanelVbox.get_children().filter(_filter_out_no_button_panels)
	for idx in range(len(panels)):
		var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
		panel.set_buttons_focus_neighbor_top(backButton)
		panel.set_buttons_focus_neighbor_bottom(backButton)
		if idx == 0:
			if isLoading:
				backButton.focus_neighbor_bottom = backButton.get_path_to(panel.loadButton if panel.loadBtnControl.visible else panel.copyButton)
			else:
				backButton.focus_neighbor_bottom = backButton.get_path_to(panel.saveButton if panel.saveButton.visible else panel.copyButton)
		else:
			panel.set_buttons_focus_neighbor_top(panels[idx - 1])
			panels[idx - 1].set_buttons_focus_neighbor_bottom(panel)
		if idx < len(panels) - 1:
			panel.set_buttons_focus_neighbor_bottom(panels[idx + 1])
			panels[idx + 1].set_buttons_focus_neighbor_top(panel)
		if idx == len(panels) - 1:
			if isLoading:
				backButton.focus_neighbor_top = backButton.get_path_to(panel.loadButton if panel.loadBtnControl.visible else panel.copyButton)
			else:
				backButton.focus_neighbor_top = backButton.get_path_to(panel.saveButton if panel.saveButton.visible else panel.copyButton)

func get_num_saves() -> int:
	var count = 0
	var children = savePanelVbox.get_children()
	for node in children:
		var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
		if panel != null and panel.playerInfo != null:
			count += 1
	return count

func has_quick_save() -> bool:
	var panel: LoadSaveItemPanel = savePanelVbox.get_children()[0] as LoadSaveItemPanel
	if panel != null:
		return panel.playerInfo != null
	return false

func save_to(saveFolder: String):
	if isLoading:
		return
	
	if saveFolder != PlayerResources.saveFolder:
		savingFolder = saveFolder
		var savePanel: LoadSaveItemPanel = null
		var children = savePanelVbox.get_children()
		for node in children:
			var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
			if panel.saveFolder == saveFolder:
				savePanel = panel
				break
		if savePanel == null:
			printerr('delete_save_pressed() error: Could not find save file for ', saveFolder)
			return
		if savePanel.playerInfo != null:
			confirmPanel.title = 'Save Over ' + savePanel.saveSlotName + '?'
			confirmPanel.description = 'Are you sure you want to overwrite the story of ' + savePanel.playerInfo.combatant.disp_name() + '?'
			confirmPanel.load_item_confirm_panel()
			return
	save_game(saveFolder)

func save_game(saveFolder: String):
	var success = SaveHandler.save_data(saveFolder)
	if success:
		PlayerResources.saveFolder = saveFolder
		game_saved.emit()
	else:
		game_save_failed.emit()
	var setFocus: bool = false
	var children = savePanelVbox.get_children()
	for node in children:
		var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
		if panel.saveFolder == saveFolder:
			panel.saveButton.grab_focus()
			setFocus = true
			break
	if not setFocus:
		initial_focus()
	load_save_item_panels()

func load_save(saveFolder: String):
	SaveHandler.load_data(saveFolder)
	SceneLoader.load_game(saveFolder)

func copy_save_pressed(saveFolder: String, isCopyTo: bool):
	var panels = savePanelVbox.get_children()
	if not isCopyTo:
		for idx in range(len(panels)):
			var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
			panel.isCopyFrom = saveFolder == panel.saveFolder
			panel.showCopyTo = true
			panel.update_buttons_visibility()
		fromSave = saveFolder
	else:
		toSave = saveFolder
		if fromSave != toSave:
			var overwritesPanel: LoadSaveItemPanel = null
			for idx in range(len(panels)):
				var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
				if panel.saveFolder == toSave and panel.playerInfo != null:
					overwritesPanel = panel
					break
			if overwritesPanel == null:
				copy_save()
			else:
				confirmPanel.title = 'Copy Over ' + overwritesPanel.saveSlotName + '?'
				confirmPanel.description = 'Are you sure you want to copy over the story of ' + overwritesPanel.playerInfo.combatant.disp_name() + '?'
				confirmPanel.load_item_confirm_panel()
		else:
			fromSave = ''
			toSave = ''
			for idx in range(len(panels)):
				var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
				panel.isCopyFrom = false
				panel.showCopyTo = false
				panel.update_buttons_visibility()
	update_focus_neighbors()

func copy_save(yes: bool = true):
	if fromSave == '' or toSave == '':
		fromSave = ''
		toSave = ''
		return
	
	if yes:
		var success = SaveHandler.copy_save(fromSave, toSave)
		if not success:
			game_save_failed.emit()
		else:
			game_saved.emit()
	var panels = savePanelVbox.get_children()
	for idx in range(len(panels)):
		var panel: LoadSaveItemPanel = panels[idx] as LoadSaveItemPanel
		panel.isCopyFrom = false
		panel.showCopyTo = false
		if panel.saveFolder == fromSave:
			panel.copyButton.grab_focus()
		panel.load_save_item_panel()
	fromSave = ''
	toSave = ''

func delete_save_pressed(saveFolder: String):
	var savePanel: LoadSaveItemPanel = null
	var children = savePanelVbox.get_children()
	for node in children:
		var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
		if panel.saveFolder == saveFolder:
			savePanel = panel
			break
	if savePanel == null:
		printerr('delete_save_pressed() error: Could not find save file for ', saveFolder)
		return
	
	deleteSaveFolder = saveFolder
	confirmPanel.title = 'Delete ' + savePanel.saveSlotName + '?'
	confirmPanel.description = 'Are you sure you want to erase the story of ' + savePanel.playerInfo.combatant.disp_name() + '?'
	confirmPanel.load_item_confirm_panel()

func delete_save(saveFolder: String):
	SaveHandler.delete_save(saveFolder)
	load_save_item_panels()
	initial_focus()

func _on_back_button_pressed():
	visible = false
	if fromSave != '':
		copy_save_pressed(fromSave, true) # resets state from "copy save" being mid-action
	deleteSaveFolder = ''
	savingFolder = ''
	back_pressed.emit()

func _on_item_confirm_panel_confirm_option(yes: bool):
	if fromSave != '' and toSave != '':
		# copy save confirm
		copy_save(yes)
	elif deleteSaveFolder != '':
		# delete save confirm
		if yes:
			delete_save(deleteSaveFolder)
		else:
			var children = savePanelVbox.get_children()
			for node in children:
				var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
				if panel.saveFolder == deleteSaveFolder:
					panel.deleteButton.grab_focus()
					break
		deleteSaveFolder = ''
	elif not isLoading:
		# save game confirm
		if yes:
			save_game(savingFolder)
		else:
			var children = savePanelVbox.get_children()
			for node in children:
				var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
				if panel.saveFolder == savingFolder:
					panel.saveButton.grab_focus()
					break
		savingFolder = ''

func _filter_out_no_button_panels(panel: LoadSaveItemPanel) -> bool:
	return (not isLoading and panel.saveFolder != 'save') or panel.playerInfo != null or fromSave != ''
