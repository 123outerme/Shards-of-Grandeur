extends Control
class_name CutsceneHistoryPanel

signal back_pressed

@export var cutscene: Cutscene = null
@export var currentFrameIdx: int = 0

var cutsceneHistoryItemPanelScene: PackedScene = load('res://prefabs/ui/cutscene_history/cutscene_history_item_panel.tscn')

@onready var backButton: Button = get_node('Panel/BackButton')
@onready var vboxContainer: VBoxContainer = get_node('Panel/ScrollContainer/VBoxContainer')
@onready var boxContainerScroller: BoxContainerScroller = get_node('Panel/BoxContainerScroller')

func load_cutscene_history_panel() -> void:
	if cutscene == null or currentFrameIdx <= 0 or currentFrameIdx >= len(cutscene.cutsceneFrames):
		printerr('Error loading CutsceneHistoryPanel: Null cutscene or bad frame index')
		return
	
	visible = true
	for child: Node in vboxContainer.get_children():
		if child != null:
			child.queue_free()
	
	# check all frames up to the current frame (since dialogue displays at the end of the frame, in transition to the next frame)
	for frameIdx: int in range(min(currentFrameIdx + 1, len(cutscene.cutsceneFrames))):
		var frame: CutsceneFrame = cutscene.cutsceneFrames[frameIdx]
		# if the current frame hasn't yet had its text triggered: skip it
		if frameIdx == currentFrameIdx and not frame.get_text_was_triggered():
			continue
		for dialogue: CutsceneDialogue in frame.dialogues:
			for textIdx: int in range(len(dialogue.texts)):
				var itemPanel: CutsceneHistoryItemPanel = cutsceneHistoryItemPanelScene.instantiate() as CutsceneHistoryItemPanel
				itemPanel.cutsceneDialogue = dialogue
				itemPanel.textIdx = textIdx
				itemPanel.isFirst = textIdx == 0
				vboxContainer.add_child(itemPanel)
				itemPanel.load_cutscene_history_item_panel.call_deferred()
	
	_on_box_container_scroller_scroll_buttons_updated()
	initial_focus()

func initial_focus() -> void:
	backButton.grab_focus()

func close_panel(emitSignal: bool = true) -> void:
	visible = false
	if emitSignal:
		back_pressed.emit()

func _on_back_button_pressed() -> void:
	close_panel()

func _on_box_container_scroller_scroll_buttons_updated() -> void:
	if boxContainerScroller.scrollDownBtn.visible:
		boxContainerScroller.connect_scroll_down_bottom_neighbor(backButton)
	else:
		backButton.focus_neighbor_top = '.'
		if SceneLoader.mainGame.lastFocusedControl == boxContainerScroller.scrollDownBtn:
			initial_focus()
