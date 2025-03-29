extends Node2D
class_name TestOverworldEnemyTester

@onready var overworldEnemy: OverworldEnemy = get_node('OverworldEnemy')
@onready var walkStandToggle: Button = get_node('WalkStandToggle')
@onready var flipToggle: Button = get_node('FlipToggle')

var spriteFacesRight: bool = false

func _ready() -> void:
	if overworldEnemy.enemyData != null:
		overworldEnemy.position = Vector2.ZERO
		overworldEnemy.homePoint = overworldEnemy.enemyData.position
		overworldEnemy.enemySprite.play('walk')
		spriteFacesRight = overworldEnemy.combatant.get_sprite_obj().spriteFacesRight 
		update_flip_button()

func update_flip_button() -> void:
	flipToggle.text = 'Facing Right' if flipToggle.button_pressed != spriteFacesRight else 'Facing Left'

func _on_reload_button_pressed() -> void:
	SignalBus.player_run_toggled.disconnect(overworldEnemy._player_running_changed)
	overworldEnemy._ready()
	overworldEnemy.position = Vector2.ZERO
	_on_walk_stand_toggle_toggled(walkStandToggle.button_pressed)

func _on_walk_stand_toggle_toggled(toggled_on: bool) -> void:
	overworldEnemy.enemySprite.play('stand' if toggled_on else 'walk')
	walkStandToggle.text = 'Stand' if toggled_on else 'Walk'

func _on_flip_toggle_toggled(toggled_on: bool) -> void:
	update_flip_button()
	overworldEnemy.enemySprite.flip_h = toggled_on
	overworldEnemy.update_facing()
