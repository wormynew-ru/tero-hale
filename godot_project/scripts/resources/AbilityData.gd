class_name AbilityData
extends Resource

const MAX_SPELL_LEVEL: int = 5

@export var id: String = ""
@export var title: String = ""
@export var icon_emoji: String = "✨"
@export_multiline var description: String = ""
@export var required_class_id: String = ""
@export var mana_cost: float = 15.0
@export var cooldown: float = 6.0
@export var effect_type: String = "damage" # "damage" | "pierce_damage" | "multi_hit" | "execute_damage" | "lifesteal_damage" | "blood_damage" | "blood_nova" | "heal" | "buff" | "dot" | "overcharge_burn"
@export var power_multiplier: float = 1.8

@export_group("Advanced Combat & Buffs")
@export var duration: float = 0.0
@export var hit_count: int = 1
@export var armor_ignore_pct: float = 0.5
@export var hp_sacrifice_pct: float = 0.0
@export var lifesteal_ratio: float = 0.0
@export var mana_restore_flat: float = 0.0

@export var buff_damage_pct: float = 0.0
@export var buff_attack_speed_pct: float = 0.0
@export var buff_armor_pct: float = 0.0
@export var buff_dodge_bonus: float = 0.0
@export var buff_crit_chance_bonus: float = 0.0
@export var buff_crit_mult_bonus: float = 0.0
@export var buff_spell_power_pct: float = 0.0
@export var buff_mana_regen_pct: float = 0.0
@export var buff_lifesteal_pct: float = 0.0
@export var buff_thorns_pct: float = 0.0


func get_display_name() -> String:
	return "%s %s" % [icon_emoji, title]


static func get_level_multiplier(spell_level: int) -> float:
	var clamped: int = clampi(spell_level, 1, MAX_SPELL_LEVEL)
	return 1.0 + float(clamped - 1) * 0.15

