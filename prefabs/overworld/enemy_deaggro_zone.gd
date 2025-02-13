extends Area2D
class_name EnemyDeaggroZone

## if true, will not stop enemies chasing the player once the enemy enters this zone
@export var disabled: bool = false

## If none of the listed StoryRequirements are valid, disables this de-aggro zone
@export var storyRequirements: Array[StoryRequirements] = []

func _ready() -> void:
	PlayerResources.story_requirements_updated.connect(_story_reqs_updated)
	_story_reqs_updated()

func _on_area_entered(area: Area2D) -> void:
	if area.name == 'EnemyEncounterCollider' and not disabled:
		var enemyNode: Node2D = area.get_parent()
		if enemyNode != null and enemyNode is OverworldEnemy:
			var enemy: OverworldEnemy = enemyNode as OverworldEnemy
			enemy.stop_chasing_player()

func _story_reqs_updated() -> void:
	disabled = not StoryRequirements.list_is_valid(storyRequirements)
