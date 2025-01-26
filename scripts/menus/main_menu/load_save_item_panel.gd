extends Panel
class_name LoadSaveItemPanel

@export var saveFolder: String = 'save'
@export var saveSlotName: String = 'Auto-Save'

var playerInfo: PlayerInfo = null
var isInBattle: bool = false
var parentPanel: SavesPanel = null
var showCopyTo: bool = false
var isCopyFrom: bool = false

@onready var saveSlotLabel: RichTextLabel = get_node('SaveSlotLabel')
@onready var playerSaveName: RichTextLabel = get_node('PlayerSaveNameLabel')
@onready var saveTimeLabel: RichTextLabel = get_node('SaveTimeLabel')
@onready var versionLabel: RichTextLabel = get_node('VersionLabel')

@onready var saveButton: Button = get_node('ButtonHBoxContainer/SaveBtnControl/SaveButton')

@onready var loadBtnControl: Control = get_node('ButtonHBoxContainer/LoadBtnControl')
@onready var loadButton: Button = get_node('ButtonHBoxContainer/LoadBtnControl/LoadButton')

@onready var copyButton: Button = get_node('ButtonHBoxContainer/CopyBtnControl/CopyButton')

@onready var deleteButton: Button = get_node('ButtonHBoxContainer/DeleteBtnControl/DeleteButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_save_item_panel():
	playerInfo = SaveHandler.get_save_player_info(saveFolder)
	isInBattle = SaveHandler.is_save_in_battle(saveFolder)
	saveSlotLabel.text = saveSlotName
	if not parentPanel.isLoading and PlayerResources.saveFolder == saveFolder:
		saveSlotLabel.text += ' (Loaded)'
	
	if playerInfo != null:
		playerSaveName.text = playerInfo.combatant.disp_name()
		var location: String = '???'
		var worldLocation: WorldLocation = MapLoader.get_world_location_for_name(playerInfo.map)
		if worldLocation != null:
			location = worldLocation.locationName
		if SaveHandler.is_save_in_battle(saveFolder):
			location += ' (in Battle)'
		saveTimeLabel.text = location + ' - ' + TextUtils.get_elapsed_time(playerInfo.playtimeSecs)
		saveTimeLabel.visible = true
		versionLabel.text = '[right]v' + playerInfo.version + '[/right]'
		versionLabel.visible = true
	else:
		playerSaveName.text = '[i]Empty[/i]'
		saveTimeLabel.visible = false
		versionLabel.visible = false
	update_buttons_visibility()

func update_buttons_visibility():
	if parentPanel.isLoading:
		saveButton.visible = false
		loadBtnControl.visible = true
		loadButton.disabled = not (playerInfo != null and not showCopyTo)
	else:
		saveButton.visible = true
		saveButton.disabled = not (not showCopyTo and saveFolder != 'save')
		loadBtnControl.visible = false
	copyButton.disabled = not ((playerInfo != null or showCopyTo) and not (showCopyTo and saveFolder == 'save' and not isCopyFrom))
	if showCopyTo:
		copyButton.text = 'Cancel' if isCopyFrom else 'Copy To'
	else:
		copyButton.text = 'Copy'
	deleteButton.disabled = not (playerInfo != null and not showCopyTo and not (not parentPanel.isLoading and PlayerResources.saveFolder == saveFolder))
	
	update_focus_neighbor_lr()

func set_buttons_focus_neighbor_top(control: Control):
	var saveNeighbor: Control = control
	var loadNeighbor: Control = control
	var copyNeighbor: Control = control
	var deleteNeighbor: Control = control
	var changeSave: bool = true
	var changeLoad: bool = true
	var changeCopy: bool = true
	var changeDelete: bool = true
	if control is LoadSaveItemPanel:
		var panel: LoadSaveItemPanel = control as LoadSaveItemPanel
		if panel.saveButton.visible:
			saveNeighbor = panel.saveButton
		else:
			changeSave = false
		if panel.loadBtnControl.visible:
			loadNeighbor = panel.loadButton
		else:
			changeLoad = false
		if panel.copyButton.visible:
			copyNeighbor = panel.copyButton
		else:
			changeCopy = false
		if panel.deleteButton.visible:
			deleteNeighbor = panel.deleteButton
		else:
			changeDelete = false
	
	if changeSave:
		saveButton.focus_neighbor_top = saveButton.get_path_to(saveNeighbor)
	if changeLoad:
		loadButton.focus_neighbor_top = loadButton.get_path_to(loadNeighbor)
	if changeCopy:
		copyButton.focus_neighbor_top = copyButton.get_path_to(copyNeighbor)
	if changeDelete:
		deleteButton.focus_neighbor_top = deleteButton.get_path_to(deleteNeighbor)

func set_buttons_focus_neighbor_bottom(control: Control):
	var saveNeighbor: Control = control
	var loadNeighbor: Control = control
	var copyNeighbor: Control = control
	var deleteNeighbor: Control = control
	var changeSave: bool = true
	var changeLoad: bool = true
	var changeCopy: bool = true
	var changeDelete: bool = true
	if control is LoadSaveItemPanel:
		var panel: LoadSaveItemPanel = control as LoadSaveItemPanel
		if panel.saveButton.visible:
			saveNeighbor = panel.saveButton
		else:
			changeSave = false
		if panel.loadBtnControl.visible:
			loadNeighbor = panel.loadButton
		else:
			changeLoad = false
		if panel.copyButton.visible:
			copyNeighbor = panel.copyButton
		else:
			changeCopy = false
		if panel.deleteButton.visible:
			deleteNeighbor = panel.deleteButton
		else:
			changeDelete = false
	
	if changeSave:
		saveButton.focus_neighbor_bottom = saveButton.get_path_to(saveNeighbor)
	if changeLoad:
		loadButton.focus_neighbor_bottom = loadButton.get_path_to(loadNeighbor)
	if changeCopy:
		copyButton.focus_neighbor_bottom = copyButton.get_path_to(copyNeighbor)
	if changeDelete:
		deleteButton.focus_neighbor_bottom = deleteButton.get_path_to(deleteNeighbor)

func update_focus_neighbor_lr():
	saveButton.focus_neighbor_right = saveButton.get_path_to(copyButton) if copyButton.visible else NodePath('.')
	loadButton.focus_neighbor_right = loadButton.get_path_to(copyButton) if copyButton.visible else NodePath('.')
	if parentPanel.isLoading:
		copyButton.focus_neighbor_left = copyButton.get_path_to(loadButton) if loadBtnControl.visible else NodePath('.')
	else:
		copyButton.focus_neighbor_left = copyButton.get_path_to(saveButton) if saveButton.visible else NodePath('.')
	copyButton.focus_neighbor_right = copyButton.get_path_to(deleteButton) if deleteButton.visible else NodePath('.')
	deleteButton.focus_neighbor_left = deleteButton.get_path_to(copyButton) if copyButton.visible else NodePath('.')

func _on_save_button_pressed():
	parentPanel.save_to(saveFolder)

func _on_load_button_pressed():
	parentPanel.load_save(saveFolder)

func _on_copy_button_pressed():
	parentPanel.copy_save_pressed(saveFolder, showCopyTo)

func _on_delete_button_pressed():
	parentPanel.delete_save_pressed(saveFolder)
