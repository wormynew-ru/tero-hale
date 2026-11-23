class_name SkillNodeData
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var icon_emoji: String = "⭐"
@export_multiline var description: String = ""
@export var grid_position: Vector2 = Vector2.ZERO
@export var prerequisites: Array[String] = []
@export var cost_skill_points: int = 1
@export var requires_alchemy: bool = false

@export_group("Bonus")
@export_enum(
	"strength",
	"agility",
	"endurance",
	"intellect",
	"crit_chance",
	"gold_mult",
	"xp_mult",
	"melee_dmg",
	"ranged_dmg",
	"spell_power",
	"mastery_xp_mult",
	"max_mana",
	"mana_regen",
	"flat_armor",
	"dodge_chance",
	"ammo_save",
	"mana_cost_red",
	"ability_cd_red",
	"garden_mastery",
	"alchemy_cauldron"
)
var bonus_type: String = "strength"
@export var bonus_value: float = 0.0


func get_bonus_summary() -> String:
	match bonus_type:
		"strength":
			return "+%d к Силе" % int(bonus_value)
		"agility":
			return "+%d к Ловкости" % int(bonus_value)
		"endurance":
			return "+%d к Выносливости" % int(bonus_value)
		"intellect":
			return "+%d к Инте" % int(bonus_value)
		"crit_chance":
			return "+%d%% к шансу крита" % roundi(bonus_value * 100.0)
		"gold_mult":
			return "+%d%% к добыче золота" % roundi(bonus_value * 100.0)
		"xp_mult":
			return "+%d%% к получаемому опыту" % roundi(bonus_value * 100.0)
		"melee_dmg":
			return "+%d%% к урону ближнего боя" % roundi(bonus_value * 100.0)
		"ranged_dmg":
			return "+%d%% к урону дальнего боя" % roundi(bonus_value * 100.0)
		"spell_power":
			return "+%d%% к силе заклинаний" % roundi(bonus_value * 100.0)
		"mastery_xp_mult":
			return "+%d%% к опыту навыков владения" % roundi(bonus_value * 100.0)
		"max_mana":
			return "+%d к макс. мане" % int(bonus_value)
		"mana_regen":
			return "+%.1f/с к регену маны" % bonus_value
		"flat_armor":
			return "+%d к плоской броне" % int(bonus_value)
		"dodge_chance":
			return "+%d%% к уклонению" % roundi(bonus_value * 100.0)
		"ammo_save":
			return "%d%% шанс не потратить снаряд" % roundi(bonus_value * 100.0)
		"mana_cost_red":
			return "-%d%% к стоимости маны заклинаний" % roundi(bonus_value * 100.0)
		"ability_cd_red":
			return "-%d%% к перезарядке способностей" % roundi(bonus_value * 100.0)
		"garden_mastery":
			return "+%d%% скорости роста сада и +1 грядка" % roundi(bonus_value * 100.0)
		"alchemy_cauldron":
			return "+1 котёл зельеварения и +%d%% мощи зелий" % roundi(bonus_value * 100.0)
	return ""
