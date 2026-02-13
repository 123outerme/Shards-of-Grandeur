extends Panel
class_name SavesPanel

signal game_saved
signal game_save_failed
signal back_pressed

@export var isLoading: bool = true
@export var shade: ColorRect = null
@export var fromMainMenu: bool = false

var fromSave: String = ''
var toSave: String = ''
var deleteSaveFolder: String = ''
var savingFolder: String = ''
var loadPressed: bool = false

var choosingExportSlot: bool = false
var choosingImportSlot: bool = false
var exportImportSaveFolder: String = ''
var importZipFilePath: String = ''
var fileDialog: FileDialog = null

@onready var savesPanelLabel: RichTextLabel = get_node('SavesPanelLabel')
@onready var savePanelVbox: VBoxContainer = get_node('ScrollContainer/VBoxContainer')
@onready var backButton: Button = get_node('BackButton')
@onready var exportButton: Button = get_node('ExportButton')
@onready var importButton: Button = get_node('ImportButton')
@onready var confirmPanel: ItemConfirmPanel = get_node('ItemConfirmPanel')
@onready var tooltipPanel: TooltipPanel = get_node('TooltipPanel')

const loadSaveItemPanelScene = preload('res://prefabs/ui/main_menu/load_save_item_panel.tscn')

func _unhandled_input(event):
	if visible:
		if event.is_action_pressed('game_decline') and not loadPressed:
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()

func initial_focus():
	if choosingExportSlot:
		var setFocus: bool = false
		var children = savePanelVbox.get_children()
		for node in children:
			var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
			if panel.playerInfo != null and not setFocus:
				panel.copyButton.grab_focus()
				setFocus = true
		if not setFocus:
			backButton.grab_focus()
	elif choosingImportSlot:
		var setFocus: bool = false
		var children = savePanelVbox.get_children()
		for node in children:
			var panel: LoadSaveItemPanel = node as LoadSaveItemPanel
			if panel.playerInfo != null and not setFocus:
				panel.saveButton.grab_focus()
				setFocus = true
		if not setFocus:
			backButton.grab_focus()
	elif isLoading:
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
	if choosingExportSlot:
		savesPanelLabel.text = '[center]Export Save[/center]'
	elif choosingImportSlot:
		savesPanelLabel.text = '[center]Choose Import Destination[/center]'
	else:
		savesPanelLabel.text = '[center]' + ('Load' if isLoading else 'Save') + ' Game[/center]'
	load_save_item_panels()
	if fromMainMenu and not choosingExportSlot and not choosingImportSlot:
		exportButton.visible = true
		importButton.visible = true
		backButton.focus_neighbor_left = backButton.get_path_to(importButton)
	else:
		exportButton.visible = false
		importButton.visible = false
		backButton.focus_neighbor_left = '.'
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
	if loadPressed:
		return
	loadPressed = true
	get_viewport().gui_release_focus() # release focus so player can't spam load button
	await fade_out_panel()
	await get_tree().process_frame
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
	if loadPressed:
		return
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
	if loadPressed:
		return
	SaveHandler.delete_save(saveFolder)
	load_save_item_panels()
	initial_focus()

func export_save_chosen(saveFolder: String) -> void:
	exportImportSaveFolder = saveFolder
	fileDialog = FileDialog.new()
	fileDialog.file_mode = FileDialog.FileMode.FILE_MODE_SAVE_FILE
	fileDialog.access = FileDialog.Access.ACCESS_FILESYSTEM
	fileDialog.use_native_dialog = true
	fileDialog.filters = ['*.zip']
	fileDialog.position = get_viewport_rect().size / 2.0 - fileDialog.size / 2.0
	fileDialog.display_mode = FileDialog.DISPLAY_LIST
	fileDialog.file_selected.connect(_on_export_save_location_chosen)
	add_child(fileDialog)
	fileDialog.visible = true
	fileDialog.get_line_edit().grab_focus.call_deferred()

func import_save_slot_chosen(saveFolder: String) -> void:
	exportImportSaveFolder = saveFolder
	if SaveHandler.save_file_exists(saveFolder):
		confirmPanel.title = 'Overwrite Save On Import?'
		var saveNumber: String = saveFolder.trim_prefix('save')
		confirmPanel.description = 'Save File ' + saveNumber + ' already exists. Overwrite this existing save and import the new save?'
		confirmPanel.load_item_confirm_panel()
	else:
		load_imported_save_slot()

func load_imported_save_slot() -> void:
	var success: bool = SaveHandler.import_zip_of_save_file(exportImportSaveFolder, importZipFilePath)
	_on_back_button_pressed()
	if success:
		tooltipPanel.title = 'Import Success'
		tooltipPanel.details = 'Save file was imported successfully!'
	else:
		tooltipPanel.title = 'Import FAILURE'
		tooltipPanel.details = 'An error has occurred. Save file was not imported successfully. Please try again.'
	tooltipPanel.load_tooltip_panel()
	await tooltipPanel.ok_pressed

func fade_out_panel() -> void:
	SceneLoader.audioHandler.fade_out_music(0.5)
	if shade == null:
		return
	shade.visible = true
	shade.modulate = Color(0, 0, 0, 0)
	var shadeTween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	shadeTween.tween_property(shade, 'modulate', Color(0, 0, 0, 1.0), 0.5)
	await shadeTween.finished

func _on_back_button_pressed():
	if loadPressed:
		return
	if choosingImportSlot or choosingExportSlot:
		var wasChoosingImport: bool = choosingImportSlot
		choosingExportSlot = false
		choosingImportSlot = false
		exportImportSaveFolder = ''
		importZipFilePath = ''
		if fileDialog != null:
			fileDialog.visible = false
			fileDialog.queue_free()
		load_saves_panel()
		if wasChoosingImport:
			importButton.grab_focus()
		else:
			exportButton.grab_focus()
		return
	visible = false
	if fromSave != '':
		copy_save_pressed(fromSave, true) # resets state from "copy save" being mid-action
	deleteSaveFolder = ''
	savingFolder = ''
	back_pressed.emit()

func _on_export_button_pressed() -> void:
	choosingExportSlot = true
	load_saves_panel()

func _on_import_button_pressed() -> void:
	fileDialog = FileDialog.new()
	fileDialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE
	fileDialog.access = FileDialog.Access.ACCESS_FILESYSTEM
	fileDialog.use_native_dialog = true
	fileDialog.filters = ['*.zip']
	fileDialog.position = get_viewport_rect().size / 2.0 - fileDialog.size / 2.0
	fileDialog.display_mode = FileDialog.DISPLAY_LIST
	fileDialog.file_selected.connect(_on_import_file_chosen)
	add_child(fileDialog)
	fileDialog.visible = true
	fileDialog.get_line_edit().grab_focus.call_deferred()

func _on_export_save_location_chosen(path: String) -> void:
	fileDialog.visible = false
	fileDialog.queue_free()
	if path == '':
		_on_back_button_pressed()
		return
	if not path.ends_with(".zip"):
		path += ".zip"
	var success: bool = SaveHandler.create_zip_of_save_file(exportImportSaveFolder, path)
	if success:
		tooltipPanel.title = 'Export Success'
		tooltipPanel.details = 'Save file was exported successfully.'
	else:
		tooltipPanel.title = 'Export FAILURE'
		tooltipPanel.details = 'An error has occurred. Save file was not exported successfully. Please try again.'
	tooltipPanel.load_tooltip_panel()
	await tooltipPanel.ok_pressed
	_on_back_button_pressed()

func _on_import_file_chosen(path: String) -> void:
	fileDialog.visible = false
	fileDialog.queue_free()
	if path == '':
		_on_back_button_pressed()
		return
	if not FileAccess.file_exists(path):
		tooltipPanel.title = 'Import FAILURE'
		tooltipPanel.details = 'File name provided does not exist or could not be opened.'
		tooltipPanel.load_tooltip_panel()
		await tooltipPanel.ok_pressed
		_on_back_button_pressed()
		return
	choosingImportSlot = true
	importZipFilePath = path
	load_saves_panel()

func _on_item_confirm_panel_confirm_option(yes: bool):
	if choosingImportSlot:
		if yes:
			load_imported_save_slot()
		else:
			_on_back_button_pressed()
		return
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
