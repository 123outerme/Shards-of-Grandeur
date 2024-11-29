extends Node2D
class_name TestOverworldEnemyTester

@onready var overworldEnemy: OverworldEnemy = get_node('OverworldEnemy')
@onready var walkStandToggle: Button = get_node('WalkStandToggle')

func _ready() -> void:
	if overworldEnemy.enemyData != null:
		overworldEnemy.position = Vector2.ZERO
		overworldEnemy.homePoint = overworldEnemy.enemyData.position
		overworldEnemy.enemySprite.play('walk')


func _on_reload_button_pressed() -> void:
	SignalBus.player_run_toggled.disconnect(overworldEnemy._player_running_changed)
	overworldEnemy._ready()
	overworldEnemy.position = Vector2.ZERO
	_on_walk_stand_toggle_toggled(walkStandToggle.button_pressed)

func _on_walk_stand_toggle_toggled(toggled_on: bool) -> void:
	overworldEnemy.enemySprite.play('stand' if toggled_on else 'walk')
	walkStandToggle.text = 'Stand' if toggled_on else 'Walk'
