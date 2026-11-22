class_name CropData
extends Resource

@export var id: String = ""
@export var crop_name: String = ""
@export var icon_emoji: String = "🌱"
@export var rarity_label: String = "Обычное"
@export var garden_type: String = "dark"
@export_multiline var description: String = ""

@export var seed_item_path: String = ""
@export var harvest_item_path: String = ""

@export var base_drop_chance: float = 0.0005
@export var boss_drop_chance: float = 0.0
@export var final_boss_only: bool = false
@export var min_enemy_xp: float = 0.0

@export var grow_seconds: float = 120.0
@export var required_final_boss_kills: int = 0
@export var is_spirit_training_crop: bool = false
@export var instant_grow_feed_items: Dictionary = {}
@export var harvest_min: int = 1
@export var harvest_max: int = 2
@export var accent_color: Color = Color(0.45, 0.92, 0.58, 1.0)


func is_boss_kill_crop() -> bool:
	return required_final_boss_kills > 0


func is_light_crop() -> bool:
	return garden_type == "light"


func has_instant_grow_feed() -> bool:
	return not instant_grow_feed_items.is_empty()
