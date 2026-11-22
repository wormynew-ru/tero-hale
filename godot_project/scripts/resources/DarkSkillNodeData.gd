class_name DarkSkillNodeData
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var icon_emoji: String = "🌑"
@export var branch_name: String = "Основа"
@export_multiline var description: String = ""
@export var grid_position: Vector2 = Vector2.ZERO
@export var prerequisites: Array[String] = []
@export var cost_dark_points: int = 1
@export var requires_alchemy: bool = false

@export_group("Dark Effect")
@export_enum(
	"awakening_power",
	"vampirism",
	"echo_strike",
	"armor_rend",
	"dark_execution",
	"mana_fountain",
	"swift_runes",
	"spell_overload",
	"arcane_barrier",
	"titan_heritage",
	"blacksmith_brand",
	"abyssal_greed",
	"curse_ward",
	"berserk_fury",
	"immortal_pact",
	"shadow_quiver",
	"piercing_volley",
	"phantom_arrows",
	"deadeye_abyss",
	"wind_mastery_dark",
	"arcane_echo",
	"spirit_communion",
	"ancient_memory",
	"soul_harvest",
	"seed_drop_mult",
	"brew_speed_mult"
)
var effect_type: String = "awakening_power"
@export var effect_value: float = 0.0


func get_effect_summary() -> String:
	match effect_type:
		"awakening_power":
			return "+%d%% урона и +10%% к статам в новом ране" % roundi(effect_value * 100.0)
		"vampirism":
			return "Вампиризм %d%% от урона атак в HP" % roundi(effect_value * 100.0)
		"echo_strike":
			return "%d%% шанс мгновенной 2-й атаки (75%% урона)" % roundi(effect_value * 100.0)
		"armor_rend":
			return "Игнорирует %d%% плоской брони врагов" % roundi(effect_value * 100.0)
		"dark_execution":
			return "+%d%% урона по врагам с <30%% HP" % roundi(effect_value * 100.0)
		"mana_fountain":
			return "+60% регена маны и -20% манакоста"
		"swift_runes":
			return "-25% КД способностей и +35% силы магии"
		"spell_overload":
			return "%d%% шанс сбросить КД боевой магии" % roundi(effect_value * 100.0)
		"arcane_barrier":
			return "%d%% урона поглощается маной, 2x реген в отдыхе" % roundi(effect_value * 100.0)
		"titan_heritage":
			return "Старт рана: +1K золота и +5 ко всем статам"
		"blacksmith_brand":
			return "-25% цены заточки и +25% силы зачарований"
		"abyssal_greed":
			return "+100% золота и +50% опыта навсегда"
		"curse_ward":
			return "Ослабляет все проклятия сложности на %d%%" % roundi(effect_value * 100.0)
		"berserk_fury":
			return "До +%d%% урона при низком здоровье" % roundi(effect_value * 100.0)
		"immortal_pact":
			return "+%d%% Max HP и +2%% регена HP/с в бою" % roundi(effect_value * 100.0)
		"shadow_quiver":
			return "30%% шанс не потратить снаряд и +%d%% дальнего урона" % roundi(effect_value * 100.0)
		"piercing_volley":
			return "Криты пробивают 100%% брони и +%d%% к крит-множителю" % roundi(effect_value * 100.0)
		"phantom_arrows":
			return "%d%% шанс двойного выстрела дальним оружием" % roundi(effect_value * 100.0)
		"deadeye_abyss":
			return "+%d%% шанса крита и +40%% дальнего урона" % roundi(effect_value * 100.0)
		"wind_mastery_dark":
			return "Ускорение всех атак на +%d%% навсегда" % roundi(effect_value * 100.0)
		"arcane_echo":
			return "Магия добавляет +%d%% от текущей маны к урону" % roundi(effect_value * 100.0)
		"spirit_communion":
			return "+%d%% к мощи и скорости природных духов" % roundi(effect_value * 100.0)
		"ancient_memory":
			return "+%d%% опыта навыков владения и старт с 3-го уровня" % roundi(effect_value * 100.0)
		"soul_harvest":
			return "+5%% ко всему урону за каждые 100 побед в ране"
		"seed_drop_mult":
			return "+%d%% шанс выпадения редких семян с врагов навсегда" % roundi(effect_value * 100.0)
		"brew_speed_mult":
			return "+%d%% скорость варки зелий в Убежище навсегда" % roundi(effect_value * 100.0)
	return description
