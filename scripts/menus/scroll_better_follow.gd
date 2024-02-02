extends ScrollContainer
class_name ScrollBetterFollow

@export var boxContainer: BoxContainer

func _viewport_focus_changed(control):
	print('fix focus')
	var controlPath: NodePath = get_path_to(control)
	if controlPath.get_name(0) == boxContainer.name and follow_focus:
		# if the control is in the path of the nested box container, fix the follow_focus scroll
		var panelPath = controlPath.get_name(0) + '/' + controlPath.get_name(1)
		var controlPanel: Control = get_node_or_null(panelPath)
		if boxContainer is VBoxContainer:
			if controlPanel != null:
				var scrollDist = controlPanel.position.y
				if scroll_vertical + size.y < scrollDist:
					scrollDist += controlPanel.size.y
				scroll_vertical = scrollDist
		else: # HBoxContainer
			if controlPanel != null:
				var scrollDist = controlPanel.position.x
				if scroll_horizontal + size.x < scrollDist:
					scrollDist += controlPanel.size.x
				scroll_horizontal = scrollDist

func _on_visibility_changed():
	if visible and !get_viewport().gui_focus_changed.is_connected(_viewport_focus_changed):
		get_viewport().gui_focus_changed.connect(_viewport_focus_changed)
	elif get_viewport().gui_focus_changed.is_connected(_viewport_focus_changed):
			get_viewport().gui_focus_changed.disconnect(_viewport_focus_changed)
