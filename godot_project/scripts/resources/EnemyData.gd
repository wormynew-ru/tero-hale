class_name EnemyData
extends Resource

@export var id: String = ""
@export var enemy_name: String = ""
@export var icon_emoji: String = "👾"
@export var max_hp: float = 40.0
@export var max_mana: float = 0.0
@export var attack_damage: float = 5.0
@export var agility: int = 4
@export var defense: float = 0.0
@export var xp_reward: int = 12
@export var gold_reward: int = 6
@export var spawn_weight: float = 1.0

@export_group("Loot Table")
@export var drop_items: Array[ItemData] = []
@export var drop_chances: Array[float] = []

@export_group("Visual")
@export var sprite_color: Color = Color(0.35, 0.8, 0.45, 1.0)


func get_attack_interval() -> float:
	return maxf(0.55, 2.5 / (1.0 + float(agility) * 0.08))
