extends Area2D
class_name EnemyDeaggroZone

@export var disabled: bool = false

func _on_area_entered(area: Area2D) -> void:
	if area.name == 'EnemyEncounterCollider' and not disabled:
		var enemyNode: Node2D = area.get_parent()
		if enemyNode != null and enemyNode is OverworldEnemy:
			var enemy: OverworldEnemy = enemyNode as OverworldEnemy
			enemy.stop_chasing_player()
