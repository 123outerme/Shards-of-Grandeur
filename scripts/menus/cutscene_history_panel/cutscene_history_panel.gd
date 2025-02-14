extends Control
class_name CutsceneHistoryPanel

signal back_pressed

@export var cutscene: Cutscene = null
@export var currentFrameIdx: int = 0

var cutsceneHistoryItemPanelScene: PackedScene = load('res://prefabs/ui/cutscene_history/cutscene_history_item_panel.tscn')

@onready var scrollContainer: ScrollContainer = get_node('Panel/ScrollContainer')
@onready var vboxContainer: VBoxContainer = get_node('Panel/ScrollContainer/VBoxContainer')
@onready var boxContainerScroller: BoxContainerScroller = get_node('Panel/BoxContainerScroller')

@onready var backButton: Button = get_node('Panel/BackButton')


func load_cutscene_history_panel() -> void:
	if cutscene == null or currentFrameIdx <= 0 or currentFrameIdx >= len(cutscene.cutsceneFrames):
		printerr('Error loading CutsceneHistoryPanel: Null cutscene or bad frame index')
		return
	
	visible = true
	for child: Node in vboxContainer.get_children():
		if child != null:
			child.queue_free()
	
	# check all frames up to the current frame (since dialogue displays at the end of the frame, in transition to the next frame)
	var itemPanels: Array[CutsceneHistoryItemPanel] = []
	for frameIdx: int in range(min(currentFrameIdx + 1, len(cutscene.cutsceneFrames))):
		var frame: CutsceneFrame = cutscene.cutsceneFrames[frameIdx]
		# if the current frame hasn't yet had its text triggered: skip it
		if frameIdx == currentFrameIdx and not frame.get_text_was_triggered():
			continue
		for dialogue: CutsceneDialogue in frame.dialogues:
			for textIdx: int in range(len(dialogue.texts)):
				# if this line hasn't been shown in the cutscene yet, don't add it
				if len(PlayerFinder.player.cutsceneTexts) > 0 and dialogue == PlayerFinder.player.cutsceneTexts[PlayerFinder.player.cutsceneTextIndex] and textIdx > PlayerFinder.player.cutsceneLineIndex:
					continue
				
				var itemPanel: CutsceneHistoryItemPanel = cutsceneHistoryItemPanelScene.instantiate() as CutsceneHistoryItemPanel
				itemPanel.cutsceneDialogue = dialogue
				itemPanel.textIdx = textIdx
				itemPanels.append(itemPanel)
	
	var curDialogue: CutsceneDialogue = null
	# iterate backwards over list of panels to put most recent dialogue first
	for panelIdx: int in range(len(itemPanels) - 1, -1, -1):
		var itemPanel: CutsceneHistoryItemPanel = itemPanels[panelIdx]
		# when the dialogue changes, this is now the first panel in the list for the current dialogue item
		if curDialogue != itemPanel.cutsceneDialogue:
			itemPanel.isFirst = true
			curDialogue = itemPanel.cutsceneDialogue
		vboxContainer.add_child(itemPanel)
		itemPanel.load_cutscene_history_item_panel.call_deferred()
	
	scrollContainer.scroll_vertical = 0
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
	if boxContainerScroller.visible:
		boxContainerScroller.connect_scroll_down_bottom_neighbor(backButton)
		boxContainerScroller.connect_scroll_down_left_neighbor(backButton)
	else:
		backButton.focus_neighbor_top = '.'
		backButton.focus_neighbor_right = '.'
		if SceneLoader.mainGame.lastFocusedControl == boxContainerScroller.scrollDownBtn:
			initial_focus()
