extends Panel
class_name LoadSaveItemPanel

@export var saveFolder: String = 'save'
@export var saveSlotName: String = 'Auto-Save'

var playerInfo: PlayerInfo = null
var isInBattle: bool = false
var parentPanel: SavesPanel = null
var showCopyTo: bool:
	get:
		return _showCopyTo
	set(val):
		_showCopyTo = val
		update_buttons_visibility()

var _showCopyTo: bool = false
var isCopyFrom: bool = false

@onready var saveSlotLabel: RichTextLabel = get_node('SaveSlotLabel')
@onready var playerSaveName: RichTextLabel = get_node('PlayerSaveNameLabel')
@onready var saveTimeLabel: RichTextLabel = get_node('SaveTimeLabel')

@onready var saveBtnControl: Control = get_node('ButtonHBoxContainer/SaveBtnControl')
@onready var saveButton: Button = get_node('ButtonHBoxContainer/SaveBtnControl/SaveButton')

@onready var loadBtnControl: Control = get_node('ButtonHBoxContainer/LoadBtnControl')
@onready var loadButton: Button = get_node('ButtonHBoxContainer/LoadBtnControl/LoadButton')

@onready var copyBtnControl: Control = get_node('ButtonHBoxContainer/CopyBtnControl')
@onready var copyButton: Button = get_node('ButtonHBoxContainer/CopyBtnControl/CopyButton')

@onready var deleteBtnControl: Control = get_node('ButtonHBoxContainer/DeleteBtnControl')
@onready var deleteButton: Button = get_node('ButtonHBoxContainer/DeleteBtnControl/DeleteButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_save_item_panel():
	playerInfo = SaveHandler.get_save_player_info(saveFolder)
	isInBattle = SaveHandler.is_save_in_battle(saveFolder)
	saveSlotLabel.text = saveSlotName
	if playerInfo != null:
		playerSaveName.text = playerInfo.combatant.disp_name()
		saveTimeLabel.text = TextUtils.get_elapsed_time(playerInfo.playtimeSecs)
		saveTimeLabel.visible = true
	else:
		playerSaveName.text = '[i]Empty[/i]'
		saveTimeLabel.visible = false
	update_buttons_visibility()

func update_buttons_visibility():
	if parentPanel.isLoading:
		saveBtnControl.visible = false
		loadBtnControl.visible = playerInfo != null and not showCopyTo
		copyBtnControl.visible = playerInfo != null or showCopyTo
		if showCopyTo:
			copyButton.text = 'Cancel' if isCopyFrom else 'Copy To'
		else:
			copyButton.text = 'Copy'
		deleteBtnControl.visible = playerInfo != null and not showCopyTo
	else:
		saveBtnControl.visible = not showCopyTo and not (not parentPanel.isLoading and PlayerResources.saveFolder == 'save')
		loadBtnControl.visible = false
		copyBtnControl.visible = playerInfo != null or (showCopyTo and not saveFolder == 'save')
		if showCopyTo:
			copyButton.text = 'Cancel' if isCopyFrom else 'Copy To'
		else:
			copyButton.text = 'Copy'
		deleteBtnControl.visible = playerInfo != null and not showCopyTo and not (not parentPanel.isLoading and PlayerResources.saveFolder == saveFolder)
	update_focus_neighbor_lr()

func set_buttons_focus_neighbor_top(control: Control):
	var saveNeighbor: Control = control
	var loadNeighbor: Control = control
	var copyNeighbor: Control = control
	var deleteNeighbor: Control = control
	if control is LoadSaveItemPanel:
		var panel: LoadSaveItemPanel = control as LoadSaveItemPanel
		saveNeighbor = panel.saveButton
		loadNeighbor = panel.loadButton
		copyNeighbor = panel.copyButton
		deleteNeighbor = panel.deleteButton
	
	saveButton.focus_neighbor_top = saveButton.get_path_to(saveNeighbor)
	loadButton.focus_neighbor_top = loadButton.get_path_to(loadNeighbor)
	copyButton.focus_neighbor_top = copyButton.get_path_to(copyNeighbor)
	deleteButton.focus_neighbor_top = deleteButton.get_path_to(deleteNeighbor)

func set_buttons_focus_neighbor_bottom(control: Control):
	var saveNeighbor: Control = control
	var loadNeighbor: Control = control
	var copyNeighbor: Control = control
	var deleteNeighbor: Control = control
	if control is LoadSaveItemPanel:
		var panel: LoadSaveItemPanel = control as LoadSaveItemPanel
		saveNeighbor = panel.saveButton
		loadNeighbor = panel.loadButton
		copyNeighbor = panel.copyButton
		deleteNeighbor = panel.deleteButton
	
	saveButton.focus_neighbor_top = saveButton.get_path_to(saveNeighbor)
	loadButton.focus_neighbor_bottom = loadButton.get_path_to(loadNeighbor)
	copyButton.focus_neighbor_bottom = copyButton.get_path_to(copyNeighbor)
	deleteButton.focus_neighbor_bottom = deleteButton.get_path_to(deleteNeighbor)

func update_focus_neighbor_lr():
	saveButton.focus_neighbor_right = saveButton.get_path_to(copyButton) if copyBtnControl.visible else '.'
	loadButton.focus_neighbor_right = loadButton.get_path_to(copyButton) if copyBtnControl.visible else '.'
	if parentPanel.isLoading:
		copyButton.focus_neighbor_left = copyButton.get_path_to(loadButton) if loadBtnControl.visible else '.'
	else:
		copyButton.focus_neighbor_left = copyButton.get_path_to(saveButton) if saveBtnControl.visible else '.'
	copyButton.focus_neighbor_right = copyButton.get_path_to(deleteButton) if deleteBtnControl.visible else '.'
	deleteButton.focus_neighbor_left = deleteButton.get_path_to(copyButton) if copyBtnControl.visible else '.'

func _on_save_button_pressed():
	parentPanel.save_to(saveFolder)

func _on_load_button_pressed():
	parentPanel.load_save(saveFolder)

func _on_copy_button_pressed():
	parentPanel.copy_save_pressed(saveFolder, showCopyTo)

func _on_delete_button_pressed():
	parentPanel.delete_save_pressed(saveFolder)
