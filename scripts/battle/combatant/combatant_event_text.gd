extends RichTextLabel
class_name CombatantEventText

signal event_text_completed

static var DAMAGE_COLOR: Color = Color(0.82, 0.365, 0.341) # color #d15d57
static var HEAL_COLOR: Color = Color(0.443, 0.82, 0.394) # color #71d164

var eventTextTween: Tween = null

static func build_damage_text(damage: int) -> String:
	var isHealing: bool = false
	var prefix: String = '-'
	if damage < 0:
		isHealing = true
		damage *= -1
		prefix = '+'
	elif damage == 0:
		return ''
	
	var dmgText: String = '[color=' + \
		(HEAL_COLOR if isHealing else DAMAGE_COLOR).to_html() + \
		']' + prefix + TextUtils.num_to_comma_string(damage) + '[/color]'
	return dmgText

static func build_status_get_text(status: StatusEffect) -> String:
	if status == null:
		return ''
	if status.type == StatusEffect.Type.NONE:
		return 'Cured' + StatusEffect.potency_to_string(status.potency) + ' Status'
	return 'Afflicted ' + status.status_effect_to_string()

static func build_stat_changes_texts(statChanges: StatChanges) -> Array[String]:
	if statChanges == null or not statChanges.has_stat_changes():
		return []
	var multiplierTexts: Array[StatMultiplierText] = statChanges.get_multipliers_text()
	var retValTexts: Array[String] = []
	for multText: StatMultiplierText in multiplierTexts:
		retValTexts.append(multText.print_multiplier())
	return retValTexts

func load_event_text(eventText: String, delay: float = 0, center: bool = true) -> void:
	if eventText == '':
		event_text_completed.emit()
		queue_free()
		return
	
	if center:
		text = '[center]' + eventText + '[/center]'
	else:
		text = eventText
	modulate = Color(1, 1, 1, 0)
	eventTextTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	# fade in quickly
	eventTextTween.tween_property(self, 'modulate', Color(1,1,1,1), 0.15).set_delay(delay)
	# then, slide upwards, and at the same time, prepare to fade out partway through the slide upwards
	eventTextTween.tween_property(self, 'position', Vector2(0, -36), 1.25).as_relative()
	eventTextTween.set_parallel()
	eventTextTween.tween_property(self, 'modulate', Color(1,1,1,0), 0.25).set_delay(1)
	# once finished, call the callback
	eventTextTween.finished.connect(_event_text_completed)
	
func _event_text_completed() -> void:
	event_text_completed.emit()
	queue_free()
