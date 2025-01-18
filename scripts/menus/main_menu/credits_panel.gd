extends Panel
class_name CreditsPanel

const SCROLL_WAIT_SECS: float = 1.5
const SCROLL_AMOUNT_PER_SEC: float = 60

var visibleTimer: float = 0
var autoScrolling: bool = false
var creditsScrollHeight: float = 0
var creditsScrollBar: VScrollBar = null

@onready var creditsText: RichTextLabel = get_node('CreditsText')
@onready var creditsTextLabelScroller: RichTextLabelScroller = get_node('RichTextLabelScroller')
@onready var backButton: Button = get_node('BackButton')

func _ready() -> void:
	creditsScrollBar = creditsText.get_v_scroll_bar()
	if creditsScrollBar != null:
		creditsScrollBar.gui_input.connect(_on_credits_text_gui_input)
	creditsTextLabelScroller.connect_scroll_down_bottom_neighbor(backButton)
	creditsTextLabelScroller.connect_scroll_down_left_neighbor(backButton)

func _on_visibility_changed() -> void:
	autoScrolling = visible
	visibleTimer = 0
	creditsScrollHeight = 0
	if creditsScrollBar != null:
		creditsScrollBar.value = 0

func _process(delta: float) -> void:
	if visible and autoScrolling:
		visibleTimer += delta
		if visibleTimer > SCROLL_WAIT_SECS:
			if creditsScrollBar != null:
				creditsScrollHeight += SCROLL_AMOUNT_PER_SEC * delta
				creditsScrollBar.value = round(creditsScrollHeight)
				#print(creditsScrollBar.value, ', ', creditsScrollBar.size.y, ' / ', creditsScrollBar.max_value)
				if creditsScrollBar.value + creditsText.size.y >= creditsScrollBar.max_value:
					autoScrolling = false

func _on_credits_text_gui_input(event: InputEvent) -> void:
	if autoScrolling and (event is InputEventScreenTouch or \
			event is InputEventScreenDrag or \
			event is InputEventMouseButton or \
			event.is_action_pressed('ui_up') or \
			event.is_action_pressed('ui_down')):
		autoScrolling = false
		visibleTimer = 0

func _on_rich_text_label_scroller_text_label_scroll_changed() -> void:
	if autoScrolling:
		autoScrolling = false
		visibleTimer = 0
