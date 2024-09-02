extends ColorRect
class_name BattlefieldShade

@export var battleController: Node2D

var battlefieldShadeTween: Tween = null
var battlefieldShadeAnim: BattlefieldShadeAnim = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color = Color(0, 0, 0, 0)

## Default shade z-index. Sets shade below combatants by default, unless combatants are set to be explicitly below
func set_shade_above_combatants() -> void:
	z_index = 1

func set_shade_below_combatants() -> void:
	z_index = 0

func do_battlefield_shade_anim(shadeAnim: BattlefieldShadeAnim, callback: Callable = Callable()) -> void:
	if shadeAnim == null:
		if battlefieldShadeAnim != null:
			lift_battlefield_shade()
		return
	battlefieldShadeAnim = shadeAnim
	
	if shadeAnim.startSecs > 0:
		await get_tree().create_timer(shadeAnim.startSecs).timeout
	
	modulate_battlefield_shade_to(shadeAnim.color, shadeAnim.fadeInSecs, callback)
	
	if shadeAnim.lastsSecs > 0:
		await get_tree().create_timer(shadeAnim.lastsSecs).timeout
		lift_battlefield_shade()

func lift_battlefield_shade(callback: Callable = Callable()) -> void:
	if battlefieldShadeAnim != null:
		modulate_battlefield_shade_to(Color(0, 0, 0, 0), battlefieldShadeAnim.fadeOutSecs, callback)
		battlefieldShadeAnim = null
	else:
		await get_tree().process_frame
		battleController.battlefield_shade_finished_fading.emit() # nothing to do so it's already done

func modulate_battlefield_shade_to(shadeColor: Color, secs: float = 0.5, callback: Callable = Callable()):
	if battlefieldShadeTween != null and battlefieldShadeTween.is_valid():
		battlefieldShadeTween.kill()
	battlefieldShadeTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	battlefieldShadeTween.tween_property(self, 'color', shadeColor, secs)
	if callback != Callable():
		battlefieldShadeTween.finished.connect(callback)
	battlefieldShadeTween.finished.connect(_battlefield_shade_mod_finish)

func _battlefield_shade_mod_finish() -> void:
	battlefieldShadeTween = null
	# if the shade is going back to being invisible: reset combatants' z-indicess
	if color.a == 0:
		battleController.reset_all_combatants_shade_z_indices()
	battleController.battlefield_shade_finished_fading.emit()
