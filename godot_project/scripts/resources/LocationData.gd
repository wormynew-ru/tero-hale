class_name LocationData
extends Resource

@export var id: String = ""
@export var location_name: String = ""
@export var icon_emoji: String = "🗺️"
@export_multiline var description: String = ""
@export var required_level: int = 1
@export var required_difficulty: int = 1
@export var always_open_once_unlocked: bool = false
@export var is_one_attempt_mine: bool = false
@export var is_training_grounds: bool = false
@export var enemies: Array[EnemyData] = []
@export var background_color: Color = Color(0.12, 0.2, 0.14, 1.0)


func pick_random_enemy() -> EnemyData:
	if enemies.is_empty():
		return null

	var total_weight: float = 0.0
	for enemy: EnemyData in enemies:
		if enemy != null:
			total_weight += maxf(0.01, enemy.spawn_weight)

	if total_weight <= 0.0:
		return enemies[0]

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for enemy: EnemyData in enemies:
		if enemy == null:
			continue
		cumulative += maxf(0.01, enemy.spawn_weight)
		if roll <= cumulative:
			return enemy

	return enemies[enemies.size() - 1]
