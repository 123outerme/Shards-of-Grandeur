extends RichTextLabel
class_name CombatantEventText

signal event_text_completed

static var DAMAGE_COLOR: Color = Color(0.82, 0.365, 0.341) # color #d15d57
static var SUPER_EFFECTIVE_DAMAGE_COLOR: Color = Color(0.976, 0.729, 0.455) # color #f9ba74
static var HEAL_COLOR: Color = Color(0.443, 0.82, 0.394) # color #71d164

static var FADE_IN_SECS: float = 0.15
static var SCROLL_UP_SECS: float = 1.25
static var FADE_OUT_SECS: float = 0.25
static var SECS_UNTIL_FADE_OUT: float = 1

var eventTextTween: Tween = null

var eventCallable: Callable = Callable()
var callableCalled: bool = false

static func build_damage_text(damage: int, superEffective: bool = false) -> String:
	var isHealing: bool = false
	var prefix: String = '-'
	if damage < 0:
		isHealing = true
		damage *= -1
		prefix = '+'
	elif damage == 0:
		return ''
	
	var textColor: Color = HEAL_COLOR if isHealing else (SUPER_EFFECTIVE_DAMAGE_COLOR if superEffective else DAMAGE_COLOR)
	var dmgNumberText: String = TextUtils.num_to_comma_string(damage)
	if superEffective:
		dmgNumberText += '!'
	
	var dmgText: String = '[color=' + textColor.to_html() + ']' \
		+ prefix + dmgNumberText + '[/color]'
	return dmgText

static func build_status_get_text(status: StatusEffect) -> String:
	if status == null:
		return ''
	if status.type == StatusEffect.Type.NONE:
		return '[color=' + HEAL_COLOR.to_html() + ']Cured ' + StatusEffect.potency_to_string(status.potency) + ' Status[/color]'
	return 'Afflicted ' + status.status_effect_to_string()

static func build_stat_changes_texts(statChanges: StatChanges) -> Array[String]:
	if statChanges == null or not statChanges.has_stat_changes():
		return []
	var multiplierTexts: Array[StatMultiplierText] = statChanges.get_multipliers_text()
	var retValTexts: Array[String] = []
	for multText: StatMultiplierText in multiplierTexts:
		retValTexts.append(multText.print_multiplier())
	return retValTexts

func load_event_text(eventText: String, callable: Callable = Callable(), delay: float = 0, center: bool = true) -> void:
	if eventText == '':
		callableCalled = true
		event_text_completed.emit()
		queue_free()
		return
	
	eventCallable = callable
	if center:
		text = '[center]' + eventText + '[/center]'
	else:
		text = eventText
	modulate = Color(1, 1, 1, 0)
	eventTextTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	# fade in quickly and call the provided callable at the same time
	eventTextTween.tween_property(self, 'modulate', Color(1,1,1,1), CombatantEventText.FADE_IN_SECS).set_delay(delay)
	eventTextTween.set_parallel()
	eventTextTween.tween_callback(_call_event_callable)
	eventTextTween.set_parallel(false)
	# then, slide upwards, and at the same time, prepare to fade out partway through the slide upwards
	eventTextTween.tween_property(self, 'position', Vector2(0, -36), CombatantEventText.SCROLL_UP_SECS).as_relative()
	eventTextTween.set_parallel()
	eventTextTween.tween_property(self, 'modulate', Color(1,1,1,0), CombatantEventText.FADE_OUT_SECS).set_delay(CombatantEventText.SECS_UNTIL_FADE_OUT)
	# once finished, call the callback
	eventTextTween.finished.connect(_event_text_completed)
	
func destroy() -> void:
	_event_text_completed()

func _event_text_completed() -> void:
	if eventTextTween != null:
		eventTextTween.kill()
		eventTextTween = null
	event_text_completed.emit()
	queue_free()

func _call_event_callable() -> void:
	if eventCallable != Callable():
		eventCallable.call()
	callableCalled = true
