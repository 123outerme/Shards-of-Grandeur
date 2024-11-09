extends Control
class_name BoxContainerScroller

signal scroll_buttons_updated

@export var scrollContainer: ScrollContainer
@export var scrollPx: int = 60
@export var bailoutFocusControl: Control

@onready var scrollUpBtn: TextureButton = get_node('ScrollUpButton')
@onready var scrollDownBtn: TextureButton = get_node('ScrollDownButton')
@onready var scrollLeftBtn: TextureButton = get_node('ScrollLeftButton')
@onready var scrollRightBtn: TextureButton = get_node('ScrollRightButton')

var vertical: bool = false

func _process(delta: float) -> void:
	var enabled: bool = true
	if scrollContainer != null:
		var vScrollbar: VScrollBar = scrollContainer.get_v_scroll_bar()
		var hScrollbar: HScrollBar = scrollContainer.get_h_scroll_bar()
		if vScrollbar != null and vScrollbar.visible and vScrollbar.max_value != vScrollbar.min_value:
			if not visible:
				visible = true
			update_scroll_buttons(true)
		elif hScrollbar != null and hScrollbar.visible and hScrollbar.max_value != hScrollbar.min_value:
			if not visible:
				visible = true
			update_scroll_buttons(false)
		else:
			enabled = false
	else:
		enabled = false
	
	if not enabled and visible:
		if scrollUpBtn.has_focus() or scrollDownBtn.has_focus() or scrollLeftBtn.has_focus() or scrollRightBtn.has_focus():
			if bailoutFocusControl != null:
				bailoutFocusControl.grab_focus()
		visible = false

func update_scroll_buttons(isVertical: bool) -> void:
	vertical = isVertical
	scrollUpBtn.visible = vertical
	scrollDownBtn.visible = vertical
	scrollLeftBtn.visible = not vertical
	scrollRightBtn.visible = not vertical
	if scrollContainer != null:
		if vertical:
			var vScrollBar: VScrollBar = scrollContainer.get_v_scroll_bar()
			if vScrollBar != null:
				scrollUpBtn.disabled = vScrollBar.value == vScrollBar.min_value
				scrollDownBtn.disabled = vScrollBar.value == vScrollBar.max_value - scrollContainer.size.y
			#print(vScrollBar.value, ': ', vScrollBar.min_value, ' / ', vScrollBar.max_value)
		else:
			var hScrollBar: HScrollBar = scrollContainer.get_h_scroll_bar()
			if hScrollBar != null:
				scrollLeftBtn.disabled = hScrollBar.value == hScrollBar.min_value
				scrollRightBtn.disabled = hScrollBar.value == hScrollBar.max_value - scrollContainer.size.x
		scroll_buttons_updated.emit()

func connect_scroll_up_top_neighbor(control: Control) -> void:
	if control != null:
		scrollUpBtn.focus_neighbor_top = scrollUpBtn.get_path_to(control)
		control.focus_neighbor_bottom = control.get_path_to(scrollUpBtn)
	else:
		scrollUpBtn.focus_neighbor_top = ''

func connect_scroll_up_bottom_neighbor(control: Control) -> void:
	if control != null:
		scrollUpBtn.focus_neighbor_bottom = scrollUpBtn.get_path_to(control)
		control.focus_neighbor_top = control.get_path_to(scrollUpBtn)
	else:
		scrollUpBtn.focus_neighbor_bottom = ''

func connect_scroll_up_left_neighbor(control: Control) -> void:
	if control != null:
		scrollUpBtn.focus_neighbor_left = scrollUpBtn.get_path_to(control)
		control.focus_neighbor_right = control.get_path_to(scrollUpBtn)
	else:
		scrollUpBtn.focus_neighbor_left = ''
		
func connect_scroll_up_right_neighbor(control: Control) -> void:
	if control != null:
		scrollUpBtn.focus_neighbor_right = scrollUpBtn.get_path_to(control)
		control.focus_neighbor_left = control.get_path_to(scrollUpBtn)
	else:
		scrollUpBtn.focus_neighbor_right = ''

func connect_scroll_down_top_neighbor(control: Control) -> void:
	if control != null:
		scrollDownBtn.focus_neighbor_top = scrollDownBtn.get_path_to(control)
		control.focus_neighbor_bottom = control.get_path_to(scrollDownBtn)
	else:
		scrollDownBtn.focus_neighbor_top = ''

func connect_scroll_down_bottom_neighbor(control: Control) -> void:
	if control != null:
		scrollDownBtn.focus_neighbor_bottom = scrollDownBtn.get_path_to(control)
		control.focus_neighbor_top = control.get_path_to(scrollDownBtn)
	else:
		scrollDownBtn.focus_neighbor_bottom = ''

func connect_scroll_down_left_neighbor(control: Control) -> void:
	if control != null:
		scrollDownBtn.focus_neighbor_left = scrollDownBtn.get_path_to(control)
		control.focus_neighbor_right = control.get_path_to(scrollDownBtn)
	else:
		scrollDownBtn.focus_neighbor_left = ''

func connect_scroll_down_right_neighbor(control: Control) -> void:
	if control != null:
		scrollDownBtn.focus_neighbor_right = scrollDownBtn.get_path_to(control)
		control.focus_neighbor_left = control.get_path_to(scrollDownBtn)
	else:
		scrollDownBtn.focus_neighbor_right = ''

func connect_scroll_left_top_neighbor(control: Control) -> void:
	if control != null:
		scrollLeftBtn.focus_neighbor_top = scrollLeftBtn.get_path_to(control)
		control.focus_neighbor_bottom = control.get_path_to(scrollLeftBtn)
	else:
		scrollLeftBtn.focus_neighbor_top = ''

func connect_scroll_left_left_neighbor(control: Control) -> void:
	if control != null:
		scrollLeftBtn.focus_neighbor_left = scrollLeftBtn.get_path_to(control)
		control.focus_neighbor_right = control.get_path_to(scrollLeftBtn)
	else:
		scrollLeftBtn.focus_neighbor_left = ''

func connect_scroll_left_right_neighbor(control: Control) -> void:
	if control != null:
		scrollLeftBtn.focus_neighbor_right = scrollLeftBtn.get_path_to(control)
		control.focus_neighbor_left = control.get_path_to(scrollLeftBtn)
	else:
		scrollLeftBtn.focus_neighbor_right = ''

func connect_scroll_left_bottom_neighbor(control: Control) -> void:
	if control != null:
		scrollLeftBtn.focus_neighbor_bottom = scrollLeftBtn.get_path_to(control)
		control.focus_neighbor_top = control.get_path_to(scrollLeftBtn)
	else:
		scrollLeftBtn.focus_neighbor_bottom = ''

func connect_scroll_right_bottom_neighbor(control: Control) -> void:
	if control != null:
		scrollRightBtn.focus_neighbor_bottom = scrollRightBtn.get_path_to(control)
		control.focus_neighbor_top = control.get_path_to(scrollRightBtn)
	else:
		scrollRightBtn.focus_neighbor_bottom = ''

func connect_scroll_right_top_neighbor(control: Control) -> void:
	if control != null:
		scrollRightBtn.focus_neighbor_top = scrollRightBtn.get_path_to(control)
		control.focus_neighbor_bottom = control.get_path_to(scrollRightBtn)
	else:
		scrollRightBtn.focus_neighbor_top = ''

func connect_scroll_right_right_neighbor(control: Control) -> void:
	if control != null:
		scrollRightBtn.focus_neighbor_right = scrollRightBtn.get_path_to(control)
		control.focus_neighbor_left = control.get_path_to(scrollRightBtn)
	else:
		scrollRightBtn.focus_neighbor_right = ''

func connect_scroll_right_left_neighbor(control: Control) -> void:
	if control != null:
		scrollRightBtn.focus_neighbor_left = scrollRightBtn.get_path_to(control)
		control.focus_neighbor_right = control.get_path_to(scrollRightBtn)
	else:
		scrollRightBtn.focus_neighbor_left = ''

func _on_scroll_up_button_pressed() -> void:
	if vertical:
		var vScrollBar: VScrollBar = scrollContainer.get_v_scroll_bar()
		if vScrollBar != null:
			vScrollBar.value -= scrollPx
	else:
		var hScrollBar: HScrollBar = scrollContainer.get_h_scroll_bar()
		if hScrollBar != null:
			hScrollBar.value -= scrollPx
	update_scroll_buttons(vertical)

func _on_scroll_down_button_pressed() -> void:
	if vertical:
		var vScrollBar: VScrollBar = scrollContainer.get_v_scroll_bar()
		if vScrollBar != null:
			vScrollBar.value += scrollPx
	else:
		var hScrollBar: HScrollBar = scrollContainer.get_h_scroll_bar()
		if hScrollBar != null:
			hScrollBar.value += scrollPx
	update_scroll_buttons(vertical)
