extends ScrollContainer
class_name ScrollBetterFollow

## select the container that is the direct child of this one, to be tracked for scroll fixing
@export var boxContainer: BoxContainer

## if true, will scroll the list so the that the selected entry (beyond the end of the viewport) will be at the start of the container, instead of the bottom
@export var jumpToStartOnEndScroll: bool = false

func _viewport_focus_changed(control):
	#print('fix focus')
	var controlPath: NodePath = get_path_to(control)
	if follow_focus and controlPath.get_name(0) == boxContainer.name:
		# if the control is in the path of the nested box container, fix the follow_focus scroll
		var panelPath = controlPath.get_name(0) + '/' + controlPath.get_name(1)
		var controlPanel: Control = get_node_or_null(panelPath)
		if boxContainer is VBoxContainer:
			if controlPanel != null and \
				(controlPanel.position.y < scroll_vertical or \
				controlPanel.position.y + controlPanel.size.y > scroll_vertical + size.y):
				var scrollDist = controlPanel.position.y
				if scroll_vertical + size.y < scrollDist:
					scrollDist += controlPanel.size.y
				elif not jumpToStartOnEndScroll and controlPanel.position.y >= scroll_vertical:
					scrollDist = scroll_vertical + controlPanel.size.y
				scroll_vertical = scrollDist
		else: # HBoxContainer
			if controlPanel != null and \
				(controlPanel.position.x < scroll_horizontal or \
				controlPanel.position.x + controlPanel.size.x > scroll_horizontal + size.x):
				var scrollDist = controlPanel.position.x
				if scroll_horizontal + size.x < scrollDist:
					scrollDist += controlPanel.size.x
				elif not jumpToStartOnEndScroll and controlPanel.position.x >= scroll_horizontal:
					scrollDist = scroll_horizontal + controlPanel.size.x
				scroll_horizontal = scrollDist

func _on_visibility_changed():
	if visible and not get_viewport().gui_focus_changed.is_connected(_viewport_focus_changed):
		get_viewport().gui_focus_changed.connect(_viewport_focus_changed)
	elif get_viewport().gui_focus_changed.is_connected(_viewport_focus_changed):
		get_viewport().gui_focus_changed.disconnect(_viewport_focus_changed)
