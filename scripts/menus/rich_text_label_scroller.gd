extends Control
class_name RichTextLabelScroller

@export var label: RichTextLabel
@export var scrollLinesApprox: float = 1
@export var bailoutFocusControl: Control

@onready var scrollUpBtn: TextureButton = get_node('ScrollUpButton')
@onready var scrollDownBtn: TextureButton = get_node('ScrollDownButton')

func _process(delta: float) -> void:
	var enabled: bool = true
	if label != null and label.scroll_active:
		var labelScrollbar: VScrollBar = label.get_v_scroll_bar()
		if labelScrollbar != null and labelScrollbar.visible and labelScrollbar.max_value != labelScrollbar.min_value:
			if not visible:
				visible = true
				update_scroll_buttons()
		else:
			enabled = false
	else:
		enabled = false
	
	if not enabled and visible:
		if scrollUpBtn.has_focus() or scrollDownBtn.has_focus():
			if bailoutFocusControl != null:
				bailoutFocusControl.grab_focus()
			elif label.focus_mode == FocusMode.FOCUS_ALL:
				label.grab_focus()
		visible = false

func update_scroll_buttons() -> void:
	if label != null and label.scroll_active:
		var vScrollBar: VScrollBar = label.get_v_scroll_bar()
		if vScrollBar != null:
			scrollUpBtn.disabled = vScrollBar.value == vScrollBar.min_value
			scrollDownBtn.disabled = vScrollBar.value == vScrollBar.max_value - label.size.y
			#print(vScrollBar.value, ': ', vScrollBar.min_value, ' / ', vScrollBar.max_value)

func connect_scroll_up_top_neighbor(control: Control) -> void:
	if control != null:
		scrollUpBtn.focus_neighbor_top = scrollUpBtn.get_path_to(control)
		control.focus_neighbor_bottom = control.get_path_to(scrollUpBtn)
	else:
		scrollUpBtn.focus_neighbor_top = ''

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

func _on_scroll_up_button_pressed() -> void:
	var vScrollBar: VScrollBar = label.get_v_scroll_bar()
	if vScrollBar != null:
		var fontSize: int = label.get_theme_default_font_size()
		 # seems to scroll exactly half, so multiply by 2
		vScrollBar.value -= fontSize * label.scale.y * scrollLinesApprox * 2
	update_scroll_buttons()

func _on_scroll_down_button_pressed() -> void:
	var vScrollBar: VScrollBar = label.get_v_scroll_bar()
	if vScrollBar != null:
		var fontSize: int = label.get_theme_default_font_size()
		 # seems to scroll exactly half, so multiply by 2
		vScrollBar.value += fontSize * label.scale.y * scrollLinesApprox * 2
	update_scroll_buttons()
