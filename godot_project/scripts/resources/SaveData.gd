class_name SaveData
extends Resource

@export var save_version: int = 1
@export var level: int = 1
@export var current_xp: float = 0.0
@export var gold: float = 20.0
@export var skill_points: int = 0

@export var base_strength: int = 5
@export var base_agility: int = 5
@export var base_endurance: int = 5
@export var current_hp: float = 175.0
@export var current_mana: float = 55.0

@export var current_location_id: String = "quiet_glade"
@export var equipped_weapon_path: String = ""
@export var equipped_armor_path: String = ""
@export var equipped_ammo_path: String = ""
@export var equipped_ammo_count: int = 0
@export var inventory_paths: Array[String] = []
@export var inventory_counts: Array[int] = []
@export var unlocked_skills: Array[String] = []
@export var equipped_ability_ids: Array[String] = ["fireball", "nature_mend", "arcane_surge"]
@export var ability_auto_cast: Array[bool] = [false, false, false]
@export var auto_potion_enabled: bool = false
@export var enemies_defeated: int = 0
@export var kills_in_run: int = 0

@export var melee_level: int = 1
@export var melee_xp: float = 0.0
@export var ranged_level: int = 1
@export var ranged_xp: float = 0.0
@export var magic_level: int = 1
@export var magic_xp: float = 0.0

@export var difficulty_level: int = 1
@export var max_unlocked_difficulty: int = 1
@export var boss_defeated_this_run: bool = false
@export var dark_points: int = 0
@export var dark_points_claimed_difficulties: Array[int] = []
@export var unlocked_dark_skills: Array[String] = []
@export var difficulty_curses: Dictionary = {}
@export var total_runs_completed: int = 0
@export var weapon_enchant_level: int = 0
@export var armor_enchant_level: int = 0

@export var selected_class_id: String = "wanderer"
@export var curse_reroll_tokens: int = 0
@export var reroll_boss_kills_in_run: int = 0
@export var owned_pet_ids: Array[String] = []
@export var equipped_pet_id: String = ""

@export var garden_plots: Array[Dictionary] = []
@export var light_garden_plots: Array[Dictionary] = []
@export var brewing_slots: Array[Dictionary] = []
@export var alchemist_next_mistake_safe: bool = false
@export var pet_training_levels: Dictionary = {}
@export var spirit_training_levels: Dictionary = {"fire": 0, "wind": 0, "forest": 0, "earth": 0}

@export var dark_weapon_enchant_level: int = 0
@export var dark_armor_enchant_level: int = 0
@export var mine_locked_this_run: bool = false
@export var mine_depth: int = 0

@export var auto_hp_threshold_pct: int = 35
@export var auto_hp_condition: String = "combat"
@export var auto_mana_enabled: bool = false
@export var auto_mana_threshold_pct: int = 30
@export var auto_mana_condition: String = "combat"
@export var auto_buff_enabled: bool = false
@export var auto_buff_condition: String = "on_expire_combat"
@export var auto_buff_whitelist: Array[String] = []
