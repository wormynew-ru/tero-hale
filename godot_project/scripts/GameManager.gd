extends Node

signal stats_changed
signal hp_changed(current_hp: float, max_hp: float)
signal mana_changed(current_mana: float, max_mana: float)
signal player_healed(amount: float)
signal inventory_changed
signal location_changed(location: LocationData)
signal level_up(new_level: int)
signal item_acquired(item: ItemData, amount: int)
signal save_status_changed(message: String)
signal skills_changed
signal dark_skills_changed
signal difficulty_changed
signal enchant_changed
signal final_boss_cleared(dark_points_gained: int, unlocked_difficulty: int)
signal curse_warden_defeated(tokens_total: int, kills_in_run: int)
signal mastery_changed(skill_id: String, new_level: int, leveled_up: bool)
signal class_changed(class_data: HeroClassData)
signal pets_changed
signal abilities_changed
signal buffs_changed
signal garden_changed
signal brewing_changed
signal afk_mode_changed(is_afk: bool)
signal afk_stats_updated(elapsed_seconds: float, kills: int, gold_earned: float, xp_earned: float)
signal dark_forge_changed
signal dark_shop_changed
signal mine_state_changed
signal mine_run_failed(depth_reached: int)
signal barrier_changed(current_barrier: float, max_barrier: float)
signal bestiary_changed
signal challenge_changed
signal loadouts_changed
signal wave_dungeon_changed
signal game_reset

const SAVE_PATH: String = "user://save.tres"
const SAVE_BACKUP_PATH: String = "user://save.bak.tres"
const SAVE_TEMP_PATH: String = "user://save.tmp.tres"
const SAVE_SCHEMA_VERSION: int = 1
const BASE_DAMAGE: float = 6.0
const BASE_CRIT_CHANCE: float = 0.05
const CRIT_MULTIPLIER: float = 1.75
const AUTOSAVE_INTERVAL: float = 480.0
const SAVE_THROTTLE_INTERVAL: float = 120.0
const NORMAL_FPS_LIMIT: int = 60
const DEFAULT_AFK_MAX_FPS: int = 20
const AFK_FPS_OPTIONS: Array[int] = [15, 20, 30, 60]
const AUTO_POTION_HP_THRESHOLD: float = 0.35
const MAX_ENCHANT_LEVEL: int = 100
const ALCHEMIST_MAX_ENCHANT_LEVEL: int = 250
const ALCHEMY_UNLOCK_DIFFICULTY: int = 10
const CLASSES_UNLOCK_DIFFICULTY: int = 50
const CRUCIBLE_UNLOCK_DIFFICULTY: int = 100
const BASE_GARDEN_PLOTS: int = 4
const BASE_LIGHT_GARDEN_PLOTS: int = 3
const BASE_BREWING_SLOTS: int = 2
const MAX_ACTIVE_ABILITY_SLOTS: int = 3
const MAX_PET_TRAINING_LEVEL: int = 10
const DEFAULT_EQUIPPED_ABILITIES: Array[String] = ["fireball", "nature_mend", "arcane_surge"]
const FINAL_BOSS_ID: String = "eternal_titan"
const FINAL_BOSS_LOCATION_ID: String = "celestial_throne"
const CURSE_WARDEN_ID: String = "curse_warden"
const SPIRIT_KEYS: Array[String] = ["fire", "wind", "forest", "earth"]
const SKILL_PRESET_COUNT: int = 3
const LOADOUT_COUNT: int = 3
const AUTO_SALVAGE_QUALITY_THRESHOLDS: Array[int] = [85, 95, 105, 115, 125]
const WELL_OF_GREED_COOLDOWN: float = 3600.0
const WAVE_DUNGEON_TOTAL_WAVES: int = 10
const MINE_CHECKPOINT_DEPTHS: Array[int] = [10, 25, 50]
const MINE_CHECKPOINT_COSTS: Dictionary = {10: 5, 25: 14, 50: 30}
const HP_THRESHOLD_PRESETS: Array[int] = [20, 35, 50, 70, 85]
const MANA_THRESHOLD_PRESETS: Array[int] = [15, 30, 50, 70]
const DIFFICULTY_RESET_DROP_CHANCE: float = 0.00001
const DIFFICULTY_RESET_ITEM_PATH: String = "res://resources/items/abyss_difficulty_reset_orb.tres"

const BESTIARY_MILESTONES: Array[Dictionary] = [
	{"kills": 100, "dmg_bonus": 0.02, "label": "I (100 уб.): +2% урона по виду"},
	{"kills": 1000, "dmg_bonus": 0.04, "label": "II (1000 уб.): +4% урона по виду +3% золота с вида"},
	{"kills": 10000, "dmg_bonus": 0.05, "label": "III (10000 уб.): +5% урона по виду +10% шанса дропа с вида"},
]

const CHALLENGE_CATALOG: Array[Dictionary] = [
	{
		"id": "no_potions_titan",
		"title": "🚱 Без зелий до Титана",
		"desc": "Зелья HP, MP и бафф-эликсиры заблокированы до победы над Вечным титаном.",
		"reward_desc": "+15% эффективности лечения способностей (навсегда)",
		"class_id": "alchemist",
	},
	{
		"id": "staff_master",
		"title": "🪄 Путь Арканы",
		"desc": "Разрешены только магические посохи и талисманы; мечи/луки/арбалеты заблокированы.",
		"reward_desc": "+12% силы заклинаний (навсегда)",
		"class_id": "blood_archmage",
	},
	{
		"id": "naked_ascetic",
		"title": "🧘 Испытание аскета",
		"desc": "Вся экипировка (оружие, броня, оффхенд, снаряды) запрещена на весь ран.",
		"reward_desc": "+10% ко всем 4 базовым статам (навсегда)",
		"class_id": "spirit",
	},
	{
		"id": "speedrun_titan",
		"title": "⏱️ Молниеносный Титан",
		"desc": "Одолейте Вечного титана менее чем за 300 секунд (5 минут) с начала рана.",
		"reward_desc": "+8% скорости атаки и -8% перезарядки чар (навсегда)",
		"class_id": "abyss_ranger",
	},
]

const SPELL_LEVEL_CAST_THRESHOLDS: Array[int] = [0, 25, 100, 300, 750]

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

const PET_EXPEDITION_PLANS: Array[Dictionary] = [
	{"id": "short", "title": "🌿 Короткая (15 мин)", "duration": 900.0, "ore_chance": 0.45, "seed_rolls": 2},
	{"id": "long", "title": "🗺️ Долгая (1 час)", "duration": 3600.0, "ore_chance": 1.0, "seed_rolls": 5},
]

const BUFF_POTION_CATALOG: Array[Dictionary] = [
	{"id": "fury_potion", "label": "💢 Ярость", "path": "res://resources/items/fury_potion.tres"},
	{"id": "ironhide_potion", "label": "🛡️ Каменная кожа", "path": "res://resources/items/ironhide_potion.tres"},
	{"id": "swiftwind_potion", "label": "💨 Вихрь", "path": "res://resources/items/swiftwind_potion.tres"},
	{"id": "arcane_wisdom_potion", "label": "🧠 Прозрение", "path": "res://resources/items/arcane_wisdom_potion.tres"},
	{"id": "titan_blood_brew", "label": "🔥 Кровь титана", "path": "res://resources/items/titan_blood_brew.tres"},
	{"id": "immortal_dew_potion", "label": "🥛 Роса бессмертия", "path": "res://resources/items/immortal_dew_potion.tres"},
	{"id": "crimson_petal_elixir", "label": "🌺 Алый лепесток", "path": "res://resources/items/crimson_petal_elixir.tres"},
	{"id": "void_berserk_draught", "label": "💥 Ярость Бездны", "path": "res://resources/items/void_berserk_draught.tres"},
	{"id": "abyss_archmage_elixir", "label": "🔮 Эликсир Архимага", "path": "res://resources/items/abyss_archmage_elixir.tres"},
	{"id": "titan_bastion_serum", "label": "🛡️ Бастион Титана", "path": "res://resources/items/titan_bastion_serum.tres"},
	{"id": "crimson_immortality_orb", "label": "🫀 Кровавая сфера", "path": "res://resources/items/crimson_immortality_orb.tres"},
	{"id": "cataclysm_apotheosis_flask", "label": "🌋 Апофеоз Бездны", "path": "res://resources/items/cataclysm_apotheosis_flask.tres"},
]

const DARK_FORGE_RECIPES: Array[Dictionary] = [
	{
		"id": "eternal_abyss_blade",
		"title": "🗡️ Вечный клинок Бездны",
		"desc": "Меч (+150 урон, +48 Силы, +10% крит). НЕ сбрасывается между ранами!",
		"dark_points": 3,
		"abyss_ore": 5,
		"ancient_page": 0,
		"result_path": "res://resources/items/eternal_abyss_blade.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "eternal_void_bow",
		"title": "🏹 Вечный лук Пустоты",
		"desc": "Лук (+125 урон, +52 Ловкости, +14% крит). НЕ сбрасывается между ранами!",
		"dark_points": 3,
		"abyss_ore": 5,
		"ancient_page": 1,
		"result_path": "res://resources/items/eternal_void_bow.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "eternal_astral_staff",
		"title": "🌟 Вечный посох Бездны",
		"desc": "Посох (+140 урон, +60 Инта, +65% чар, -15% манакост). НЕ сбрасывается!",
		"dark_points": 3,
		"abyss_ore": 4,
		"ancient_page": 4,
		"result_path": "res://resources/items/eternal_astral_staff.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "eternal_titan_plate",
		"title": "🛡️ Вечные латы Титана",
		"desc": "Броня (+82 Выносливость, +30 Сила, +24 Ловкость). НЕ сбрасывается!",
		"dark_points": 3,
		"abyss_ore": 6,
		"ancient_page": 0,
		"result_path": "res://resources/items/eternal_titan_plate.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "eternal_mage_archrobe",
		"title": "🧙 Вечное облачение Архимага",
		"desc": "Мантия (+55 Инта, +45% чар, -18% манакост, +25% длит.). НЕ сбрасывается!",
		"dark_points": 3,
		"abyss_ore": 3,
		"ancient_page": 5,
		"result_path": "res://resources/items/eternal_mage_archrobe.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "tome_eternal_codex",
		"title": "📖 Вечный фолиант Вечности",
		"desc": "БЕСКОНЕЧНАЯ книга-снаряд (+22 Инта, -20% манакост, +40% чары и длит.). Не тратится!",
		"dark_points": 4,
		"abyss_ore": 2,
		"ancient_page": 8,
		"result_path": "res://resources/items/tome_eternal_codex.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "craft_tome_archon",
		"title": "📓 Кодекс Архонта (x50)",
		"desc": "Сшить 50 зарядов книги-снаряда (Тип 1: +16 Инта, -22% манакост) из Древних листов.",
		"dark_points": 0,
		"abyss_ore": 0,
		"ancient_page": 3,
		"result_path": "res://resources/items/tome_archon_mind.tres",
		"amount": 50,
		"eternal": false,
	},
	{
		"id": "craft_tome_primordial",
		"title": "📙 Первозданный гримуар (x50)",
		"desc": "Сшить 50 зарядов книги-снаряда (Тип 2: +40% чары, +45% длит.) из Древних листов.",
		"dark_points": 0,
		"abyss_ore": 0,
		"ancient_page": 3,
		"result_path": "res://resources/items/tome_primordial_grimoire.tres",
		"amount": 50,
		"eternal": false,
	},
	{
		"id": "ultimate_cataclysm_reaver",
		"title": "⚔️ УЛЬТ: Вечный Рассекатель Катаклизма",
		"desc": "Сплав редкого дропа (+245 урон, +76 Сила, +14% крит). Нужны Клинок дракона + Астральный двуручник.",
		"dark_points": 6,
		"abyss_ore": 10,
		"ancient_page": 2,
		"required_items": {"dragonbone_blade": 1, "astral_greatsword": 1},
		"result_path": "res://resources/items/eternal_cataclysm_reaver.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "ultimate_eclipse_aegis",
		"title": "🛡️ УЛЬТ: Вечная Эгида Затмения",
		"desc": "Ультимативный щит (+950 Барьер, +8/Вын, +48 Вын). Нужны Доспех небесного стража + Эгида бастиона.",
		"dark_points": 6,
		"abyss_ore": 10,
		"ancient_page": 2,
		"required_items": {"celestial_aegis": 1, "aegis_bulwark_shield": 1},
		"result_path": "res://resources/items/eternal_eclipse_aegis.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "ultimate_archon_talisman",
		"title": "🧿 УЛЬТ: Вечный Гримуар Архонта",
		"desc": "Ультимативный талисман (+820 Барьер, +8.5/Инт, +46 Инт, +24% Чар). Нужны Скипетр лича + Астральный посох.",
		"dark_points": 6,
		"abyss_ore": 8,
		"ancient_page": 6,
		"required_items": {"lich_scepter": 1, "astral_staff": 1},
		"result_path": "res://resources/items/eternal_archon_talisman.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "ultimate_void_bastion_plate",
		"title": "🛡️ УЛЬТ: Вечная Броня Бастиона Пустоты",
		"desc": "Ультимативная броня (+160 Выносл., +48 Сила, +36 Ловк., +48 Броня). Нужны Панцирь Бездны + Доспех Небесного Стража.",
		"dark_points": 6,
		"abyss_ore": 10,
		"ancient_page": 2,
		"required_items": {"abyssal_carapace": 1, "celestial_aegis": 1},
		"result_path": "res://resources/items/eternal_void_bastion_plate.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "ultimate_abyss_bulwark",
		"title": "🔰 УЛЬТ: Вечный Оплот Бездны",
		"desc": "Ультимативный щит (+1850 Барьер, +12.5/Вын, +96 Вын, +58 Броня). Нужны Железный башенный щит + Эгида бастиона.",
		"dark_points": 6,
		"abyss_ore": 10,
		"ancient_page": 2,
		"required_items": {"iron_tower_shield": 1, "aegis_bulwark_shield": 1},
		"result_path": "res://resources/items/eternal_abyss_bulwark.tres",
		"amount": 1,
		"eternal": true,
	},
	{
		"id": "ultimate_bastion_greatsword",
		"title": "🗡️ УЛЬТ: Вечный Двуручный Бастион",
		"desc": "Ульт. двуручный меч защитника (+235 урон, +115 Выносл. HP, +52 Броня, +64 Сила). Нужны Трезубец Бездны + Астральный двуручник.",
		"dark_points": 6,
		"abyss_ore": 10,
		"ancient_page": 2,
		"required_items": {"trident_of_abyss": 1, "astral_greatsword": 1},
		"result_path": "res://resources/items/eternal_bastion_greatsword.tres",
		"amount": 1,
		"eternal": true,
	},
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
	{
		"pet_id": "firework_spark",
		"pattern": ["spark_chili", "sky_chamomile", "spark_chili"],
	},
	{
		"pet_id": "healing_wisp",
		"pattern": ["light_clover", "sky_chamomile", "light_clover"],
	},
	{
		"pet_id": "abyss_mimic",
		"pattern": ["honey_berry", "light_clover", "honey_berry"],
	},
	{
		"pet_id": "ember_fox",
		"pattern": ["spark_chili", "honey_berry", "spark_chili"],
	},
	{
		"pet_id": "chrono_owl",
		"pattern": ["sky_chamomile", "sky_chamomile", "light_clover"],
	},
	{
		"pet_id": "thunder_griffin",
		"pattern": ["sky_chamomile", "spark_chili", "honey_berry"],
	},
]

const BREW_STEP_TRANSITIONS: Dictionary = {
	"water": {
		"moon_mint_harvest": {
			"next_id": "base_mint",
			"title": "Лунный отвар (Шаг 1)",
			"emoji": "🌿",
			"duration": 10.0,
			"stage": 1,
			"can_collect": false,
			"result_item_path": "",
			"result_count": 0,
		},
		"sun_root_harvest": {
			"next_id": "base_sun",
			"title": "Солнечная настойка (Шаг 1)",
			"emoji": "🥕",
			"duration": 10.0,
			"stage": 1,
			"can_collect": false,
			"result_item_path": "",
			"result_count": 0,
		},
	},
	"base_mint": {
		"moon_mint_harvest": {
			"next_id": "moonlight_elixir",
			"title": "Лунный эликсир",
			"emoji": "🌙",
			"duration": 15.0,
			"stage": 2,
			"can_collect": true,
			"result_item_path": "res://resources/items/moonlight_elixir.tres",
			"result_count": 1,
		},
		"azure_lotus_harvest": {
			"next_id": "arcane_nectar",
			"title": "Нектар арканы (x2)",
			"emoji": "🔮",
			"duration": 15.0,
			"stage": 2,
			"can_collect": true,
			"result_item_path": "res://resources/items/arcane_nectar.tres",
			"result_count": 2,
		},
	},
	"base_sun": {
		"sun_root_harvest": {
			"next_id": "fury_potion",
			"title": "Зелье ярости (x2)",
			"emoji": "🩸",
			"duration": 15.0,
			"stage": 2,
			"can_collect": true,
			"result_item_path": "res://resources/items/fury_potion.tres",
			"result_count": 2,
		},
		"azure_lotus_harvest": {
			"next_id": "swiftwind_potion",
			"title": "Зелье вихря (x2)",
			"emoji": "🌪️",
			"duration": 15.0,
			"stage": 2,
			"can_collect": true,
			"result_item_path": "res://resources/items/swiftwind_potion.tres",
			"result_count": 2,
		},
	},
	"moonlight_elixir": {
		"star_truffle_harvest": {
			"next_id": "immortal_dew_potion",
			"title": "Роса бессмертия",
			"emoji": "🥛",
			"duration": 20.0,
			"stage": 3,
			"can_collect": true,
			"result_item_path": "res://resources/items/immortal_dew_potion.tres",
			"result_count": 1,
		},
		"scarlet_petal_harvest": {
			"next_id": "crimson_petal_elixir",
			"title": "Эликсир Алого Лепестка",
			"emoji": "🌺",
			"duration": 20.0,
			"stage": 3,
			"can_collect": true,
			"result_item_path": "res://resources/items/crimson_petal_elixir.tres",
			"result_count": 1,
		},
	},
	"arcane_nectar": {
		"star_truffle_harvest": {
			"next_id": "arcane_wisdom_potion",
			"title": "Эликсир мудрости (x2)",
			"emoji": "📜",
			"duration": 20.0,
			"stage": 3,
			"can_collect": true,
			"result_item_path": "res://resources/items/arcane_wisdom_potion.tres",
			"result_count": 2,
		},
	},
	"fury_potion": {
		"star_truffle_harvest": {
			"next_id": "titan_blood_brew",
			"title": "Отвар крови титана",
			"emoji": "🔥",
			"duration": 20.0,
			"stage": 3,
			"can_collect": true,
			"result_item_path": "res://resources/items/titan_blood_brew.tres",
			"result_count": 1,
		},
		"scarlet_petal_harvest": {
			"next_id": "crimson_petal_elixir",
			"title": "Эликсир Алого Лепестка",
			"emoji": "🌺",
			"duration": 20.0,
			"stage": 3,
			"can_collect": true,
			"result_item_path": "res://resources/items/crimson_petal_elixir.tres",
			"result_count": 1,
		},
	},
	"swiftwind_potion": {
		"star_truffle_harvest": {
			"next_id": "ironhide_potion",
			"title": "Зелье железной кожи (x3)",
			"emoji": "🛡️",
			"duration": 20.0,
			"stage": 3,
			"can_collect": true,
			"result_item_path": "res://resources/items/ironhide_potion.tres",
			"result_count": 3,
		},
	},
}

const STARTER_POTION_PATH: String = "res://resources/items/small_healing_potion.tres"
const LOCATION_PATHS: Array[String] = [
	"res://resources/locations/quiet_glade.tres",
	"res://resources/locations/dark_forest.tres",
	"res://resources/locations/abandoned_mine.tres",
	"res://resources/locations/ancient_ruins.tres",
	"res://resources/locations/swamp_marshes.tres",
	"res://resources/locations/frost_peaks.tres",
	"res://resources/locations/obsidian_citadel.tres",
	"res://resources/locations/dragon_lair.tres",
	"res://resources/locations/sunken_temple.tres",
	"res://resources/locations/astral_spire.tres",
	"res://resources/locations/celestial_throne.tres",
	"res://resources/locations/abyss_crucible.tres",
]
const SHOP_ITEM_PATHS: Array[String] = [
	"res://resources/items/small_healing_potion.tres",
	"res://resources/items/medium_healing_potion.tres",
	"res://resources/items/large_healing_potion.tres",
	"res://resources/items/elixir_of_life.tres",
	"res://resources/items/divine_nectar.tres",
	"res://resources/items/ambrosia_flask.tres",
	"res://resources/items/small_mana_potion.tres",
	"res://resources/items/medium_mana_potion.tres",
	"res://resources/items/large_mana_potion.tres",
	"res://resources/items/arcane_nectar.tres",
	"res://resources/items/fury_potion.tres",
	"res://resources/items/ironhide_potion.tres",
	"res://resources/items/arcane_wisdom_potion.tres",
	"res://resources/items/swiftwind_potion.tres",
	"res://resources/items/wooden_sword.tres",
	"res://resources/items/apprentice_staff.tres",
	"res://resources/items/crystal_wand.tres",
	"res://resources/items/wooden_bow.tres",
	"res://resources/items/wooden_arrows.tres",
	"res://resources/items/tome_intellect_flow.tres",
	"res://resources/items/tome_spell_amplify.tres",
	"res://resources/items/leather_jacket.tres",
	"res://resources/items/mage_robe.tres",
	"res://resources/items/hunter_dagger.tres",
	"res://resources/items/iron_sword.tres",
	"res://resources/items/iron_crossbow.tres",
	"res://resources/items/iron_bolts.tres",
	"res://resources/items/chainmail_armor.tres",
	"res://resources/items/elven_longbow.tres",
	"res://resources/items/steel_arrows.tres",
	"res://resources/items/mithril_bolts.tres",
	"res://resources/items/tome_archon_mind.tres",
	"res://resources/items/tome_primordial_grimoire.tres",
	"res://resources/items/dragon_crossbow.tres",
	"res://resources/items/astral_arrows.tres",
	"res://resources/items/abyss_bolts.tres",
	"res://resources/items/astral_bow.tres",
	"res://resources/items/wooden_buckler.tres",
	"res://resources/items/apprentice_talisman.tres",
]
const DARK_SHOP_ITEM_PATHS: Array[String] = [
	"res://resources/items/dark_ambrosia_vial.tres",
	"res://resources/items/void_berserk_draught.tres",
	"res://resources/items/abyss_archmage_elixir.tres",
	"res://resources/items/titan_bastion_serum.tres",
	"res://resources/items/crimson_immortality_orb.tres",
	"res://resources/items/cataclysm_apotheosis_flask.tres",
]
const SKILL_PATHS: Array[String] = [
	"res://resources/skills/hero_foundation.tres",
	"res://resources/skills/heavy_strike.tres",
	"res://resources/skills/melee_practice.tres",
	"res://resources/skills/deadly_precision.tres",
	"res://resources/skills/titan_might.tres",
	"res://resources/skills/executioner_focus.tres",
	"res://resources/skills/colossus_wrath.tres",
	"res://resources/skills/apex_predator.tres",
	"res://resources/skills/swift_reflexes.tres",
	"res://resources/skills/wind_step.tres",
	"res://resources/skills/eagle_eye.tres",
	"res://resources/skills/lightning_tempo.tres",
	"res://resources/skills/quiver_conservation.tres",
	"res://resources/skills/phantom_stride.tres",
	"res://resources/skills/wind_archer_mastery.tres",
	"res://resources/skills/arcane_spark.tres",
	"res://resources/skills/spell_weaving.tres",
	"res://resources/skills/mana_flow.tres",
	"res://resources/skills/archmage_focus.tres",
	"res://resources/skills/elemental_mastery.tres",
	"res://resources/skills/quick_learning.tres",
	"res://resources/skills/iron_bastion.tres",
	"res://resources/skills/thick_hide.tres",
	"res://resources/skills/vital_surge.tres",
	"res://resources/skills/herbal_mastery.tres",
	"res://resources/skills/master_brewer.tres",
	"res://resources/skills/immortal_vessel.tres",
	"res://resources/skills/guardian_aegis.tres",
	"res://resources/skills/treasure_hunter.tres",
	"res://resources/skills/golden_greed.tres",
	"res://resources/skills/midas_blessing.tres",
	"res://resources/skills/battle_scholar.tres",
	"res://resources/skills/ancient_wisdom.tres",
	"res://resources/skills/cosmic_enlightenment.tres",
	"res://resources/skills/arcane_mind.tres",
	"res://resources/skills/sage_insight.tres",
	"res://resources/skills/astral_conduit.tres",
	"res://resources/skills/spell_cataclysm.tres",
	"res://resources/skills/archmage_reserve.tres",
	"res://resources/skills/warlord_brutality.tres",
	"res://resources/skills/berserker_edge.tres",
	"res://resources/skills/wind_grace.tres",
	"res://resources/skills/titan_endurance_node.tres",
	"res://resources/skills/eternal_aegis_node.tres",
]
const DARK_SKILL_PATHS: Array[String] = [
	"res://resources/dark_skills/abyss_awakening.tres",
	"res://resources/dark_skills/blood_vampirism.tres",
	"res://resources/dark_skills/echo_strike.tres",
	"res://resources/dark_skills/armor_rend.tres",
	"res://resources/dark_skills/dark_execution.tres",
	"res://resources/dark_skills/berserk_fury.tres",
	"res://resources/dark_skills/immortal_pact.tres",
	"res://resources/dark_skills/shadow_quiver.tres",
	"res://resources/dark_skills/piercing_volley.tres",
	"res://resources/dark_skills/phantom_arrows.tres",
	"res://resources/dark_skills/deadeye_abyss.tres",
	"res://resources/dark_skills/wind_mastery_dark.tres",
	"res://resources/dark_skills/mana_fountain.tres",
	"res://resources/dark_skills/swift_runes.tres",
	"res://resources/dark_skills/spell_overload.tres",
	"res://resources/dark_skills/arcane_barrier.tres",
	"res://resources/dark_skills/arcane_echo.tres",
	"res://resources/dark_skills/spirit_communion.tres",
	"res://resources/dark_skills/titan_heritage.tres",
	"res://resources/dark_skills/blacksmith_brand.tres",
	"res://resources/dark_skills/abyssal_greed.tres",
	"res://resources/dark_skills/abyss_botanist.tres",
	"res://resources/dark_skills/eternal_cauldron.tres",
	"res://resources/dark_skills/curse_ward.tres",
	"res://resources/dark_skills/ancient_memory.tres",
	"res://resources/dark_skills/soul_harvest.tres",
	"res://resources/dark_skills/abyssal_vitality.tres",
	"res://resources/dark_skills/void_plating.tres",
	"res://resources/dark_skills/mirror_carapace.tres",
	"res://resources/dark_skills/obsidian_bulwark.tres",
	"res://resources/dark_skills/thorn_apotheosis.tres",
]
const ABILITY_PATHS: Array[String] = [
	"res://resources/abilities/fireball.tres",
	"res://resources/abilities/nature_mend.tres",
	"res://resources/abilities/arcane_surge.tres",
	"res://resources/abilities/ice_lance.tres",
	"res://resources/abilities/chain_thunder.tres",
	"res://resources/abilities/meteor_strike.tres",
	"res://resources/abilities/poison_cloud.tres",
	"res://resources/abilities/soul_overload.tres",
	"res://resources/abilities/battle_frenzy.tres",
	"res://resources/abilities/stone_aegis.tres",
	"res://resources/abilities/eagle_focus.tres",
	"res://resources/abilities/arcane_meditation.tres",
	"res://resources/abilities/mana_siphon.tres",
	"res://resources/abilities/execute_sigil.tres",
	"res://resources/abilities/arcane_cataclysm.tres",
	"res://resources/abilities/astral_tempest.tres",
	"res://resources/abilities/starfall_oblivion.tres",
	"res://resources/abilities/sacred_revival.tres",
	"res://resources/abilities/archmage_ascension.tres",
	"res://resources/abilities/crimson_lance.tres",
	"res://resources/abilities/hemorrhage_curse.tres",
	"res://resources/abilities/crimson_ward.tres",
	"res://resources/abilities/blood_frenzy.tres",
	"res://resources/abilities/crimson_nova.tres",
	"res://resources/abilities/sanguine_apotheosis.tres",
	"res://resources/abilities/crimson_apocalypse.tres",
	"res://resources/abilities/mirror_apotheosis.tres",
]
const CLASS_PATHS: Array[String] = [
	"res://resources/classes/wanderer.tres",
	"res://resources/classes/alchemist.tres",
	"res://resources/classes/troll.tres",
	"res://resources/classes/spirit.tres",
	"res://resources/classes/abyss_ranger.tres",
	"res://resources/classes/blood_archmage.tres",
	"res://resources/classes/reflector.tres",
]
const PET_PATHS: Array[String] = [
	"res://resources/pets/firework_spark.tres",
	"res://resources/pets/healing_wisp.tres",
	"res://resources/pets/abyss_mimic.tres",
	"res://resources/pets/ember_fox.tres",
	"res://resources/pets/chrono_owl.tres",
	"res://resources/pets/thunder_griffin.tres",
]
const ENEMY_PATHS: Array[String] = [
	"res://resources/enemies/slime.tres",
	"res://resources/enemies/wolf.tres",
	"res://resources/enemies/goblin.tres",
	"res://resources/enemies/bandit.tres",
	"res://resources/enemies/skeleton.tres",
	"res://resources/enemies/bog_toad.tres",
	"res://resources/enemies/swamp_witch.tres",
	"res://resources/enemies/rock_golem.tres",
	"res://resources/enemies/crystal_spider.tres",
	"res://resources/enemies/mine_kobold.tres",
	"res://resources/enemies/mine_overseer.tres",
	"res://resources/enemies/orc_warlord.tres",
	"res://resources/enemies/dark_mage.tres",
	"res://resources/enemies/ice_golem.tres",
	"res://resources/enemies/frost_wyvern.tres",
	"res://resources/enemies/ember_knight.tres",
	"res://resources/enemies/fire_elemental.tres",
	"res://resources/enemies/ancient_dragon.tres",
	"res://resources/enemies/abyssal_naga.tres",
	"res://resources/enemies/krakens_spawn.tres",
	"res://resources/enemies/astral_archon.tres",
	"res://resources/enemies/void_stalker.tres",
	"res://resources/enemies/shadow_lich.tres",
	"res://resources/enemies/fallen_seraph.tres",
	"res://resources/enemies/curse_warden.tres",
	"res://resources/enemies/eternal_titan.tres",
]

const CURSE_CATALOG: Array[Dictionary] = [
	{
		"id": "rot",
		"title": "☠️ Гниение",
		"base_value": 0.01,
		"desc_fmt": "Герой теряет %.1f%% Max HP каждую секунду в бою",
	},
	{
		"id": "clumsy_hands",
		"title": "🧤 Кривые руки",
		"base_value": 0.30,
		"desc_fmt": "Стоимость маны всех способностей +%d%%",
	},
	{
		"id": "lead_shackles",
		"title": "⛓️ Свинцовые оковы",
		"base_value": 0.25,
		"desc_fmt": "Скорость атаки героя замедлена на %d%%",
	},
	{
		"id": "brittle_armor",
		"title": "🩸 Хрупкая броня",
		"base_value": 0.40,
		"desc_fmt": "Плоская броня героя снижена на %d%%",
	},
	{
		"id": "stone_skin",
		"title": "🪨 Каменная кожа",
		"base_value": 0.35,
		"desc_fmt": "Плоская броня врагов выше на +%d%%",
	},
	{
		"id": "mana_burn",
		"title": "🕯️ Истощение маны",
		"base_value": 0.45,
		"desc_fmt": "Регенерация маны героя снижена на %d%%",
	},
	{
		"id": "blood_tax",
		"title": "🩹 Кровавая дань",
		"base_value": 0.25,
		"desc_fmt": "Урон врагов +%d%%, а лечение слабее на %d%%",
	},
	{
		"id": "greedy_curse",
		"title": "🕸️ Алчность бездны",
		"base_value": 0.50,
		"desc_fmt": "Цены в лавке и стоимость заточки выше на +%d%%",
	},
	{
		"id": "abyss_frenzy",
		"title": "⚡ Бешенство бездны",
		"base_value": 0.25,
		"desc_fmt": "Скорость атаки врагов быстрее на %d%%",
	},
	{
		"id": "dull_edge",
		"title": "🌑 Тупое лезвие",
		"base_value": 0.12,
		"desc_fmt": "Шанс крита -%d%%, крит. урон слабее",
	},
]

var level: int = 1
var current_xp: float = 0.0
var gold: float = 20.0
var skill_points: int = 1
var enemies_defeated: int = 0
var kills_in_run: int = 0

var base_strength: int = 5
var base_agility: int = 5
var base_endurance: int = 5
var base_intellect: int = 5
var current_hp: float = 400.0
var current_mana: float = 285.0

var melee_level: int = 1
var melee_xp: float = 0.0
var ranged_level: int = 1
var ranged_xp: float = 0.0
var magic_level: int = 1
var magic_xp: float = 0.0

var equipped_weapon: ItemData = null
var equipped_weapon_quality: int = 100
var equipped_weapon_stars: int = 1
var equipped_armor: ItemData = null
var equipped_armor_quality: int = 100
var equipped_armor_stars: int = 1
var equipped_offhand: ItemData = null
var equipped_offhand_quality: int = 100
var equipped_offhand_stars: int = 1
var equipped_ammo: ItemData = null
var equipped_ammo_count: int = 0
var weapon_enchant_level: int = 0
var armor_enchant_level: int = 0
var offhand_enchant_level: int = 0
var inventory: Array[Dictionary] = []
var auto_salvage_mode: String = "off" # "off" | "sell" | "salvage"
var auto_salvage_min_quality: int = 95
var abyss_ore_shards: int = 0

var locations: Array[LocationData] = []
var current_location: LocationData = null
var shop_items: Array[ItemData] = []
var dark_shop_items: Array[ItemData] = []

var skill_nodes: Array[SkillNodeData] = []
var _skills_by_id: Dictionary = {}
var unlocked_skills: Array[String] = []
var skill_presets: Array[Dictionary] = []
var active_skill_preset_index: int = 0
var skill_auto_upgrade_enabled: bool = false

var dark_skill_nodes: Array[DarkSkillNodeData] = []
var _dark_skills_by_id: Dictionary = {}
var dark_points: int = 0
var dark_shop_coins: int = 0
var dark_points_claimed_difficulties: Array[int] = []
var unlocked_dark_skills: Array[String] = []

var hero_classes: Array[HeroClassData] = []
var _classes_by_id: Dictionary = {}
var selected_class_id: String = "wanderer"
var reflector_kill_hp_stacks: int = 0

var all_pets: Array[PetData] = []
var _pets_by_id: Dictionary = {}
var owned_pet_ids: Array[String] = []
var equipped_pet_id: String = ""

var difficulty_level: int = 1
var max_unlocked_difficulty: int = 1
var boss_defeated_this_run: bool = false
var difficulty_curses: Dictionary = {}
var total_runs_completed: int = 0
var curse_reroll_tokens: int = 0
var reroll_boss_kills_in_run: int = 0

var all_abilities: Array[AbilityData] = []
var _abilities_by_id: Dictionary = {}
var equipped_ability_ids: Array[String] = ["fireball", "nature_mend", "arcane_surge"]
var abilities: Array[AbilityData] = []
var ability_cooldowns: Array[float] = [0.0, 0.0, 0.0]
var ability_auto_cast: Array[bool] = [false, false, false]
var ability_casts: Dictionary = {}
var ability_levels: Dictionary = {}
var ability_runes: Dictionary = {}
var active_buffs: Array[Dictionary] = []

var auto_potion_enabled: bool = false
var auto_hp_threshold_pct: int = 35
var auto_hp_condition: String = "combat"
var auto_mana_enabled: bool = false
var auto_mana_threshold_pct: int = 30
var auto_mana_condition: String = "combat"
var auto_buff_enabled: bool = false
var auto_buff_condition: String = "on_expire_combat"
var auto_buff_whitelist: Array[String] = []

var dark_weapon_enchant_level: int = 0
var dark_armor_enchant_level: int = 0
var dark_offhand_enchant_level: int = 0
var mine_locked_this_run: bool = false
var mine_depth: int = 0
var unlocked_mine_checkpoints: Array[int] = []
var mine_start_depth: int = 1

var is_afk_mode: bool = false
var afk_target_fps: int = DEFAULT_AFK_MAX_FPS
var is_menu_open: bool = false
var afk_elapsed_seconds: float = 0.0
var afk_kills: int = 0
var afk_gold_earned: float = 0.0
var afk_xp_earned: float = 0.0

var current_barrier: float = 0.0
var bestiary_kills: Dictionary = {}
var active_challenge_id: String = ""
var completed_challenges: Array[String] = []
var run_elapsed_seconds: float = 0.0
var combat_loadouts: Array[Dictionary] = []
var auto_route_enabled: bool = false
var auto_route_wins_threshold: int = 5
var consecutive_location_wins: int = 0
var well_greed_cooldown_remaining: float = 0.0
var well_run_blessing: String = ""
var pet_expeditions: Array[Dictionary] = []
var wave_dungeon_active: bool = false
var wave_dungeon_wave: int = 0
var wave_dungeon_clears: int = 0
var _wave_dungeon_return_location_id: String = ""

var crops: Array[CropData] = []
var _crops_by_id: Dictionary = {}
var garden_plots: Array[Dictionary] = []
var light_garden_plots: Array[Dictionary] = []
var brewing_slots: Array[Dictionary] = []
var alchemist_next_mistake_safe: bool = false
var pet_training_levels: Dictionary = {}
var spirit_training_levels: Dictionary = {"fire": 0, "wind": 0, "forest": 0, "earth": 0}

var _autosave_timer: float = 0.0
var _afk_ui_sync_timer: float = 0.0
var _buff_ui_sync_timer: float = 0.0
var _sanctuary_ui_sync_timer: float = 0.0
var _hp_mp_ui_sync_timer: float = 0.0
var _ability_ui_sync_timer: float = 0.0
var _hp_ui_dirty: bool = false
var _mana_ui_dirty: bool = false
var _abilities_ui_dirty: bool = false
var _save_throttle_timer: float = 0.0
var _save_pending: bool = false

var _save_thread: Thread = null
var _save_in_progress: bool = false
var _save_queued_after_worker: bool = false

var _item_path_cache: Dictionary = {}
var _unlocked_skill_set: Dictionary = {}
var _unlocked_dark_skill_set: Dictionary = {}
var _skill_bonus_cache: Dictionary = {}
var _dark_bonus_cache: Dictionary = {}
var _curse_value_cache: Dictionary = {}
var _active_curses_cache: Array[Dictionary] = []
var _progression_caches_dirty: bool = true
var _cached_curse_difficulty: int = -1
var _stats_cache: Dictionary = {}
var _stats_cache_dirty: bool = true


var all_enemies: Array[EnemyData] = []
var _enemies_by_id: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_locations()
	_load_enemies()
	_load_shop_items()
	_load_dark_shop_items()
	_load_skills()
	_load_dark_skills()
	_load_abilities()
	_load_classes()
	_load_pets()
	_load_crops()
	if not load_game():
		_init_full_reset_state()
	_ensure_sanctuary_slots()
	ensure_skill_presets()
	_ensure_loadouts()
	ensure_curses_for_difficulty(difficulty_level)
	_invalidate_progression_caches()
	Engine.max_fps = NORMAL_FPS_LIMIT
	DisplayServer.screen_set_keep_on(false)
	_emit_all_refresh_signals()


func _exit_tree() -> void:
	_wait_for_save_thread()


func _process(delta: float) -> void:
	if _save_throttle_timer > 0.0:
		_save_throttle_timer = maxf(0.0, _save_throttle_timer - delta)
		if _save_throttle_timer <= 0.0 and _save_pending:
			save_game(false)

	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		_save_throttle_timer = 0.0
		save_game(false)

	var max_mana: float = get_max_mana()
	if current_mana < max_mana:
		restore_mana(get_mana_regen_per_sec() * delta, false)

	var cd_speed_mult: float = 1.0 + get_pet_effect_value("cooldown_haste")
	var cd_changed: bool = false
	var cd_finished_any: bool = false
	for i: int in range(ability_cooldowns.size()):
		if ability_cooldowns[i] > 0.0:
			ability_cooldowns[i] = maxf(0.0, ability_cooldowns[i] - delta * cd_speed_mult)
			cd_changed = true
			if ability_cooldowns[i] <= 0.0:
				cd_finished_any = true
	if cd_changed:
		_abilities_ui_dirty = true

	_hp_mp_ui_sync_timer += delta
	if _hp_mp_ui_sync_timer >= 0.1:
		_hp_mp_ui_sync_timer = 0.0
		if _hp_ui_dirty:
			_hp_ui_dirty = false
			hp_changed.emit(current_hp, get_max_hp())
		if _mana_ui_dirty:
			_mana_ui_dirty = false
			mana_changed.emit(current_mana, get_max_mana())

	_ability_ui_sync_timer += delta
	if _abilities_ui_dirty and (cd_finished_any or _ability_ui_sync_timer >= 0.1):
		_ability_ui_sync_timer = 0.0
		_abilities_ui_dirty = false
		abilities_changed.emit()

	run_elapsed_seconds += delta
	if well_greed_cooldown_remaining > 0.0:
		well_greed_cooldown_remaining = maxf(0.0, well_greed_cooldown_remaining - delta)

	if not active_buffs.is_empty():
		var expired_any: bool = false
		for i: int in range(active_buffs.size() - 1, -1, -1):
			active_buffs[i]["remaining"] = float(active_buffs[i]["remaining"]) - delta
			if float(active_buffs[i]["remaining"]) <= 0.0:
				active_buffs.remove_at(i)
				expired_any = true
		_buff_ui_sync_timer += delta
		if expired_any:
			_buff_ui_sync_timer = 0.0
			mark_stats_dirty()
			buffs_changed.emit()
			stats_changed.emit()
		elif _buff_ui_sync_timer >= 0.25:
			_buff_ui_sync_timer = 0.0
			buffs_changed.emit()

	_process_sanctuary(delta)

	if is_afk_mode:
		afk_elapsed_seconds += delta
		_afk_ui_sync_timer += delta
		if _afk_ui_sync_timer >= 0.5:
			_afk_ui_sync_timer = 0.0
			afk_stats_updated.emit(afk_elapsed_seconds, afk_kills, afk_gold_earned, afk_xp_earned)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		DisplayServer.screen_set_keep_on(false)
		save_game(true)
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		save_game(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		save_game(true)


func _emit_all_refresh_signals() -> void:
	stats_changed.emit()
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())
	inventory_changed.emit()
	skills_changed.emit()
	dark_skills_changed.emit()
	difficulty_changed.emit()
	enchant_changed.emit()
	abilities_changed.emit()
	buffs_changed.emit()
	class_changed.emit(get_current_class())
	pets_changed.emit()
	garden_changed.emit()
	brewing_changed.emit()
	dark_forge_changed.emit()
	dark_shop_changed.emit()
	mine_state_changed.emit()
	barrier_changed.emit(current_barrier, get_max_barrier())
	bestiary_changed.emit()
	challenge_changed.emit()
	loadouts_changed.emit()
	wave_dungeon_changed.emit()
	mastery_changed.emit("melee", melee_level, false)
	mastery_changed.emit("ranged", ranged_level, false)
	mastery_changed.emit("magic", magic_level, false)
	if current_location != null:
		location_changed.emit(current_location)


func _load_locations() -> void:
	locations.clear()
	for path: String in LOCATION_PATHS:
		var loc: LocationData = load(path) as LocationData
		if loc != null:
			locations.append(loc)


func _load_enemies() -> void:
	all_enemies.clear()
	_enemies_by_id.clear()
	for path: String in ENEMY_PATHS:
		var enemy: EnemyData = load(path) as EnemyData
		if enemy != null and not enemy.id.is_empty():
			all_enemies.append(enemy)
			_enemies_by_id[enemy.id] = enemy


func _load_shop_items() -> void:
	shop_items.clear()
	for path: String in SHOP_ITEM_PATHS:
		var item: ItemData = load(path) as ItemData
		if item != null:
			shop_items.append(item)


func _load_dark_shop_items() -> void:
	dark_shop_items.clear()
	for path: String in DARK_SHOP_ITEM_PATHS:
		var item: ItemData = load(path) as ItemData
		if item != null:
			dark_shop_items.append(item)


func _load_skills() -> void:
	skill_nodes.clear()
	_skills_by_id.clear()
	for path: String in SKILL_PATHS:
		var skill: SkillNodeData = load(path) as SkillNodeData
		if skill != null and not skill.id.is_empty():
			skill_nodes.append(skill)
			_skills_by_id[skill.id] = skill


func _load_dark_skills() -> void:
	dark_skill_nodes.clear()
	_dark_skills_by_id.clear()
	for path: String in DARK_SKILL_PATHS:
		var dskill: DarkSkillNodeData = load(path) as DarkSkillNodeData
		if dskill != null and not dskill.id.is_empty():
			dark_skill_nodes.append(dskill)
			_dark_skills_by_id[dskill.id] = dskill


func _load_abilities() -> void:
	all_abilities.clear()
	_abilities_by_id.clear()
	for path: String in ABILITY_PATHS:
		var ability: AbilityData = load(path) as AbilityData
		if ability != null and not ability.id.is_empty():
			all_abilities.append(ability)
			_abilities_by_id[ability.id] = ability
	_sync_equipped_abilities()
	ability_cooldowns.resize(MAX_ACTIVE_ABILITY_SLOTS)
	ability_auto_cast.resize(MAX_ACTIVE_ABILITY_SLOTS)
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		ability_cooldowns[i] = 0.0
		ability_auto_cast[i] = false


func _load_classes() -> void:
	hero_classes.clear()
	_classes_by_id.clear()
	for path: String in CLASS_PATHS:
		var hclass: HeroClassData = load(path) as HeroClassData
		if hclass != null and not hclass.id.is_empty():
			hero_classes.append(hclass)
			_classes_by_id[hclass.id] = hclass


func _load_pets() -> void:
	all_pets.clear()
	_pets_by_id.clear()
	for path: String in PET_PATHS:
		var pet: PetData = load(path) as PetData
		if pet != null and not pet.id.is_empty():
			all_pets.append(pet)
			_pets_by_id[pet.id] = pet


func _load_crops() -> void:
	crops.clear()
	_crops_by_id.clear()
	for path: String in CROP_PATHS:
		var crop: CropData = load(path) as CropData
		if crop != null and not crop.id.is_empty():
			crops.append(crop)
			_crops_by_id[crop.id] = crop


func get_cached_item(path: String) -> ItemData:
	if path.is_empty():
		return null
	if _item_path_cache.has(path):
		return _item_path_cache[path] as ItemData
	if not ResourceLoader.exists(path):
		return null
	var item: ItemData = load(path) as ItemData
	if item != null:
		_item_path_cache[path] = item
	return item


func mark_stats_dirty() -> void:
	_stats_cache_dirty = true
	_stats_cache.clear()


func set_menu_open(open: bool) -> void:
	is_menu_open = open


func set_afk_fps_limit(fps: int) -> void:
	if fps != 15 and fps != 20 and fps != 30 and fps != 60:
		return
	afk_target_fps = fps
	if is_afk_mode:
		Engine.max_fps = afk_target_fps
	afk_stats_updated.emit(afk_elapsed_seconds, afk_kills, afk_gold_earned, afk_xp_earned)
	save_game()


func _invalidate_progression_caches() -> void:
	_progression_caches_dirty = true
	mark_stats_dirty()


func _ensure_progression_caches() -> void:
	if not _progression_caches_dirty and _cached_curse_difficulty == difficulty_level:
		return
	_progression_caches_dirty = false
	_cached_curse_difficulty = difficulty_level

	_unlocked_skill_set.clear()
	_skill_bonus_cache.clear()
	for skill_id: String in unlocked_skills:
		_unlocked_skill_set[skill_id] = true
		var skill: SkillNodeData = get_skill_by_id(skill_id)
		if skill != null and not skill.bonus_type.is_empty():
			_skill_bonus_cache[skill.bonus_type] = float(_skill_bonus_cache.get(skill.bonus_type, 0.0)) + skill.bonus_value

	_unlocked_dark_skill_set.clear()
	_dark_bonus_cache.clear()
	for dskill_id: String in unlocked_dark_skills:
		_unlocked_dark_skill_set[dskill_id] = true
		var dskill: DarkSkillNodeData = get_dark_skill_by_id(dskill_id)
		if dskill != null and not dskill.effect_type.is_empty():
			_dark_bonus_cache[dskill.effect_type] = float(_dark_bonus_cache.get(dskill.effect_type, 0.0)) + dskill.effect_value

	_curse_value_cache.clear()
	_active_curses_cache.clear()
	var max_tier: int = floori(float(difficulty_level) / 10.0) * 10
	if max_tier >= 10:
		ensure_curses_for_difficulty(difficulty_level)
		var atten: float = 0.6 if _unlocked_dark_skill_set.has("curse_ward") else 1.0
		for tier: int in range(10, max_tier + 1, 10):
			var cid: String = str(difficulty_curses.get(tier, ""))
			var def: Dictionary = _get_curse_definition(cid)
			if def.is_empty():
				continue
			var eff_val: float = float(def["base_value"]) * atten
			_active_curses_cache.append({
				"tier": tier,
				"id": cid,
				"title": str(def["title"]),
				"value": eff_val,
				"description": format_curse_description(def, eff_val),
			})
			_curse_value_cache[cid] = float(_curse_value_cache.get(cid, 0.0)) + eff_val


func _init_full_reset_state() -> void:
	difficulty_level = 1
	max_unlocked_difficulty = 1
	afk_target_fps = DEFAULT_AFK_MAX_FPS
	dark_points = 0
	dark_shop_coins = 0
	dark_points_claimed_difficulties.clear()
	unlocked_dark_skills.clear()
	difficulty_curses.clear()
	total_runs_completed = 0
	curse_reroll_tokens = 0
	selected_class_id = "wanderer"
	reflector_kill_hp_stacks = 0
	owned_pet_ids.clear()
	equipped_pet_id = ""
	pet_expeditions.clear()
	auto_potion_enabled = false
	auto_hp_threshold_pct = 35
	auto_hp_condition = "combat"
	auto_mana_enabled = false
	auto_mana_threshold_pct = 30
	auto_mana_condition = "combat"
	auto_buff_enabled = false
	auto_buff_condition = "on_expire_combat"
	auto_buff_whitelist.clear()
	auto_salvage_mode = "off"
	auto_salvage_min_quality = 95
	abyss_ore_shards = 0
	dark_weapon_enchant_level = 0
	dark_armor_enchant_level = 0
	dark_offhand_enchant_level = 0
	mine_locked_this_run = false
	mine_depth = 0
	unlocked_mine_checkpoints.clear()
	mine_start_depth = 1
	equipped_weapon = null
	equipped_weapon_quality = 100
	equipped_weapon_stars = 1
	equipped_armor = null
	equipped_armor_quality = 100
	equipped_armor_stars = 1
	equipped_offhand = null
	equipped_offhand_quality = 100
	equipped_offhand_stars = 1
	equipped_ammo = null
	equipped_ammo_count = 0
	inventory.clear()
	enemies_defeated = 0
	bestiary_kills.clear()
	active_challenge_id = ""
	completed_challenges.clear()
	run_elapsed_seconds = 0.0
	combat_loadouts.clear()
	auto_route_enabled = false
	auto_route_wins_threshold = 5
	consecutive_location_wins = 0
	well_greed_cooldown_remaining = 0.0
	well_run_blessing = ""
	wave_dungeon_active = false
	wave_dungeon_wave = 0
	wave_dungeon_clears = 0
	_wave_dungeon_return_location_id = ""
	garden_plots.clear()
	light_garden_plots.clear()
	brewing_slots.clear()
	alchemist_next_mistake_safe = false
	pet_training_levels.clear()
	spirit_training_levels = {"fire": 0, "wind": 0, "forest": 0, "earth": 0}
	equipped_ability_ids = DEFAULT_EQUIPPED_ABILITIES.duplicate()
	ability_casts.clear()
	ability_levels.clear()
	ability_runes.clear()
	_sync_equipped_abilities()
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		ability_auto_cast[i] = false
	skill_presets.clear()
	active_skill_preset_index = 0
	skill_auto_upgrade_enabled = false
	ensure_skill_presets()
	_ensure_loadouts()
	_invalidate_progression_caches()
	_init_run_state(1, "")
	_ensure_sanctuary_slots()


func _init_run_state(target_difficulty: int, challenge_id: String = "") -> void:
	difficulty_level = clampi(target_difficulty, 1, maxi(1, max_unlocked_difficulty))
	ensure_curses_for_difficulty(difficulty_level)
	active_challenge_id = challenge_id if not get_challenge_def(challenge_id).is_empty() else ""
	run_elapsed_seconds = 0.0
	consecutive_location_wins = 0
	well_greed_cooldown_remaining = 0.0
	well_run_blessing = ""
	wave_dungeon_active = false
	wave_dungeon_wave = 0
	_wave_dungeon_return_location_id = ""
	_invalidate_progression_caches()

	level = 1
	current_xp = 0.0
	skill_points = 1
	boss_defeated_this_run = false
	reroll_boss_kills_in_run = 0
	kills_in_run = 0
	mine_locked_this_run = false
	mine_depth = 0

	var start_mastery_lvl: int = 3 if has_dark_skill("ancient_memory") else 1
	melee_level = start_mastery_lvl
	melee_xp = 0.0
	ranged_level = start_mastery_lvl
	ranged_xp = 0.0
	magic_level = start_mastery_lvl
	magic_xp = 0.0

	var base_start: int = 5
	if has_dark_skill("abyss_awakening"):
		base_start += 1
	if has_dark_skill("titan_heritage"):
		base_start += 5

	base_strength = base_start
	base_agility = base_start
	base_endurance = base_start
	base_intellect = base_start

	var start_gold: float = 20.0
	if has_dark_skill("titan_heritage"):
		start_gold += 1000.0 * get_difficulty_gold_mult()
	gold = start_gold

	var preserved_garden_items: Array[Dictionary] = []
	for entry: Dictionary in inventory:
		var existing_item: ItemData = entry["item"] as ItemData
		var existing_cnt: int = int(entry["count"])
		if existing_item != null and existing_cnt > 0 and (
			existing_item.item_type == ItemData.ItemType.SEED
			or existing_item.item_type == ItemData.ItemType.HARVEST
			or existing_item.item_type == ItemData.ItemType.MATERIAL
			or existing_item.is_dark_forged
		):
			preserved_garden_items.append({
				"item": existing_item,
				"count": existing_cnt,
				"quality_pct": int(entry.get("quality_pct", 100)),
				"star_level": int(entry.get("star_level", 1)),
			})

	var gear_blocked: bool = is_gear_blocked_by_challenge() or is_equipment_disabled()
	var preserved_weapon: ItemData = equipped_weapon if (equipped_weapon != null and equipped_weapon.is_dark_forged) else null
	var preserved_weapon_q: int = equipped_weapon_quality
	var preserved_weapon_s: int = equipped_weapon_stars
	var preserved_armor: ItemData = equipped_armor if (equipped_armor != null and equipped_armor.is_dark_forged) else null
	var preserved_armor_q: int = equipped_armor_quality
	var preserved_armor_s: int = equipped_armor_stars
	var preserved_offhand: ItemData = equipped_offhand if (equipped_offhand != null and equipped_offhand.is_dark_forged) else null
	var preserved_offhand_q: int = equipped_offhand_quality
	var preserved_offhand_s: int = equipped_offhand_stars
	var preserved_ammo: ItemData = equipped_ammo if (equipped_ammo != null and equipped_ammo.is_dark_forged) else null
	var preserved_ammo_cnt: int = equipped_ammo_count if preserved_ammo != null else 0

	equipped_weapon = null
	equipped_weapon_quality = 100
	equipped_weapon_stars = 1
	equipped_armor = null
	equipped_armor_quality = 100
	equipped_armor_stars = 1
	equipped_offhand = null
	equipped_offhand_quality = 100
	equipped_offhand_stars = 1
	equipped_ammo = null
	equipped_ammo_count = 0

	if not gear_blocked:
		if preserved_weapon != null:
			if is_non_staff_blocked_by_challenge() and not preserved_weapon.is_mage_staff():
				preserved_garden_items.append({"item": preserved_weapon, "count": 1, "quality_pct": preserved_weapon_q, "star_level": preserved_weapon_s})
			else:
				equipped_weapon = preserved_weapon
				equipped_weapon_quality = preserved_weapon_q
				equipped_weapon_stars = preserved_weapon_s
		if preserved_armor != null:
			equipped_armor = preserved_armor
			equipped_armor_quality = preserved_armor_q
			equipped_armor_stars = preserved_armor_s
		if preserved_offhand != null:
			if is_non_staff_blocked_by_challenge() and preserved_offhand.offhand_kind != ItemData.OffhandKind.TALISMAN:
				preserved_garden_items.append({"item": preserved_offhand, "count": 1, "quality_pct": preserved_offhand_q, "star_level": preserved_offhand_s})
			else:
				equipped_offhand = preserved_offhand
				equipped_offhand_quality = preserved_offhand_q
				equipped_offhand_stars = preserved_offhand_s
		if preserved_ammo != null:
			if is_non_staff_blocked_by_challenge() and preserved_ammo.ammo_kind != ItemData.AmmoKind.TOME:
				preserved_garden_items.append({"item": preserved_ammo, "count": maxi(1, preserved_ammo_cnt), "quality_pct": 100, "star_level": 1})
			else:
				equipped_ammo = preserved_ammo
				equipped_ammo_count = maxi(1, preserved_ammo_cnt)
	else:
		if preserved_weapon != null:
			preserved_garden_items.append({"item": preserved_weapon, "count": 1, "quality_pct": preserved_weapon_q, "star_level": preserved_weapon_s})
		if preserved_armor != null:
			preserved_garden_items.append({"item": preserved_armor, "count": 1, "quality_pct": preserved_armor_q, "star_level": preserved_armor_s})
		if preserved_offhand != null:
			preserved_garden_items.append({"item": preserved_offhand, "count": 1, "quality_pct": preserved_offhand_q, "star_level": preserved_offhand_s})
		if preserved_ammo != null:
			preserved_garden_items.append({"item": preserved_ammo, "count": maxi(1, preserved_ammo_cnt), "quality_pct": 100, "star_level": 1})

	weapon_enchant_level = 0
	armor_enchant_level = 0
	offhand_enchant_level = 0
	inventory.clear()
	unlocked_skills.clear()
	_invalidate_progression_caches()
	active_buffs.clear()
	_validate_equipped_abilities_for_class()
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		ability_cooldowns[i] = 0.0

	var starter_potion: ItemData = get_cached_item(STARTER_POTION_PATH)
	if starter_potion != null:
		add_item(starter_potion, 2, false)

	for saved_garden: Dictionary in preserved_garden_items:
		var g_item: ItemData = saved_garden["item"] as ItemData
		var g_cnt: int = int(saved_garden["count"])
		var g_q: int = int(saved_garden.get("quality_pct", 100))
		var g_s: int = int(saved_garden.get("star_level", 1))
		add_item(g_item, g_cnt, false, g_q, g_s, false)

	_ensure_sanctuary_slots()
	ensure_skill_presets()
	_ensure_loadouts()
	if skill_auto_upgrade_enabled:
		try_apply_skill_preset(false)

	mark_stats_dirty()
	current_barrier = get_max_barrier()
	current_hp = get_max_hp()
	current_mana = get_max_mana()
	if not locations.is_empty():
		current_location = locations[0]


func start_new_run(target_difficulty: int, challenge_id: String = "") -> void:
	_wait_for_save_thread()
	var clamped_diff: int = clampi(target_difficulty, 1, maxi(1, max_unlocked_difficulty))
	if boss_defeated_this_run:
		total_runs_completed += 1
	_init_run_state(clamped_diff, challenge_id)
	save_game(true)
	_emit_all_refresh_signals()
	game_reset.emit()


func reset_progress() -> void:
	_wait_for_save_thread()
	for path: String in [SAVE_PATH, SAVE_BACKUP_PATH, SAVE_TEMP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	set_afk_mode(false)
	_init_full_reset_state()
	save_game(true)
	_emit_all_refresh_signals()
	game_reset.emit()


# --- Hero Classes (50+ Difficulty) ---

func is_classes_unlocked() -> bool:
	return max_unlocked_difficulty >= CLASSES_UNLOCK_DIFFICULTY


func get_class_by_id(class_id: String) -> HeroClassData:
	if _classes_by_id.has(class_id):
		return _classes_by_id[class_id] as HeroClassData
	return null


func get_current_class() -> HeroClassData:
	var hc: HeroClassData = get_class_by_id(selected_class_id)
	if hc != null:
		return hc
	if not hero_classes.is_empty():
		return hero_classes[0]
	return null


func has_hero_class(class_id: String) -> bool:
	return selected_class_id == class_id


func is_equipment_disabled() -> bool:
	var hc: HeroClassData = get_current_class()
	return hc != null and hc.disables_equipment


func select_hero_class(class_id: String) -> bool:
	var target: HeroClassData = get_class_by_id(class_id)
	if target == null:
		return false
	if target.required_difficulty > 1 and not is_classes_unlocked():
		return false
	if selected_class_id == class_id:
		return false

	var prev_max_hp: float = get_max_hp()
	var prev_max_mana: float = get_max_mana()
	selected_class_id = class_id
	mark_stats_dirty()
	_validate_equipped_abilities_for_class()
	clear_active_buffs()

	if target.disables_equipment:
		if equipped_weapon != null:
			add_item(equipped_weapon, 1, false, equipped_weapon_quality, equipped_weapon_stars, false)
			equipped_weapon = null
			equipped_weapon_quality = 100
			equipped_weapon_stars = 1
		if equipped_armor != null:
			add_item(equipped_armor, 1, false, equipped_armor_quality, equipped_armor_stars, false)
			equipped_armor = null
			equipped_armor_quality = 100
			equipped_armor_stars = 1
		if equipped_offhand != null:
			add_item(equipped_offhand, 1, false, equipped_offhand_quality, equipped_offhand_stars, false)
			equipped_offhand = null
			equipped_offhand_quality = 100
			equipped_offhand_stars = 1
		if equipped_ammo != null and equipped_ammo_count > 0:
			add_item(equipped_ammo, equipped_ammo_count, false)
			equipped_ammo = null
			equipped_ammo_count = 0

	mark_stats_dirty()
	var new_max_hp: float = get_max_hp()
	if new_max_hp > prev_max_hp:
		current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))
	else:
		current_hp = minf(new_max_hp, current_hp)

	var new_max_mana: float = get_max_mana()
	if new_max_mana > prev_max_mana:
		current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))
	else:
		current_mana = minf(new_max_mana, current_mana)

	current_barrier = 0.0 if has_hero_class("reflector") else minf(current_barrier, get_max_barrier())
	class_changed.emit(target)
	stats_changed.emit()
	inventory_changed.emit()
	enchant_changed.emit()
	abilities_changed.emit()
	buffs_changed.emit()
	barrier_changed.emit(current_barrier, get_max_barrier())
	hp_changed.emit(current_hp, new_max_hp)
	mana_changed.emit(current_mana, new_max_mana)
	save_game()
	return true


# --- Companions / Pets (Immortal Slot) ---

func get_pet_by_id(pet_id: String) -> PetData:
	if _pets_by_id.has(pet_id):
		return _pets_by_id[pet_id] as PetData
	return null


func get_equipped_pet() -> PetData:
	if equipped_pet_id.is_empty():
		return null
	return get_pet_by_id(equipped_pet_id)


func has_pet_owned(pet_id: String) -> bool:
	return owned_pet_ids.has(pet_id)


func get_pet_training_level(pet_id: String) -> int:
	return clampi(int(pet_training_levels.get(pet_id, 0)), 0, MAX_PET_TRAINING_LEVEL)


func get_pet_training_multiplier(pet_id: String) -> float:
	var lvl: int = get_pet_training_level(pet_id)
	return 1.0 + float(lvl) * 0.12


func get_pet_effect_value(effect_type: String) -> float:
	var pet: PetData = get_equipped_pet()
	if pet != null and pet.effect_type == effect_type:
		var raw: float = pet.effect_value * get_pet_training_multiplier(pet.id)
		if effect_type == "crit_lightning":
			return clampf(raw, 0.0, 0.90)
		return raw
	return 0.0


func get_pet_secondary_value(effect_type: String) -> float:
	var pet: PetData = get_equipped_pet()
	if pet != null and pet.effect_type == effect_type:
		var raw: float = pet.effect_secondary * get_pet_training_multiplier(pet.id)
		if effect_type == "gold_echo" or effect_type == "cooldown_haste":
			return clampf(raw, 0.0, 0.95)
		return raw
	return 0.0


func get_pet_buy_price(pet: PetData) -> float:
	if pet == null:
		return 0.0
	var mult: float = get_difficulty_price_mult() * (1.0 + get_curse_value("greedy_curse"))
	return maxf(1.0, round(pet.buy_price * mult))


func buy_pet(_pet_id: String) -> Dictionary:
	return {
		"success": false,
		"message": "Путников нельзя купить за золото — приманите их узором растений в ☀️ Светлом саду!",
	}


func get_pet_treat_success_chance(pet_id: String, treat_item: ItemData) -> float:
	var pet: PetData = get_pet_by_id(pet_id)
	if pet == null or treat_item == null or treat_item.item_type != ItemData.ItemType.HARVEST:
		return 0.0
	if treat_item.garden_category != "light":
		return 0.0
	var lvl: int = get_pet_training_level(pet_id)
	if lvl >= MAX_PET_TRAINING_LEVEL:
		return 0.0
	if treat_item.id == pet.favorite_treat_id:
		return maxf(0.15, 0.55 - float(lvl) * 0.04)
	if treat_item.id == pet.secondary_treat_id:
		return maxf(0.08, 0.30 - float(lvl) * 0.025)
	return maxf(0.05, 0.12 - float(lvl) * 0.01)


func train_pet_with_treat(pet_id: String, treat_item: ItemData) -> Dictionary:
	var pet: PetData = get_pet_by_id(pet_id)
	if pet == null:
		return {"success": false, "leveled_up": false, "message": "Путник не найден."}
	if not has_pet_owned(pet_id):
		return {"success": false, "leveled_up": false, "message": "Сначала приманите этого путника в Светлом саду."}
	var cur_lvl: int = get_pet_training_level(pet_id)
	if cur_lvl >= MAX_PET_TRAINING_LEVEL:
		return {"success": false, "leveled_up": false, "message": "%s %s уже достиг максимального уровня дрессировки (%d/%d)!" % [pet.icon_emoji, pet.pet_name, cur_lvl, MAX_PET_TRAINING_LEVEL]}
	if treat_item == null or treat_item.item_type != ItemData.ItemType.HARVEST or treat_item.garden_category != "light":
		return {"success": false, "leveled_up": false, "message": "Для дрессировки подходят только растения Светлого сада."}

	var chance: float = get_pet_treat_success_chance(pet_id, treat_item)
	if not remove_item(treat_item, 1):
		return {"success": false, "leveled_up": false, "message": "Недостаточно «%s» в рюкзаке." % treat_item.item_name}

	var treat_tag: String = "★ любимый пряник" if treat_item.id == pet.favorite_treat_id else ("👍 хороший пряник" if treat_item.id == pet.secondary_treat_id else "🍪 пряник")
	if randf() <= chance:
		var new_lvl: int = cur_lvl + 1
		pet_training_levels[pet_id] = new_lvl
		mark_stats_dirty()
		pets_changed.emit()
		stats_changed.emit()
		save_game()
		return {
			"success": true,
			"leveled_up": true,
			"message": "🎉 %s %s с радостью съел %s (%s, шанс %d%%) и поднял дрессировку до Ур.%d (+%d%% эффекта)!" % [
				pet.icon_emoji,
				pet.pet_name,
				treat_item.get_display_name(),
				treat_tag,
				roundi(chance * 100.0),
				new_lvl,
				new_lvl * 12,
			],
		}

	pets_changed.emit()
	save_game()
	return {
		"success": false,
		"leveled_up": false,
		"message": "😋 %s %s скушал %s (%s, шанс %d%%), но уровень остался Ур.%d. Попробуйте ещё!" % [
			pet.icon_emoji,
			pet.pet_name,
			treat_item.get_display_name(),
			treat_tag,
			roundi(chance * 100.0),
			cur_lvl,
		],
	}


func equip_pet(pet_id: String) -> bool:
	if not has_pet_owned(pet_id):
		return false
	if is_pet_on_expedition(pet_id):
		return false
	if equipped_pet_id == pet_id:
		return false
	equipped_pet_id = pet_id
	mark_stats_dirty()
	pets_changed.emit()
	stats_changed.emit()
	save_game()
	return true


func unequip_pet() -> void:
	if equipped_pet_id.is_empty():
		return
	equipped_pet_id = ""
	mark_stats_dirty()
	pets_changed.emit()
	stats_changed.emit()
	save_game()


func is_pet_on_expedition(pet_id: String) -> bool:
	for pet_exp: Dictionary in pet_expeditions:
		if str(pet_exp.get("pet_id", "")) == pet_id:
			return true
	return false


func get_pet_expedition(pet_id: String) -> Dictionary:
	for pet_exp: Dictionary in pet_expeditions:
		if str(pet_exp.get("pet_id", "")) == pet_id:
			return pet_exp
	return {}


func get_expedition_plan(plan_id: String) -> Dictionary:
	for p: Dictionary in PET_EXPEDITION_PLANS:
		if str(p.get("id", "")) == plan_id:
			return p
	return {}


func start_pet_expedition(pet_id: String, plan_id: String) -> Dictionary:
	if not has_pet_owned(pet_id):
		return {"success": false, "message": "Путник не приручён."}
	if equipped_pet_id == pet_id:
		return {"success": false, "message": "Сначала снимите активного путника перед отправкой в экспедицию."}
	if is_pet_on_expedition(pet_id):
		return {"success": false, "message": "Этот путник уже в экспедиции."}
	var plan: Dictionary = get_expedition_plan(plan_id)
	if plan.is_empty():
		return {"success": false, "message": "Неизвестный план экспедиции."}
	pet_expeditions.append({
		"pet_id": pet_id,
		"plan_id": plan_id,
		"elapsed": 0.0,
		"duration": float(plan["duration"]),
		"completed": false,
	})
	pets_changed.emit()
	save_game()
	return {"success": true, "message": "🧭 Путник отправлен в экспедицию: %s!" % str(plan["title"])}


func claim_pet_expedition(pet_id: String) -> Dictionary:
	var idx: int = -1
	for i: int in range(pet_expeditions.size()):
		if str(pet_expeditions[i].get("pet_id", "")) == pet_id:
			idx = i
			break
	if idx < 0:
		return {"success": false, "message": "Экспедиция не найдена."}
	var pet_exp: Dictionary = pet_expeditions[idx]
	if not bool(pet_exp.get("completed", false)):
		return {"success": false, "message": "Экспедиция ещё не завершена."}
	var plan: Dictionary = get_expedition_plan(str(pet_exp.get("plan_id", "short")))
	var ore_chance: float = float(plan.get("ore_chance", 0.45))
	var seed_rolls: int = int(plan.get("seed_rolls", 2))
	var rewards: Array[String] = []

	var bonus_gold: float = round((120.0 + float(seed_rolls) * 60.0) * get_gold_multiplier())
	add_gold(bonus_gold)
	rewards.append("+%s з." % NumberFormatter.format_number(bonus_gold))

	if randf() <= ore_chance:
		var ore_item: ItemData = get_cached_item("res://resources/items/abyss_ore.tres")
		if ore_item != null:
			var ore_amt: int = 1 if seed_rolls <= 2 else 2
			add_item(ore_item, ore_amt, true)
			rewards.append("⛏️ Руда Бездны x%d" % ore_amt)

	var light_seeds: Array[String] = [
		"res://resources/items/light_clover_seed.tres",
		"res://resources/items/honey_berry_seed.tres",
		"res://resources/items/sky_chamomile_seed.tres",
		"res://resources/items/spark_chili_seed.tres",
	]
	for _r: int in range(seed_rolls):
		var s_path: String = light_seeds[randi() % light_seeds.size()]
		var s_item: ItemData = get_cached_item(s_path)
		if s_item != null:
			add_item(s_item, 1, true)
			rewards.append(s_item.get_display_name())

	if seed_rolls >= 5:
		var page_item: ItemData = get_cached_item("res://resources/items/ancient_page.tres")
		if page_item != null:
			add_item(page_item, 1, true)
			rewards.append("📜 Древний лист x1")

	pet_expeditions.remove_at(idx)
	pets_changed.emit()
	inventory_changed.emit()
	stats_changed.emit()
	save_game()
	return {"success": true, "message": "🎒 Награда экспедиции: %s" % ", ".join(rewards)}


# --- Learn by Doing (Melee / Ranged / Magic Masteries) ---

func get_mastery_level(skill_id: String) -> int:
	match skill_id:
		"melee":
			return melee_level
		"ranged":
			return ranged_level
		"magic":
			return magic_level
	return 1


func get_mastery_xp(skill_id: String) -> float:
	match skill_id:
		"melee":
			return melee_xp
		"ranged":
			return ranged_xp
		"magic":
			return magic_xp
	return 0.0


func get_mastery_xp_required(skill_id: String, lvl: int) -> float:
	if skill_id == "magic":
		return 30.0 + float(maxi(1, lvl) - 1) * 25.0
	return 15.0 + float(maxi(1, lvl) - 1) * 12.0


func get_mastery_xp_multiplier() -> float:
	return 1.0 + get_skill_bonus("mastery_xp_mult") + get_dark_bonus("ancient_memory")


func get_mastery_bonus_multiplier(skill_id: String) -> float:
	var lvl: int = get_mastery_level(skill_id)
	var per_lvl: float = 0.03 if skill_id == "melee" else 0.035
	return 1.0 + float(maxi(0, lvl - 1)) * per_lvl


func add_mastery_xp(skill_id: String, base_amount: float) -> void:
	if base_amount <= 0.0:
		return
	var gained: float = base_amount * get_mastery_xp_multiplier()
	var leveled_up: bool = false
	var new_lvl: int = 1

	match skill_id:
		"melee":
			melee_xp += gained
			while melee_xp >= get_mastery_xp_required("melee", melee_level):
				melee_xp -= get_mastery_xp_required("melee", melee_level)
				melee_level += 1
				leveled_up = true
			new_lvl = melee_level
		"ranged":
			ranged_xp += gained
			while ranged_xp >= get_mastery_xp_required("ranged", ranged_level):
				ranged_xp -= get_mastery_xp_required("ranged", ranged_level)
				ranged_level += 1
				leveled_up = true
			new_lvl = ranged_level
		"magic":
			magic_xp += gained
			while magic_xp >= get_mastery_xp_required("magic", magic_level):
				magic_xp -= get_mastery_xp_required("magic", magic_level)
				magic_level += 1
				leveled_up = true
			new_lvl = magic_level
		_:
			return

	mastery_changed.emit(skill_id, new_lvl, leveled_up)
	if leveled_up:
		mark_stats_dirty()
		stats_changed.emit()


# --- Difficulty & Curses ---

func get_difficulty_enemy_hp_mult() -> float:
	return pow(1.65, float(difficulty_level - 1))


func get_difficulty_enemy_dmg_mult() -> float:
	return pow(1.42, float(difficulty_level - 1))


func get_difficulty_enemy_armor_mult() -> float:
	return pow(1.38, float(difficulty_level - 1))


func get_difficulty_enemy_flat_armor() -> float:
	return float(difficulty_level - 1) * 4.0


func get_difficulty_price_mult() -> float:
	return pow(1.45, float(difficulty_level - 1))


func get_difficulty_train_mult() -> float:
	return pow(1.35, float(difficulty_level - 1))


func get_difficulty_gold_mult() -> float:
	return pow(1.50, float(difficulty_level - 1))


func get_difficulty_xp_mult() -> float:
	return pow(1.25, float(difficulty_level - 1))


func get_curse_attenuation() -> float:
	return 0.6 if has_dark_skill("curse_ward") else 1.0


func ensure_curses_for_difficulty(target_diff: int) -> void:
	var max_tier: int = floori(float(target_diff) / 10.0) * 10
	if max_tier < 10:
		return

	var used_ids: Array[String] = []
	for tier_key: Variant in difficulty_curses.keys():
		var cid: String = str(difficulty_curses[tier_key])
		if not cid.is_empty() and not used_ids.has(cid):
			used_ids.append(cid)

	var added_any: bool = false
	for tier: int in range(10, max_tier + 1, 10):
		if difficulty_curses.has(tier) and not str(difficulty_curses[tier]).is_empty():
			continue
		var candidates: Array[Dictionary] = []
		for entry: Dictionary in CURSE_CATALOG:
			if not used_ids.has(str(entry["id"])):
				candidates.append(entry)
		if candidates.is_empty():
			candidates = CURSE_CATALOG.duplicate()
		var picked: Dictionary = candidates[randi() % candidates.size()]
		var picked_id: String = str(picked["id"])
		difficulty_curses[tier] = picked_id
		added_any = true
		if not used_ids.has(picked_id):
			used_ids.append(picked_id)
	if added_any:
		_invalidate_progression_caches()


func _get_curse_definition(curse_id: String) -> Dictionary:
	for entry: Dictionary in CURSE_CATALOG:
		if str(entry["id"]) == curse_id:
			return entry
	return {}


func get_active_curses() -> Array[Dictionary]:
	_ensure_progression_caches()
	return _active_curses_cache


func format_curse_description(def: Dictionary, eff_val: float) -> String:
	var cid: String = str(def.get("id", ""))
	var fmt: String = str(def.get("desc_fmt", ""))
	if cid == "rot":
		return fmt % [eff_val * 100.0]
	elif cid == "blood_tax":
		var pct: int = roundi(eff_val * 100.0)
		return fmt % [pct, pct]
	return fmt % [roundi(eff_val * 100.0)]


func get_curse_value(curse_id: String) -> float:
	if curse_id == "greedy_curse" and has_hero_class("alchemist"):
		return 0.0
	_ensure_progression_caches()
	return float(_curse_value_cache.get(curse_id, 0.0))


func reroll_curse_at_tier(tier: int) -> Dictionary:
	if curse_reroll_tokens <= 0:
		return {"success": false, "message": "Нет жетонов реролла проклятий."}
	if not difficulty_curses.has(tier):
		return {"success": false, "message": "На уровне %d нет проклятия." % tier}

	var current_cid: String = str(difficulty_curses[tier])
	var used_elsewhere: Array[String] = []
	for t_key: Variant in difficulty_curses.keys():
		if int(t_key) != tier:
			used_elsewhere.append(str(difficulty_curses[t_key]))

	var preferred: Array[Dictionary] = []
	var fallback: Array[Dictionary] = []
	for entry: Dictionary in CURSE_CATALOG:
		var cid: String = str(entry["id"])
		if cid == current_cid:
			continue
		fallback.append(entry)
		if not used_elsewhere.has(cid):
			preferred.append(entry)

	var pool: Array[Dictionary] = preferred if not preferred.is_empty() else fallback
	if pool.is_empty():
		return {"success": false, "message": "Нет альтернативных проклятий."}

	var picked: Dictionary = pool[randi() % pool.size()]
	var new_cid: String = str(picked["id"])
	difficulty_curses[tier] = new_cid
	curse_reroll_tokens -= 1
	_invalidate_progression_caches()

	difficulty_changed.emit()
	stats_changed.emit()
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())
	save_game()
	return {
		"success": true,
		"message": "🎲 Проклятие Сл.%d заменено на %s!" % [tier, str(picked["title"])],
	}


func is_dark_points_claimed_for_difficulty(diff: int) -> bool:
	return dark_points_claimed_difficulties.has(diff)


func get_challenge_def(challenge_id: String) -> Dictionary:
	for ch: Dictionary in CHALLENGE_CATALOG:
		if str(ch.get("id", "")) == challenge_id:
			return ch
	return {}


func is_challenge_completed(challenge_id: String) -> bool:
	return completed_challenges.has(challenge_id)


func is_potions_blocked_by_challenge() -> bool:
	return active_challenge_id == "no_potions_titan"


func is_non_staff_blocked_by_challenge() -> bool:
	return active_challenge_id == "staff_master"


func is_gear_blocked_by_challenge() -> bool:
	return active_challenge_id == "naked_ascetic"


func on_final_boss_defeated() -> void:
	if boss_defeated_this_run:
		return
	boss_defeated_this_run = true
	var gained: int = 0
	if not dark_points_claimed_difficulties.has(difficulty_level):
		dark_points_claimed_difficulties.append(difficulty_level)
		gained = 2
		dark_points += gained
	var coins_gained: int = maxi(1, difficulty_level)
	dark_shop_coins += coins_gained
	if difficulty_level >= max_unlocked_difficulty:
		max_unlocked_difficulty = difficulty_level + 1
	if not active_challenge_id.is_empty():
		var passed: bool = (active_challenge_id != "speedrun_titan") or (run_elapsed_seconds <= 300.0)
		if passed and not completed_challenges.has(active_challenge_id):
			completed_challenges.append(active_challenge_id)
		active_challenge_id = ""
		challenge_changed.emit()
	ensure_curses_for_difficulty(max_unlocked_difficulty)
	_invalidate_progression_caches()
	dark_skills_changed.emit()
	dark_shop_changed.emit()
	difficulty_changed.emit()
	stats_changed.emit()
	final_boss_cleared.emit(gained, max_unlocked_difficulty)
	save_game()


func get_location_by_id(location_id: String) -> LocationData:
	for loc: LocationData in locations:
		if loc != null and loc.id == location_id:
			return loc
	return null



func on_curse_warden_defeated() -> void:
	curse_reroll_tokens += 1
	reroll_boss_kills_in_run += 1
	difficulty_changed.emit()
	stats_changed.emit()
	curse_warden_defeated.emit(curse_reroll_tokens, reroll_boss_kills_in_run)
	save_game()


# --- Dark Skills ---

func get_dark_skill_by_id(skill_id: String) -> DarkSkillNodeData:
	if _dark_skills_by_id.has(skill_id):
		return _dark_skills_by_id[skill_id] as DarkSkillNodeData
	return null


func has_dark_skill(skill_id: String) -> bool:
	_ensure_progression_caches()
	return _unlocked_dark_skill_set.has(skill_id)


func are_dark_prerequisites_met(skill_id: String) -> bool:
	var dskill: DarkSkillNodeData = get_dark_skill_by_id(skill_id)
	if dskill == null:
		return false
	for prereq_id: String in dskill.prerequisites:
		if not has_dark_skill(prereq_id):
			return false
	return true


func can_unlock_dark_skill(skill_id: String) -> bool:
	var dskill: DarkSkillNodeData = get_dark_skill_by_id(skill_id)
	if dskill == null:
		return false
	if dskill.requires_alchemy and not is_alchemy_unlocked():
		return false
	if has_dark_skill(skill_id):
		return false
	if dark_points < dskill.cost_dark_points:
		return false
	return are_dark_prerequisites_met(skill_id)


func unlock_dark_skill(skill_id: String) -> bool:
	if not can_unlock_dark_skill(skill_id):
		return false
	var dskill: DarkSkillNodeData = get_dark_skill_by_id(skill_id)
	if dskill == null:
		return false

	var prev_max_hp: float = get_max_hp()
	var prev_max_mana: float = get_max_mana()
	dark_points -= dskill.cost_dark_points
	unlocked_dark_skills.append(skill_id)
	_invalidate_progression_caches()

	var new_max_hp: float = get_max_hp()
	if new_max_hp > prev_max_hp:
		current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))
	var new_max_mana: float = get_max_mana()
	if new_max_mana > prev_max_mana:
		current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))

	dark_skills_changed.emit()
	difficulty_changed.emit()
	enchant_changed.emit()
	abilities_changed.emit()
	stats_changed.emit()
	hp_changed.emit(current_hp, new_max_hp)
	mana_changed.emit(current_mana, new_max_mana)
	save_game()
	return true


func get_dark_bonus(effect_type: String) -> float:
	_ensure_progression_caches()
	return float(_dark_bonus_cache.get(effect_type, 0.0))


# --- Regular Skills ---

func get_skill_by_id(skill_id: String) -> SkillNodeData:
	if _skills_by_id.has(skill_id):
		return _skills_by_id[skill_id] as SkillNodeData
	return null


func is_skill_unlocked(skill_id: String) -> bool:
	_ensure_progression_caches()
	return _unlocked_skill_set.has(skill_id)


func are_prerequisites_met(skill_id: String) -> bool:
	var skill: SkillNodeData = get_skill_by_id(skill_id)
	if skill == null:
		return false
	for prereq_id: String in skill.prerequisites:
		if not is_skill_unlocked(prereq_id):
			return false
	return true


func can_unlock_skill(skill_id: String) -> bool:
	var skill: SkillNodeData = get_skill_by_id(skill_id)
	if skill == null:
		return false
	if skill.requires_alchemy and not is_alchemy_unlocked():
		return false
	if is_skill_unlocked(skill_id):
		return false
	if skill_points < skill.cost_skill_points:
		return false
	return are_prerequisites_met(skill_id)


func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false
	var skill: SkillNodeData = get_skill_by_id(skill_id)
	if skill == null:
		return false

	var prev_max_hp: float = get_max_hp()
	var prev_max_mana: float = get_max_mana()
	skill_points -= skill.cost_skill_points
	unlocked_skills.append(skill_id)
	_invalidate_progression_caches()

	var new_max_hp: float = get_max_hp()
	if new_max_hp > prev_max_hp:
		current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))

	var new_max_mana: float = get_max_mana()
	if new_max_mana > prev_max_mana:
		current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))

	skills_changed.emit()
	stats_changed.emit()
	hp_changed.emit(current_hp, new_max_hp)
	mana_changed.emit(current_mana, new_max_mana)
	save_game()
	return true


func get_skill_bonus(bonus_type: String) -> float:
	_ensure_progression_caches()
	return float(_skill_bonus_cache.get(bonus_type, 0.0))


func ensure_skill_presets() -> void:
	var sanitized: Array[Dictionary] = []
	for i: int in range(SKILL_PRESET_COUNT):
		var default_name: String = "Профиль %d" % (i + 1)
		var preset_name: String = default_name
		var clean_order: Array[String] = []
		if i < skill_presets.size() and skill_presets[i] is Dictionary:
			var raw: Dictionary = skill_presets[i] as Dictionary
			var candidate_name: String = str(raw.get("name", default_name)).strip_edges()
			if not candidate_name.is_empty():
				preset_name = candidate_name
			if raw.get("order") is Array:
				for raw_id: Variant in raw["order"]:
					var sid: String = str(raw_id)
					if _skills_by_id.has(sid) and not clean_order.has(sid):
						clean_order.append(sid)
		sanitized.append({"name": preset_name, "order": clean_order})
	skill_presets = sanitized
	active_skill_preset_index = clampi(active_skill_preset_index, 0, SKILL_PRESET_COUNT - 1)


func get_skill_preset_name(index: int) -> String:
	ensure_skill_presets()
	var idx: int = clampi(index, 0, SKILL_PRESET_COUNT - 1)
	return str(skill_presets[idx].get("name", "Профиль %d" % (idx + 1)))


func get_active_skill_preset_order() -> Array[String]:
	ensure_skill_presets()
	var order: Array[String] = []
	var raw_order: Variant = skill_presets[active_skill_preset_index].get("order", [])
	if raw_order is Array:
		for s: Variant in raw_order:
			order.append(str(s))
	return order


func get_skill_preset_position(skill_id: String) -> int:
	var order: Array[String] = get_active_skill_preset_order()
	var idx: int = order.find(skill_id)
	return (idx + 1) if idx >= 0 else 0


func set_active_skill_preset(index: int) -> void:
	ensure_skill_presets()
	var next_idx: int = clampi(index, 0, SKILL_PRESET_COUNT - 1)
	if active_skill_preset_index == next_idx:
		return
	active_skill_preset_index = next_idx
	if skill_auto_upgrade_enabled:
		try_apply_skill_preset(false)
	skills_changed.emit()
	save_game()


func set_skill_auto_upgrade_enabled(enabled: bool) -> void:
	ensure_skill_presets()
	if skill_auto_upgrade_enabled == enabled:
		return
	skill_auto_upgrade_enabled = enabled
	if skill_auto_upgrade_enabled:
		try_apply_skill_preset(false)
	skills_changed.emit()
	save_game()


func toggle_skill_in_active_preset(skill_id: String) -> bool:
	ensure_skill_presets()
	if not _skills_by_id.has(skill_id):
		return false
	var order: Array[String] = get_active_skill_preset_order()
	var existing_idx: int = order.find(skill_id)
	var added: bool = false
	if existing_idx >= 0:
		order.remove_at(existing_idx)
	else:
		order.append(skill_id)
		added = true
	skill_presets[active_skill_preset_index]["order"] = order
	if added and skill_auto_upgrade_enabled:
		try_apply_skill_preset(false)
	skills_changed.emit()
	save_game()
	return added


func clear_active_skill_preset() -> void:
	ensure_skill_presets()
	var empty_order: Array[String] = []
	skill_presets[active_skill_preset_index]["order"] = empty_order
	skills_changed.emit()
	save_game()


func try_apply_skill_preset(should_save: bool = true) -> int:
	ensure_skill_presets()
	if not skill_auto_upgrade_enabled or skill_points <= 0:
		return 0
	var order: Array[String] = get_active_skill_preset_order()
	if order.is_empty():
		return 0

	var prev_max_hp: float = get_max_hp()
	var prev_max_mana: float = get_max_mana()
	var applied_count: int = 0

	while skill_points > 0:
		var picked_id: String = ""
		for sid: String in order:
			if can_unlock_skill(sid):
				picked_id = sid
				break
		if picked_id.is_empty():
			break
		var skill: SkillNodeData = get_skill_by_id(picked_id)
		if skill == null:
			break
		skill_points -= skill.cost_skill_points
		unlocked_skills.append(picked_id)
		_invalidate_progression_caches()
		applied_count += 1

	if applied_count > 0:
		var new_max_hp: float = get_max_hp()
		if new_max_hp > prev_max_hp:
			current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))
		var new_max_mana: float = get_max_mana()
		if new_max_mana > prev_max_mana:
			current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))
		skills_changed.emit()
		stats_changed.emit()
		hp_changed.emit(current_hp, new_max_hp)
		mana_changed.emit(current_mana, new_max_mana)
		if should_save:
			save_game()

	return applied_count


# --- Enchanting System (+0 .. +100, or +250 for Alchemist) ---

func get_max_enchant_level() -> int:
	if has_hero_class("alchemist"):
		return ALCHEMIST_MAX_ENCHANT_LEVEL
	return MAX_ENCHANT_LEVEL


func get_quality_multiplier(quality_pct: int) -> float:
	return float(clampi(quality_pct, 50, 200)) / 100.0


func get_star_multiplier(star_level: int) -> float:
	return 1.0 + float(maxi(0, star_level - 1)) * 0.20


func get_equipped_slot_item(slot_type: ItemData.ItemType) -> ItemData:
	if slot_type == ItemData.ItemType.WEAPON:
		return equipped_weapon
	if slot_type == ItemData.ItemType.ARMOR:
		return equipped_armor
	if slot_type == ItemData.ItemType.OFFHAND:
		return equipped_offhand
	return null


func get_equipped_slot_quality(slot_type: ItemData.ItemType) -> int:
	if slot_type == ItemData.ItemType.WEAPON:
		return equipped_weapon_quality
	if slot_type == ItemData.ItemType.ARMOR:
		return equipped_armor_quality
	if slot_type == ItemData.ItemType.OFFHAND:
		return equipped_offhand_quality
	return 100


func get_equipped_slot_stars(slot_type: ItemData.ItemType) -> int:
	if slot_type == ItemData.ItemType.WEAPON:
		return equipped_weapon_stars
	if slot_type == ItemData.ItemType.ARMOR:
		return equipped_armor_stars
	if slot_type == ItemData.ItemType.OFFHAND:
		return equipped_offhand_stars
	return 1


func get_enchant_level(slot_type: ItemData.ItemType) -> int:
	if slot_type == ItemData.ItemType.WEAPON:
		return weapon_enchant_level
	if slot_type == ItemData.ItemType.ARMOR:
		return armor_enchant_level
	if slot_type == ItemData.ItemType.OFFHAND:
		return offhand_enchant_level
	return 0


func get_enchant_success_chance(current_lvl: int) -> float:
	var max_lvl: int = get_max_enchant_level()
	if current_lvl >= max_lvl:
		return 0.0
	var base_chance: float = clampf(95.0 - float(current_lvl) * (94.5 / 99.0), 0.5, 95.0)
	if has_hero_class("alchemist"):
		return clampf(base_chance * 1.6, 1.5, 98.0)
	return base_chance


func get_enchant_cost(current_lvl: int) -> float:
	var base_cost: float = 50.0 * pow(1.82, float(current_lvl))
	var mult: float = get_difficulty_price_mult() * (1.0 + get_curse_value("greedy_curse"))
	if has_dark_skill("blacksmith_brand"):
		mult *= 0.75
	if has_hero_class("alchemist"):
		mult *= 0.60
	return maxf(1.0, round(base_cost * mult))


func get_dark_enchant_level(slot_type: ItemData.ItemType) -> int:
	if slot_type == ItemData.ItemType.WEAPON:
		return dark_weapon_enchant_level
	if slot_type == ItemData.ItemType.ARMOR:
		return dark_armor_enchant_level
	if slot_type == ItemData.ItemType.OFFHAND:
		return dark_offhand_enchant_level
	return 0


func get_total_slot_enchant_level(slot_type: ItemData.ItemType) -> int:
	return get_enchant_level(slot_type) + get_dark_enchant_level(slot_type)


func get_enchant_power_multiplier(enchant_lvl: int) -> float:
	var per_level: float = 0.15 * (1.25 if has_dark_skill("blacksmith_brand") else 1.0)
	return 1.0 + float(enchant_lvl) * per_level


func get_equipped_stat_bonuses(slot_type: ItemData.ItemType) -> Dictionary:
	if is_equipment_disabled() or is_gear_blocked_by_challenge():
		return {"strength": 0, "agility": 0, "endurance": 0, "intellect": 0}
	var item: ItemData = get_equipped_slot_item(slot_type)
	if item == null:
		return {"strength": 0, "agility": 0, "endurance": 0, "intellect": 0}
	var run_elvl: int = get_enchant_level(slot_type)
	var dark_elvl: int = get_dark_enchant_level(slot_type)
	var total_elvl: int = run_elvl + dark_elvl
	var gear_scale: float = get_quality_multiplier(get_equipped_slot_quality(slot_type)) * get_star_multiplier(get_equipped_slot_stars(slot_type))
	var mult: float = get_enchant_power_multiplier(total_elvl) * gear_scale
	var flat_per_lvl: int = 2 if has_dark_skill("blacksmith_brand") else 1

	var s: int = roundi(float(item.bonus_strength) * mult)
	var a: int = roundi(float(item.bonus_agility) * mult)
	var e: int = roundi(float(item.bonus_endurance) * mult)
	var intel: int = roundi(float(item.bonus_intellect) * mult)
	if slot_type == ItemData.ItemType.WEAPON:
		if item.is_mage_staff():
			intel += run_elvl * flat_per_lvl + dark_elvl * 3
		else:
			s += run_elvl * flat_per_lvl + dark_elvl * 2
	elif slot_type == ItemData.ItemType.ARMOR:
		e += run_elvl * flat_per_lvl + dark_elvl * 2
		if item.bonus_intellect > 0:
			intel += dark_elvl * 2
	elif slot_type == ItemData.ItemType.OFFHAND:
		if item.offhand_kind == ItemData.OffhandKind.TALISMAN:
			intel += run_elvl * flat_per_lvl + dark_elvl * 3
		else:
			e += run_elvl * flat_per_lvl + dark_elvl * 2
	return {"strength": s, "agility": a, "endurance": e, "intellect": intel}


func try_enchant_slot(slot_type: ItemData.ItemType) -> Dictionary:
	if is_equipment_disabled():
		return {"success": false, "message": "Класс Спирит не может использовать и ковать экипировку."}
	if is_gear_blocked_by_challenge():
		return {"success": false, "message": "Активное испытание запрещает экипировку и заточку."}
	var item: ItemData = get_equipped_slot_item(slot_type)
	if item == null:
		return {"success": false, "message": "Сначала экипируйте предмет в этот слот."}

	var current_lvl: int = get_enchant_level(slot_type)
	var max_lvl: int = get_max_enchant_level()
	if current_lvl >= max_lvl:
		return {"success": false, "message": "Достигнут максимальный уровень зачарования (+%d)." % max_lvl}

	var cost: float = get_enchant_cost(current_lvl)
	if gold < cost:
		return {
			"success": false,
			"message": "Нужно %s золота (у вас %s)." % [
				NumberFormatter.format_number(cost),
				NumberFormatter.format_number(gold),
			],
		}

	gold -= cost
	var chance: float = get_enchant_success_chance(current_lvl)
	var roll: float = randf() * 100.0
	var succeeded: bool = roll < chance

	if succeeded:
		var prev_max_hp: float = get_max_hp()
		var prev_max_mana: float = get_max_mana()
		if slot_type == ItemData.ItemType.WEAPON:
			weapon_enchant_level += 1
		elif slot_type == ItemData.ItemType.ARMOR:
			armor_enchant_level += 1
		elif slot_type == ItemData.ItemType.OFFHAND:
			offhand_enchant_level += 1

		mark_stats_dirty()
		var new_max_hp: float = get_max_hp()
		if new_max_hp > prev_max_hp:
			current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))
		var new_max_mana: float = get_max_mana()
		if new_max_mana > prev_max_mana:
			current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))
		var max_bar: float = get_max_barrier()
		current_barrier = 0.0 if has_hero_class("reflector") else minf(maxf(current_barrier, max_bar), max_bar)

		stats_changed.emit()
		hp_changed.emit(current_hp, new_max_hp)
		mana_changed.emit(current_mana, new_max_mana)
		barrier_changed.emit(current_barrier, max_bar)
		enchant_changed.emit()
		save_game()
		return {
			"success": true,
			"message": "✨ Успех! Слот усилен до +%d (шанс %.2f%%)." % [current_lvl + 1, chance],
		}

	stats_changed.emit()
	enchant_changed.emit()
	save_game()
	return {
		"success": false,
		"message": "💨 Неудача (шанс был %.2f%%). Уровень сохранён на +%d." % [chance, current_lvl],
	}


# --- Dark Forge (Permanent Crafting & Persistent Enchanting with Dark Points) ---

func get_dark_forge_enchant_chance(current_lvl: int) -> float:
	if current_lvl <= 0:
		return 25.0
	return maxf(15.0, 20.0 - float(current_lvl - 1) * 1.0)


func get_dark_forge_enchant_cost(current_lvl: int) -> int:
	return 4 + maxi(0, current_lvl) * 2


func try_dark_forge_enchant(slot_type: ItemData.ItemType) -> Dictionary:
	if is_equipment_disabled():
		return {"success": false, "message": "Класс Спирит не может использовать Тёмную заточку."}
	if is_gear_blocked_by_challenge():
		return {"success": false, "message": "Активное испытание запрещает экипировку."}
	var item: ItemData = get_equipped_slot_item(slot_type)
	if item == null:
		return {"success": false, "message": "Сначала экипируйте предмет в этот слот."}

	var current_lvl: int = get_dark_enchant_level(slot_type)
	var cost: int = get_dark_forge_enchant_cost(current_lvl)
	if dark_points < cost:
		return {"success": false, "message": "Нужно %d 🌑 Очков Тьмы (у вас %d 🌑)." % [cost, dark_points]}

	dark_points -= cost
	var chance: float = get_dark_forge_enchant_chance(current_lvl)
	var succeeded: bool = (randf() * 100.0) < chance

	if succeeded:
		var prev_max_hp: float = get_max_hp()
		var prev_max_mana: float = get_max_mana()
		if slot_type == ItemData.ItemType.WEAPON:
			dark_weapon_enchant_level += 1
		elif slot_type == ItemData.ItemType.ARMOR:
			dark_armor_enchant_level += 1
		elif slot_type == ItemData.ItemType.OFFHAND:
			dark_offhand_enchant_level += 1

		mark_stats_dirty()
		var new_max_hp: float = get_max_hp()
		if new_max_hp > prev_max_hp:
			current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))
		var new_max_mana: float = get_max_mana()
		if new_max_mana > prev_max_mana:
			current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))
		var max_bar: float = get_max_barrier()
		current_barrier = 0.0 if has_hero_class("reflector") else minf(maxf(current_barrier, max_bar), max_bar)

		stats_changed.emit()
		dark_skills_changed.emit()
		enchant_changed.emit()
		dark_forge_changed.emit()
		barrier_changed.emit(current_barrier, max_bar)
		hp_changed.emit(current_hp, new_max_hp)
		mana_changed.emit(current_mana, new_max_mana)
		save_game()
		return {
			"success": true,
			"message": "🔥 Тёмный успех! Вечная заточка слота повышена до 🌑+%d (шанс %.0f%%) — сохранится навсегда!" % [current_lvl + 1, chance],
		}

	stats_changed.emit()
	dark_skills_changed.emit()
	dark_forge_changed.emit()
	save_game()
	return {
		"success": false,
		"message": "💨 Пламя Тёмной кузни дрогнуло (шанс %.0f%%). Уровень сохранён на 🌑+%d." % [chance, current_lvl],
	}


func get_dark_forge_material_count(item_id: String) -> int:
	var item: ItemData = get_cached_item("res://resources/items/%s.tres" % item_id)
	if item == null:
		return 0
	return get_item_count_in_inventory(item)


func _get_dark_forge_recipe(recipe_id: String) -> Dictionary:
	for r: Dictionary in DARK_FORGE_RECIPES:
		if str(r.get("id", "")) == recipe_id:
			return r
	return {}


func can_craft_dark_forge_recipe(recipe_id: String) -> bool:
	var r: Dictionary = _get_dark_forge_recipe(recipe_id)
	if r.is_empty():
		return false
	if dark_points < int(r.get("dark_points", 0)):
		return false
	var need_ore: int = int(r.get("abyss_ore", 0))
	var need_page: int = int(r.get("ancient_page", 0))
	if need_ore > 0 and get_dark_forge_material_count("abyss_ore") < need_ore:
		return false
	if need_page > 0 and get_dark_forge_material_count("ancient_page") < need_page:
		return false
	var req_items: Variant = r.get("required_items", {})
	if req_items is Dictionary:
		for req_id_var: Variant in (req_items as Dictionary).keys():
			var req_id: String = str(req_id_var)
			var req_cnt: int = int((req_items as Dictionary)[req_id_var])
			if get_dark_forge_material_count(req_id) < req_cnt:
				return false
	return true


func craft_dark_forge_item(recipe_id: String) -> Dictionary:
	var r: Dictionary = _get_dark_forge_recipe(recipe_id)
	if r.is_empty():
		return {"success": false, "message": "Рецепт не найден."}
	var need_dp: int = int(r.get("dark_points", 0))
	var need_ore: int = int(r.get("abyss_ore", 0))
	var need_page: int = int(r.get("ancient_page", 0))

	if dark_points < need_dp:
		return {"success": false, "message": "Недостаточно 🌑 Очков Тьмы (нужно %d, у вас %d)." % [need_dp, dark_points]}
	var ore_item: ItemData = get_cached_item("res://resources/items/abyss_ore.tres")
	var page_item: ItemData = get_cached_item("res://resources/items/ancient_page.tres")
	if need_ore > 0 and (ore_item == null or get_item_count_in_inventory(ore_item) < need_ore):
		return {"success": false, "message": "Недостаточно ⛏️ Руды Бездны (нужно %d)." % need_ore}
	if need_page > 0 and (page_item == null or get_item_count_in_inventory(page_item) < need_page):
		return {"success": false, "message": "Недостаточно 📜 Древних листов (нужно %d)." % need_page}

	var extra_consume: Array[Dictionary] = []
	var req_items: Variant = r.get("required_items", {})
	if req_items is Dictionary:
		for req_id_var: Variant in (req_items as Dictionary).keys():
			var req_id: String = str(req_id_var)
			var req_cnt: int = int((req_items as Dictionary)[req_id_var])
			var req_item: ItemData = get_cached_item("res://resources/items/%s.tres" % req_id)
			if req_item == null or get_item_count_in_inventory(req_item) < req_cnt:
				var title: String = req_item.get_display_name() if req_item != null else req_id
				return {"success": false, "message": "Нужен предмет в инвентаре: %s x%d." % [title, req_cnt]}
			extra_consume.append({"item": req_item, "count": req_cnt})

	var result_item: ItemData = get_cached_item(str(r.get("result_path", "")))
	if result_item == null:
		return {"success": false, "message": "Предмет рецепта повреждён."}

	dark_points -= need_dp
	if need_ore > 0 and ore_item != null:
		remove_item(ore_item, need_ore)
	if need_page > 0 and page_item != null:
		remove_item(page_item, need_page)
	for entry: Dictionary in extra_consume:
		remove_item(entry["item"] as ItemData, int(entry["count"]))

	var amt: int = maxi(1, int(r.get("amount", 1)))
	add_item(result_item, amt, true, 100, 1, false)
	dark_skills_changed.emit()
	dark_forge_changed.emit()
	stats_changed.emit()
	save_game()
	var eternal_note: String = " (Вечный — не сбрасывается между ранами!)" if bool(r.get("eternal", false)) else ""
	return {
		"success": true,
		"message": "🔥 Выковано: %s x%d%s" % [result_item.get_display_name(), amt, eternal_note],
	}


# --- Ranged, Staff & Ammo Helpers ---

func is_using_ranged_weapon() -> bool:
	if is_equipment_disabled() or equipped_weapon == null:
		return false
	return equipped_weapon.is_ranged_weapon()


func is_using_mage_staff() -> bool:
	if is_equipment_disabled() or equipped_weapon == null:
		return false
	return equipped_weapon.is_mage_staff()


func is_using_ammo_weapon() -> bool:
	return is_using_ranged_weapon() or is_using_mage_staff()


func _try_refill_ammo_from_inventory(required_kind: ItemData.AmmoKind) -> bool:
	if required_kind == ItemData.AmmoKind.NONE or is_equipment_disabled():
		return false
	for i: int in range(inventory.size()):
		var entry: Dictionary = inventory[i]
		var item: ItemData = entry["item"] as ItemData
		var cnt: int = int(entry["count"])
		if item != null and item.item_type == ItemData.ItemType.AMMO and item.ammo_kind == required_kind and cnt > 0:
			equipped_ammo = item
			equipped_ammo_count = cnt
			inventory.remove_at(i)
			inventory_changed.emit()
			return true
	return false


func has_matching_ammo() -> bool:
	if not is_using_ammo_weapon():
		return false
	var req_kind: ItemData.AmmoKind = equipped_weapon.required_ammo
	if equipped_ammo != null and equipped_ammo.ammo_kind == req_kind and (equipped_ammo_count > 0 or equipped_ammo.is_dark_forged):
		return true
	return _try_refill_ammo_from_inventory(req_kind)


func get_ammo_save_chance() -> float:
	var chance: float = get_skill_bonus("ammo_save")
	if has_dark_skill("shadow_quiver"):
		chance += 0.30
	if has_hero_class("abyss_ranger") and is_using_ranged_weapon():
		chance += 0.60
	return clampf(chance, 0.0, 0.92)


func consume_one_ammo() -> bool:
	if not has_matching_ammo():
		return false
	if equipped_ammo != null and equipped_ammo.is_dark_forged:
		return true
	if randf() < get_ammo_save_chance():
		return true
	equipped_ammo_count = maxi(0, equipped_ammo_count - 1)
	if equipped_ammo_count == 0:
		var req_kind: ItemData.AmmoKind = equipped_weapon.required_ammo
		equipped_ammo = null
		_try_refill_ammo_from_inventory(req_kind)
	inventory_changed.emit()
	stats_changed.emit()
	return true


# --- Player Stats ---

func get_total_strength() -> int:
	if not _stats_cache_dirty and _stats_cache.has("strength"):
		return int(_stats_cache["strength"])
	var wb: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var ob: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.OFFHAND)
	var total: float = float(base_strength + roundi(get_skill_bonus("strength")) + int(wb["strength"]) + int(ab["strength"]) + int(ob["strength"]))
	if is_challenge_completed("naked_ascetic"):
		total *= 1.10
	if has_hero_class("spirit"):
		total *= 1.35
	elif has_hero_class("troll"):
		total *= 1.20
	var res: int = maxi(1, roundi(total))
	_stats_cache["strength"] = res
	_stats_cache_dirty = false
	return res


func get_total_agility() -> int:
	if not _stats_cache_dirty and _stats_cache.has("agility"):
		return int(_stats_cache["agility"])
	var wb: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var ob: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.OFFHAND)
	var total: float = float(base_agility + roundi(get_skill_bonus("agility")) + int(wb["agility"]) + int(ab["agility"]) + int(ob["agility"]))
	if is_challenge_completed("naked_ascetic"):
		total *= 1.10
	if has_hero_class("spirit"):
		total *= 1.35
	var res: int = maxi(1, roundi(total))
	_stats_cache["agility"] = res
	_stats_cache_dirty = false
	return res


func get_total_endurance() -> int:
	if not _stats_cache_dirty and _stats_cache.has("endurance"):
		return int(_stats_cache["endurance"])
	var wb: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var ob: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.OFFHAND)
	var total: float = float(base_endurance + roundi(get_skill_bonus("endurance")) + int(wb["endurance"]) + int(ab["endurance"]) + int(ob["endurance"]))
	if is_challenge_completed("naked_ascetic"):
		total *= 1.10
	if has_hero_class("spirit"):
		total *= 1.35
	var res: int = maxi(1, roundi(total))
	_stats_cache["endurance"] = res
	_stats_cache_dirty = false
	return res


func get_total_intellect() -> int:
	if not _stats_cache_dirty and _stats_cache.has("intellect"):
		return int(_stats_cache["intellect"])
	var wb: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var ob: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.OFFHAND)
	var tome_int: int = 0
	if is_using_mage_staff() and has_matching_ammo() and equipped_ammo != null:
		tome_int = equipped_ammo.bonus_intellect
	var total: float = float(base_intellect + roundi(get_skill_bonus("intellect")) + int(wb["intellect"]) + int(ab["intellect"]) + int(ob["intellect"]) + tome_int)
	if is_challenge_completed("naked_ascetic"):
		total *= 1.10
	if has_hero_class("spirit"):
		total *= 1.35
	elif has_hero_class("blood_archmage"):
		total *= 2.0
	var res: int = maxi(1, roundi(total))
	_stats_cache["intellect"] = res
	_stats_cache_dirty = false
	return res


func get_equipped_mana_cost_reduction() -> float:
	if is_equipment_disabled() or is_gear_blocked_by_challenge():
		return 0.0
	var red: float = 0.0
	if equipped_weapon != null:
		red += equipped_weapon.bonus_mana_cost_red * get_quality_multiplier(equipped_weapon_quality) * get_star_multiplier(equipped_weapon_stars)
	if equipped_armor != null:
		red += equipped_armor.bonus_mana_cost_red * get_quality_multiplier(equipped_armor_quality) * get_star_multiplier(equipped_armor_stars)
	if equipped_offhand != null:
		red += equipped_offhand.bonus_mana_cost_red * get_quality_multiplier(equipped_offhand_quality) * get_star_multiplier(equipped_offhand_stars)
	if is_using_mage_staff() and has_matching_ammo() and equipped_ammo != null:
		red += equipped_ammo.bonus_mana_cost_red
	return clampf(red, 0.0, 0.65)


func get_equipped_spell_power_bonus() -> float:
	if is_equipment_disabled() or is_gear_blocked_by_challenge():
		return 0.0
	var sp: float = 0.0
	if equipped_weapon != null:
		sp += equipped_weapon.bonus_spell_power_pct * get_quality_multiplier(equipped_weapon_quality) * get_star_multiplier(equipped_weapon_stars)
	if equipped_armor != null:
		sp += equipped_armor.bonus_spell_power_pct * get_quality_multiplier(equipped_armor_quality) * get_star_multiplier(equipped_armor_stars)
	if equipped_offhand != null:
		sp += equipped_offhand.bonus_spell_power_pct * get_quality_multiplier(equipped_offhand_quality) * get_star_multiplier(equipped_offhand_stars)
	if is_using_mage_staff() and has_matching_ammo() and equipped_ammo != null:
		sp += equipped_ammo.bonus_spell_power_pct
	return maxf(0.0, sp)


func get_effect_duration_multiplier() -> float:
	if is_equipment_disabled() or is_gear_blocked_by_challenge():
		return 1.0
	var bonus: float = 0.0
	if equipped_weapon != null:
		bonus += equipped_weapon.bonus_effect_duration_pct * get_quality_multiplier(equipped_weapon_quality) * get_star_multiplier(equipped_weapon_stars)
	if equipped_armor != null:
		bonus += equipped_armor.bonus_effect_duration_pct * get_quality_multiplier(equipped_armor_quality) * get_star_multiplier(equipped_armor_stars)
	if equipped_offhand != null:
		bonus += equipped_offhand.bonus_effect_duration_pct * get_quality_multiplier(equipped_offhand_quality) * get_star_multiplier(equipped_offhand_stars)
	if is_using_mage_staff() and has_matching_ammo() and equipped_ammo != null:
		bonus += equipped_ammo.bonus_effect_duration_pct
	return maxf(1.0, 1.0 + bonus)


func get_raw_max_barrier() -> float:
	if is_equipment_disabled() or is_gear_blocked_by_challenge():
		return 0.0
	var raw_bar: float = 0.0
	if equipped_offhand != null:
		var total_elvl: int = get_total_slot_enchant_level(ItemData.ItemType.OFFHAND)
		var mult: float = get_enchant_power_multiplier(total_elvl) * get_quality_multiplier(equipped_offhand_quality) * get_star_multiplier(equipped_offhand_stars)
		var stat_val: float = float(get_total_intellect()) if equipped_offhand.offhand_kind == ItemData.OffhandKind.TALISMAN else float(get_total_endurance())
		raw_bar += (equipped_offhand.bonus_barrier + equipped_offhand.bonus_barrier_scale * stat_val) * mult
	if equipped_armor != null and (equipped_armor.bonus_barrier > 0.0 or equipped_armor.bonus_barrier_scale > 0.0):
		var total_alvl: int = get_total_slot_enchant_level(ItemData.ItemType.ARMOR)
		var amult: float = get_enchant_power_multiplier(total_alvl) * get_quality_multiplier(equipped_armor_quality) * get_star_multiplier(equipped_armor_stars)
		raw_bar += (equipped_armor.bonus_barrier + equipped_armor.bonus_barrier_scale * float(get_total_endurance())) * amult
	if well_run_blessing == "barrier_surge":
		raw_bar *= 1.25
	return maxf(0.0, raw_bar)


func get_max_barrier() -> float:
	if has_hero_class("reflector"):
		return 0.0
	return get_raw_max_barrier()


func add_barrier(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	if has_hero_class("reflector"):
		return heal(amount)
	var cap: float = maxf(get_max_barrier() * 1.5, get_max_hp() * 0.50)
	var prev: float = current_barrier
	current_barrier = minf(cap, current_barrier + amount)
	var gained: float = current_barrier - prev
	if gained > 0.0:
		barrier_changed.emit(current_barrier, maxf(get_max_barrier(), current_barrier))
	return gained


func restore_barrier_full() -> void:
	if has_hero_class("reflector"):
		current_barrier = 0.0
		barrier_changed.emit(0.0, 0.0)
		return
	var max_bar: float = get_max_barrier()
	current_barrier = maxf(current_barrier, max_bar)
	barrier_changed.emit(current_barrier, maxf(max_bar, current_barrier))


func get_max_hp() -> float:
	if not _stats_cache_dirty and _stats_cache.has("max_hp"):
		return float(_stats_cache["max_hp"])
	var hp_val: float = 100.0 + float(get_total_endurance()) * 60.0
	var dark_hp_mult: float = get_dark_bonus("immortal_pact") + get_dark_bonus("abyssal_vitality") + get_dark_bonus("obsidian_bulwark")
	if dark_hp_mult > 0.0:
		hp_val *= (1.0 + dark_hp_mult)
	if well_run_blessing == "barrier_surge":
		hp_val *= 1.12
	if has_hero_class("troll"):
		hp_val *= 1.25
	elif has_hero_class("reflector"):
		var total_hp_gain: float = maxf(0.0, hp_val - 100.0) + float(reflector_kill_hp_stacks) + get_raw_max_barrier()
		total_hp_gain *= 1.30
		hp_val = 100.0 + total_hp_gain * 20.0
	_stats_cache["max_hp"] = hp_val
	_stats_cache_dirty = false
	return hp_val


func get_max_mana() -> float:
	if not _stats_cache_dirty and _stats_cache.has("max_mana"):
		return float(_stats_cache["max_mana"])
	var mana_from_int: float = float(get_total_intellect()) * 32.0
	if has_hero_class("blood_archmage"):
		mana_from_int *= 3.0
	var mp_val: float = 40.0 + float(level) * 5.0 + float(get_total_endurance()) * 16.0 + mana_from_int + get_skill_bonus("max_mana")
	_stats_cache["max_mana"] = mp_val
	_stats_cache_dirty = false
	return mp_val


func get_mana_regen_per_sec() -> float:
	if not _stats_cache_dirty and _stats_cache.has("mana_regen"):
		return float(_stats_cache["mana_regen"])
	var regen: float = 2.5 + float(get_total_endurance()) * 0.25 + float(get_total_intellect()) * 0.45 + get_skill_bonus("mana_regen")
	regen *= (1.0 + float(magic_level - 1) * 0.04)
	regen *= (1.0 + get_dark_bonus("mana_fountain"))
	regen *= (1.0 + get_active_buff_sum("mana_regen_pct"))
	regen *= (1.0 + get_pet_secondary_value("aura_regen"))
	if has_hero_class("alchemist"):
		regen *= 1.15
	regen *= maxf(0.1, 1.0 - get_curse_value("mana_burn"))
	_stats_cache["mana_regen"] = regen
	_stats_cache_dirty = false
	return regen


func spend_mana(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current_mana < amount:
		return false
	current_mana = maxf(0.0, current_mana - amount)
	mana_changed.emit(current_mana, get_max_mana())
	return true


func restore_mana(amount: float, emit_signal_immediately: bool = true) -> float:
	if amount <= 0.0:
		return 0.0
	var max_mana: float = get_max_mana()
	var prev_mana: float = current_mana
	current_mana = minf(max_mana, current_mana + amount)
	var actual: float = current_mana - prev_mana
	if actual > 0.0:
		if emit_signal_immediately or current_mana >= max_mana:
			_mana_ui_dirty = false
			mana_changed.emit(current_mana, max_mana)
		else:
			_mana_ui_dirty = true
	return actual


func get_ability_by_id(ability_id: String) -> AbilityData:
	if _abilities_by_id.has(ability_id):
		return _abilities_by_id[ability_id] as AbilityData
	return null


func is_ability_unlocked(ability: AbilityData) -> bool:
	if ability == null:
		return false
	if ability.required_class_id.is_empty():
		return true
	return has_hero_class(ability.required_class_id)


func get_equipped_slot_for_ability(ability_id: String) -> int:
	if ability_id.is_empty():
		return -1
	for i: int in range(mini(MAX_ACTIVE_ABILITY_SLOTS, equipped_ability_ids.size())):
		if equipped_ability_ids[i] == ability_id:
			return i
	return -1


func _sync_equipped_abilities() -> void:
	while equipped_ability_ids.size() < MAX_ACTIVE_ABILITY_SLOTS:
		equipped_ability_ids.append("")
	if equipped_ability_ids.size() > MAX_ACTIVE_ABILITY_SLOTS:
		equipped_ability_ids.resize(MAX_ACTIVE_ABILITY_SLOTS)

	abilities.resize(MAX_ACTIVE_ABILITY_SLOTS)
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		var aid: String = equipped_ability_ids[i]
		var ab: AbilityData = get_ability_by_id(aid) if not aid.is_empty() else null
		if ab != null and is_ability_unlocked(ab):
			abilities[i] = ab
		else:
			abilities[i] = null
			equipped_ability_ids[i] = ""


func _validate_equipped_abilities_for_class() -> void:
	while equipped_ability_ids.size() < MAX_ACTIVE_ABILITY_SLOTS:
		equipped_ability_ids.append("")
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		var ab: AbilityData = get_ability_by_id(equipped_ability_ids[i])
		if ab == null or not is_ability_unlocked(ab):
			equipped_ability_ids[i] = ""
			if i < ability_auto_cast.size():
				ability_auto_cast[i] = false
			if i < ability_cooldowns.size():
				ability_cooldowns[i] = 0.0
	_sync_equipped_abilities()


func equip_ability_to_slot(ability_id: String, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_ACTIVE_ABILITY_SLOTS:
		return false
	var target: AbilityData = get_ability_by_id(ability_id)
	if target == null or not is_ability_unlocked(target):
		return false

	_sync_equipped_abilities()
	var existing_slot: int = get_equipped_slot_for_ability(ability_id)
	if existing_slot == slot_index:
		return true
	if existing_slot != -1:
		var prev_id: String = equipped_ability_ids[slot_index]
		equipped_ability_ids[existing_slot] = prev_id
		equipped_ability_ids[slot_index] = ability_id
		var tmp_cd: float = ability_cooldowns[existing_slot]
		ability_cooldowns[existing_slot] = ability_cooldowns[slot_index]
		ability_cooldowns[slot_index] = tmp_cd
		var tmp_auto: bool = ability_auto_cast[existing_slot]
		ability_auto_cast[existing_slot] = ability_auto_cast[slot_index]
		ability_auto_cast[slot_index] = tmp_auto
	else:
		equipped_ability_ids[slot_index] = ability_id
		ability_cooldowns[slot_index] = 0.0

	_sync_equipped_abilities()
	abilities_changed.emit()
	save_game()
	return true


func clear_ability_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_ACTIVE_ABILITY_SLOTS:
		return
	_sync_equipped_abilities()
	equipped_ability_ids[slot_index] = ""
	ability_cooldowns[slot_index] = 0.0
	ability_auto_cast[slot_index] = false
	_sync_equipped_abilities()
	abilities_changed.emit()
	save_game()


func get_ability_casts(ability_id: String) -> int:
	return maxi(0, int(ability_casts.get(ability_id, 0)))


func get_ability_level(ability_id: String) -> int:
	return clampi(int(ability_levels.get(ability_id, 1)), 1, AbilityData.MAX_SPELL_LEVEL)


func get_next_spell_level_casts(ability_id: String) -> int:
	var lvl: int = get_ability_level(ability_id)
	if lvl >= AbilityData.MAX_SPELL_LEVEL:
		return 0
	return SPELL_LEVEL_CAST_THRESHOLDS[lvl]


func get_ability_upgrade_page_cost(ability_id: String) -> int:
	var lvl: int = get_ability_level(ability_id)
	if lvl >= AbilityData.MAX_SPELL_LEVEL:
		return 0
	return lvl * 2


func upgrade_ability_with_page(ability_id: String) -> Dictionary:
	var ab: AbilityData = get_ability_by_id(ability_id)
	if ab == null:
		return {"success": false, "message": "Заклинание не найдено."}
	var lvl: int = get_ability_level(ability_id)
	if lvl >= AbilityData.MAX_SPELL_LEVEL:
		return {"success": false, "message": "%s уже на макс. Ур.%d!" % [ab.title, AbilityData.MAX_SPELL_LEVEL]}
	var page_cost: int = get_ability_upgrade_page_cost(ability_id)
	var page_item: ItemData = get_cached_item("res://resources/items/ancient_page.tres")
	if page_item == null or not remove_item(page_item, page_cost):
		return {"success": false, "message": "Нужно %d 📜 Древних листов для улучшения чар." % page_cost}
	ability_levels[ability_id] = lvl + 1
	abilities_changed.emit()
	stats_changed.emit()
	save_game()
	return {"success": true, "message": "📖 %s повышено до Ур.%d!" % [ab.title, lvl + 1]}


func record_ability_cast(ability_id: String) -> void:
	if ability_id.is_empty():
		return
	var next_casts: int = get_ability_casts(ability_id) + 1
	ability_casts[ability_id] = next_casts
	var cur_lvl: int = get_ability_level(ability_id)
	while cur_lvl < AbilityData.MAX_SPELL_LEVEL and next_casts >= SPELL_LEVEL_CAST_THRESHOLDS[cur_lvl]:
		cur_lvl += 1
		ability_levels[ability_id] = cur_lvl
	abilities_changed.emit()


func get_ability_rune(ability_id: String) -> String:
	var key: String = str(ability_runes.get(ability_id, ""))
	return key if (key == "a" or key == "b") else ""


func get_ability_rune_data(ability_id: String) -> Dictionary:
	var r_key: String = get_ability_rune(ability_id)
	if r_key.is_empty() or not SPELL_RUNES_CATALOG.has(ability_id):
		return {}
	var pair: Dictionary = SPELL_RUNES_CATALOG[ability_id] as Dictionary
	if pair.has(r_key):
		return pair[r_key] as Dictionary
	return {}


func set_ability_rune(ability_id: String, rune_key: String) -> void:
	if rune_key != "" and rune_key != "a" and rune_key != "b":
		return
	if rune_key.is_empty():
		ability_runes.erase(ability_id)
	else:
		ability_runes[ability_id] = rune_key
	abilities_changed.emit()
	save_game()


func apply_ability_buff(ability: AbilityData, potency_scale: float = 1.0) -> void:
	if ability == null or ability.duration <= 0.0:
		return
	var rune_data: Dictionary = get_ability_rune_data(ability.id)
	var dur_mult: float = float(rune_data.get("duration_mult", 1.0))
	var lvl_mult: float = AbilityData.get_level_multiplier(get_ability_level(ability.id))
	var final_scale: float = potency_scale * lvl_mult * float(rune_data.get("power_mult", 1.0))
	var final_dur: float = maxf(1.0, ability.duration * get_effect_duration_multiplier() * dur_mult)
	var entry: Dictionary = {
		"id": ability.id,
		"title": ability.title,
		"icon_emoji": ability.icon_emoji,
		"remaining": final_dur,
		"duration": final_dur,
		"damage_pct": ability.buff_damage_pct * final_scale,
		"attack_speed_pct": ability.buff_attack_speed_pct * final_scale,
		"armor_pct": ability.buff_armor_pct * final_scale,
		"dodge_bonus": ability.buff_dodge_bonus * final_scale,
		"crit_chance_bonus": ability.buff_crit_chance_bonus * final_scale,
		"crit_mult_bonus": ability.buff_crit_mult_bonus * final_scale,
		"spell_power_pct": ability.buff_spell_power_pct * final_scale,
		"mana_regen_pct": ability.buff_mana_regen_pct * final_scale,
		"lifesteal_pct": ability.buff_lifesteal_pct * final_scale,
		"thorns_pct": ability.buff_thorns_pct * final_scale,
		"reflect_pct": ability.buff_reflect_pct * final_scale,
	}
	var replaced: bool = false
	for i: int in range(active_buffs.size()):
		if str(active_buffs[i]["id"]) == ability.id:
			active_buffs[i] = entry
			replaced = true
			break
	if not replaced:
		active_buffs.append(entry)
	mark_stats_dirty()
	buffs_changed.emit()
	stats_changed.emit()


func has_active_buff(buff_id: String) -> bool:
	for b: Dictionary in active_buffs:
		if str(b["id"]) == buff_id and float(b["remaining"]) > 0.0:
			return true
	return false


func get_active_buff_remaining(buff_id: String) -> float:
	for b: Dictionary in active_buffs:
		if str(b["id"]) == buff_id:
			return maxf(0.0, float(b["remaining"]))
	return 0.0


func get_active_buff_sum(stat_key: String) -> float:
	var total: float = 0.0
	for b: Dictionary in active_buffs:
		if float(b.get("remaining", 0.0)) > 0.0:
			total += float(b.get(stat_key, 0.0))
	return total


func clear_active_buffs() -> void:
	if active_buffs.is_empty():
		return
	active_buffs.clear()
	mark_stats_dirty()
	buffs_changed.emit()
	stats_changed.emit()


func get_ability(slot_index: int) -> AbilityData:
	if slot_index < 0 or slot_index >= abilities.size():
		return null
	return abilities[slot_index]


func get_ability_mana_cost(ability: AbilityData) -> float:
	if ability == null:
		return 0.0
	var cost: float = ability.mana_cost
	if has_dark_skill("mana_fountain"):
		cost *= 0.80
	cost *= maxf(0.35, 1.0 - get_skill_bonus("mana_cost_red"))
	cost *= maxf(0.25, 1.0 - get_equipped_mana_cost_reduction())
	if has_hero_class("blood_archmage"):
		cost *= 0.50
	var rune_data: Dictionary = get_ability_rune_data(ability.id)
	cost *= float(rune_data.get("cost_mult", 1.0))
	cost *= (1.0 + get_curse_value("clumsy_hands"))
	return maxf(1.0, round(cost))


func get_ability_cooldown_duration(ability: AbilityData) -> float:
	if ability == null:
		return 0.0
	var cd: float = ability.cooldown
	if has_dark_skill("swift_runes"):
		cd *= 0.75
	cd *= maxf(0.35, 1.0 - get_skill_bonus("ability_cd_red"))
	if has_hero_class("blood_archmage"):
		cd *= 0.70
	if is_challenge_completed("speedrun_titan"):
		cd *= 0.92
	if well_run_blessing == "arcane_overdrive":
		cd *= 0.85
	var rune_data: Dictionary = get_ability_rune_data(ability.id)
	cd *= float(rune_data.get("cd_mult", 1.0))
	return maxf(0.4, cd)


func get_ability_power_multiplier(ability: AbilityData) -> float:
	if ability == null:
		return 1.0
	var mult: float = ability.power_multiplier * AbilityData.get_level_multiplier(get_ability_level(ability.id))
	var rune_data: Dictionary = get_ability_rune_data(ability.id)
	mult *= float(rune_data.get("power_mult", 1.0))
	mult *= get_mastery_bonus_multiplier("magic")
	var spell_bonus: float = get_skill_bonus("spell_power") + get_active_buff_sum("spell_power_pct") + get_equipped_spell_power_bonus() + float(get_total_intellect()) * 0.015
	if is_challenge_completed("staff_master"):
		spell_bonus += 0.12
	if well_run_blessing == "arcane_overdrive":
		spell_bonus += 0.20
	mult *= (1.0 + spell_bonus)
	if has_dark_skill("swift_runes"):
		mult *= 1.35
	if has_hero_class("blood_archmage"):
		mult *= 1.75
	if ability.effect_type == "heal":
		if is_challenge_completed("no_potions_titan"):
			mult *= 1.15
		mult *= maxf(0.25, 1.0 - get_curse_value("blood_tax"))
	return mult


func get_ability_cooldown(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= ability_cooldowns.size():
		return 0.0
	return ability_cooldowns[slot_index]


func is_ability_auto_cast(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= ability_auto_cast.size():
		return false
	return ability_auto_cast[slot_index]


func toggle_ability_auto_cast(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= ability_auto_cast.size():
		return
	ability_auto_cast[slot_index] = not ability_auto_cast[slot_index]
	abilities_changed.emit()
	save_game()


func start_ability_cooldown(slot_index: int, duration: float) -> void:
	if slot_index < 0 or slot_index >= ability_cooldowns.size():
		return
	ability_cooldowns[slot_index] = maxf(0.0, duration)
	abilities_changed.emit()


func reduce_all_ability_cooldowns(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var changed: bool = false
	for i: int in range(ability_cooldowns.size()):
		if ability_cooldowns[i] > 0.0:
			ability_cooldowns[i] = maxf(0.0, ability_cooldowns[i] - seconds)
			changed = true
	if changed:
		abilities_changed.emit()


func get_soul_harvest_bonus() -> float:
	if not has_dark_skill("soul_harvest"):
		return 0.0
	return float(floori(float(kills_in_run) / 100.0)) * get_dark_bonus("soul_harvest")


func get_berserk_bonus() -> float:
	if not has_dark_skill("berserk_fury"):
		return 0.0
	var max_hp: float = maxf(1.0, get_max_hp())
	var missing_ratio: float = clampf(1.0 - (current_hp / max_hp), 0.0, 1.0)
	return missing_ratio * get_dark_bonus("berserk_fury")


func get_player_damage(preview_ammo_ready: bool = true) -> float:
	if has_hero_class("reflector"):
		return 0.0
	var total_weapon_elvl: int = get_total_slot_enchant_level(ItemData.ItemType.WEAPON)
	var dmg: float = BASE_DAMAGE + float(get_total_strength()) * 1.5
	if is_using_mage_staff():
		dmg = BASE_DAMAGE + float(get_total_strength()) * 0.8 + float(get_total_intellect()) * 2.2
	if not is_equipment_disabled() and not is_gear_blocked_by_challenge() and equipped_weapon != null and equipped_weapon.bonus_damage > 0.0:
		var w_scale: float = get_quality_multiplier(equipped_weapon_quality) * get_star_multiplier(equipped_weapon_stars)
		dmg += equipped_weapon.bonus_damage * get_enchant_power_multiplier(total_weapon_elvl) * w_scale

	if is_using_ranged_weapon():
		if preview_ammo_ready and has_matching_ammo():
			if equipped_ammo != null:
				dmg += equipped_ammo.bonus_damage
			dmg *= get_mastery_bonus_multiplier("ranged")
			dmg *= (1.0 + get_skill_bonus("ranged_dmg"))
			dmg *= (1.0 + get_dark_bonus("shadow_quiver"))
			if has_dark_skill("deadeye_abyss"):
				dmg *= 1.40
			if has_hero_class("abyss_ranger"):
				dmg *= 1.40
		else:
			dmg *= 0.45
	elif is_using_mage_staff():
		if preview_ammo_ready and has_matching_ammo():
			if equipped_ammo != null:
				dmg += equipped_ammo.bonus_damage
			dmg *= get_mastery_bonus_multiplier("magic")
			dmg *= (1.0 + get_skill_bonus("spell_power") * 0.5 + get_equipped_spell_power_bonus() * 0.5)
		else:
			dmg *= 0.45
	else:
		dmg *= get_mastery_bonus_multiplier("melee")
		dmg *= (1.0 + get_skill_bonus("melee_dmg"))

	dmg *= (1.0 + get_dark_bonus("awakening_power") + get_soul_harvest_bonus() + get_berserk_bonus() + get_active_buff_sum("damage_pct") + get_pet_secondary_value("enemy_burn"))
	if well_run_blessing == "damage_surge":
		dmg *= 1.15
	return dmg


func get_player_armor_penetration() -> float:
	if is_equipment_disabled() or is_gear_blocked_by_challenge():
		return 0.0
	var pen: float = 0.0
	if equipped_weapon != null:
		pen += equipped_weapon.armor_penetration
	if is_using_ammo_weapon() and has_matching_ammo() and equipped_ammo != null:
		pen += equipped_ammo.armor_penetration
	return pen


func get_player_attack_interval() -> float:
	var base_interval: float = maxf(0.42, 2.4 / (1.0 + float(get_total_agility()) * 0.08))
	var wind_speed: float = get_dark_bonus("wind_mastery_dark") + get_active_buff_sum("attack_speed_pct")
	if is_challenge_completed("speedrun_titan"):
		wind_speed += 0.08
	if wind_speed > 0.0:
		base_interval /= (1.0 + wind_speed)
	return maxf(0.26, base_interval * (1.0 + get_curse_value("lead_shackles")))


func get_player_dps() -> float:
	if has_hero_class("reflector"):
		return 0.0
	var avg_crit_factor: float = 1.0 + get_crit_chance() * (get_crit_multiplier() - 1.0)
	return (get_player_damage() * avg_crit_factor) / get_player_attack_interval()


func get_dodge_chance() -> float:
	if has_hero_class("reflector"):
		return 0.0
	return clampf(float(get_total_agility()) * 0.008 + get_skill_bonus("dodge_chance") + get_active_buff_sum("dodge_bonus"), 0.0, 0.65)


func get_armor_reduction() -> float:
	var raw_armor: float = float(get_total_endurance()) * 0.6 + get_skill_bonus("flat_armor") + get_dark_bonus("void_plating")
	if not is_equipment_disabled() and not is_gear_blocked_by_challenge():
		if equipped_weapon != null and equipped_weapon.bonus_defense > 0.0:
			raw_armor += equipped_weapon.bonus_defense * get_enchant_power_multiplier(get_total_slot_enchant_level(ItemData.ItemType.WEAPON)) * get_quality_multiplier(equipped_weapon_quality) * get_star_multiplier(equipped_weapon_stars)
		if equipped_armor != null and equipped_armor.bonus_defense > 0.0:
			raw_armor += equipped_armor.bonus_defense * get_enchant_power_multiplier(get_total_slot_enchant_level(ItemData.ItemType.ARMOR)) * get_quality_multiplier(equipped_armor_quality) * get_star_multiplier(equipped_armor_stars)
		if equipped_offhand != null and equipped_offhand.bonus_defense > 0.0:
			raw_armor += equipped_offhand.bonus_defense * get_enchant_power_multiplier(get_total_slot_enchant_level(ItemData.ItemType.OFFHAND)) * get_quality_multiplier(equipped_offhand_quality) * get_star_multiplier(equipped_offhand_stars)
	var dark_armor_pct: float = (0.25 if has_dark_skill("void_plating") else 0.0) + (0.35 if has_dark_skill("obsidian_bulwark") else 0.0)
	if dark_armor_pct > 0.0:
		raw_armor *= (1.0 + dark_armor_pct)
	if has_hero_class("spirit"):
		raw_armor *= 1.50
	elif has_hero_class("reflector"):
		raw_armor *= 1.40
	raw_armor *= (1.0 + get_active_buff_sum("armor_pct"))
	raw_armor *= maxf(0.15, 1.0 - get_curse_value("brittle_armor"))
	return raw_armor


func get_damage_reflection_pct() -> float:
	var base_reflect: float = 0.20 if has_hero_class("reflector") else 0.0
	return base_reflect + get_dark_bonus("mirror_carapace") + get_dark_bonus("thorn_apotheosis") + get_active_buff_sum("reflect_pct")


func get_reflector_mitigation_pct() -> float:
	if not has_hero_class("reflector"):
		return 0.0
	return minf(get_damage_reflection_pct(), 0.99)


func get_crit_chance() -> float:
	var extra: float = get_active_buff_sum("crit_chance_bonus") + get_pet_effect_value("crit_lightning")
	if not is_equipment_disabled() and not is_gear_blocked_by_challenge() and equipped_weapon != null:
		extra += equipped_weapon.bonus_crit_chance
	if is_using_ranged_weapon():
		extra += float(maxi(0, ranged_level - 1)) * 0.003
		if has_matching_ammo() and equipped_ammo != null:
			extra += equipped_ammo.bonus_crit_chance
	elif is_using_mage_staff() and has_matching_ammo() and equipped_ammo != null:
		extra += equipped_ammo.bonus_crit_chance
	extra += get_dark_bonus("deadeye_abyss")
	return clampf(BASE_CRIT_CHANCE + get_skill_bonus("crit_chance") + extra - get_curse_value("dull_edge"), 0.02, 0.95)


func get_crit_multiplier() -> float:
	var penalty: float = 0.25 if get_curse_value("dull_edge") > 0.0 else 0.0
	var bonus: float = get_dark_bonus("piercing_volley") + get_active_buff_sum("crit_mult_bonus")
	if has_hero_class("abyss_ranger"):
		bonus += float(get_total_agility()) * 0.015
	return maxf(1.25, CRIT_MULTIPLIER + bonus - penalty)


func get_gold_multiplier() -> float:
	var mult: float = (1.0 + get_skill_bonus("gold_mult") + get_dark_bonus("abyssal_greed") + get_pet_effect_value("gold_echo")) * get_difficulty_gold_mult()
	if has_hero_class("alchemist"):
		mult *= 1.15
	if well_run_blessing == "greed_fortune":
		mult *= 1.25
	return mult


func get_xp_multiplier() -> float:
	var dark_xp: float = 0.5 if has_dark_skill("abyssal_greed") else 0.0
	return (1.0 + get_skill_bonus("xp_mult") + dark_xp) * get_difficulty_xp_mult()


func get_xp_to_next_level() -> float:
	var lvl_idx: float = float(maxi(0, level - 1))
	return round(150.0 * pow(1.10, lvl_idx) + lvl_idx * lvl_idx * 55.0)


func _get_base_stat_value(stat_name: String) -> int:
	match stat_name:
		"strength":
			return base_strength
		"agility":
			return base_agility
		"endurance":
			return base_endurance
		"intellect":
			return base_intellect
	return 5


func get_train_cost(stat_name: String) -> float:
	var stat_val: int = _get_base_stat_value(stat_name)
	return round((10.0 + float(stat_val) * 5.0) * get_difficulty_train_mult())


func _sum_train_cost_for_steps(start_val: int, steps: int, diff_mult: float) -> float:
	if steps <= 0:
		return 0.0
	if steps <= 100:
		var exact_total: float = 0.0
		for i: int in range(steps):
			exact_total += round((10.0 + float(start_val + i) * 5.0) * diff_mult)
		return exact_total
	var first_c: float = (10.0 + float(start_val) * 5.0) * diff_mult
	var last_c: float = (10.0 + float(start_val + steps - 1) * 5.0) * diff_mult
	return round((first_c + last_c) * 0.5 * float(steps))


func get_train_bulk_cost(stat_name: String, target_count: int) -> Dictionary:
	var start_val: int = _get_base_stat_value(stat_name)
	var diff_mult: float = get_difficulty_train_mult()
	if target_count > 0:
		return {
			"count": target_count,
			"cost": _sum_train_cost_for_steps(start_val, target_count, diff_mult),
		}
	var one_cost: float = round((10.0 + float(start_val) * 5.0) * diff_mult)
	if gold < one_cost:
		return {"count": 0, "cost": one_cost}
	var upper_bound: int = 1
	while upper_bound < 100000000 and _sum_train_cost_for_steps(start_val, upper_bound, diff_mult) <= gold:
		upper_bound *= 2
	var lo: int = 1
	var hi_bound: int = upper_bound
	var best_k: int = 0
	var best_cost: float = 0.0
	while lo <= hi_bound:
		var mid: int = floori(float(lo + hi_bound) * 0.5)
		var c: float = _sum_train_cost_for_steps(start_val, mid, diff_mult)
		if c <= gold:
			best_k = mid
			best_cost = c
			lo = mid + 1
		else:
			hi_bound = mid - 1
	return {"count": best_k, "cost": best_cost}


func get_item_buy_price(item: ItemData) -> float:
	if item == null:
		return 0.0
	var mult: float = get_difficulty_price_mult() * (1.0 + get_curse_value("greedy_curse"))
	return maxf(1.0, round(float(item.buy_price) * mult))


func get_item_sell_value(item: ItemData) -> float:
	if item == null:
		return 0.0
	var mult: float = pow(1.35, float(difficulty_level - 1))
	return maxf(1.0, round(float(item.sell_value) * mult))


func set_auto_potion(enabled: bool) -> void:
	auto_potion_enabled = enabled
	stats_changed.emit()
	save_game()


func set_auto_hp_settings(enabled: bool, threshold_pct: int, condition: String) -> void:
	auto_potion_enabled = enabled
	auto_hp_threshold_pct = clampi(threshold_pct, 10, 95)
	auto_hp_condition = "always" if condition == "always" else "combat"
	stats_changed.emit()
	save_game()


func set_auto_mana_settings(enabled: bool, threshold_pct: int, condition: String) -> void:
	auto_mana_enabled = enabled
	auto_mana_threshold_pct = clampi(threshold_pct, 10, 95)
	auto_mana_condition = "always" if condition == "always" else "combat"
	stats_changed.emit()
	save_game()


func set_auto_buff_settings(enabled: bool, condition: String) -> void:
	auto_buff_enabled = enabled
	auto_buff_condition = "on_expire_always" if condition == "on_expire_always" else "on_expire_combat"
	stats_changed.emit()
	save_game()


func is_buff_potion_whitelisted(potion_id: String) -> bool:
	if auto_buff_whitelist.is_empty():
		return true
	return auto_buff_whitelist.has(potion_id)


func toggle_buff_potion_whitelist(potion_id: String) -> void:
	if auto_buff_whitelist.is_empty():
		# Enable explicit filter containing everything except toggled item
		for entry: Dictionary in BUFF_POTION_CATALOG:
			var bid: String = str(entry.get("id", ""))
			if not bid.is_empty() and bid != potion_id:
				auto_buff_whitelist.append(bid)
	elif auto_buff_whitelist.has(potion_id):
		auto_buff_whitelist.erase(potion_id)
	else:
		auto_buff_whitelist.append(potion_id)
		if auto_buff_whitelist.size() >= BUFF_POTION_CATALOG.size():
			auto_buff_whitelist.clear()
	stats_changed.emit()
	save_game()


func get_total_potion_count() -> int:
	var total: int = 0
	for entry: Dictionary in inventory:
		var item: ItemData = entry["item"] as ItemData
		if item != null and item.item_type == ItemData.ItemType.CONSUMABLE and (item.heal_amount > 0.0 or item.heal_pct > 0.0):
			total += int(entry["count"])
	return total


func get_total_mana_potion_count() -> int:
	var total: int = 0
	for entry: Dictionary in inventory:
		var item: ItemData = entry["item"] as ItemData
		if item != null and item.item_type == ItemData.ItemType.CONSUMABLE and (item.mana_amount > 0.0 or item.mana_pct > 0.0):
			total += int(entry["count"])
	return total


func use_best_healing_potion() -> String:
	var max_hp: float = get_max_hp()
	if current_hp >= max_hp:
		return "Здоровье уже полное."

	var missing_hp: float = max_hp - current_hp
	var best_item: ItemData = null
	var best_score: float = INF

	for entry: Dictionary in inventory:
		var item: ItemData = entry["item"] as ItemData
		if item == null or item.item_type != ItemData.ItemType.CONSUMABLE:
			continue
		var eff_heal: float = item.heal_amount + max_hp * item.heal_pct
		if eff_heal <= 0.0:
			continue
		var score: float = eff_heal - missing_hp if eff_heal >= missing_hp else 10000.0 - eff_heal
		if score < best_score:
			best_score = score
			best_item = item

	if best_item == null:
		return "Нет зелий лечения."

	return use_or_equip_item(best_item)


func use_best_mana_potion() -> String:
	var max_mp: float = get_max_mana()
	if current_mana >= max_mp:
		return "Мана уже полная."

	var missing_mp: float = max_mp - current_mana
	var best_item: ItemData = null
	var best_score: float = INF

	for entry: Dictionary in inventory:
		var item: ItemData = entry["item"] as ItemData
		if item == null or item.item_type != ItemData.ItemType.CONSUMABLE:
			continue
		var eff_mana: float = item.mana_amount + max_mp * item.mana_pct
		if eff_mana <= 0.0:
			continue
		var score: float = eff_mana - missing_mp if eff_mana >= missing_mp else 10000.0 - eff_mana
		if score < best_score:
			best_score = score
			best_item = item

	if best_item == null:
		return "Нет зелий маны."

	return use_or_equip_item(best_item)


func try_auto_use_potion(is_in_combat: bool = true) -> String:
	if not auto_potion_enabled:
		return ""
	if auto_hp_condition == "combat" and not is_in_combat:
		return ""
	var max_hp: float = get_max_hp()
	if current_hp <= 0.0 or max_hp <= 0.0:
		return ""
	var hp_ratio: float = float(auto_hp_threshold_pct) / 100.0
	if (current_hp / max_hp) >= hp_ratio:
		return ""
	if get_total_potion_count() <= 0:
		return ""
	return use_best_healing_potion()


func try_auto_use_mana_potion(is_in_combat: bool = true) -> String:
	if not auto_mana_enabled:
		return ""
	if auto_mana_condition == "combat" and not is_in_combat:
		return ""
	var max_mp: float = get_max_mana()
	if current_hp <= 0.0 or max_mp <= 0.0:
		return ""
	var mp_ratio: float = float(auto_mana_threshold_pct) / 100.0
	if (current_mana / max_mp) >= mp_ratio:
		return ""
	if get_total_mana_potion_count() <= 0:
		return ""
	return use_best_mana_potion()


func try_auto_use_buff_potions(is_in_combat: bool = true) -> String:
	if not auto_buff_enabled:
		return ""
	if current_hp <= 0.0:
		return ""
	if auto_buff_condition == "on_expire_combat" and not is_in_combat:
		return ""
	for entry: Dictionary in inventory:
		var item: ItemData = entry["item"] as ItemData
		var cnt: int = int(entry["count"])
		if item == null or cnt <= 0 or not item.is_buff_potion():
			continue
		if not is_buff_potion_whitelisted(item.id):
			continue
		var buff_key: String = item.buff_id if not item.buff_id.is_empty() else ("potion_" + item.id)
		if not has_active_buff(buff_key):
			return use_or_equip_item(item)
	return ""


func try_auto_use_all_potions(is_in_combat: bool) -> String:
	var res_hp: String = try_auto_use_potion(is_in_combat)
	if not res_hp.is_empty():
		return res_hp
	var res_mp: String = try_auto_use_mana_potion(is_in_combat)
	if not res_mp.is_empty():
		return res_mp
	var res_buff: String = try_auto_use_buff_potions(is_in_combat)
	return res_buff


func set_afk_mode(enabled: bool) -> void:
	if is_afk_mode == enabled:
		return
	is_afk_mode = enabled
	if is_afk_mode:
		afk_elapsed_seconds = 0.0
		afk_kills = 0
		afk_gold_earned = 0.0
		afk_xp_earned = 0.0
		_afk_ui_sync_timer = 0.0
		Engine.max_fps = afk_target_fps
		DisplayServer.screen_set_keep_on(true)
	else:
		DisplayServer.screen_set_keep_on(false)
		Engine.max_fps = NORMAL_FPS_LIMIT
		save_game()
	afk_mode_changed.emit(is_afk_mode)
	afk_stats_updated.emit(afk_elapsed_seconds, afk_kills, afk_gold_earned, afk_xp_earned)


func record_afk_rewards(xp_earned: float, gold_earned: float) -> void:
	if not is_afk_mode:
		return
	afk_kills += 1
	afk_xp_earned += xp_earned
	afk_gold_earned += gold_earned
	afk_stats_updated.emit(afk_elapsed_seconds, afk_kills, afk_gold_earned, afk_xp_earned)


func is_mine_location(loc: LocationData = null) -> bool:
	var target: LocationData = loc if loc != null else current_location
	return target != null and target.is_one_attempt_mine


func is_location_unlocked(location: LocationData) -> bool:
	if location == null:
		return false
	if location.is_one_attempt_mine and mine_locked_this_run:
		return false
	if max_unlocked_difficulty < location.required_difficulty:
		return false
	if location.always_open_once_unlocked:
		return true
	return level >= location.required_level


func select_location(location: LocationData) -> bool:
	if location == null or not is_location_unlocked(location):
		return false
	if current_location == location:
		return false
	if wave_dungeon_active:
		wave_dungeon_active = false
		wave_dungeon_wave = 0
		wave_dungeon_changed.emit()
	current_location = location
	consecutive_location_wins = 0
	if current_location.is_one_attempt_mine and mine_depth < maxi(0, mine_start_depth - 1):
		mine_depth = maxi(0, mine_start_depth - 1)
		mine_state_changed.emit()
	location_changed.emit(current_location)
	save_game()
	return true


func is_mine_checkpoint_unlocked(depth: int) -> bool:
	return depth <= 1 or unlocked_mine_checkpoints.has(depth)


func get_mine_checkpoint_cost(depth: int) -> int:
	return int(MINE_CHECKPOINT_COSTS.get(depth, 10))


func buy_mine_checkpoint(depth: int) -> Dictionary:
	if not MINE_CHECKPOINT_DEPTHS.has(depth):
		return {"success": false, "message": "Неизвестный чекпоинт."}
	if is_mine_checkpoint_unlocked(depth):
		mine_start_depth = depth
		mine_state_changed.emit()
		save_game()
		return {"success": true, "message": "⛏️ Точка старта в Шахте установлена: Глубина %d." % depth}
	var cost: int = get_mine_checkpoint_cost(depth)
	var ore_item: ItemData = get_cached_item("res://resources/items/abyss_ore.tres")
	if ore_item == null or not remove_item(ore_item, cost):
		return {"success": false, "message": "Нужно %d ⛏️ Руды Бездны для открытия Глубины %d." % [cost, depth]}
	unlocked_mine_checkpoints.append(depth)
	mine_start_depth = depth
	mine_state_changed.emit()
	save_game()
	return {"success": true, "message": "⛏️ Чекпоинт Шахты (Глубина %d) открыт навсегда!" % depth}


func set_mine_start_depth(depth: int) -> void:
	if not is_mine_checkpoint_unlocked(depth):
		return
	mine_start_depth = maxi(1, depth)
	mine_state_changed.emit()
	save_game()


func set_auto_route_settings(enabled: bool, threshold: int) -> void:
	auto_route_enabled = enabled
	auto_route_wins_threshold = clampi(threshold, 3, 25)
	if not auto_route_enabled:
		consecutive_location_wins = 0
	stats_changed.emit()
	save_game()


func record_location_win_for_auto_route() -> String:
	if wave_dungeon_active or is_mine_location():
		return ""
	consecutive_location_wins += 1
	if not auto_route_enabled or consecutive_location_wins < auto_route_wins_threshold:
		return ""
	var cur_idx: int = locations.find(current_location)
	if cur_idx < 0:
		return ""
	for next_i: int in range(cur_idx + 1, locations.size()):
		var candidate: LocationData = locations[next_i]
		if candidate != null and not candidate.is_one_attempt_mine and is_location_unlocked(candidate):
			if select_location(candidate):
				return "🧭 Авто-маршрут: переход в «%s»!" % candidate.location_name
	return ""


func retreat_to_safer_location() -> String:
	if locations.is_empty():
		return ""
	var cur_idx: int = locations.find(current_location)
	if cur_idx <= 0:
		heal(get_max_hp() * 0.25)
		return ""
	for prev_i: int in range(cur_idx - 1, -1, -1):
		var candidate: LocationData = locations[prev_i]
		if candidate != null and not candidate.is_one_attempt_mine and is_location_unlocked(candidate):
			select_location(candidate)
			heal(get_max_hp() * 0.25)
			return "🧭 Отступление в «%s» при критическом HP!" % candidate.location_name
	return ""


func record_bestiary_kill(enemy_id: String) -> void:
	if enemy_id.is_empty():
		return
	bestiary_kills[enemy_id] = get_bestiary_kills(enemy_id) + 1
	bestiary_changed.emit()


func get_bestiary_kills(enemy_id: String) -> int:
	return maxi(0, int(bestiary_kills.get(enemy_id, 0)))


func get_bestiary_damage_bonus(enemy_id: String) -> float:
	var kills: int = get_bestiary_kills(enemy_id)
	var bonus: float = 0.0
	for m: Dictionary in BESTIARY_MILESTONES:
		if kills >= int(m["kills"]):
			bonus += float(m["dmg_bonus"])
	return bonus


func get_bestiary_gold_bonus(enemy_id: String) -> float:
	return 0.03 if get_bestiary_kills(enemy_id) >= 1000 else 0.0


func get_bestiary_drop_bonus(enemy_id: String) -> float:
	return 0.10 if get_bestiary_kills(enemy_id) >= 10000 else 0.0


func can_sacrifice_to_well() -> Dictionary:
	if well_greed_cooldown_remaining > 0.0:
		var mins: int = ceili(well_greed_cooldown_remaining / 60.0)
		return {"ok": false, "reason": "Колодец Жадности восстанавливается (%d мин)." % mins}
	if gold < 100.0:
		return {"ok": false, "reason": "Минимум для жертвы — 100 золота."}
	return {"ok": true, "reason": "Готов принять всё золото (%s з.)." % NumberFormatter.format_number(gold)}


func get_well_blessing_label() -> String:
	match well_run_blessing:
		"damage_surge":
			return "🔥 Благословение: +15% урона"
		"barrier_surge":
			return "🛡️ Благословение: +25% Барьера, +12% Max HP"
		"greed_fortune":
			return "🪙 Благословение: +25% золота"
		"arcane_overdrive":
			return "🔮 Благословение: +20% Чар, -15% КД"
	return "Нет активного благословения рана"


func sacrifice_all_gold_to_well() -> Dictionary:
	var check: Dictionary = can_sacrifice_to_well()
	if not bool(check.get("ok", false)):
		return {"success": false, "message": str(check.get("reason", ""))}
	var sacrificed: float = gold
	gold = 0.0
	well_greed_cooldown_remaining = WELL_OF_GREED_COOLDOWN

	var tier: int = clampi(int(floor(log(maxf(10.0, sacrificed)) / log(10.0))) - 1, 1, 6)
	var rewards: Array[String] = []
	var ore_amt: int = maxi(1, tier)
	var ore_item: ItemData = get_cached_item("res://resources/items/abyss_ore.tres")
	if ore_item != null:
		add_item(ore_item, ore_amt, true)
		rewards.append("⛏️ Руда Бездны x%d" % ore_amt)

	var page_amt: int = maxi(1, floori(float(tier + 1) / 2.0))
	var page_item: ItemData = get_cached_item("res://resources/items/ancient_page.tres")
	if page_item != null:
		add_item(page_item, page_amt, true)
		rewards.append("📜 Древний лист x%d" % page_amt)

	if tier >= 3:
		curse_reroll_tokens += 1
		rewards.append("🎲 Жетон реролла x1")

	var seed_paths: Array[String] = [
		"res://resources/items/moon_mint_seed.tres",
		"res://resources/items/sun_root_seed.tres",
		"res://resources/items/light_clover_seed.tres",
		"res://resources/items/honey_berry_seed.tres",
	]
	var s_item: ItemData = get_cached_item(seed_paths[randi() % seed_paths.size()])
	if s_item != null:
		add_item(s_item, 1, true)
		rewards.append(s_item.get_display_name())

	var blessings: Array[String] = ["damage_surge", "barrier_surge", "greed_fortune", "arcane_overdrive"]
	well_run_blessing = blessings[randi() % blessings.size()]
	mark_stats_dirty()
	stats_changed.emit()
	hp_changed.emit(current_hp, get_max_hp())
	barrier_changed.emit(current_barrier, get_max_barrier())
	save_game()
	return {
		"success": true,
		"message": "⛲ Пожертвовано %s з.! Получено: %s | %s" % [
			NumberFormatter.format_number(sacrificed),
			", ".join(rewards),
			get_well_blessing_label(),
		],
	}


func _ensure_loadouts() -> void:
	while combat_loadouts.size() < LOADOUT_COUNT:
		var idx: int = combat_loadouts.size() + 1
		combat_loadouts.append({
			"saved": false,
			"name": "Комплект %d" % idx,
			"class_id": "",
			"weapon_path": "",
			"armor_path": "",
			"offhand_path": "",
			"ammo_path": "",
			"ability_ids": [],
			"pet_id": "",
		})
	if combat_loadouts.size() > LOADOUT_COUNT:
		combat_loadouts.resize(LOADOUT_COUNT)


func has_combat_loadout_saved(idx: int) -> bool:
	_ensure_loadouts()
	if idx < 0 or idx >= combat_loadouts.size():
		return false
	return bool(combat_loadouts[idx].get("saved", false))


func get_combat_loadout_summary(idx: int) -> String:
	_ensure_loadouts()
	if idx < 0 or idx >= combat_loadouts.size():
		return "Пусто"
	var l: Dictionary = combat_loadouts[idx]
	if not bool(l.get("saved", false)):
		return "Пустой слот — нажмите «💾 Сохранить»"
	var hc: HeroClassData = get_class_by_id(str(l.get("class_id", "wanderer")))
	var cls_title: String = hc.title if hc != null else str(l.get("class_id", ""))
	var w_item: ItemData = get_cached_item(str(l.get("weapon_path", "")))
	var o_item: ItemData = get_cached_item(str(l.get("offhand_path", "")))
	return "%s | %s | %s" % [
		cls_title,
		w_item.item_name if w_item != null else "без оружия",
		o_item.item_name if o_item != null else "без оффхенда",
	]


func save_combat_loadout(idx: int) -> Dictionary:
	_ensure_loadouts()
	if idx < 0 or idx >= LOADOUT_COUNT:
		return {"success": false, "message": "Неверный слот комплекта."}
	combat_loadouts[idx] = {
		"saved": true,
		"name": "Комплект %d" % (idx + 1),
		"class_id": selected_class_id,
		"weapon_path": equipped_weapon.resource_path if equipped_weapon != null else "",
		"armor_path": equipped_armor.resource_path if equipped_armor != null else "",
		"offhand_path": equipped_offhand.resource_path if equipped_offhand != null else "",
		"ammo_path": equipped_ammo.resource_path if equipped_ammo != null else "",
		"ability_ids": equipped_ability_ids.duplicate(),
		"pet_id": equipped_pet_id,
	}
	loadouts_changed.emit()
	save_game()
	return {"success": true, "message": "💾 Комплект %d сохранён!" % (idx + 1)}


func _equip_best_matching_path(target_path: String, expected_type: ItemData.ItemType) -> void:
	if target_path.is_empty():
		return
	var current_item: ItemData = get_equipped_slot_item(expected_type)
	if current_item != null and current_item.resource_path == target_path:
		return
	var best_idx: int = -1
	var best_score: int = -1
	for i: int in range(inventory.size()):
		var entry: Dictionary = inventory[i]
		var it: ItemData = entry["item"] as ItemData
		if it != null and it.item_type == expected_type and it.resource_path == target_path:
			var sc: int = get_entry_stars(entry) * 1000 + get_entry_quality(entry)
			if sc > best_score:
				best_score = sc
				best_idx = i
	if best_idx >= 0:
		var chosen: Dictionary = inventory[best_idx]
		use_or_equip_item(chosen["item"] as ItemData, get_entry_quality(chosen), get_entry_stars(chosen))


func apply_combat_loadout(idx: int) -> Dictionary:
	_ensure_loadouts()
	if idx < 0 or idx >= LOADOUT_COUNT:
		return {"success": false, "message": "Комплект не найден."}
	var l: Dictionary = combat_loadouts[idx]
	if not bool(l.get("saved", false)):
		return {"success": false, "message": "Комплект %d ещё пуст." % (idx + 1)}
	var cls_id: String = str(l.get("class_id", ""))
	if not cls_id.is_empty() and cls_id != selected_class_id:
		select_hero_class(cls_id)

	var w_path: String = str(l.get("weapon_path", ""))
	if w_path.is_empty():
		unequip_slot(ItemData.ItemType.WEAPON)
	else:
		_equip_best_matching_path(w_path, ItemData.ItemType.WEAPON)

	var a_path: String = str(l.get("armor_path", ""))
	if a_path.is_empty():
		unequip_slot(ItemData.ItemType.ARMOR)
	else:
		_equip_best_matching_path(a_path, ItemData.ItemType.ARMOR)

	var o_path: String = str(l.get("offhand_path", ""))
	if o_path.is_empty():
		unequip_slot(ItemData.ItemType.OFFHAND)
	else:
		_equip_best_matching_path(o_path, ItemData.ItemType.OFFHAND)

	var am_path: String = str(l.get("ammo_path", ""))
	if not am_path.is_empty() and (equipped_ammo == null or equipped_ammo.resource_path != am_path):
		var am_item: ItemData = get_cached_item(am_path)
		if am_item != null and get_item_count_in_inventory(am_item) > 0:
			use_or_equip_item(am_item)

	var saved_ab: Variant = l.get("ability_ids", [])
	if saved_ab is Array:
		var ab_arr: Array = saved_ab as Array
		for s_i: int in range(mini(MAX_ACTIVE_ABILITY_SLOTS, ab_arr.size())):
			var aid: String = str(ab_arr[s_i])
			if aid.is_empty():
				clear_ability_slot(s_i)
			else:
				equip_ability_to_slot(aid, s_i)

	var p_id: String = str(l.get("pet_id", ""))
	if p_id.is_empty():
		unequip_pet()
	elif has_pet_owned(p_id) and not is_pet_on_expedition(p_id):
		equip_pet(p_id)

	mark_stats_dirty()
	loadouts_changed.emit()
	save_game()
	return {"success": true, "message": "🎒 Применён Комплект %d!" % (idx + 1)}


func start_wave_dungeon() -> Dictionary:
	if wave_dungeon_active:
		return {"success": false, "message": "Данж волн уже запущен!"}
	_wave_dungeon_return_location_id = current_location.id if current_location != null else "quiet_glade"
	wave_dungeon_active = true
	wave_dungeon_wave = 1
	restore_barrier_full()
	wave_dungeon_changed.emit()
	return {"success": true, "message": "🏰 Вход в Данж волн (10 волн)! Бой начался!"}


func abort_wave_dungeon() -> void:
	if not wave_dungeon_active:
		return
	wave_dungeon_active = false
	wave_dungeon_wave = 0
	var ret_loc: LocationData = get_location_by_id(_wave_dungeon_return_location_id)
	if ret_loc != null and is_location_unlocked(ret_loc):
		current_location = ret_loc
		location_changed.emit(current_location)
	wave_dungeon_changed.emit()


func get_wave_dungeon_enemy_for_wave(wave_idx: int) -> EnemyData:
	if all_enemies.is_empty():
		return null
	if wave_idx >= WAVE_DUNGEON_TOTAL_WAVES:
		if _enemies_by_id.has("curse_warden"):
			return _enemies_by_id["curse_warden"] as EnemyData
	var unlocked_pool: Array[EnemyData] = []
	for loc: LocationData in locations:
		if loc != null and not loc.is_one_attempt_mine and loc.id != FINAL_BOSS_LOCATION_ID and is_location_unlocked(loc):
			for e: EnemyData in loc.enemies:
				if e != null and not unlocked_pool.has(e):
					unlocked_pool.append(e)
	if unlocked_pool.is_empty():
		unlocked_pool = all_enemies.duplicate()
	var idx: int = clampi(floori(float(wave_idx - 1) * float(unlocked_pool.size()) / float(WAVE_DUNGEON_TOTAL_WAVES)), 0, unlocked_pool.size() - 1)
	return unlocked_pool[idx]


func advance_wave_dungeon_on_kill() -> Dictionary:
	if not wave_dungeon_active:
		return {"completed": false, "message": ""}
	if wave_dungeon_wave < WAVE_DUNGEON_TOTAL_WAVES:
		wave_dungeon_wave += 1
		wave_dungeon_changed.emit()
		return {"completed": false, "message": "🏰 Волна %d / %d!" % [wave_dungeon_wave, WAVE_DUNGEON_TOTAL_WAVES]}

	wave_dungeon_active = false
	wave_dungeon_wave = 0
	wave_dungeon_clears += 1
	var ore_item: ItemData = get_cached_item("res://resources/items/abyss_ore.tres")
	if ore_item != null:
		add_item(ore_item, 2, true)
	var page_item: ItemData = get_cached_item("res://resources/items/ancient_page.tres")
	if page_item != null:
		add_item(page_item, 2, true)
	var chest_gold: float = round(450.0 * get_gold_multiplier())
	add_gold(chest_gold)
	var chest_offhand: ItemData = get_cached_item("res://resources/items/aegis_bulwark_shield.tres" if randf() < 0.5 else "res://resources/items/astral_arcane_talisman.tres")
	var bonus_drop: String = ""
	if chest_offhand != null and max_unlocked_difficulty >= 5:
		add_item(chest_offhand, 1, true, 100, 1, true)
		bonus_drop = " + %s" % chest_offhand.get_display_name()

	var ret_loc: LocationData = get_location_by_id(_wave_dungeon_return_location_id)
	if ret_loc != null and is_location_unlocked(ret_loc) and current_location != ret_loc:
		current_location = ret_loc
		location_changed.emit(current_location)
	wave_dungeon_changed.emit()
	save_game()
	return {
		"completed": true,
		"message": "🏆 Сундук Данжа волн: +%s з., ⛏️ Руда x2, 📜 Листы x2%s!" % [
			NumberFormatter.format_number(chest_gold),
			bonus_drop,
		],
	}


func record_mine_kill() -> void:
	if not is_mine_location():
		return
	mine_depth += 1
	mine_state_changed.emit()


func fail_mine_run() -> void:
	if not is_mine_location():
		return
	var reached: int = mine_depth
	mine_locked_this_run = true
	if not locations.is_empty():
		current_location = locations[0]
	mine_state_changed.emit()
	mine_run_failed.emit(reached)
	if current_location != null:
		location_changed.emit(current_location)
	save_game(true)


func roll_mine_ambient_find() -> String:
	if not is_mine_location():
		return ""
	var r: float = randf()
	if r < 0.44:
		var ore_item: ItemData = get_cached_item("res://resources/items/abyss_ore.tres")
		if ore_item != null:
			add_item(ore_item, 1, true)
			return "⛏️ Найдена жила: +1 Руда Бездны!"
	elif r < 0.78:
		var page_item: ItemData = get_cached_item("res://resources/items/ancient_page.tres")
		if page_item != null:
			add_item(page_item, 1, true)
			return "📜 Найден тайник: +1 Древний лист!"
	else:
		var bonus_gold: float = round((25.0 + float(mine_depth) * 8.0) * get_gold_multiplier())
		add_gold(bonus_gold)
		return "🪙 Золотая жила: +%s з." % NumberFormatter.format_number(bonus_gold)
	return ""


func add_xp(amount: float) -> void:
	if amount <= 0.0:
		return
	current_xp += amount
	var leveled_up_any: bool = false
	while current_xp >= get_xp_to_next_level():
		current_xp -= get_xp_to_next_level()
		level += 1
		skill_points += 1
		current_hp = get_max_hp()
		current_mana = get_max_mana()
		leveled_up_any = true
		level_up.emit(level)
	if leveled_up_any and skill_auto_upgrade_enabled:
		try_apply_skill_preset(false)
	stats_changed.emit()
	skills_changed.emit()
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())


func add_gold(amount: float) -> void:
	if amount <= 0.0:
		return
	gold += amount
	stats_changed.emit()


func record_kill() -> void:
	enemies_defeated += 1
	kills_in_run += 1
	if has_hero_class("reflector"):
		var prev_max_hp: float = get_max_hp()
		reflector_kill_hp_stacks += 1
		mark_stats_dirty()
		var new_max_hp: float = get_max_hp()
		var hp_gain: float = maxf(20.0, new_max_hp - prev_max_hp)
		current_hp = minf(new_max_hp, current_hp + hp_gain)
		hp_changed.emit(current_hp, new_max_hp)
	stats_changed.emit()


func apply_damage(raw_damage: float) -> float:
	var reduced: float = maxf(1.0, raw_damage - get_armor_reduction())
	if has_dark_skill("arcane_barrier") and current_mana > 0.0:
		var mana_shield_cap: float = minf(current_mana, reduced * get_dark_bonus("arcane_barrier"))
		if mana_shield_cap > 0.0:
			spend_mana(mana_shield_cap)
			reduced = maxf(1.0, reduced - mana_shield_cap)
	if not has_hero_class("reflector") and current_barrier > 0.0:
		var absorbed: float = minf(current_barrier, reduced)
		current_barrier = maxf(0.0, current_barrier - absorbed)
		reduced = maxf(0.0, reduced - absorbed)
		barrier_changed.emit(current_barrier, maxf(get_max_barrier(), current_barrier))
	if reduced > 0.0:
		current_hp = maxf(0.0, current_hp - reduced)
		hp_changed.emit(current_hp, get_max_hp())
	return reduced


func apply_rot_damage(amount: float, emit_signal_immediately: bool = true) -> void:
	if amount <= 0.0:
		return
	current_hp = maxf(0.0, current_hp - amount)
	if emit_signal_immediately or current_hp <= 0.0:
		_hp_ui_dirty = false
		hp_changed.emit(current_hp, get_max_hp())
	else:
		_hp_ui_dirty = true


func heal(amount: float, emit_signal_immediately: bool = true) -> float:
	if amount <= 0.0:
		return 0.0
	var max_hp: float = get_max_hp()
	var prev_hp: float = current_hp
	current_hp = minf(max_hp, current_hp + amount)
	var actual: float = current_hp - prev_hp
	if actual > 0.0:
		if emit_signal_immediately or current_hp >= max_hp:
			_hp_ui_dirty = false
			hp_changed.emit(current_hp, max_hp)
		else:
			_hp_ui_dirty = true
	return actual


func upgrade_stat_with_skill_point(stat_name: String) -> bool:
	return upgrade_stat_with_skill_points_bulk(stat_name, 1) > 0


func upgrade_stat_with_skill_points_bulk(stat_name: String, target_count: int) -> int:
	if skill_points <= 0:
		return 0
	var actual_count: int = skill_points if target_count <= 0 else mini(target_count, skill_points)
	if actual_count <= 0:
		return 0
	var prev_max_hp: float = get_max_hp()
	var prev_max_mana: float = get_max_mana()
	if not _add_base_stat(stat_name, actual_count):
		return 0
	skill_points -= actual_count
	mark_stats_dirty()
	var new_max_hp: float = get_max_hp()
	var new_max_mana: float = get_max_mana()
	if new_max_hp > prev_max_hp:
		current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))
	if new_max_mana > prev_max_mana:
		current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))
	stats_changed.emit()
	skills_changed.emit()
	hp_changed.emit(current_hp, new_max_hp)
	mana_changed.emit(current_mana, new_max_mana)
	barrier_changed.emit(current_barrier, get_max_barrier())
	save_game()
	return actual_count


func train_stat_with_gold(stat_name: String) -> bool:
	return train_stat_with_gold_bulk(stat_name, 1) > 0


func train_stat_with_gold_bulk(stat_name: String, target_count: int) -> int:
	var bulk_info: Dictionary = get_train_bulk_cost(stat_name, target_count)
	var actual_count: int = int(bulk_info.get("count", 0))
	var cost: float = float(bulk_info.get("cost", 0.0))
	if actual_count <= 0 or gold < cost:
		return 0
	var prev_max_hp: float = get_max_hp()
	var prev_max_mana: float = get_max_mana()
	if not _add_base_stat(stat_name, actual_count):
		return 0
	gold -= cost
	mark_stats_dirty()
	var new_max_hp: float = get_max_hp()
	var new_max_mana: float = get_max_mana()
	if new_max_hp > prev_max_hp:
		current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))
	if new_max_mana > prev_max_mana:
		current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))
	stats_changed.emit()
	hp_changed.emit(current_hp, new_max_hp)
	mana_changed.emit(current_mana, new_max_mana)
	barrier_changed.emit(current_barrier, get_max_barrier())
	save_game()
	return actual_count


func _increment_base_stat(stat_name: String) -> bool:
	return _add_base_stat(stat_name, 1)


func _add_base_stat(stat_name: String, amount: int) -> bool:
	if amount <= 0:
		return false
	match stat_name:
		"strength":
			base_strength += amount
			return true
		"agility":
			base_agility += amount
			return true
		"endurance":
			base_endurance += amount
			return true
		"intellect":
			base_intellect += amount
			return true
	return false


func get_entry_quality(entry: Dictionary) -> int:
	return clampi(int(entry.get("quality_pct", 100)), 80, 125)


func get_entry_stars(entry: Dictionary) -> int:
	return clampi(int(entry.get("star_level", 1)), 1, 5)


func set_auto_salvage_settings(mode: String, min_quality: int) -> void:
	if mode == "sell" or mode == "salvage":
		auto_salvage_mode = mode
	else:
		auto_salvage_mode = "off"
	auto_salvage_min_quality = clampi(min_quality, 80, 125)
	inventory_changed.emit()
	save_game()


func add_item(item: ItemData, amount: int = 1, notify: bool = true, quality_pct: int = 100, star_level: int = 1, from_loot: bool = false) -> void:
	if item == null or amount <= 0:
		return
	var is_gear: bool = item.is_equipment()
	var final_q: int = randi_range(80, 125) if (from_loot and is_gear) else (clampi(quality_pct, 80, 125) if is_gear else 100)
	var final_s: int = clampi(star_level, 1, 5) if is_gear else 1

	if from_loot and is_gear and not item.is_dark_forged and auto_salvage_mode != "off" and final_q < auto_salvage_min_quality:
		if auto_salvage_mode == "sell":
			var sell_g: float = maxf(1.0, round(get_item_sell_value(item) * get_quality_multiplier(final_q) * float(amount)))
			add_gold(sell_g)
			return
		elif auto_salvage_mode == "salvage":
			abyss_ore_shards += amount
			var forged_ores: int = floori(float(abyss_ore_shards) / 10.0)
			if forged_ores > 0:
				abyss_ore_shards -= forged_ores * 10
				var ore_item: ItemData = get_cached_item("res://resources/items/abyss_ore.tres")
				if ore_item != null:
					add_item(ore_item, forged_ores, true, 100, 1, false)
			inventory_changed.emit()
			stats_changed.emit()
			return

	if item.item_type == ItemData.ItemType.AMMO and equipped_ammo != null and equipped_ammo.id == item.id and not is_equipment_disabled():
		equipped_ammo_count += amount
		inventory_changed.emit()
		stats_changed.emit()
		if notify:
			item_acquired.emit(item, amount)
		return
	for entry: Dictionary in inventory:
		var existing: ItemData = entry["item"] as ItemData
		if existing != null and existing.id == item.id:
			if not is_gear or (get_entry_quality(entry) == final_q and get_entry_stars(entry) == final_s):
				entry["count"] = int(entry["count"]) + amount
				inventory_changed.emit()
				if notify:
					item_acquired.emit(item, amount)
				return
	inventory.append({"item": item, "count": amount, "quality_pct": final_q, "star_level": final_s})
	inventory_changed.emit()
	if notify:
		item_acquired.emit(item, amount)


func remove_item(item: ItemData, amount: int = 1, quality_pct: int = -1, star_level: int = -1) -> bool:
	if item == null or amount <= 0:
		return false
	for i: int in range(inventory.size()):
		var entry: Dictionary = inventory[i]
		var existing: ItemData = entry["item"] as ItemData
		if existing != null and existing.id == item.id:
			if quality_pct >= 0 and get_entry_quality(entry) != quality_pct:
				continue
			if star_level >= 1 and get_entry_stars(entry) != star_level:
				continue
			var count: int = int(entry["count"])
			if count < amount:
				return false
			var remaining: int = count - amount
			if remaining <= 0:
				inventory.remove_at(i)
			else:
				entry["count"] = remaining
			inventory_changed.emit()
			return true
	return false


func get_item_count_in_inventory(item: ItemData) -> int:
	if item == null:
		return 0
	var total: int = 0
	for entry: Dictionary in inventory:
		var existing: ItemData = entry["item"] as ItemData
		if existing != null and existing.id == item.id:
			total += int(entry["count"])
	return total


func get_merge_candidates() -> Array[Dictionary]:
	var buckets: Dictionary = {}
	for entry: Dictionary in inventory:
		var it: ItemData = entry["item"] as ItemData
		if it == null or not it.is_equipment():
			continue
		var stars: int = get_entry_stars(entry)
		if stars >= 5:
			continue
		var key: String = "%s|%d" % [it.id, stars]
		if not buckets.has(key):
			buckets[key] = {"item": it, "star_level": stars, "total": 0, "max_quality": 80}
		var b: Dictionary = buckets[key] as Dictionary
		b["total"] = int(b["total"]) + int(entry["count"])
		b["max_quality"] = maxi(int(b["max_quality"]), get_entry_quality(entry))
	var res: Array[Dictionary] = []
	for k: Variant in buckets.keys():
		var b: Dictionary = buckets[k] as Dictionary
		if int(b["total"]) >= 2:
			res.append(b)
	return res


func merge_duplicate_item(item_id: String, star_level: int) -> Dictionary:
	if star_level < 1 or star_level >= 5:
		return {"success": false, "message": "Максимальный уровень слияния: ★5."}
	var matching: Array[Dictionary] = []
	var total_cnt: int = 0
	var target_item: ItemData = null
	var best_q: int = 80
	for entry: Dictionary in inventory:
		var it: ItemData = entry["item"] as ItemData
		if it != null and it.id == item_id and get_entry_stars(entry) == star_level:
			matching.append(entry)
			total_cnt += int(entry["count"])
			target_item = it
			best_q = maxi(best_q, get_entry_quality(entry))
	if target_item == null or total_cnt < 2:
		return {"success": false, "message": "Нужно минимум 2 дубликата одного ★ уровня."}

	matching.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return get_entry_quality(a) < get_entry_quality(b)
	)
	var consumed: int = 0
	for m: Dictionary in matching:
		var q: int = get_entry_quality(m)
		var avail: int = int(m["count"])
		var take: int = mini(2 - consumed, avail)
		if take > 0 and remove_item(target_item, take, q, star_level):
			consumed += take
		if consumed >= 2:
			break
	if consumed < 2:
		return {"success": false, "message": "Не удалось объединить дубликаты."}

	var next_star: int = star_level + 1
	add_item(target_item, 1, true, best_q, next_star, false)
	save_game()
	return {
		"success": true,
		"message": "⭐ Слияние! %s улучшен до ★%d (%d%% кач.)!" % [target_item.get_display_name(), next_star, best_q],
	}


func sell_item(item: ItemData, amount: int = 1, quality_pct: int = -1, star_level: int = -1) -> String:
	if item == null or amount <= 0:
		return ""
	var use_q: int = quality_pct
	var use_s: int = star_level
	if use_q < 0 or use_s < 1:
		for entry: Dictionary in inventory:
			var ex: ItemData = entry["item"] as ItemData
			if ex != null and ex.id == item.id:
				use_q = get_entry_quality(entry)
				use_s = get_entry_stars(entry)
				break
	if not remove_item(item, amount, quality_pct, star_level):
		return ""
	var gear_scale: float = (get_quality_multiplier(use_q) * get_star_multiplier(use_s)) if item.is_equipment() else 1.0
	var total_gold: float = maxf(1.0, round(get_item_sell_value(item) * gear_scale)) * float(amount)
	add_gold(total_gold)
	save_game()
	return "Продано %s x%d (+%s з.)." % [
		item.get_display_name(),
		amount,
		NumberFormatter.format_number(total_gold),
	]


func buy_item(item: ItemData) -> String:
	if item == null:
		return ""
	var price: float = get_item_buy_price(item)
	if gold < price:
		return "Недостаточно золота для покупки %s." % item.get_display_name()
	gold -= price
	var pack_amt: int = maxi(1, item.shop_pack_amount)
	if item.item_type == ItemData.ItemType.AMMO and equipped_ammo == null and not is_equipment_disabled():
		equipped_ammo = item
		equipped_ammo_count = pack_amt
		inventory_changed.emit()
	else:
		add_item(item, pack_amt, false)
	stats_changed.emit()
	save_game()
	return "Куплено: %s x%d за %s з." % [
		item.get_display_name(),
		pack_amt,
		NumberFormatter.format_number(price),
	]


func get_dark_shop_item_price(item: ItemData) -> int:
	if item == null:
		return 1
	return maxi(1, item.dark_shop_coin_price)


func buy_dark_shop_item(item: ItemData) -> Dictionary:
	if item == null:
		return {"success": false, "message": "Товар не найден."}
	var price: int = get_dark_shop_item_price(item)
	if dark_shop_coins < price:
		return {
			"success": false,
			"message": "Недостаточно монет Тёмного магазина (нужно %d 🪙, есть %d)." % [price, dark_shop_coins],
		}
	dark_shop_coins -= price
	var pack_amt: int = maxi(1, item.shop_pack_amount)
	add_item(item, pack_amt, false)
	dark_shop_changed.emit()
	stats_changed.emit()
	save_game()
	return {
		"success": true,
		"message": "✅ Куплено: %s x%d за %d 🪙! (Внимание: неиспользованные расходники пропадут при Новом ране)" % [
			item.get_display_name(),
			pack_amt,
			price,
		],
	}


func apply_potion_buff(item: ItemData, duration_scale: float = 1.0) -> void:
	if item == null or not item.is_buff_potion():
		return
	var buff_key: String = item.buff_id if not item.buff_id.is_empty() else ("potion_" + item.id)
	var final_dur: float = maxf(1.0, item.buff_duration * duration_scale)
	var entry: Dictionary = {
		"id": buff_key,
		"title": item.item_name,
		"icon_emoji": item.icon_emoji,
		"remaining": final_dur,
		"duration": final_dur,
		"damage_pct": item.buff_damage_pct,
		"attack_speed_pct": item.buff_attack_speed_pct,
		"armor_pct": item.buff_armor_pct,
		"dodge_bonus": item.buff_dodge_bonus,
		"crit_chance_bonus": item.buff_crit_chance_bonus,
		"crit_mult_bonus": item.buff_crit_mult_bonus,
		"spell_power_pct": item.buff_spell_power_pct,
		"mana_regen_pct": item.buff_mana_regen_pct,
		"lifesteal_pct": item.buff_lifesteal_pct,
		"thorns_pct": 0.0,
	}
	var replaced: bool = false
	for i: int in range(active_buffs.size()):
		if str(active_buffs[i]["id"]) == buff_key:
			active_buffs[i] = entry
			replaced = true
			break
	if not replaced:
		active_buffs.append(entry)
	buffs_changed.emit()
	stats_changed.emit()


func use_or_equip_item(item: ItemData, quality_pct: int = -1, star_level: int = -1) -> String:
	if item == null:
		return ""
	match item.item_type:
		ItemData.ItemType.CONSUMABLE:
			if item.resets_claimed_difficulties:
				if dark_points_claimed_difficulties.is_empty():
					return "Отметки пройденных сложностей уже пусты — все 🌑 награды доступны."
				if remove_item(item, 1):
					var reset_res: Dictionary = reset_claimed_difficulties_rewards()
					return str(reset_res.get("message", ""))
				return "Не найден предмет в инвентаре."
			if is_potions_blocked_by_challenge():
				return "🏆 Испытание «Без зелий до Титана» блокирует использование зелий!"
			var has_heal: bool = item.heal_amount > 0.0 or item.heal_pct > 0.0
			var has_mana: bool = item.mana_amount > 0.0 or item.mana_pct > 0.0
			var has_buff: bool = item.is_buff_potion()
			var need_heal: bool = current_hp < get_max_hp()
			var need_mana: bool = current_mana < get_max_mana()

			if not has_buff:
				if has_heal and not has_mana and not need_heal:
					return "Здоровье уже полное."
				if has_mana and not has_heal and not need_mana:
					return "Мана уже полная."
				if has_heal and has_mana and not need_heal and not need_mana:
					return "Здоровье и мана уже полные."

			var saved_potion: bool = has_hero_class("alchemist") and randf() < 0.20
			var consumed: bool = true if saved_potion else remove_item(item, 1)
			if consumed:
				var parts: Array[String] = []
				var cauldron_bonus: float = 1.0 + get_skill_bonus("alchemy_cauldron")
				var alch_mult: float = 1.60 if has_hero_class("alchemist") else 1.0
				if has_heal:
					var heal_mult: float = maxf(0.25, 1.0 - get_curse_value("blood_tax")) * alch_mult * cauldron_bonus
					var raw_heal: float = item.heal_amount * heal_mult + get_max_hp() * item.heal_pct
					var healed: float = heal(raw_heal)
					player_healed.emit(healed)
					parts.append("+%s HP" % NumberFormatter.format_number(healed))
				if has_mana:
					var mana_mult: float = alch_mult * cauldron_bonus
					var raw_mana: float = item.mana_amount * mana_mult + get_max_mana() * item.mana_pct
					var restored: float = restore_mana(raw_mana)
					parts.append("+%s MP" % NumberFormatter.format_number(restored))
				if has_buff:
					var dur_scale: float = cauldron_bonus * (1.30 if has_hero_class("alchemist") else 1.0) * get_effect_duration_multiplier()
					apply_potion_buff(item, dur_scale)
					parts.append("бафф %.0fс" % (item.buff_duration * dur_scale))
				save_game()
				var suffix: String = " (⚗️ Зелье сохранено!)" if saved_potion else ""
				return "Использовано %s (%s)%s." % [
					item.get_display_name(),
					", ".join(parts),
					suffix,
				]
		ItemData.ItemType.SEED:
			var seed_crop: CropData = get_crop_by_id(item.seed_crop_id)
			var plant_res: Dictionary = plant_light_seed_in_first_empty_plot(item) if (seed_crop != null and seed_crop.is_light_crop()) else plant_seed_in_first_empty_plot(item)
			return str(plant_res.get("message", ""))
		ItemData.ItemType.HARVEST:
			if item.garden_category == "light":
				return "Светлое растение %s используется для дрессировки путников (пряник) или подкормки духов (Убежище)." % item.get_display_name()
			if item.id == "spirit_primordial_harvest":
				return "Сакральный плод %s используется для дрессировки духов класса Спирит в Убежище." % item.get_display_name()
			return "Урожай %s используется в котле зельеварения Убежища (или продаётся в лавке)." % item.get_display_name()
		ItemData.ItemType.MATERIAL:
			return "Ресурс Шахты %s используется в 🔥 Тёмной кузне для ковки вечного снаряжения и древних книг (не сбрасывается между ранами)." % item.get_display_name()
		ItemData.ItemType.WEAPON, ItemData.ItemType.ARMOR, ItemData.ItemType.OFFHAND:
			if is_equipment_disabled():
				return "Класс Спирит не может носить экипировку."
			if is_gear_blocked_by_challenge():
				return "🏆 Испытание «Аскет» запрещает экипировку!"
			if is_non_staff_blocked_by_challenge():
				if item.item_type == ItemData.ItemType.WEAPON and not item.is_mage_staff():
					return "🏆 Испытание «Путь Арканы» разрешает только магические посохи!"
				if item.item_type == ItemData.ItemType.OFFHAND and item.offhand_kind != ItemData.OffhandKind.TALISMAN:
					return "🏆 Испытание «Путь Арканы» разрешает только талисманы!"
			var target_q: int = quality_pct
			var target_s: int = star_level
			if target_q < 0 or target_s < 1:
				var best_sc: int = -1
				for entry: Dictionary in inventory:
					var ex: ItemData = entry["item"] as ItemData
					if ex != null and ex.id == item.id:
						var sc: int = get_entry_stars(entry) * 1000 + get_entry_quality(entry)
						if sc > best_sc:
							best_sc = sc
							target_q = get_entry_quality(entry)
							target_s = get_entry_stars(entry)
			if target_q < 0:
				target_q = 100
			if target_s < 1:
				target_s = 1
			if remove_item(item, 1, target_q, target_s):
				if item.item_type == ItemData.ItemType.WEAPON:
					if equipped_weapon != null:
						add_item(equipped_weapon, 1, false, equipped_weapon_quality, equipped_weapon_stars, false)
					equipped_weapon = item
					equipped_weapon_quality = target_q
					equipped_weapon_stars = target_s
				elif item.item_type == ItemData.ItemType.ARMOR:
					if equipped_armor != null:
						add_item(equipped_armor, 1, false, equipped_armor_quality, equipped_armor_stars, false)
					equipped_armor = item
					equipped_armor_quality = target_q
					equipped_armor_stars = target_s
				else:
					if equipped_offhand != null:
						add_item(equipped_offhand, 1, false, equipped_offhand_quality, equipped_offhand_stars, false)
					equipped_offhand = item
					equipped_offhand_quality = target_q
					equipped_offhand_stars = target_s
				mark_stats_dirty()
				current_hp = minf(current_hp, get_max_hp())
				current_mana = minf(current_mana, get_max_mana())
				var max_bar: float = get_max_barrier()
				current_barrier = 0.0 if has_hero_class("reflector") else minf(maxf(current_barrier, max_bar), max_bar)
				stats_changed.emit()
				hp_changed.emit(current_hp, get_max_hp())
				mana_changed.emit(current_mana, get_max_mana())
				barrier_changed.emit(current_barrier, max_bar)
				inventory_changed.emit()
				enchant_changed.emit()
				save_game()
				return "Экипировано: %s (%d%% ★%d)." % [item.get_display_name(), target_q, target_s]
		ItemData.ItemType.AMMO:
			if is_equipment_disabled():
				return "Класс Спирит не может использовать снаряды."
			if is_gear_blocked_by_challenge():
				return "🏆 Испытание «Аскет» запрещает экипировку и снаряды!"
			if is_non_staff_blocked_by_challenge() and item.ammo_kind != ItemData.AmmoKind.TOME:
				return "🏆 Испытание «Путь Арканы» разрешает только магические книги-фолианты!"
			var stack_count: int = get_item_count_in_inventory(item)
			if stack_count <= 0:
				return ""
			if remove_item(item, stack_count):
				if equipped_ammo != null and equipped_ammo_count > 0:
					if equipped_ammo.id == item.id:
						equipped_ammo_count += stack_count
					else:
						var prev_ammo: ItemData = equipped_ammo
						var prev_cnt: int = equipped_ammo_count
						equipped_ammo = item
						equipped_ammo_count = stack_count
						add_item(prev_ammo, prev_cnt, false)
				else:
					equipped_ammo = item
					equipped_ammo_count = stack_count
				mark_stats_dirty()
				stats_changed.emit()
				inventory_changed.emit()
				save_game()
				return "Экипированы снаряды: %s x%d." % [item.get_display_name(), equipped_ammo_count]
	return ""


func unequip_slot(slot_type: ItemData.ItemType) -> void:
	match slot_type:
		ItemData.ItemType.WEAPON:
			if equipped_weapon != null:
				var prev: ItemData = equipped_weapon
				var pq: int = equipped_weapon_quality
				var ps: int = equipped_weapon_stars
				equipped_weapon = null
				equipped_weapon_quality = 100
				equipped_weapon_stars = 1
				add_item(prev, 1, false, pq, ps, false)
		ItemData.ItemType.ARMOR:
			if equipped_armor != null:
				var prev: ItemData = equipped_armor
				var pq: int = equipped_armor_quality
				var ps: int = equipped_armor_stars
				equipped_armor = null
				equipped_armor_quality = 100
				equipped_armor_stars = 1
				add_item(prev, 1, false, pq, ps, false)
		ItemData.ItemType.OFFHAND:
			if equipped_offhand != null:
				var prev: ItemData = equipped_offhand
				var pq: int = equipped_offhand_quality
				var ps: int = equipped_offhand_stars
				equipped_offhand = null
				equipped_offhand_quality = 100
				equipped_offhand_stars = 1
				add_item(prev, 1, false, pq, ps, false)
		ItemData.ItemType.AMMO:
			if equipped_ammo != null and equipped_ammo_count > 0:
				var prev_ammo: ItemData = equipped_ammo
				var prev_cnt: int = equipped_ammo_count
				equipped_ammo = null
				equipped_ammo_count = 0
				add_item(prev_ammo, prev_cnt, false)
	mark_stats_dirty()
	current_hp = minf(current_hp, get_max_hp())
	current_mana = minf(current_mana, get_max_mana())
	var max_bar: float = get_max_barrier()
	current_barrier = 0.0 if has_hero_class("reflector") else minf(current_barrier, max_bar)
	stats_changed.emit()
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())
	barrier_changed.emit(current_barrier, max_bar)
	inventory_changed.emit()
	enchant_changed.emit()
	save_game()


# --- Sanctuary: Light Garden (Diff 1+), Dark Garden & Brewing (Diff 10+), Spirit Training ---

func is_alchemy_unlocked() -> bool:
	return max_unlocked_difficulty >= ALCHEMY_UNLOCK_DIFFICULTY


func get_crop_by_id(crop_id: String) -> CropData:
	if _crops_by_id.has(crop_id):
		return _crops_by_id[crop_id] as CropData
	return null


func get_garden_plot_count() -> int:
	var extra: int = 1 if is_skill_unlocked("herbal_mastery") else 0
	return maxi(BASE_GARDEN_PLOTS + extra, garden_plots.size())


func get_light_garden_plot_count() -> int:
	return maxi(BASE_LIGHT_GARDEN_PLOTS, light_garden_plots.size())


func is_garden_plot_accessible(plot_index: int) -> bool:
	var unlocked_cap: int = BASE_GARDEN_PLOTS + (1 if is_skill_unlocked("herbal_mastery") else 0)
	if plot_index < unlocked_cap:
		return true
	if plot_index < garden_plots.size() and str(garden_plots[plot_index].get("status", "empty")) != "empty":
		return true
	return false


func get_brewing_slot_count() -> int:
	var extra: int = 1 if is_skill_unlocked("master_brewer") else 0
	return maxi(BASE_BREWING_SLOTS + extra, brewing_slots.size())


func is_brewing_slot_accessible(slot_index: int) -> bool:
	var unlocked_cap: int = BASE_BREWING_SLOTS + (1 if is_skill_unlocked("master_brewer") else 0)
	if slot_index < unlocked_cap:
		return true
	if slot_index < brewing_slots.size() and str(brewing_slots[slot_index].get("state", "empty")) != "empty":
		return true
	return false


func _make_empty_garden_plot() -> Dictionary:
	return {
		"crop_id": "",
		"status": "empty",
		"elapsed": 0.0,
		"boss_kills": 0,
	}


func _make_empty_light_garden_plot() -> Dictionary:
	return {
		"crop_id": "",
		"status": "empty",
		"elapsed": 0.0,
	}


func _make_empty_brewing_slot() -> Dictionary:
	return {
		"state": "empty",
		"brew_id": "",
		"brew_title": "",
		"brew_emoji": "⚗️",
		"stage": 0,
		"elapsed": 0.0,
		"duration": 0.0,
		"can_collect": false,
		"result_item_path": "",
		"result_count": 0,
		"pending_next_id": "",
		"pending_title": "",
		"pending_emoji": "",
		"pending_stage": 0,
		"pending_can_collect": false,
		"pending_result_item_path": "",
		"pending_result_count": 0,
	}


func _ensure_sanctuary_slots() -> void:
	var target_plots: int = BASE_GARDEN_PLOTS + (1 if is_skill_unlocked("herbal_mastery") else 0)
	while garden_plots.size() < target_plots:
		garden_plots.append(_make_empty_garden_plot())
	while light_garden_plots.size() < BASE_LIGHT_GARDEN_PLOTS:
		light_garden_plots.append(_make_empty_light_garden_plot())
	if light_garden_plots.size() > BASE_LIGHT_GARDEN_PLOTS:
		light_garden_plots.resize(BASE_LIGHT_GARDEN_PLOTS)
	var target_cauldrons: int = BASE_BREWING_SLOTS + (1 if is_skill_unlocked("master_brewer") else 0)
	while brewing_slots.size() < target_cauldrons:
		brewing_slots.append(_make_empty_brewing_slot())
	for sk: String in SPIRIT_KEYS:
		if not spirit_training_levels.has(sk):
			spirit_training_levels[sk] = 0


func get_garden_growth_speed_mult() -> float:
	return 1.0 + get_skill_bonus("garden_mastery")


func get_brewing_speed_mult() -> float:
	var mult: float = 1.0
	if has_hero_class("alchemist"):
		mult *= 2.0
	mult *= (1.0 + get_dark_bonus("brew_speed_mult"))
	return mult


func get_seed_drop_multiplier() -> float:
	var mult: float = 1.0
	if has_hero_class("alchemist"):
		mult *= 2.0
	mult *= (1.0 + get_dark_bonus("seed_drop_mult"))
	return mult


func _process_sanctuary(delta: float) -> void:
	var garden_dirty: bool = false
	var brew_dirty: bool = false
	var any_active_timer: bool = false
	var garden_mult: float = get_garden_growth_speed_mult()
	var brew_mult: float = get_brewing_speed_mult()

	for i: int in range(garden_plots.size()):
		var plot: Dictionary = garden_plots[i]
		if str(plot.get("status", "empty")) != "growing":
			continue
		var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
		if crop == null or crop.is_boss_kill_crop():
			continue
		any_active_timer = true
		var next_elapsed: float = float(plot.get("elapsed", 0.0)) + delta * garden_mult
		if next_elapsed >= crop.grow_seconds:
			plot["elapsed"] = crop.grow_seconds
			plot["status"] = "ready"
			garden_dirty = true
		else:
			plot["elapsed"] = next_elapsed

	for i: int in range(light_garden_plots.size()):
		var lplot: Dictionary = light_garden_plots[i]
		if str(lplot.get("status", "empty")) != "growing":
			continue
		var lcrop: CropData = get_crop_by_id(str(lplot.get("crop_id", "")))
		if lcrop == null:
			continue
		any_active_timer = true
		var next_l_elapsed: float = float(lplot.get("elapsed", 0.0)) + delta * garden_mult
		if next_l_elapsed >= lcrop.grow_seconds:
			lplot["elapsed"] = lcrop.grow_seconds
			lplot["status"] = "ready"
			garden_dirty = true
		else:
			lplot["elapsed"] = next_l_elapsed

	for i: int in range(brewing_slots.size()):
		var cauldron: Dictionary = brewing_slots[i]
		if str(cauldron.get("state", "empty")) != "brewing":
			continue
		any_active_timer = true
		var dur: float = maxf(0.1, float(cauldron.get("duration", 10.0)))
		var next_elapsed: float = float(cauldron.get("elapsed", 0.0)) + delta * brew_mult
		if next_elapsed >= dur:
			cauldron["state"] = "ready"
			cauldron["brew_id"] = str(cauldron.get("pending_next_id", ""))
			cauldron["brew_title"] = str(cauldron.get("pending_title", ""))
			cauldron["brew_emoji"] = str(cauldron.get("pending_emoji", "⚗️"))
			cauldron["stage"] = int(cauldron.get("pending_stage", 1))
			cauldron["can_collect"] = bool(cauldron.get("pending_can_collect", false))
			cauldron["result_item_path"] = str(cauldron.get("pending_result_item_path", ""))
			cauldron["result_count"] = int(cauldron.get("pending_result_count", 0))
			cauldron["elapsed"] = 0.0
			cauldron["duration"] = 0.0
			brew_dirty = true
		else:
			cauldron["elapsed"] = next_elapsed

	var exp_dirty: bool = false
	for i: int in range(pet_expeditions.size()):
		var pet_exp: Dictionary = pet_expeditions[i]
		if bool(pet_exp.get("completed", false)):
			continue
		any_active_timer = true
		var dur: float = maxf(1.0, float(pet_exp.get("duration", 900.0)))
		var next_elapsed: float = float(pet_exp.get("elapsed", 0.0)) + delta
		if next_elapsed >= dur:
			pet_exp["elapsed"] = dur
			pet_exp["completed"] = true
			exp_dirty = true
		else:
			pet_exp["elapsed"] = next_elapsed

	if garden_dirty:
		garden_changed.emit()
		save_game()
	if brew_dirty:
		brewing_changed.emit()
		save_game()
	if exp_dirty:
		pets_changed.emit()
		save_game()

	if any_active_timer:
		_sanctuary_ui_sync_timer += delta
		if _sanctuary_ui_sync_timer >= 0.25:
			_sanctuary_ui_sync_timer = 0.0
			garden_changed.emit()
			brewing_changed.emit()
			if not pet_expeditions.is_empty():
				pets_changed.emit()


func roll_rare_seed_drops(enemy: EnemyData) -> void:
	if enemy == null or crops.is_empty():
		return
	var is_final_boss: bool = (enemy.id == FINAL_BOSS_ID)
	var is_boss_enemy: bool = (is_final_boss or enemy.id == CURSE_WARDEN_ID)
	var mult: float = get_seed_drop_multiplier()
	for crop: CropData in crops:
		if crop == null or enemy.xp_reward < crop.min_enemy_xp:
			continue
		if crop.final_boss_only and not is_final_boss:
			continue
		var raw_chance: float = crop.boss_drop_chance if (is_boss_enemy and crop.boss_drop_chance > 0.0) else crop.base_drop_chance
		var effective_chance: float = raw_chance if crop.final_boss_only else (raw_chance * mult)
		if effective_chance > 0.0 and randf() <= effective_chance:
			var seed_item: ItemData = get_cached_item(crop.seed_item_path)
			if seed_item != null:
				add_item(seed_item, 1, true)


func roll_difficulty_reset_item_drop() -> void:
	if randf() <= DIFFICULTY_RESET_DROP_CHANCE:
		var orb: ItemData = get_cached_item(DIFFICULTY_RESET_ITEM_PATH)
		if orb != null:
			add_item(orb, 1, true, 100, 1, false)


func reset_claimed_difficulties_rewards() -> Dictionary:
	var cleared_cnt: int = dark_points_claimed_difficulties.size()
	if cleared_cnt == 0:
		return {"success": false, "message": "Награды 🌑 за сложности ещё не получены."}
	dark_points_claimed_difficulties.clear()
	difficulty_changed.emit()
	dark_skills_changed.emit()
	stats_changed.emit()
	save_game()
	return {
		"success": true,
		"message": "⏳ Сброшено %d пройденных сложностей! Макс. Сл.%d сохранена — за каждую сложность можно снова получить +2 🌑!" % [cleared_cnt, max_unlocked_difficulty],
	}


func on_final_boss_killed_for_garden() -> void:
	var changed: bool = false
	var any_became_ready: bool = false
	for i: int in range(garden_plots.size()):
		var plot: Dictionary = garden_plots[i]
		if str(plot.get("status", "empty")) != "growing":
			continue
		var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
		if crop == null or not crop.is_boss_kill_crop():
			continue
		var next_kills: int = int(plot.get("boss_kills", 0)) + 1
		plot["boss_kills"] = next_kills
		changed = true
		if next_kills >= crop.required_final_boss_kills:
			plot["status"] = "ready"
			any_became_ready = true
	if changed:
		garden_changed.emit()
		if any_became_ready:
			save_game()


func plant_seed_on_plot(plot_index: int, seed_item: ItemData) -> Dictionary:
	if not is_alchemy_unlocked():
		return {"success": false, "message": "Тёмный сад откроется после победы на 10-й сложности."}
	if seed_item == null or seed_item.item_type != ItemData.ItemType.SEED:
		return {"success": false, "message": "Выберите подходящие семена."}
	_ensure_sanctuary_slots()
	if plot_index < 0 or plot_index >= garden_plots.size() or not is_garden_plot_accessible(plot_index):
		return {"success": false, "message": "Эта грядка Тёмного сада ещё не открыта."}
	var plot: Dictionary = garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "empty":
		return {"success": false, "message": "На этой грядке уже растёт культура."}
	var crop: CropData = get_crop_by_id(seed_item.seed_crop_id)
	if crop == null:
		return {"success": false, "message": "Неизвестная культура для этих семян."}
	if crop.is_light_crop():
		return {"success": false, "message": "Это семя Светлого сада — высаживайте его на грядках ☀️ Светлого сада!"}
	if not remove_item(seed_item, 1):
		return {"success": false, "message": "Недостаточно семян в рюкзаке."}

	garden_plots[plot_index] = {
		"crop_id": crop.id,
		"status": "growing",
		"elapsed": 0.0,
		"boss_kills": 0,
	}
	garden_changed.emit()
	save_game()
	return {
		"success": true,
		"message": "%s Посажено в Тёмном саду (грядка #%d): %s!" % [crop.icon_emoji, plot_index + 1, crop.crop_name],
	}


func plant_seed_in_first_empty_plot(seed_item: ItemData) -> Dictionary:
	if not is_alchemy_unlocked():
		return {"success": false, "message": "Тёмный сад откроется после победы на 10-й сложности."}
	_ensure_sanctuary_slots()
	for i: int in range(garden_plots.size()):
		if is_garden_plot_accessible(i) and str(garden_plots[i].get("status", "empty")) == "empty":
			return plant_seed_on_plot(i, seed_item)
	return {"success": false, "message": "Все доступные грядки Тёмного сада заняты!"}


func harvest_garden_plot(plot_index: int) -> Dictionary:
	if not is_alchemy_unlocked():
		return {"success": false, "message": "Тёмный сад открывается после 10-й сложности."}
	if plot_index < 0 or plot_index >= garden_plots.size():
		return {"success": false, "message": "Грядка не найдена."}
	var plot: Dictionary = garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "ready":
		return {"success": false, "message": "Урожай ещё не созрел."}
	var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
	if crop == null:
		garden_plots[plot_index] = _make_empty_garden_plot()
		garden_changed.emit()
		return {"success": false, "message": "Культура повреждена."}

	var yield_amt: int = randi_range(crop.harvest_min, maxi(crop.harvest_min, crop.harvest_max))
	var harvest_item: ItemData = get_cached_item(crop.harvest_item_path)
	if harvest_item != null:
		add_item(harvest_item, yield_amt, true)

	garden_plots[plot_index] = _make_empty_garden_plot()
	garden_changed.emit()
	save_game()
	return {
		"success": true,
		"message": "%s Собрано с Тёмного сада (грядка #%d): %s x%d!" % [
			crop.icon_emoji,
			plot_index + 1,
			harvest_item.item_name if harvest_item != null else crop.crop_name,
			yield_amt,
		],
	}


func can_instant_grow_plot(plot_index: int) -> bool:
	if plot_index < 0 or plot_index >= garden_plots.size():
		return false
	var plot: Dictionary = garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "growing":
		return false
	var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
	if crop == null or not crop.has_instant_grow_feed():
		return false
	for item_id_var: Variant in crop.instant_grow_feed_items.keys():
		var req_id: String = str(item_id_var)
		var req_cnt: int = int(crop.instant_grow_feed_items[item_id_var])
		var req_item: ItemData = get_cached_item("res://resources/items/%s.tres" % req_id)
		if req_item == null or get_item_count_in_inventory(req_item) < req_cnt:
			return false
	return true


func feed_growing_crop_for_instant_growth(plot_index: int) -> Dictionary:
	if plot_index < 0 or plot_index >= garden_plots.size():
		return {"success": false, "message": "Грядка не найдена."}
	var plot: Dictionary = garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "growing":
		return {"success": false, "message": "Культура уже созрела или грядка пуста."}
	var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
	if crop == null or not crop.has_instant_grow_feed():
		return {"success": false, "message": "Эту культуру нельзя ускорить подкормкой духов."}

	var to_consume: Array[Dictionary] = []
	for item_id_var: Variant in crop.instant_grow_feed_items.keys():
		var req_id: String = str(item_id_var)
		var req_cnt: int = int(crop.instant_grow_feed_items[item_id_var])
		var req_item: ItemData = get_cached_item("res://resources/items/%s.tres" % req_id)
		if req_item == null:
			return {"success": false, "message": "Не найден ресурс растения %s." % req_id}
		var owned_cnt: int = get_item_count_in_inventory(req_item)
		if owned_cnt < req_cnt:
			return {"success": false, "message": "Нужно %s %s x%d (у вас %d)." % [req_item.icon_emoji, req_item.item_name, req_cnt, owned_cnt]}
		to_consume.append({"item": req_item, "count": req_cnt})

	for entry: Dictionary in to_consume:
		remove_item(entry["item"] as ItemData, int(entry["count"]))

	plot["elapsed"] = crop.grow_seconds
	plot["status"] = "ready"
	garden_changed.emit()
	save_game()
	return {
		"success": true,
		"message": "🌟 Духи вкусили базовые растения Светлого сада — %s %s на грядке #%d созрел МОМЕНТАЛЬНО!" % [
			crop.icon_emoji,
			crop.crop_name,
			plot_index + 1,
		],
	}


func plant_light_seed_on_plot(plot_index: int, seed_item: ItemData) -> Dictionary:
	if seed_item == null or seed_item.item_type != ItemData.ItemType.SEED:
		return {"success": false, "message": "Выберите подходящие семена Светлого сада."}
	_ensure_sanctuary_slots()
	if plot_index < 0 or plot_index >= light_garden_plots.size():
		return {"success": false, "message": "Грядка Светлого сада не найдена."}
	var plot: Dictionary = light_garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "empty":
		return {"success": false, "message": "На этой грядке Светлого сада уже растёт растение."}
	var crop: CropData = get_crop_by_id(seed_item.seed_crop_id)
	if crop == null or not crop.is_light_crop():
		return {"success": false, "message": "Сюда можно сажать только простые растения ☀️ Светлого сада!"}
	if not remove_item(seed_item, 1):
		return {"success": false, "message": "Недостаточно семян в рюкзаке."}

	light_garden_plots[plot_index] = {
		"crop_id": crop.id,
		"status": "growing",
		"elapsed": 0.0,
	}
	garden_changed.emit()
	save_game()
	return {
		"success": true,
		"message": "%s Посажено в Светлый сад (слот #%d): %s!" % [crop.icon_emoji, plot_index + 1, crop.crop_name],
	}


func plant_light_seed_in_first_empty_plot(seed_item: ItemData) -> Dictionary:
	_ensure_sanctuary_slots()
	for i: int in range(light_garden_plots.size()):
		if str(light_garden_plots[i].get("status", "empty")) == "empty":
			return plant_light_seed_on_plot(i, seed_item)
	return {"success": false, "message": "Все 3 грядки Светлого сада заняты!"}


func harvest_light_garden_plot(plot_index: int) -> Dictionary:
	_ensure_sanctuary_slots()
	if plot_index < 0 or plot_index >= light_garden_plots.size():
		return {"success": false, "message": "Грядка Светлого сада не найдена."}
	var plot: Dictionary = light_garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "ready":
		return {"success": false, "message": "Растение ещё не выросло."}
	var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
	if crop == null:
		light_garden_plots[plot_index] = _make_empty_light_garden_plot()
		garden_changed.emit()
		return {"success": false, "message": "Растение испорчено."}

	var yield_amt: int = randi_range(crop.harvest_min, maxi(crop.harvest_min, crop.harvest_max))
	var harvest_item: ItemData = get_cached_item(crop.harvest_item_path)
	if harvest_item != null:
		add_item(harvest_item, yield_amt, true)

	light_garden_plots[plot_index] = _make_empty_light_garden_plot()
	garden_changed.emit()
	save_game()
	return {
		"success": true,
		"message": "%s Собрано из Светлого сада (#%d): %s x%d (для пряников и подкормки духов)!" % [
			crop.icon_emoji,
			plot_index + 1,
			harvest_item.item_name if harvest_item != null else crop.crop_name,
			yield_amt,
		],
	}


func can_lure_pet_from_light_garden() -> bool:
	_ensure_sanctuary_slots()
	if light_garden_plots.size() < BASE_LIGHT_GARDEN_PLOTS:
		return false
	for i: int in range(BASE_LIGHT_GARDEN_PLOTS):
		if str(light_garden_plots[i].get("status", "empty")) != "ready":
			return false
	return true


func lure_pet_from_light_garden() -> Dictionary:
	_ensure_sanctuary_slots()
	if not can_lure_pet_from_light_garden():
		return {"success": false, "withered": false, "duplicate": false, "message": "Чтобы приманить путника, должны созреть все 3 грядки Светлого сада!"}

	var planted_pattern: Array[String] = []
	for i: int in range(BASE_LIGHT_GARDEN_PLOTS):
		planted_pattern.append(str(light_garden_plots[i].get("crop_id", "")))

	var matched_pet_id: String = ""
	for recipe: Dictionary in PET_LURE_RECIPES:
		var pat: Array = recipe.get("pattern", []) as Array
		if pat.size() == BASE_LIGHT_GARDEN_PLOTS and str(pat[0]) == planted_pattern[0] and str(pat[1]) == planted_pattern[1] and str(pat[2]) == planted_pattern[2]:
			matched_pet_id = str(recipe.get("pet_id", ""))
			break

	# Consume / wither all 3 Light Garden plots regardless of outcome
	for i: int in range(BASE_LIGHT_GARDEN_PLOTS):
		light_garden_plots[i] = _make_empty_light_garden_plot()

	if matched_pet_id.is_empty():
		garden_changed.emit()
		save_game()
		return {
			"success": false,
			"withered": true,
			"duplicate": false,
			"message": "🥀 На эту высадку никто не откликнулся — ничего не произошло, растения на 3 грядках завяли.",
		}

	var pet: PetData = get_pet_by_id(matched_pet_id)
	if has_pet_owned(matched_pet_id):
		garden_changed.emit()
		save_game()
		var pet_title: String = "%s %s" % [pet.icon_emoji, pet.pet_name] if pet != null else matched_pet_id
		return {
			"success": false,
			"withered": true,
			"duplicate": true,
			"message": "🥀 На аромат заглянул %s, но этот путник уже приручён (повторка) — ничего не произошло, растения на 3 грядках завяли." % pet_title,
		}

	owned_pet_ids.append(matched_pet_id)
	if equipped_pet_id.is_empty():
		equipped_pet_id = matched_pet_id
	pets_changed.emit()
	garden_changed.emit()
	stats_changed.emit()
	save_game()
	return {
		"success": true,
		"withered": false,
		"duplicate": false,
		"message": "🐾 Чудо Светлого сада! На высадку прибежал и приручился %s %s!" % [
			pet.icon_emoji if pet != null else "🐾",
			pet.pet_name if pet != null else matched_pet_id,
		],
	}


func get_spirit_training_level(spirit_key: String) -> int:
	return maxi(0, int(spirit_training_levels.get(spirit_key, 0)))


func get_spirit_power_multiplier(spirit_key: String) -> float:
	return 1.0 + float(get_spirit_training_level(spirit_key)) * 0.15


func get_spirit_speed_multiplier(spirit_key: String) -> float:
	return 1.0 + float(get_spirit_training_level(spirit_key)) * 0.03


func train_spirit(spirit_key: String) -> Dictionary:
	if not SPIRIT_KEYS.has(spirit_key):
		return {"success": false, "message": "Неизвестный дух природы."}
	if not has_hero_class("spirit"):
		return {"success": false, "message": "Дрессировка духов доступна только классу 🌿 Спирит (Сл.50+)."}
	var fruit_item: ItemData = get_cached_item("res://resources/items/spirit_primordial_harvest.tres")
	if fruit_item == null or not remove_item(fruit_item, 1):
		return {"success": false, "message": "Нужен 🌟 Плод первоцвета духов (семя падает с 0.03% шансом ТОЛЬКО с Вечного титана)."}

	var next_lvl: int = get_spirit_training_level(spirit_key) + 1
	spirit_training_levels[spirit_key] = next_lvl
	mark_stats_dirty()
	stats_changed.emit()
	garden_changed.emit()
	save_game()

	var spirit_titles: Dictionary = {
		"fire": "🔥 Дух Огня",
		"wind": "🌪️ Дух Ветра",
		"forest": "🌿 Дух Леса",
		"earth": "🪨 Дух Земли",
	}
	return {
		"success": true,
		"message": "🌟 %s надрессирован до Ур.%d (+%d%% сила, +%d%% скорость)!" % [
			str(spirit_titles.get(spirit_key, spirit_key)),
			next_lvl,
			next_lvl * 15,
			next_lvl * 3,
		],
	}


func start_brewing_water(slot_index: int) -> Dictionary:
	if not is_alchemy_unlocked():
		return {"success": false, "message": "Зельеварение открывается после 10-й сложности."}
	_ensure_sanctuary_slots()
	if slot_index < 0 or slot_index >= brewing_slots.size() or not is_brewing_slot_accessible(slot_index):
		return {"success": false, "message": "Этот котёл ещё не открыт."}
	var cauldron: Dictionary = brewing_slots[slot_index]
	var st: String = str(cauldron.get("state", "empty"))
	if st != "empty" and st != "exploded":
		return {"success": false, "message": "Котёл уже используется."}

	brewing_slots[slot_index] = {
		"state": "ready",
		"brew_id": "water",
		"brew_title": "Колба с водой (Основа)",
		"brew_emoji": "💧",
		"stage": 0,
		"elapsed": 0.0,
		"duration": 0.0,
		"can_collect": false,
		"result_item_path": "",
		"result_count": 0,
		"pending_next_id": "",
		"pending_title": "",
		"pending_emoji": "",
		"pending_stage": 0,
		"pending_can_collect": false,
		"pending_result_item_path": "",
		"pending_result_count": 0,
	}
	brewing_changed.emit()
	save_game()
	return {"success": true, "message": "💧 Вода налита в котёл #%d. Добавьте базовую траву (Шаг 1)!" % (slot_index + 1)}


func add_brewing_ingredient(slot_index: int, ingredient_item: ItemData) -> Dictionary:
	if not is_alchemy_unlocked():
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Зельеварение открывается после 10-й сложности."}
	if ingredient_item == null or ingredient_item.item_type != ItemData.ItemType.HARVEST:
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "В котёл можно добавлять только урожай из Тёмного сада."}
	if ingredient_item.garden_category == "light" or ingredient_item.id == "spirit_primordial_harvest":
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Растения Светлого сада и плоды духов не варятся в котле — используйте их для путников и духов!"}
	_ensure_sanctuary_slots()
	if slot_index < 0 or slot_index >= brewing_slots.size() or not is_brewing_slot_accessible(slot_index):
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Котёл не открыт."}

	var cauldron: Dictionary = brewing_slots[slot_index]
	if str(cauldron.get("state", "empty")) != "ready":
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Сначала налейте воду или дождитесь окончания варки."}

	var current_brew_id: String = str(cauldron.get("brew_id", ""))
	var stage_transitions: Dictionary = BREW_STEP_TRANSITIONS.get(current_brew_id, {}) as Dictionary
	var is_valid_step: bool = stage_transitions.has(ingredient_item.id)

	if not is_valid_step:
		if has_hero_class("alchemist"):
			if alchemist_next_mistake_safe:
				# Deterministic safety guard: every 2nd wrong potion does NOT explode and stays at the same stage
				alchemist_next_mistake_safe = false
				brewing_changed.emit()
				save_game()
				return {
					"success": false,
					"exploded": false,
					"saved_by_alchemist": true,
					"message": "⚗️ Спас-флаг Алхимика сработал! Неверный ингредиент «%s» нейтрализован — зелье НЕ взорвалось и осталось на %d-м этапе." % [
						ingredient_item.item_name,
						int(cauldron.get("stage", 0)),
					],
				}
			else:
				alchemist_next_mistake_safe = true
		remove_item(ingredient_item, 1)
		var empty_exploded: Dictionary = _make_empty_brewing_slot()
		empty_exploded["state"] = "exploded"
		empty_exploded["brew_emoji"] = "💥"
		empty_exploded["brew_title"] = "Взорвано!"
		brewing_slots[slot_index] = empty_exploded
		brewing_changed.emit()
		save_game()
		var alch_note: String = " (Следующая ошибка защищена флагом Алхимика ✅!)" if has_hero_class("alchemist") else ""
		return {
			"success": false,
			"exploded": true,
			"saved_by_alchemist": false,
			"message": "💥 ВЗРЫВ КОТЛА #%d! Неподходящий ингредиент «%s» уничтожил текущее зелье (100%% шанс).%s" % [
				slot_index + 1,
				ingredient_item.item_name,
				alch_note,
			],
		}

	if not remove_item(ingredient_item, 1):
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Недостаточно «%s» в рюкзаке." % ingredient_item.item_name}

	var recipe: Dictionary = stage_transitions[ingredient_item.id] as Dictionary
	cauldron["state"] = "brewing"
	cauldron["elapsed"] = 0.0
	cauldron["duration"] = float(recipe["duration"])
	cauldron["pending_next_id"] = str(recipe["next_id"])
	cauldron["pending_title"] = str(recipe["title"])
	cauldron["pending_emoji"] = str(recipe["emoji"])
	cauldron["pending_stage"] = int(recipe["stage"])
	cauldron["pending_can_collect"] = bool(recipe["can_collect"])
	cauldron["pending_result_item_path"] = str(recipe["result_item_path"])
	cauldron["pending_result_count"] = int(recipe["result_count"])
	brewing_changed.emit()
	save_game()
	return {
		"success": true,
		"exploded": false,
		"saved_by_alchemist": false,
		"message": "🔥 Шаг %d запущен в котле #%d: варим %s %s!" % [
			int(recipe["stage"]),
			slot_index + 1,
			str(recipe["emoji"]),
			str(recipe["title"]),
		],
	}


func collect_brewed_potion(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= brewing_slots.size():
		return {"success": false, "message": "Котёл не найден."}
	var cauldron: Dictionary = brewing_slots[slot_index]
	if str(cauldron.get("state", "empty")) != "ready" or not bool(cauldron.get("can_collect", false)):
		return {"success": false, "message": "Зелье ещё не доведено до готовой ступени (нужен минимум Шаг 2)."}
	var path: String = str(cauldron.get("result_item_path", ""))
	var cnt: int = maxi(1, int(cauldron.get("result_count", 1)))
	var potion: ItemData = get_cached_item(path)
	if potion == null:
		return {"success": false, "message": "Рецепт зелья повреждён."}

	add_item(potion, cnt, true)
	brewing_slots[slot_index] = _make_empty_brewing_slot()
	brewing_changed.emit()
	save_game()
	return {
		"success": true,
		"message": "🧪 Сварено и получено: %s %s x%d!" % [potion.icon_emoji, potion.item_name, cnt],
	}


func clear_brewing_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= brewing_slots.size():
		return
	brewing_slots[slot_index] = _make_empty_brewing_slot()
	brewing_changed.emit()
	save_game()


func _build_save_data() -> SaveData:
	var save_data: SaveData = SaveData.new()
	save_data.save_version = SAVE_SCHEMA_VERSION
	save_data.level = level
	save_data.current_xp = current_xp
	save_data.gold = gold
	save_data.skill_points = skill_points
	save_data.enemies_defeated = enemies_defeated
	save_data.kills_in_run = kills_in_run
	save_data.base_strength = base_strength
	save_data.base_agility = base_agility
	save_data.base_endurance = base_endurance
	save_data.base_intellect = base_intellect
	save_data.current_hp = current_hp
	save_data.current_mana = current_mana
	save_data.melee_level = melee_level
	save_data.melee_xp = melee_xp
	save_data.ranged_level = ranged_level
	save_data.ranged_xp = ranged_xp
	save_data.magic_level = magic_level
	save_data.magic_xp = magic_xp
	save_data.current_location_id = current_location.id if current_location != null else "quiet_glade"
	save_data.equipped_weapon_path = equipped_weapon.resource_path if equipped_weapon != null else ""
	save_data.equipped_armor_path = equipped_armor.resource_path if equipped_armor != null else ""
	save_data.equipped_ammo_path = equipped_ammo.resource_path if equipped_ammo != null else ""
	save_data.equipped_ammo_count = equipped_ammo_count
	save_data.weapon_enchant_level = weapon_enchant_level
	save_data.armor_enchant_level = armor_enchant_level
	save_data.unlocked_skills = unlocked_skills.duplicate()
	save_data.skill_presets = skill_presets.duplicate(true)
	save_data.active_skill_preset_index = active_skill_preset_index
	save_data.skill_auto_upgrade_enabled = skill_auto_upgrade_enabled
	save_data.equipped_ability_ids = equipped_ability_ids.duplicate()
	save_data.ability_auto_cast = ability_auto_cast.duplicate()
	save_data.auto_potion_enabled = auto_potion_enabled
	save_data.auto_hp_threshold_pct = auto_hp_threshold_pct
	save_data.auto_hp_condition = auto_hp_condition
	save_data.auto_mana_enabled = auto_mana_enabled
	save_data.auto_mana_threshold_pct = auto_mana_threshold_pct
	save_data.auto_mana_condition = auto_mana_condition
	save_data.auto_buff_enabled = auto_buff_enabled
	save_data.auto_buff_condition = auto_buff_condition
	save_data.auto_buff_whitelist = auto_buff_whitelist.duplicate()
	save_data.dark_weapon_enchant_level = dark_weapon_enchant_level
	save_data.dark_armor_enchant_level = dark_armor_enchant_level
	save_data.mine_locked_this_run = mine_locked_this_run
	save_data.mine_depth = mine_depth

	save_data.difficulty_level = difficulty_level
	save_data.max_unlocked_difficulty = max_unlocked_difficulty
	save_data.boss_defeated_this_run = boss_defeated_this_run
	save_data.dark_points = dark_points
	save_data.dark_shop_coins = dark_shop_coins
	save_data.dark_points_claimed_difficulties = dark_points_claimed_difficulties.duplicate()
	save_data.unlocked_dark_skills = unlocked_dark_skills.duplicate()
	save_data.difficulty_curses = difficulty_curses.duplicate()
	save_data.total_runs_completed = total_runs_completed
	save_data.selected_class_id = selected_class_id
	save_data.reflector_kill_hp_stacks = reflector_kill_hp_stacks
	save_data.curse_reroll_tokens = curse_reroll_tokens
	save_data.reroll_boss_kills_in_run = reroll_boss_kills_in_run
	save_data.owned_pet_ids = owned_pet_ids.duplicate()
	save_data.equipped_pet_id = equipped_pet_id
	save_data.garden_plots = garden_plots.duplicate(true)
	save_data.light_garden_plots = light_garden_plots.duplicate(true)
	save_data.brewing_slots = brewing_slots.duplicate(true)
	save_data.alchemist_next_mistake_safe = alchemist_next_mistake_safe
	save_data.pet_training_levels = pet_training_levels.duplicate(true)
	save_data.spirit_training_levels = spirit_training_levels.duplicate(true)

	# v0.22.0 fields
	save_data.afk_target_fps = afk_target_fps
	save_data.equipped_weapon_quality = equipped_weapon_quality
	save_data.equipped_weapon_stars = equipped_weapon_stars
	save_data.equipped_armor_quality = equipped_armor_quality
	save_data.equipped_armor_stars = equipped_armor_stars
	save_data.equipped_offhand_path = equipped_offhand.resource_path if equipped_offhand != null else ""
	save_data.equipped_offhand_quality = equipped_offhand_quality
	save_data.equipped_offhand_stars = equipped_offhand_stars
	save_data.offhand_enchant_level = offhand_enchant_level
	save_data.dark_offhand_enchant_level = dark_offhand_enchant_level
	save_data.auto_salvage_mode = auto_salvage_mode
	save_data.auto_salvage_min_quality = auto_salvage_min_quality
	save_data.abyss_ore_shards = abyss_ore_shards
	save_data.bestiary_kills = bestiary_kills.duplicate(true)
	save_data.active_challenge_id = active_challenge_id
	save_data.completed_challenges = completed_challenges.duplicate()
	save_data.run_elapsed_seconds = run_elapsed_seconds
	save_data.combat_loadouts = combat_loadouts.duplicate(true)
	save_data.auto_route_enabled = auto_route_enabled
	save_data.auto_route_wins_threshold = auto_route_wins_threshold
	save_data.consecutive_location_wins = consecutive_location_wins
	save_data.well_greed_cooldown_remaining = well_greed_cooldown_remaining
	save_data.well_run_blessing = well_run_blessing
	save_data.ability_casts = ability_casts.duplicate(true)
	save_data.ability_levels = ability_levels.duplicate(true)
	save_data.ability_runes = ability_runes.duplicate(true)
	save_data.pet_expeditions = pet_expeditions.duplicate(true)
	save_data.unlocked_mine_checkpoints = unlocked_mine_checkpoints.duplicate()
	save_data.mine_start_depth = mine_start_depth
	save_data.wave_dungeon_clears = wave_dungeon_clears

	for entry: Dictionary in inventory:
		var item: ItemData = entry["item"] as ItemData
		if item != null and not item.resource_path.is_empty():
			save_data.inventory_paths.append(item.resource_path)
			save_data.inventory_counts.append(int(entry["count"]))
			save_data.inventory_qualities.append(get_entry_quality(entry))
			save_data.inventory_stars.append(get_entry_stars(entry))

	return save_data


func _apply_save_data(save_data: SaveData) -> void:
	level = maxi(1, save_data.level)
	current_xp = maxf(0.0, float(save_data.current_xp))
	gold = maxf(0.0, float(save_data.gold))
	skill_points = maxi(0, save_data.skill_points)
	enemies_defeated = maxi(0, save_data.enemies_defeated)
	kills_in_run = maxi(0, save_data.kills_in_run)
	base_strength = maxi(1, save_data.base_strength)
	base_agility = maxi(1, save_data.base_agility)
	base_endurance = maxi(1, save_data.base_endurance)
	base_intellect = maxi(1, save_data.base_intellect)
	melee_level = maxi(1, save_data.melee_level)
	melee_xp = maxf(0.0, save_data.melee_xp)
	ranged_level = maxi(1, save_data.ranged_level)
	ranged_xp = maxf(0.0, save_data.ranged_xp)
	magic_level = maxi(1, save_data.magic_level)
	magic_xp = maxf(0.0, save_data.magic_xp)
	auto_potion_enabled = save_data.auto_potion_enabled
	auto_hp_threshold_pct = clampi(save_data.auto_hp_threshold_pct, 10, 95)
	auto_hp_condition = "always" if save_data.auto_hp_condition == "always" else "combat"
	auto_mana_enabled = save_data.auto_mana_enabled
	auto_mana_threshold_pct = clampi(save_data.auto_mana_threshold_pct, 10, 95)
	auto_mana_condition = "always" if save_data.auto_mana_condition == "always" else "combat"
	auto_buff_enabled = save_data.auto_buff_enabled
	auto_buff_condition = "on_expire_always" if save_data.auto_buff_condition == "on_expire_always" else "on_expire_combat"
	auto_buff_whitelist.clear()
	for bw: String in save_data.auto_buff_whitelist:
		if not bw.is_empty() and not auto_buff_whitelist.has(bw):
			auto_buff_whitelist.append(bw)
	dark_weapon_enchant_level = maxi(0, save_data.dark_weapon_enchant_level)
	dark_armor_enchant_level = maxi(0, save_data.dark_armor_enchant_level)
	mine_locked_this_run = save_data.mine_locked_this_run
	mine_depth = maxi(0, save_data.mine_depth)

	max_unlocked_difficulty = maxi(1, save_data.max_unlocked_difficulty)
	difficulty_level = clampi(save_data.difficulty_level, 1, max_unlocked_difficulty)
	boss_defeated_this_run = save_data.boss_defeated_this_run
	dark_points = maxi(0, save_data.dark_points)
	dark_shop_coins = maxi(0, save_data.dark_shop_coins)
	dark_points_claimed_difficulties.clear()
	for diff_num: int in save_data.dark_points_claimed_difficulties:
		if diff_num >= 1 and not dark_points_claimed_difficulties.has(diff_num):
			dark_points_claimed_difficulties.append(diff_num)
	if dark_points_claimed_difficulties.is_empty() and max_unlocked_difficulty > 1:
		for cleared_d: int in range(1, max_unlocked_difficulty):
			dark_points_claimed_difficulties.append(cleared_d)
		if boss_defeated_this_run and not dark_points_claimed_difficulties.has(difficulty_level):
			dark_points_claimed_difficulties.append(difficulty_level)
	total_runs_completed = maxi(0, save_data.total_runs_completed)
	curse_reroll_tokens = maxi(0, save_data.curse_reroll_tokens)
	reroll_boss_kills_in_run = maxi(0, save_data.reroll_boss_kills_in_run)
	reflector_kill_hp_stacks = maxi(0, save_data.reflector_kill_hp_stacks)

	if _classes_by_id.has(save_data.selected_class_id) and (is_classes_unlocked() or save_data.selected_class_id == "wanderer"):
		selected_class_id = save_data.selected_class_id
	else:
		selected_class_id = "wanderer"

	owned_pet_ids.clear()
	for pet_id: String in save_data.owned_pet_ids:
		if _pets_by_id.has(pet_id) and not owned_pet_ids.has(pet_id):
			owned_pet_ids.append(pet_id)
	if not save_data.equipped_pet_id.is_empty() and owned_pet_ids.has(save_data.equipped_pet_id):
		equipped_pet_id = save_data.equipped_pet_id
	else:
		equipped_pet_id = ""

	var max_ench: int = get_max_enchant_level()
	weapon_enchant_level = clampi(save_data.weapon_enchant_level, 0, max_ench)
	armor_enchant_level = clampi(save_data.armor_enchant_level, 0, max_ench)
	offhand_enchant_level = clampi(save_data.offhand_enchant_level, 0, max_ench)
	dark_offhand_enchant_level = maxi(0, save_data.dark_offhand_enchant_level)
	afk_target_fps = save_data.afk_target_fps if AFK_FPS_OPTIONS.has(save_data.afk_target_fps) else DEFAULT_AFK_MAX_FPS

	difficulty_curses.clear()
	if save_data.difficulty_curses is Dictionary:
		for k: Variant in save_data.difficulty_curses.keys():
			difficulty_curses[int(k)] = str(save_data.difficulty_curses[k])

	unlocked_skills.clear()
	for skill_id: String in save_data.unlocked_skills:
		if _skills_by_id.has(skill_id) and not unlocked_skills.has(skill_id):
			unlocked_skills.append(skill_id)

	skill_presets = save_data.skill_presets.duplicate(true)
	active_skill_preset_index = clampi(save_data.active_skill_preset_index, 0, SKILL_PRESET_COUNT - 1)
	skill_auto_upgrade_enabled = save_data.skill_auto_upgrade_enabled
	ensure_skill_presets()

	unlocked_dark_skills.clear()
	for dskill_id: String in save_data.unlocked_dark_skills:
		if _dark_skills_by_id.has(dskill_id) and not unlocked_dark_skills.has(dskill_id):
			unlocked_dark_skills.append(dskill_id)
	_invalidate_progression_caches()

	if save_data.equipped_ability_ids.size() > 0:
		equipped_ability_ids = save_data.equipped_ability_ids.duplicate()
	else:
		equipped_ability_ids = DEFAULT_EQUIPPED_ABILITIES.duplicate()
	_validate_equipped_abilities_for_class()

	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		if i < save_data.ability_auto_cast.size():
			ability_auto_cast[i] = save_data.ability_auto_cast[i]
		else:
			ability_auto_cast[i] = false

	# v0.22.0 Challenge, Bestiary, Spells, Route, Well, Mine & Loadouts
	active_challenge_id = save_data.active_challenge_id if not get_challenge_def(save_data.active_challenge_id).is_empty() else ""
	run_elapsed_seconds = maxf(0.0, save_data.run_elapsed_seconds)
	completed_challenges.clear()
	for cid: String in save_data.completed_challenges:
		if not cid.is_empty() and not completed_challenges.has(cid):
			completed_challenges.append(cid)

	bestiary_kills.clear()
	if save_data.bestiary_kills is Dictionary:
		for bk: Variant in save_data.bestiary_kills.keys():
			bestiary_kills[str(bk)] = maxi(0, int(save_data.bestiary_kills[bk]))

	ability_casts.clear()
	if save_data.ability_casts is Dictionary:
		for ack: Variant in save_data.ability_casts.keys():
			ability_casts[str(ack)] = maxi(0, int(save_data.ability_casts[ack]))
	ability_levels.clear()
	if save_data.ability_levels is Dictionary:
		for alk: Variant in save_data.ability_levels.keys():
			ability_levels[str(alk)] = clampi(int(save_data.ability_levels[alk]), 1, AbilityData.MAX_SPELL_LEVEL)
	ability_runes.clear()
	if save_data.ability_runes is Dictionary:
		for ark: Variant in save_data.ability_runes.keys():
			var rk: String = str(save_data.ability_runes[ark])
			if rk == "a" or rk == "b":
				ability_runes[str(ark)] = rk

	combat_loadouts.clear()
	for cl: Dictionary in save_data.combat_loadouts:
		combat_loadouts.append(cl.duplicate(true))
	_ensure_loadouts()

	auto_salvage_mode = save_data.auto_salvage_mode if (save_data.auto_salvage_mode == "sell" or save_data.auto_salvage_mode == "salvage") else "off"
	auto_salvage_min_quality = clampi(save_data.auto_salvage_min_quality, 80, 125)
	abyss_ore_shards = maxi(0, save_data.abyss_ore_shards)
	auto_route_enabled = save_data.auto_route_enabled
	auto_route_wins_threshold = clampi(save_data.auto_route_wins_threshold, 3, 25)
	consecutive_location_wins = maxi(0, save_data.consecutive_location_wins)
	well_greed_cooldown_remaining = maxf(0.0, save_data.well_greed_cooldown_remaining)
	well_run_blessing = save_data.well_run_blessing
	wave_dungeon_clears = maxi(0, save_data.wave_dungeon_clears)
	wave_dungeon_active = false
	wave_dungeon_wave = 0
	unlocked_mine_checkpoints.clear()
	for cp: int in save_data.unlocked_mine_checkpoints:
		if MINE_CHECKPOINT_DEPTHS.has(cp) and not unlocked_mine_checkpoints.has(cp):
			unlocked_mine_checkpoints.append(cp)
	mine_start_depth = save_data.mine_start_depth if is_mine_checkpoint_unlocked(save_data.mine_start_depth) else 1

	equipped_weapon = null
	equipped_weapon_quality = clampi(save_data.equipped_weapon_quality, 80, 125)
	equipped_weapon_stars = clampi(save_data.equipped_weapon_stars, 1, 5)
	if not is_equipment_disabled() and not is_gear_blocked_by_challenge() and not save_data.equipped_weapon_path.is_empty():
		var w_cand: ItemData = get_cached_item(save_data.equipped_weapon_path)
		if w_cand != null and (not is_non_staff_blocked_by_challenge() or w_cand.is_mage_staff()):
			equipped_weapon = w_cand

	equipped_armor = null
	equipped_armor_quality = clampi(save_data.equipped_armor_quality, 80, 125)
	equipped_armor_stars = clampi(save_data.equipped_armor_stars, 1, 5)
	if not is_equipment_disabled() and not is_gear_blocked_by_challenge() and not save_data.equipped_armor_path.is_empty():
		equipped_armor = get_cached_item(save_data.equipped_armor_path)

	equipped_offhand = null
	equipped_offhand_quality = clampi(save_data.equipped_offhand_quality, 80, 125)
	equipped_offhand_stars = clampi(save_data.equipped_offhand_stars, 1, 5)
	if not is_equipment_disabled() and not is_gear_blocked_by_challenge() and not save_data.equipped_offhand_path.is_empty():
		var o_cand: ItemData = get_cached_item(save_data.equipped_offhand_path)
		if o_cand != null and (not is_non_staff_blocked_by_challenge() or o_cand.offhand_kind == ItemData.OffhandKind.TALISMAN):
			equipped_offhand = o_cand

	equipped_ammo = null
	equipped_ammo_count = 0
	if not is_equipment_disabled() and not is_gear_blocked_by_challenge() and not save_data.equipped_ammo_path.is_empty():
		var am_cand: ItemData = get_cached_item(save_data.equipped_ammo_path)
		if am_cand != null and (not is_non_staff_blocked_by_challenge() or am_cand.ammo_kind == ItemData.AmmoKind.TOME):
			equipped_ammo = am_cand
			equipped_ammo_count = maxi(0, save_data.equipped_ammo_count)
			if equipped_ammo.is_dark_forged:
				equipped_ammo_count = maxi(1, equipped_ammo_count)
			elif equipped_ammo_count == 0:
				equipped_ammo = null

	inventory.clear()
	var item_count: int = mini(save_data.inventory_paths.size(), save_data.inventory_counts.size())
	for i: int in range(item_count):
		var path: String = save_data.inventory_paths[i]
		var item: ItemData = get_cached_item(path)
		if item != null:
			var iq: int = save_data.inventory_qualities[i] if i < save_data.inventory_qualities.size() else 100
			var is_val: int = save_data.inventory_stars[i] if i < save_data.inventory_stars.size() else 1
			add_item(item, save_data.inventory_counts[i], false, iq, is_val, false)

	garden_plots.clear()
	for gp: Dictionary in save_data.garden_plots:
		garden_plots.append(gp.duplicate(true))
	light_garden_plots.clear()
	for lgp: Dictionary in save_data.light_garden_plots:
		light_garden_plots.append(lgp.duplicate(true))
	brewing_slots.clear()
	for bs: Dictionary in save_data.brewing_slots:
		brewing_slots.append(bs.duplicate(true))
	alchemist_next_mistake_safe = save_data.alchemist_next_mistake_safe
	pet_training_levels.clear()
	if save_data.pet_training_levels is Dictionary:
		for pk: Variant in save_data.pet_training_levels.keys():
			var pid: String = str(pk)
			if _pets_by_id.has(pid):
				pet_training_levels[pid] = clampi(int(save_data.pet_training_levels[pk]), 0, MAX_PET_TRAINING_LEVEL)
	spirit_training_levels = {"fire": 0, "wind": 0, "forest": 0, "earth": 0}
	if save_data.spirit_training_levels is Dictionary:
		for sk: String in SPIRIT_KEYS:
			if save_data.spirit_training_levels.has(sk):
				spirit_training_levels[sk] = maxi(0, int(save_data.spirit_training_levels[sk]))
	pet_expeditions.clear()
	for pe: Dictionary in save_data.pet_expeditions:
		var pe_copy: Dictionary = pe.duplicate(true)
		var pe_pid: String = str(pe_copy.get("pet_id", ""))
		if has_pet_owned(pe_pid) and equipped_pet_id != pe_pid:
			pet_expeditions.append(pe_copy)
	_ensure_sanctuary_slots()

	active_buffs.clear()
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		ability_cooldowns[i] = 0.0

	mark_stats_dirty()
	current_hp = clampf(save_data.current_hp, 0.0, get_max_hp())
	current_mana = clampf(save_data.current_mana, 0.0, get_max_mana())
	current_barrier = get_max_barrier()
	current_location = locations[0] if not locations.is_empty() else null
	for loc: LocationData in locations:
		if loc.id == save_data.current_location_id and is_location_unlocked(loc):
			current_location = loc
			break


func _save_data_to_dict(save_data: SaveData) -> Dictionary:
	return {
		"save_version": save_data.save_version,
		"level": save_data.level,
		"current_xp": save_data.current_xp,
		"gold": save_data.gold,
		"skill_points": save_data.skill_points,
		"enemies_defeated": save_data.enemies_defeated,
		"kills_in_run": save_data.kills_in_run,
		"base_strength": save_data.base_strength,
		"base_agility": save_data.base_agility,
		"base_endurance": save_data.base_endurance,
		"base_intellect": save_data.base_intellect,
		"current_hp": save_data.current_hp,
		"current_mana": save_data.current_mana,
		"melee_level": save_data.melee_level,
		"melee_xp": save_data.melee_xp,
		"ranged_level": save_data.ranged_level,
		"ranged_xp": save_data.ranged_xp,
		"magic_level": save_data.magic_level,
		"magic_xp": save_data.magic_xp,
		"current_location_id": save_data.current_location_id,
		"equipped_weapon_path": save_data.equipped_weapon_path,
		"equipped_armor_path": save_data.equipped_armor_path,
		"equipped_ammo_path": save_data.equipped_ammo_path,
		"equipped_ammo_count": save_data.equipped_ammo_count,
		"inventory_paths": save_data.inventory_paths.duplicate(),
		"inventory_counts": save_data.inventory_counts.duplicate(),
		"inventory_qualities": save_data.inventory_qualities.duplicate(),
		"inventory_stars": save_data.inventory_stars.duplicate(),
		"unlocked_skills": save_data.unlocked_skills.duplicate(),
		"skill_presets": save_data.skill_presets.duplicate(true),
		"active_skill_preset_index": save_data.active_skill_preset_index,
		"skill_auto_upgrade_enabled": save_data.skill_auto_upgrade_enabled,
		"equipped_ability_ids": save_data.equipped_ability_ids.duplicate(),
		"ability_auto_cast": save_data.ability_auto_cast.duplicate(),
		"auto_potion_enabled": save_data.auto_potion_enabled,
		"auto_hp_threshold_pct": save_data.auto_hp_threshold_pct,
		"auto_hp_condition": save_data.auto_hp_condition,
		"auto_mana_enabled": save_data.auto_mana_enabled,
		"auto_mana_threshold_pct": save_data.auto_mana_threshold_pct,
		"auto_mana_condition": save_data.auto_mana_condition,
		"auto_buff_enabled": save_data.auto_buff_enabled,
		"auto_buff_condition": save_data.auto_buff_condition,
		"auto_buff_whitelist": save_data.auto_buff_whitelist.duplicate(),
		"weapon_enchant_level": save_data.weapon_enchant_level,
		"armor_enchant_level": save_data.armor_enchant_level,
		"dark_weapon_enchant_level": save_data.dark_weapon_enchant_level,
		"dark_armor_enchant_level": save_data.dark_armor_enchant_level,
		"mine_locked_this_run": save_data.mine_locked_this_run,
		"mine_depth": save_data.mine_depth,
		"difficulty_level": save_data.difficulty_level,
		"max_unlocked_difficulty": save_data.max_unlocked_difficulty,
		"boss_defeated_this_run": save_data.boss_defeated_this_run,
		"dark_points": save_data.dark_points,
		"dark_shop_coins": save_data.dark_shop_coins,
		"dark_points_claimed_difficulties": save_data.dark_points_claimed_difficulties.duplicate(),
		"unlocked_dark_skills": save_data.unlocked_dark_skills.duplicate(),
		"difficulty_curses": save_data.difficulty_curses.duplicate(true),
		"total_runs_completed": save_data.total_runs_completed,
		"selected_class_id": save_data.selected_class_id,
		"reflector_kill_hp_stacks": save_data.reflector_kill_hp_stacks,
		"curse_reroll_tokens": save_data.curse_reroll_tokens,
		"reroll_boss_kills_in_run": save_data.reroll_boss_kills_in_run,
		"owned_pet_ids": save_data.owned_pet_ids.duplicate(),
		"equipped_pet_id": save_data.equipped_pet_id,
		"garden_plots": save_data.garden_plots.duplicate(true),
		"light_garden_plots": save_data.light_garden_plots.duplicate(true),
		"brewing_slots": save_data.brewing_slots.duplicate(true),
		"alchemist_next_mistake_safe": save_data.alchemist_next_mistake_safe,
		"pet_training_levels": save_data.pet_training_levels.duplicate(true),
		"spirit_training_levels": save_data.spirit_training_levels.duplicate(true),
		"afk_target_fps": save_data.afk_target_fps,
		"equipped_weapon_quality": save_data.equipped_weapon_quality,
		"equipped_weapon_stars": save_data.equipped_weapon_stars,
		"equipped_armor_quality": save_data.equipped_armor_quality,
		"equipped_armor_stars": save_data.equipped_armor_stars,
		"equipped_offhand_path": save_data.equipped_offhand_path,
		"equipped_offhand_quality": save_data.equipped_offhand_quality,
		"equipped_offhand_stars": save_data.equipped_offhand_stars,
		"offhand_enchant_level": save_data.offhand_enchant_level,
		"dark_offhand_enchant_level": save_data.dark_offhand_enchant_level,
		"auto_salvage_mode": save_data.auto_salvage_mode,
		"auto_salvage_min_quality": save_data.auto_salvage_min_quality,
		"abyss_ore_shards": save_data.abyss_ore_shards,
		"bestiary_kills": save_data.bestiary_kills.duplicate(true),
		"active_challenge_id": save_data.active_challenge_id,
		"completed_challenges": save_data.completed_challenges.duplicate(),
		"run_elapsed_seconds": save_data.run_elapsed_seconds,
		"combat_loadouts": save_data.combat_loadouts.duplicate(true),
		"auto_route_enabled": save_data.auto_route_enabled,
		"auto_route_wins_threshold": save_data.auto_route_wins_threshold,
		"consecutive_location_wins": save_data.consecutive_location_wins,
		"well_greed_cooldown_remaining": save_data.well_greed_cooldown_remaining,
		"well_run_blessing": save_data.well_run_blessing,
		"ability_casts": save_data.ability_casts.duplicate(true),
		"ability_levels": save_data.ability_levels.duplicate(true),
		"ability_runes": save_data.ability_runes.duplicate(true),
		"pet_expeditions": save_data.pet_expeditions.duplicate(true),
		"unlocked_mine_checkpoints": save_data.unlocked_mine_checkpoints.duplicate(),
		"mine_start_depth": save_data.mine_start_depth,
		"wave_dungeon_clears": save_data.wave_dungeon_clears,
	}


func _dict_to_save_data(data: Dictionary) -> SaveData:
	var save_data: SaveData = SaveData.new()
	save_data.save_version = int(data.get("save_version", 1))
	save_data.level = int(data.get("level", 1))
	save_data.current_xp = float(data.get("current_xp", 0.0))
	save_data.gold = float(data.get("gold", 20.0))
	save_data.skill_points = int(data.get("skill_points", 0))
	save_data.enemies_defeated = int(data.get("enemies_defeated", 0))
	save_data.kills_in_run = int(data.get("kills_in_run", 0))
	save_data.base_strength = int(data.get("base_strength", 5))
	save_data.base_agility = int(data.get("base_agility", 5))
	save_data.base_endurance = int(data.get("base_endurance", 5))
	save_data.base_intellect = int(data.get("base_intellect", 5))
	save_data.current_hp = float(data.get("current_hp", 400.0))
	save_data.current_mana = float(data.get("current_mana", 285.0))
	save_data.melee_level = int(data.get("melee_level", 1))
	save_data.melee_xp = float(data.get("melee_xp", 0.0))
	save_data.ranged_level = int(data.get("ranged_level", 1))
	save_data.ranged_xp = float(data.get("ranged_xp", 0.0))
	save_data.magic_level = int(data.get("magic_level", 1))
	save_data.magic_xp = float(data.get("magic_xp", 0.0))
	save_data.current_location_id = str(data.get("current_location_id", "quiet_glade"))
	save_data.equipped_weapon_path = str(data.get("equipped_weapon_path", ""))
	save_data.equipped_armor_path = str(data.get("equipped_armor_path", ""))
	save_data.equipped_ammo_path = str(data.get("equipped_ammo_path", ""))
	save_data.equipped_ammo_count = int(data.get("equipped_ammo_count", 0))

	if data.get("inventory_paths") is Array:
		for p: Variant in data["inventory_paths"]:
			save_data.inventory_paths.append(str(p))
	if data.get("inventory_counts") is Array:
		for c: Variant in data["inventory_counts"]:
			save_data.inventory_counts.append(int(c))
	if data.get("inventory_qualities") is Array:
		for iq: Variant in data["inventory_qualities"]:
			save_data.inventory_qualities.append(int(iq))
	if data.get("inventory_stars") is Array:
		for isv: Variant in data["inventory_stars"]:
			save_data.inventory_stars.append(int(isv))
	if data.get("unlocked_skills") is Array:
		for s: Variant in data["unlocked_skills"]:
			save_data.unlocked_skills.append(str(s))
	if data.get("skill_presets") is Array:
		for pr: Variant in data["skill_presets"]:
			if pr is Dictionary:
				save_data.skill_presets.append((pr as Dictionary).duplicate(true))
	save_data.active_skill_preset_index = int(data.get("active_skill_preset_index", 0))
	save_data.skill_auto_upgrade_enabled = bool(data.get("skill_auto_upgrade_enabled", false))
	if data.get("equipped_ability_ids") is Array:
		save_data.equipped_ability_ids.clear()
		for a: Variant in data["equipped_ability_ids"]:
			save_data.equipped_ability_ids.append(str(a))
	if data.get("ability_auto_cast") is Array:
		save_data.ability_auto_cast.clear()
		for ac: Variant in data["ability_auto_cast"]:
			save_data.ability_auto_cast.append(bool(ac))

	save_data.auto_potion_enabled = bool(data.get("auto_potion_enabled", false))
	save_data.auto_hp_threshold_pct = int(data.get("auto_hp_threshold_pct", 35))
	save_data.auto_hp_condition = str(data.get("auto_hp_condition", "combat"))
	save_data.auto_mana_enabled = bool(data.get("auto_mana_enabled", false))
	save_data.auto_mana_threshold_pct = int(data.get("auto_mana_threshold_pct", 30))
	save_data.auto_mana_condition = str(data.get("auto_mana_condition", "combat"))
	save_data.auto_buff_enabled = bool(data.get("auto_buff_enabled", false))
	save_data.auto_buff_condition = str(data.get("auto_buff_condition", "on_expire_combat"))
	if data.get("auto_buff_whitelist") is Array:
		for bw: Variant in data["auto_buff_whitelist"]:
			save_data.auto_buff_whitelist.append(str(bw))

	save_data.weapon_enchant_level = int(data.get("weapon_enchant_level", 0))
	save_data.armor_enchant_level = int(data.get("armor_enchant_level", 0))
	save_data.dark_weapon_enchant_level = int(data.get("dark_weapon_enchant_level", 0))
	save_data.dark_armor_enchant_level = int(data.get("dark_armor_enchant_level", 0))
	save_data.mine_locked_this_run = bool(data.get("mine_locked_this_run", false))
	save_data.mine_depth = int(data.get("mine_depth", 0))

	save_data.difficulty_level = int(data.get("difficulty_level", 1))
	save_data.max_unlocked_difficulty = int(data.get("max_unlocked_difficulty", 1))
	save_data.boss_defeated_this_run = bool(data.get("boss_defeated_this_run", false))
	save_data.dark_points = int(data.get("dark_points", 0))
	save_data.dark_shop_coins = int(data.get("dark_shop_coins", 0))
	if data.get("dark_points_claimed_difficulties") is Array:
		for d: Variant in data["dark_points_claimed_difficulties"]:
			save_data.dark_points_claimed_difficulties.append(int(d))
	if data.get("unlocked_dark_skills") is Array:
		for ds: Variant in data["unlocked_dark_skills"]:
			save_data.unlocked_dark_skills.append(str(ds))
	if data.get("difficulty_curses") is Dictionary:
		save_data.difficulty_curses = (data["difficulty_curses"] as Dictionary).duplicate(true)
	save_data.total_runs_completed = int(data.get("total_runs_completed", 0))
	save_data.selected_class_id = str(data.get("selected_class_id", "wanderer"))
	save_data.reflector_kill_hp_stacks = int(data.get("reflector_kill_hp_stacks", 0))
	save_data.curse_reroll_tokens = int(data.get("curse_reroll_tokens", 0))
	save_data.reroll_boss_kills_in_run = int(data.get("reroll_boss_kills_in_run", 0))
	if data.get("owned_pet_ids") is Array:
		for p: Variant in data["owned_pet_ids"]:
			save_data.owned_pet_ids.append(str(p))
	save_data.equipped_pet_id = str(data.get("equipped_pet_id", ""))

	if data.get("garden_plots") is Array:
		for gp: Variant in data["garden_plots"]:
			if gp is Dictionary:
				save_data.garden_plots.append((gp as Dictionary).duplicate(true))
	if data.get("light_garden_plots") is Array:
		for lgp: Variant in data["light_garden_plots"]:
			if lgp is Dictionary:
				save_data.light_garden_plots.append((lgp as Dictionary).duplicate(true))
	if data.get("brewing_slots") is Array:
		for bs: Variant in data["brewing_slots"]:
			if bs is Dictionary:
				save_data.brewing_slots.append((bs as Dictionary).duplicate(true))
	save_data.alchemist_next_mistake_safe = bool(data.get("alchemist_next_mistake_safe", false))
	if data.get("pet_training_levels") is Dictionary:
		save_data.pet_training_levels = (data["pet_training_levels"] as Dictionary).duplicate(true)
	if data.get("spirit_training_levels") is Dictionary:
		save_data.spirit_training_levels = (data["spirit_training_levels"] as Dictionary).duplicate(true)

	# v0.22.0 fields
	save_data.afk_target_fps = int(data.get("afk_target_fps", DEFAULT_AFK_MAX_FPS))
	save_data.equipped_weapon_quality = int(data.get("equipped_weapon_quality", 100))
	save_data.equipped_weapon_stars = int(data.get("equipped_weapon_stars", 1))
	save_data.equipped_armor_quality = int(data.get("equipped_armor_quality", 100))
	save_data.equipped_armor_stars = int(data.get("equipped_armor_stars", 1))
	save_data.equipped_offhand_path = str(data.get("equipped_offhand_path", ""))
	save_data.equipped_offhand_quality = int(data.get("equipped_offhand_quality", 100))
	save_data.equipped_offhand_stars = int(data.get("equipped_offhand_stars", 1))
	save_data.offhand_enchant_level = int(data.get("offhand_enchant_level", 0))
	save_data.dark_offhand_enchant_level = int(data.get("dark_offhand_enchant_level", 0))
	save_data.auto_salvage_mode = str(data.get("auto_salvage_mode", "off"))
	save_data.auto_salvage_min_quality = int(data.get("auto_salvage_min_quality", 95))
	save_data.abyss_ore_shards = int(data.get("abyss_ore_shards", 0))
	if data.get("bestiary_kills") is Dictionary:
		save_data.bestiary_kills = (data["bestiary_kills"] as Dictionary).duplicate(true)
	save_data.active_challenge_id = str(data.get("active_challenge_id", ""))
	if data.get("completed_challenges") is Array:
		for cid: Variant in data["completed_challenges"]:
			save_data.completed_challenges.append(str(cid))
	save_data.run_elapsed_seconds = float(data.get("run_elapsed_seconds", 0.0))
	if data.get("combat_loadouts") is Array:
		for cl: Variant in data["combat_loadouts"]:
			if cl is Dictionary:
				save_data.combat_loadouts.append((cl as Dictionary).duplicate(true))
	save_data.auto_route_enabled = bool(data.get("auto_route_enabled", false))
	save_data.auto_route_wins_threshold = int(data.get("auto_route_wins_threshold", 5))
	save_data.consecutive_location_wins = int(data.get("consecutive_location_wins", 0))
	save_data.well_greed_cooldown_remaining = float(data.get("well_greed_cooldown_remaining", 0.0))
	save_data.well_run_blessing = str(data.get("well_run_blessing", ""))
	if data.get("ability_casts") is Dictionary:
		save_data.ability_casts = (data["ability_casts"] as Dictionary).duplicate(true)
	if data.get("ability_levels") is Dictionary:
		save_data.ability_levels = (data["ability_levels"] as Dictionary).duplicate(true)
	if data.get("ability_runes") is Dictionary:
		save_data.ability_runes = (data["ability_runes"] as Dictionary).duplicate(true)
	if data.get("pet_expeditions") is Array:
		for pe: Variant in data["pet_expeditions"]:
			if pe is Dictionary:
				save_data.pet_expeditions.append((pe as Dictionary).duplicate(true))
	if data.get("unlocked_mine_checkpoints") is Array:
		for cp: Variant in data["unlocked_mine_checkpoints"]:
			save_data.unlocked_mine_checkpoints.append(int(cp))
	save_data.mine_start_depth = int(data.get("mine_start_depth", 1))
	save_data.wave_dungeon_clears = int(data.get("wave_dungeon_clears", 0))

	return save_data


func export_save_to_text() -> String:
	var save_data: SaveData = _build_save_data()
	var payload: Dictionary = {
		"format": "HERO_TALE_SAVE_TXT",
		"save_version": SAVE_SCHEMA_VERSION,
		"exported_at": Time.get_datetime_string_from_system(),
		"summary": {
			"level": level,
			"difficulty": difficulty_level,
			"max_difficulty": max_unlocked_difficulty,
			"dark_points": dark_points,
			"dark_shop_coins": dark_shop_coins,
			"class_id": selected_class_id,
			"reflector_kill_hp_stacks": reflector_kill_hp_stacks,
		},
		"data": _save_data_to_dict(save_data),
	}
	return JSON.stringify(payload, "\t")


func export_save_to_txt_file(file_path: String) -> Dictionary:
	if file_path.is_empty():
		return {"success": false, "message": "Путь для сохранения не выбран."}
	var content: String = export_save_to_text()
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var err_code: Error = FileAccess.get_open_error()
		return {"success": false, "message": "Не удалось создать файл (код %d)." % err_code}
	file.store_string(content)
	file.flush()
	file.close()
	save_status_changed.emit("Экспортировано в .txt")
	return {"success": true, "message": "✅ Сохранение экспортировано: %s" % file_path}


func import_save_from_text(raw_text: String) -> Dictionary:
	_wait_for_save_thread()
	var trimmed: String = raw_text.strip_edges()
	if trimmed.is_empty():
		return {"success": false, "message": "Файл или текст сохранения пуст."}
	var parsed: Variant = JSON.parse_string(trimmed)
	if not (parsed is Dictionary):
		return {"success": false, "message": "Неверный формат .txt сохранения (ожидался JSON)."}
	var root: Dictionary = parsed as Dictionary
	if str(root.get("format", "")) != "HERO_TALE_SAVE_TXT" or not (root.get("data") is Dictionary):
		return {"success": false, "message": "Этот .txt файл не является сохранением Hero Tale Idle RPG."}
	var data_dict: Dictionary = root["data"] as Dictionary
	var save_data: SaveData = _dict_to_save_data(data_dict)
	_apply_save_data(save_data)
	ensure_curses_for_difficulty(difficulty_level)
	_invalidate_progression_caches()
	save_game(true)
	_emit_all_refresh_signals()
	game_reset.emit()
	save_status_changed.emit("Импортировано из .txt")
	return {"success": true, "message": "✅ Прогресс загружен: Ур.%d | Сл.%d (макс. %d) | 🌑 %d" % [level, difficulty_level, max_unlocked_difficulty, dark_points]}


func import_save_from_txt_file(file_path: String) -> Dictionary:
	if file_path.is_empty():
		return {"success": false, "message": "Файл для импорта не выбран."}
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var err_code: Error = FileAccess.get_open_error()
		return {"success": false, "message": "Не удалось прочитать файл (код %d)." % err_code}
	var content: String = file.get_as_text()
	file.close()
	return import_save_from_text(content)


func _wait_for_save_thread() -> void:
	if _save_thread != null and _save_thread.is_started():
		_save_thread.wait_to_finish()
	_save_thread = null
	_save_in_progress = false


func _write_save_data_to_disk(save_data: SaveData) -> bool:
	if save_data == null:
		return false
	var err: Error = ResourceSaver.save(save_data, SAVE_TEMP_PATH)
	if err != OK or not FileAccess.file_exists(SAVE_TEMP_PATH):
		return false
	var tmp_file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.READ)
	if tmp_file == null:
		return false
	var tmp_len: int = tmp_file.get_length()
	tmp_file.close()
	if tmp_len <= 0:
		return false

	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(SAVE_BACKUP_PATH):
			DirAccess.remove_absolute(SAVE_BACKUP_PATH)
		DirAccess.rename_absolute(SAVE_PATH, SAVE_BACKUP_PATH)

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	var rename_err: Error = DirAccess.rename_absolute(SAVE_TEMP_PATH, SAVE_PATH)
	return rename_err == OK


func _save_worker_entry(save_data: SaveData) -> void:
	var ok: bool = _write_save_data_to_disk(save_data)
	call_deferred("_on_async_save_finished", ok)


func _on_async_save_finished(ok: bool) -> void:
	_wait_for_save_thread()
	if ok:
		save_status_changed.emit("Прогресс сохранён")
	if _save_queued_after_worker:
		_save_queued_after_worker = false
		save_game(false)


func save_game(force_immediate: bool = false) -> void:
	if force_immediate:
		_wait_for_save_thread()
		_save_pending = false
		_save_queued_after_worker = false
		_save_throttle_timer = SAVE_THROTTLE_INTERVAL
		var sync_data: SaveData = _build_save_data()
		if _write_save_data_to_disk(sync_data):
			save_status_changed.emit("Прогресс сохранён")
		return

	if _save_throttle_timer > 0.0:
		_save_pending = true
		return
	if _save_in_progress:
		_save_queued_after_worker = true
		return

	_save_pending = false
	_save_throttle_timer = SAVE_THROTTLE_INTERVAL
	var async_data: SaveData = _build_save_data()
	_save_thread = Thread.new()
	var start_err: Error = _save_thread.start(Callable(self, "_save_worker_entry").bind(async_data))
	if start_err == OK:
		_save_in_progress = true
	else:
		_save_thread = null
		if _write_save_data_to_disk(async_data):
			save_status_changed.emit("Прогресс сохранён")


func load_game() -> bool:
	_wait_for_save_thread()
	var save_data: SaveData = null
	var loaded_from_backup: bool = false
	for candidate_path: String in [SAVE_PATH, SAVE_BACKUP_PATH, SAVE_TEMP_PATH]:
		if not ResourceLoader.exists(candidate_path):
			continue
		var loaded: SaveData = ResourceLoader.load(candidate_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
		if loaded != null:
			save_data = loaded
			loaded_from_backup = candidate_path != SAVE_PATH
			break
	if save_data == null:
		return false

	_apply_save_data(save_data)

	if loaded_from_backup:
		save_game(true)

	return true
