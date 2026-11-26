class_name SanctuaryAndForgeCatalog
extends RefCounted

const PET_EXPEDITION_PLANS: Array[Dictionary] = [
	{"id": "short", "title": "🌿 Короткая (15 мин)", "duration": 900.0, "ore_chance": 0.45, "seed_rolls": 2},
	{"id": "long", "title": "🗺️ Долгая (1 час)", "duration": 3600.0, "ore_chance": 1.0, "seed_rolls": 5},
]

const CROP_PATHS: Array[String] = [
	"res://resources/crops/moon_mint.tres",
	"res://resources/crops/sun_root.tres",
	"res://resources/crops/azure_lotus.tres",
	"res://resources/crops/star_truffle.tres",
	"res://resources/crops/scarlet_petal.tres",
	"res://resources/crops/light_clover.tres",
	"res://resources/crops/honey_berry.tres",
	"res://resources/crops/sky_chamomile.tres",
	"res://resources/crops/spark_chili.tres",
	"res://resources/crops/spirit_primordial.tres",
]

const PET_LURE_RECIPES: Array[Dictionary] = [
	{"pet_id": "firework_spark", "pattern": ["spark_chili", "sky_chamomile", "spark_chili"]},
	{"pet_id": "healing_wisp", "pattern": ["light_clover", "sky_chamomile", "light_clover"]},
	{"pet_id": "abyss_mimic", "pattern": ["honey_berry", "light_clover", "honey_berry"]},
	{"pet_id": "ember_fox", "pattern": ["spark_chili", "honey_berry", "spark_chili"]},
	{"pet_id": "chrono_owl", "pattern": ["sky_chamomile", "sky_chamomile", "light_clover"]},
	{"pet_id": "thunder_griffin", "pattern": ["sky_chamomile", "spark_chili", "honey_berry"]},
]

const SPELL_RUNES_CATALOG: Dictionary = {
	"fireball": {
		"a": {"title": "🔥 Взрывное пламя", "desc": "+25% урона, +20% КД", "power_mult": 1.25, "cd_mult": 1.20, "cost_mult": 1.0},
		"b": {"title": "💨 Беглый огонь", "desc": "-30% манакоста, -20% КД", "power_mult": 0.95, "cd_mult": 0.80, "cost_mult": 0.70},
	},
	"nature_mend": {
		"a": {"title": "🌿 Глубокий корень", "desc": "+30% лечения, +25% манакоста", "power_mult": 1.30, "cd_mult": 1.0, "cost_mult": 1.25},
		"b": {"title": "🛡️ Барьерный росток", "desc": "+15% лечения +20% барьера", "power_mult": 1.15, "cd_mult": 0.90, "cost_mult": 1.0, "shield_barrier_pct": 0.20},
	},
	"arcane_surge": {
		"a": {"title": "✨ Перегрузка маны", "desc": "+25% длит. и силы баффа, +25% КД", "power_mult": 1.25, "cd_mult": 1.25, "cost_mult": 1.10, "duration_mult": 1.25},
		"b": {"title": "🪶 Экономичный поток", "desc": "-35% манакоста и -15% КД", "power_mult": 1.0, "cd_mult": 0.85, "cost_mult": 0.65},
	},
	"ice_lance": {
		"a": {"title": "❄️ Хрупкий лёд", "desc": "+20% шанса крита и +15% урона", "power_mult": 1.15, "cd_mult": 1.0, "cost_mult": 1.10, "crit_bonus": 0.20},
		"b": {"title": "🧊 Пронзающий осколок", "desc": "Ускоренный каст -25% КД", "power_mult": 1.0, "cd_mult": 0.75, "cost_mult": 0.85},
	},
	"chain_thunder": {
		"a": {"title": "⚡ Двойная дуга", "desc": "35% шанс повторного каста", "power_mult": 1.0, "cd_mult": 1.10, "cost_mult": 1.10, "double_cast_chance": 0.35},
		"b": {"title": "🌩️ Сверхток", "desc": "+30% урона молнией", "power_mult": 1.30, "cd_mult": 1.0, "cost_mult": 1.15},
	},
	"meteor_strike": {
		"a": {"title": "☄️ Массивный метеор", "desc": "+40% урона, +30% манакоста", "power_mult": 1.40, "cd_mult": 1.15, "cost_mult": 1.30},
		"b": {"title": "🌋 Пылающие обломки", "desc": "-25% КД и +15% урона", "power_mult": 1.15, "cd_mult": 0.75, "cost_mult": 1.0},
	},
	"poison_cloud": {
		"a": {"title": "☠️ Едкий яд", "desc": "+40% урона DoT, +20% длит.", "power_mult": 1.40, "cd_mult": 1.0, "cost_mult": 1.10, "duration_mult": 1.20},
		"b": {"title": "🧪 Дешёвые пары", "desc": "-35% манакоста, -20% КД", "power_mult": 1.05, "cd_mult": 0.80, "cost_mult": 0.65},
	},
	"soul_overload": {
		"a": {"title": "💥 Взрыв души", "desc": "+30% урона от маны", "power_mult": 1.30, "cd_mult": 1.10, "cost_mult": 1.0},
		"b": {"title": "🔮 Резонанс духа", "desc": "-25% КД, +15% крита", "power_mult": 1.05, "cd_mult": 0.75, "cost_mult": 0.90, "crit_bonus": 0.15},
	},
	"battle_frenzy": {
		"a": {"title": "💢 Ярость титана", "desc": "+35% силы баффа урона/скорости", "power_mult": 1.35, "cd_mult": 1.15, "cost_mult": 1.15, "duration_mult": 1.15},
		"b": {"title": "🩸 Боевой азарт", "desc": "-25% КД и -25% манакоста", "power_mult": 1.0, "cd_mult": 0.75, "cost_mult": 0.75},
	},
	"stone_aegis": {
		"a": {"title": "🛡️ Гранитная стена", "desc": "+30% длительности и +25% щита/барьера", "power_mult": 1.25, "cd_mult": 1.0, "cost_mult": 1.10, "duration_mult": 1.30, "shield_barrier_pct": 0.30},
		"b": {"title": "🪨 Рефлекс камня", "desc": "-30% КД, -20% манакоста", "power_mult": 1.0, "cd_mult": 0.70, "cost_mult": 0.80},
	},
	"eagle_focus": {
		"a": {"title": "🦅 Орлиный взор", "desc": "+30% баффа крита и точности", "power_mult": 1.30, "cd_mult": 1.0, "cost_mult": 1.10, "duration_mult": 1.20},
		"b": {"title": "🎯 Быстрый прицел", "desc": "-30% КД, -30% манакоста", "power_mult": 1.0, "cd_mult": 0.70, "cost_mult": 0.70},
	},
	"arcane_meditation": {
		"a": {"title": "🧘 Глубокий транс", "desc": "+35% длительности медитации", "power_mult": 1.20, "cd_mult": 1.0, "cost_mult": 0.90, "duration_mult": 1.35},
		"b": {"title": "💫 Ясный разум", "desc": "-30% КД и +15% силы", "power_mult": 1.15, "cd_mult": 0.70, "cost_mult": 0.80},
	},
	"mana_siphon": {
		"a": {"title": "🌀 Жадное поглощение", "desc": "+35% урона и вытяжки маны", "power_mult": 1.35, "cd_mult": 1.10, "cost_mult": 0.85},
		"b": {"title": "⚡ Сифон молнии", "desc": "-25% КД, 25% шанс двойного каста", "power_mult": 1.0, "cd_mult": 0.75, "cost_mult": 0.90, "double_cast_chance": 0.25},
	},
	"execute_sigil": {
		"a": {"title": "⚔️ Печать палача", "desc": "+35% казнящего урона", "power_mult": 1.35, "cd_mult": 1.15, "cost_mult": 1.15},
		"b": {"title": "💀 Быстрый приговор", "desc": "-25% КД, +15% шанса крита", "power_mult": 1.05, "cd_mult": 0.75, "cost_mult": 0.85, "crit_bonus": 0.15},
	},
	"arcane_cataclysm": {
		"a": {"title": "☄️ Аннигиляция", "desc": "+35% урона катаклизма", "power_mult": 1.35, "cd_mult": 1.15, "cost_mult": 1.15},
		"b": {"title": "🌀 Искажение времени", "desc": "-25% КД и -20% манакоста", "power_mult": 1.05, "cd_mult": 0.75, "cost_mult": 0.80},
	},
	"astral_tempest": {
		"a": {"title": "🌌 Звёздный вихрь", "desc": "30% шанс двойного шторма", "power_mult": 1.05, "cd_mult": 1.05, "cost_mult": 1.10, "double_cast_chance": 0.30},
		"b": {"title": "🌠 Плотный град", "desc": "+30% урона, -15% манакоста", "power_mult": 1.30, "cd_mult": 1.0, "cost_mult": 0.85},
	},
	"starfall_oblivion": {
		"a": {"title": "🌠 Забвение звёзд", "desc": "+40% урона, +20% крита", "power_mult": 1.40, "cd_mult": 1.20, "cost_mult": 1.15, "crit_bonus": 0.20},
		"b": {"title": "✨ Сияющий поток", "desc": "-25% КД и -25% манакоста", "power_mult": 1.0, "cd_mult": 0.75, "cost_mult": 0.75},
	},
	"sacred_revival": {
		"a": {"title": "💖 Свет спасения", "desc": "+35% лечения +30% барьера", "power_mult": 1.35, "cd_mult": 1.05, "cost_mult": 1.10, "shield_barrier_pct": 0.30},
		"b": {"title": "🕊️ Частая милость", "desc": "-30% КД и -25% манакоста", "power_mult": 1.0, "cd_mult": 0.70, "cost_mult": 0.75},
	},
	"archmage_ascension": {
		"a": {"title": "👑 Вознесение мага", "desc": "+30% длит. и +25% мощи баффа", "power_mult": 1.25, "cd_mult": 1.10, "cost_mult": 1.10, "duration_mult": 1.30},
		"b": {"title": "🧙 Поток архимага", "desc": "-25% КД, -30% манакоста", "power_mult": 1.05, "cd_mult": 0.75, "cost_mult": 0.70},
	},
	"crimson_lance": {
		"a": {"title": "🩸 Вампиризм копья", "desc": "+25% вампиризма от урона", "power_mult": 1.10, "cd_mult": 1.0, "cost_mult": 1.0, "lifesteal_bonus": 0.25},
		"b": {"title": "🗡️ Багровый натиск", "desc": "+30% урона, -15% КД", "power_mult": 1.30, "cd_mult": 0.85, "cost_mult": 1.10},
	},
	"hemorrhage_curse": {
		"a": {"title": "🩸 Глубокая рана", "desc": "+35% кровотечения, +25% длит.", "power_mult": 1.35, "cd_mult": 1.05, "cost_mult": 1.0, "duration_mult": 1.25},
		"b": {"title": "🥀 Быстрое проклятие", "desc": "-25% КД, -25% манакоста", "power_mult": 1.05, "cd_mult": 0.75, "cost_mult": 0.75},
	},
	"crimson_ward": {
		"a": {"title": "🛡️ Кровавый щит", "desc": "+25% эффекта и +30% барьера", "power_mult": 1.25, "cd_mult": 1.0, "cost_mult": 1.05, "duration_mult": 1.20, "shield_barrier_pct": 0.30},
		"b": {"title": "🩸 Очищение кровью", "desc": "-30% КД, -25% манакоста", "power_mult": 1.0, "cd_mult": 0.70, "cost_mult": 0.75},
	},
	"blood_frenzy": {
		"a": {"title": "🔥 Кровавое бешенство", "desc": "+35% баффа и +20% длит.", "power_mult": 1.35, "cd_mult": 1.10, "cost_mult": 1.10, "duration_mult": 1.20},
		"b": {"title": "⚡ Безудержная кровь", "desc": "-25% КД, -25% манакоста", "power_mult": 1.05, "cd_mult": 0.75, "cost_mult": 0.75},
	},
	"crimson_nova": {
		"a": {"title": "💥 Багровый взрыв", "desc": "+35% урона и 25% двойного каста", "power_mult": 1.35, "cd_mult": 1.15, "cost_mult": 1.15, "double_cast_chance": 0.25},
		"b": {"title": "🩸 Жатва крови", "desc": "+25% вампиризма, -20% КД", "power_mult": 1.10, "cd_mult": 0.80, "cost_mult": 0.90, "lifesteal_bonus": 0.25},
	},
	"sanguine_apotheosis": {
		"a": {"title": "🧛 Апофеоз вампира", "desc": "+30% силы и +25% длит.", "power_mult": 1.30, "cd_mult": 1.10, "cost_mult": 1.10, "duration_mult": 1.25},
		"b": {"title": "🩸 Дешевая жертва", "desc": "-25% КД и -30% манакоста", "power_mult": 1.05, "cd_mult": 0.75, "cost_mult": 0.70},
	},
	"crimson_apocalypse": {
		"a": {"title": "🌑 Конец времён", "desc": "+40% урона, +20% крита", "power_mult": 1.40, "cd_mult": 1.15, "cost_mult": 1.20, "crit_bonus": 0.20},
		"b": {"title": "🩸 Вечное эхо крови", "desc": "-25% КД, +20% вампиризма", "power_mult": 1.10, "cd_mult": 0.75, "cost_mult": 0.85, "lifesteal_bonus": 0.20},
	},
	"mirror_apotheosis": {
		"a": {"title": "🪞 Бесконечное зеркало", "desc": "+35% силы отражения и +25% длит.", "power_mult": 1.35, "cd_mult": 1.15, "cost_mult": 1.10, "duration_mult": 1.25},
		"b": {"title": "⚡ Быстрый отблеск", "desc": "-30% КД и -25% манакоста", "power_mult": 1.0, "cd_mult": 0.70, "cost_mult": 0.75},
	},
}

const BREW_STEP_TRANSITIONS: Dictionary = {
	"water": {
		"moon_mint_harvest": {"next_id": "base_mint", "title": "Лунный отвар (Шаг 1)", "emoji": "🌿", "duration": 10.0, "stage": 1, "can_collect": false, "result_item_path": "", "result_count": 0},
		"sun_root_harvest": {"next_id": "base_sun", "title": "Солнечная настойка (Шаг 1)", "emoji": "🥕", "duration": 10.0, "stage": 1, "can_collect": false, "result_item_path": "", "result_count": 0},
	},
	"base_mint": {
		"moon_mint_harvest": {"next_id": "moonlight_elixir", "title": "Лунный эликсир", "emoji": "🌙", "duration": 15.0, "stage": 2, "can_collect": true, "result_item_path": "res://resources/items/moonlight_elixir.tres", "result_count": 1},
		"azure_lotus_harvest": {"next_id": "arcane_nectar", "title": "Нектар арканы (x2)", "emoji": "🔮", "duration": 15.0, "stage": 2, "can_collect": true, "result_item_path": "res://resources/items/arcane_nectar.tres", "result_count": 2},
	},
	"base_sun": {
		"sun_root_harvest": {"next_id": "fury_potion", "title": "Зелье ярости (x2)", "emoji": "🩸", "duration": 15.0, "stage": 2, "can_collect": true, "result_item_path": "res://resources/items/fury_potion.tres", "result_count": 2},
		"azure_lotus_harvest": {"next_id": "swiftwind_potion", "title": "Зелье вихря (x2)", "emoji": "🌪️", "duration": 15.0, "stage": 2, "can_collect": true, "result_item_path": "res://resources/items/swiftwind_potion.tres", "result_count": 2},
	},
	"moonlight_elixir": {
		"star_truffle_harvest": {"next_id": "immortal_dew_potion", "title": "Роса бессмертия", "emoji": "🥛", "duration": 20.0, "stage": 3, "can_collect": true, "result_item_path": "res://resources/items/immortal_dew_potion.tres", "result_count": 1},
		"scarlet_petal_harvest": {"next_id": "crimson_petal_elixir", "title": "Эликсир Алого Лепестка", "emoji": "🌺", "duration": 20.0, "stage": 3, "can_collect": true, "result_item_path": "res://resources/items/crimson_petal_elixir.tres", "result_count": 1},
	},
	"arcane_nectar": {
		"star_truffle_harvest": {"next_id": "arcane_wisdom_potion", "title": "Эликсир мудрости (x2)", "emoji": "📜", "duration": 20.0, "stage": 3, "can_collect": true, "result_item_path": "res://resources/items/arcane_wisdom_potion.tres", "result_count": 2},
	},
	"fury_potion": {
		"star_truffle_harvest": {"next_id": "titan_blood_brew", "title": "Отвар крови титана", "emoji": "🔥", "duration": 20.0, "stage": 3, "can_collect": true, "result_item_path": "res://resources/items/titan_blood_brew.tres", "result_count": 1},
		"scarlet_petal_harvest": {"next_id": "crimson_petal_elixir", "title": "Эликсир Алого Лепестка", "emoji": "🌺", "duration": 20.0, "stage": 3, "can_collect": true, "result_item_path": "res://resources/items/crimson_petal_elixir.tres", "result_count": 1},
	},
	"swiftwind_potion": {
		"star_truffle_harvest": {"next_id": "ironhide_potion", "title": "Зелье железной кожи (x3)", "emoji": "🛡️", "duration": 20.0, "stage": 3, "can_collect": true, "result_item_path": "res://resources/items/ironhide_potion.tres", "result_count": 3},
	},
}
