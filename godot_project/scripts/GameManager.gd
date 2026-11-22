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
signal mine_state_changed
signal mine_run_failed(depth_reached: int)
signal game_reset

const SAVE_PATH: String = "user://save.tres"
const SAVE_BACKUP_PATH: String = "user://save.bak.tres"
const SAVE_TEMP_PATH: String = "user://save.tmp.tres"
const SAVE_SCHEMA_VERSION: int = 1
const BASE_DAMAGE: float = 6.0
const BASE_CRIT_CHANCE: float = 0.05
const CRIT_MULTIPLIER: float = 1.75
const AUTOSAVE_INTERVAL: float = 480.0
const AFK_FPS_LIMIT: int = 2
const NORMAL_FPS_LIMIT: int = 60
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
const CURSE_WARDEN_ID: String = "curse_warden"
const SPIRIT_KEYS: Array[String] = ["fire", "wind", "forest", "earth"]
const HP_THRESHOLD_PRESETS: Array[int] = [20, 35, 50, 70, 85]
const MANA_THRESHOLD_PRESETS: Array[int] = [15, 30, 50, 70]

const BUFF_POTION_CATALOG: Array[Dictionary] = [
	{"id": "fury_potion", "label": "💢 Ярость", "path": "res://resources/items/fury_potion.tres"},
	{"id": "ironhide_potion", "label": "🛡️ Каменная кожа", "path": "res://resources/items/ironhide_potion.tres"},
	{"id": "swiftwind_potion", "label": "💨 Вихрь", "path": "res://resources/items/swiftwind_potion.tres"},
	{"id": "arcane_wisdom_potion", "label": "🧠 Прозрение", "path": "res://resources/items/arcane_wisdom_potion.tres"},
	{"id": "titan_blood_brew", "label": "🔥 Кровь титана", "path": "res://resources/items/titan_blood_brew.tres"},
	{"id": "immortal_dew_potion", "label": "🥛 Роса бессмертия", "path": "res://resources/items/immortal_dew_potion.tres"},
	{"id": "crimson_petal_elixir", "label": "🌺 Алый лепесток", "path": "res://resources/items/crimson_petal_elixir.tres"},
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
	"res://resources/abilities/crimson_lance.tres",
	"res://resources/abilities/hemorrhage_curse.tres",
	"res://resources/abilities/crimson_ward.tres",
	"res://resources/abilities/blood_frenzy.tres",
	"res://resources/abilities/crimson_nova.tres",
	"res://resources/abilities/sanguine_apotheosis.tres",
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
var current_hp: float = 175.0
var current_mana: float = 55.0

var melee_level: int = 1
var melee_xp: float = 0.0
var ranged_level: int = 1
var ranged_xp: float = 0.0
var magic_level: int = 1
var magic_xp: float = 0.0

var equipped_weapon: ItemData = null
var equipped_armor: ItemData = null
var equipped_ammo: ItemData = null
var equipped_ammo_count: int = 0
var weapon_enchant_level: int = 0
var armor_enchant_level: int = 0
var inventory: Array[Dictionary] = []

var locations: Array[LocationData] = []
var current_location: LocationData = null
var shop_items: Array[ItemData] = []

var skill_nodes: Array[SkillNodeData] = []
var _skills_by_id: Dictionary = {}
var unlocked_skills: Array[String] = []

var dark_skill_nodes: Array[DarkSkillNodeData] = []
var _dark_skills_by_id: Dictionary = {}
var dark_points: int = 0
var dark_points_claimed_difficulties: Array[int] = []
var unlocked_dark_skills: Array[String] = []

var hero_classes: Array[HeroClassData] = []
var _classes_by_id: Dictionary = {}
var selected_class_id: String = "wanderer"

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
var mine_locked_this_run: bool = false
var mine_depth: int = 0

var is_afk_mode: bool = false
var afk_elapsed_seconds: float = 0.0
var afk_kills: int = 0
var afk_gold_earned: float = 0.0
var afk_xp_earned: float = 0.0

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
var _save_throttle_timer: float = 0.0
var _save_pending: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_locations()
	_load_shop_items()
	_load_skills()
	_load_dark_skills()
	_load_abilities()
	_load_classes()
	_load_pets()
	_load_crops()
	if not load_game():
		_init_full_reset_state()
	_ensure_sanctuary_slots()
	ensure_curses_for_difficulty(difficulty_level)
	Engine.max_fps = NORMAL_FPS_LIMIT
	RenderingServer.render_loop_enabled = true
	DisplayServer.screen_set_keep_on(false)
	_emit_all_refresh_signals()


func _process(delta: float) -> void:
	if _save_throttle_timer > 0.0:
		_save_throttle_timer = maxf(0.0, _save_throttle_timer - delta)
		if _save_throttle_timer <= 0.0 and _save_pending:
			save_game(true)

	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game(true)

	var max_mana: float = get_max_mana()
	if current_mana < max_mana:
		restore_mana(get_mana_regen_per_sec() * delta)

	var cd_speed_mult: float = 1.0 + get_pet_effect_value("cooldown_haste")
	var cd_changed: bool = false
	for i: int in range(ability_cooldowns.size()):
		if ability_cooldowns[i] > 0.0:
			ability_cooldowns[i] = maxf(0.0, ability_cooldowns[i] - delta * cd_speed_mult)
			cd_changed = true
	if cd_changed:
		abilities_changed.emit()

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
		RenderingServer.render_loop_enabled = true
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
	mine_state_changed.emit()
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


func _load_shop_items() -> void:
	shop_items.clear()
	for path: String in SHOP_ITEM_PATHS:
		var item: ItemData = load(path) as ItemData
		if item != null:
			shop_items.append(item)


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


func _init_full_reset_state() -> void:
	difficulty_level = 1
	max_unlocked_difficulty = 1
	dark_points = 0
	dark_points_claimed_difficulties.clear()
	unlocked_dark_skills.clear()
	difficulty_curses.clear()
	total_runs_completed = 0
	curse_reroll_tokens = 0
	selected_class_id = "wanderer"
	owned_pet_ids.clear()
	equipped_pet_id = ""
	auto_potion_enabled = false
	auto_hp_threshold_pct = 35
	auto_hp_condition = "combat"
	auto_mana_enabled = false
	auto_mana_threshold_pct = 30
	auto_mana_condition = "combat"
	auto_buff_enabled = false
	auto_buff_condition = "on_expire_combat"
	auto_buff_whitelist.clear()
	dark_weapon_enchant_level = 0
	dark_armor_enchant_level = 0
	mine_locked_this_run = false
	mine_depth = 0
	equipped_weapon = null
	equipped_armor = null
	equipped_ammo = null
	equipped_ammo_count = 0
	inventory.clear()
	enemies_defeated = 0
	garden_plots.clear()
	light_garden_plots.clear()
	brewing_slots.clear()
	alchemist_next_mistake_safe = false
	pet_training_levels.clear()
	spirit_training_levels = {"fire": 0, "wind": 0, "forest": 0, "earth": 0}
	equipped_ability_ids = DEFAULT_EQUIPPED_ABILITIES.duplicate()
	_sync_equipped_abilities()
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		ability_auto_cast[i] = false
	_init_run_state(1)
	_ensure_sanctuary_slots()


func _init_run_state(target_difficulty: int) -> void:
	difficulty_level = clampi(target_difficulty, 1, maxi(1, max_unlocked_difficulty))
	ensure_curses_for_difficulty(difficulty_level)

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
			preserved_garden_items.append({"item": existing_item, "count": existing_cnt})

	var preserved_weapon: ItemData = equipped_weapon if (equipped_weapon != null and equipped_weapon.is_dark_forged) else null
	var preserved_armor: ItemData = equipped_armor if (equipped_armor != null and equipped_armor.is_dark_forged) else null
	var preserved_ammo: ItemData = equipped_ammo if (equipped_ammo != null and equipped_ammo.is_dark_forged) else null
	var preserved_ammo_cnt: int = equipped_ammo_count if preserved_ammo != null else 0

	equipped_weapon = preserved_weapon
	equipped_armor = preserved_armor
	equipped_ammo = preserved_ammo
	equipped_ammo_count = maxi(1, preserved_ammo_cnt) if preserved_ammo != null else 0
	weapon_enchant_level = 0
	armor_enchant_level = 0
	inventory.clear()
	unlocked_skills.clear()
	active_buffs.clear()
	_validate_equipped_abilities_for_class()
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		ability_cooldowns[i] = 0.0

	var starter_potion: ItemData = load(STARTER_POTION_PATH) as ItemData
	if starter_potion != null:
		add_item(starter_potion, 2, false)

	for saved_garden: Dictionary in preserved_garden_items:
		var g_item: ItemData = saved_garden["item"] as ItemData
		var g_cnt: int = int(saved_garden["count"])
		add_item(g_item, g_cnt, false)

	_ensure_sanctuary_slots()

	current_hp = get_max_hp()
	current_mana = get_max_mana()
	if not locations.is_empty():
		current_location = locations[0]


func start_new_run(target_difficulty: int) -> void:
	var clamped_diff: int = clampi(target_difficulty, 1, maxi(1, max_unlocked_difficulty))
	if boss_defeated_this_run:
		total_runs_completed += 1
	_init_run_state(clamped_diff)
	save_game(true)
	_emit_all_refresh_signals()
	game_reset.emit()


func reset_progress() -> void:
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
	_validate_equipped_abilities_for_class()
	clear_active_buffs()

	if target.disables_equipment:
		if equipped_weapon != null:
			add_item(equipped_weapon, 1, false)
			equipped_weapon = null
		if equipped_armor != null:
			add_item(equipped_armor, 1, false)
			equipped_armor = null
		if equipped_ammo != null and equipped_ammo_count > 0:
			add_item(equipped_ammo, equipped_ammo_count, false)
			equipped_ammo = null
			equipped_ammo_count = 0

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

	class_changed.emit(target)
	stats_changed.emit()
	inventory_changed.emit()
	enchant_changed.emit()
	abilities_changed.emit()
	buffs_changed.emit()
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
	if equipped_pet_id == pet_id:
		return false
	equipped_pet_id = pet_id
	pets_changed.emit()
	stats_changed.emit()
	save_game()
	return true


func unequip_pet() -> void:
	if equipped_pet_id.is_empty():
		return
	equipped_pet_id = ""
	pets_changed.emit()
	stats_changed.emit()
	save_game()


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
		if not used_ids.has(picked_id):
			used_ids.append(picked_id)


func _get_curse_definition(curse_id: String) -> Dictionary:
	for entry: Dictionary in CURSE_CATALOG:
		if str(entry["id"]) == curse_id:
			return entry
	return {}


func get_active_curses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var max_tier: int = floori(float(difficulty_level) / 10.0) * 10
	if max_tier < 10:
		return result
	ensure_curses_for_difficulty(difficulty_level)

	var atten: float = get_curse_attenuation()
	for tier: int in range(10, max_tier + 1, 10):
		var cid: String = str(difficulty_curses.get(tier, ""))
		var def: Dictionary = _get_curse_definition(cid)
		if def.is_empty():
			continue
		var eff_val: float = float(def["base_value"]) * atten
		result.append({
			"tier": tier,
			"id": cid,
			"title": str(def["title"]),
			"value": eff_val,
			"description": format_curse_description(def, eff_val),
		})
	return result


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
	var total: float = 0.0
	for c: Dictionary in get_active_curses():
		if str(c["id"]) == curse_id:
			total += float(c["value"])
	return total


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


func on_final_boss_defeated() -> void:
	if boss_defeated_this_run:
		return
	boss_defeated_this_run = true
	var gained: int = 0
	if not dark_points_claimed_difficulties.has(difficulty_level):
		dark_points_claimed_difficulties.append(difficulty_level)
		gained = 2
		dark_points += gained
	if difficulty_level >= max_unlocked_difficulty:
		max_unlocked_difficulty = difficulty_level + 1
	ensure_curses_for_difficulty(max_unlocked_difficulty)
	dark_skills_changed.emit()
	difficulty_changed.emit()
	stats_changed.emit()
	final_boss_cleared.emit(gained, max_unlocked_difficulty)
	save_game()


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
	return unlocked_dark_skills.has(skill_id)


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
	var total: float = 0.0
	for skill_id: String in unlocked_dark_skills:
		var dskill: DarkSkillNodeData = get_dark_skill_by_id(skill_id)
		if dskill != null and dskill.effect_type == effect_type:
			total += dskill.effect_value
	return total


# --- Regular Skills ---

func get_skill_by_id(skill_id: String) -> SkillNodeData:
	if _skills_by_id.has(skill_id):
		return _skills_by_id[skill_id] as SkillNodeData
	return null


func is_skill_unlocked(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id)


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
	var total: float = 0.0
	for skill_id: String in unlocked_skills:
		var skill: SkillNodeData = get_skill_by_id(skill_id)
		if skill != null and skill.bonus_type == bonus_type:
			total += skill.bonus_value
	return total


# --- Enchanting System (+0 .. +100, or +250 for Alchemist) ---

func get_max_enchant_level() -> int:
	if has_hero_class("alchemist"):
		return ALCHEMIST_MAX_ENCHANT_LEVEL
	return MAX_ENCHANT_LEVEL


func get_enchant_level(slot_type: ItemData.ItemType) -> int:
	if slot_type == ItemData.ItemType.WEAPON:
		return weapon_enchant_level
	if slot_type == ItemData.ItemType.ARMOR:
		return armor_enchant_level
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
	return 0


func get_total_slot_enchant_level(slot_type: ItemData.ItemType) -> int:
	return get_enchant_level(slot_type) + get_dark_enchant_level(slot_type)


func get_enchant_power_multiplier(enchant_lvl: int) -> float:
	var per_level: float = 0.15 * (1.25 if has_dark_skill("blacksmith_brand") else 1.0)
	return 1.0 + float(enchant_lvl) * per_level


func get_equipped_stat_bonuses(slot_type: ItemData.ItemType) -> Dictionary:
	if is_equipment_disabled():
		return {"strength": 0, "agility": 0, "endurance": 0, "intellect": 0}
	var item: ItemData = equipped_weapon if slot_type == ItemData.ItemType.WEAPON else equipped_armor
	if item == null:
		return {"strength": 0, "agility": 0, "endurance": 0, "intellect": 0}
	var run_elvl: int = get_enchant_level(slot_type)
	var dark_elvl: int = get_dark_enchant_level(slot_type)
	var total_elvl: int = run_elvl + dark_elvl
	var mult: float = get_enchant_power_multiplier(total_elvl)
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
	return {"strength": s, "agility": a, "endurance": e, "intellect": intel}


func try_enchant_slot(slot_type: ItemData.ItemType) -> Dictionary:
	if is_equipment_disabled():
		return {"success": false, "message": "Класс Спирит не может использовать и ковать экипировку."}
	var item: ItemData = equipped_weapon if slot_type == ItemData.ItemType.WEAPON else equipped_armor
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
		else:
			armor_enchant_level += 1

		var new_max_hp: float = get_max_hp()
		if new_max_hp > prev_max_hp:
			current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))
		var new_max_mana: float = get_max_mana()
		if new_max_mana > prev_max_mana:
			current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))

		stats_changed.emit()
		hp_changed.emit(current_hp, new_max_hp)
		mana_changed.emit(current_mana, new_max_mana)
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
	# +1 -> +2 = 20%, decreasing down to minimum 15%
	return maxf(15.0, 20.0 - float(current_lvl - 1) * 1.0)


func get_dark_forge_enchant_cost(current_lvl: int) -> int:
	return 4 + maxi(0, current_lvl) * 2


func try_dark_forge_enchant(slot_type: ItemData.ItemType) -> Dictionary:
	if is_equipment_disabled():
		return {"success": false, "message": "Класс Спирит не может использовать Тёмную заточку."}
	var item: ItemData = equipped_weapon if slot_type == ItemData.ItemType.WEAPON else equipped_armor
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
		else:
			dark_armor_enchant_level += 1

		var new_max_hp: float = get_max_hp()
		if new_max_hp > prev_max_hp:
			current_hp = minf(new_max_hp, current_hp + (new_max_hp - prev_max_hp))
		var new_max_mana: float = get_max_mana()
		if new_max_mana > prev_max_mana:
			current_mana = minf(new_max_mana, current_mana + (new_max_mana - prev_max_mana))

		stats_changed.emit()
		dark_skills_changed.emit()
		enchant_changed.emit()
		dark_forge_changed.emit()
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
	var item: ItemData = load("res://resources/items/%s.tres" % item_id) as ItemData
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
	var ore_item: ItemData = load("res://resources/items/abyss_ore.tres") as ItemData
	var page_item: ItemData = load("res://resources/items/ancient_page.tres") as ItemData
	if need_ore > 0 and (ore_item == null or get_item_count_in_inventory(ore_item) < need_ore):
		return {"success": false, "message": "Недостаточно ⛏️ Руды Бездны (нужно %d)." % need_ore}
	if need_page > 0 and (page_item == null or get_item_count_in_inventory(page_item) < need_page):
		return {"success": false, "message": "Недостаточно 📜 Древних листов (нужно %d)." % need_page}

	var result_item: ItemData = load(str(r.get("result_path", ""))) as ItemData
	if result_item == null:
		return {"success": false, "message": "Предмет рецепта повреждён."}

	dark_points -= need_dp
	if need_ore > 0 and ore_item != null:
		remove_item(ore_item, need_ore)
	if need_page > 0 and page_item != null:
		remove_item(page_item, need_page)

	var amt: int = maxi(1, int(r.get("amount", 1)))
	add_item(result_item, amt, true)
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
	var wb: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var total: float = float(base_strength + roundi(get_skill_bonus("strength")) + int(wb["strength"]) + int(ab["strength"]))
	if has_hero_class("spirit"):
		total *= 1.35
	elif has_hero_class("troll"):
		total *= 1.20
	return maxi(1, roundi(total))


func get_total_agility() -> int:
	var wb: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var total: float = float(base_agility + roundi(get_skill_bonus("agility")) + int(wb["agility"]) + int(ab["agility"]))
	if has_hero_class("spirit"):
		total *= 1.35
	return maxi(1, roundi(total))


func get_total_endurance() -> int:
	var wb: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var total: float = float(base_endurance + roundi(get_skill_bonus("endurance")) + int(wb["endurance"]) + int(ab["endurance"]))
	if has_hero_class("spirit"):
		total *= 1.35
	return maxi(1, roundi(total))


func get_total_intellect() -> int:
	var wb: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var tome_int: int = 0
	if is_using_mage_staff() and has_matching_ammo() and equipped_ammo != null:
		tome_int = equipped_ammo.bonus_intellect
	var total: float = float(int(wb["intellect"]) + int(ab["intellect"]) + tome_int)
	if has_hero_class("spirit"):
		total *= 1.35
	elif has_hero_class("blood_archmage"):
		total *= 1.20
	return maxi(0, roundi(total))


func get_equipped_mana_cost_reduction() -> float:
	if is_equipment_disabled():
		return 0.0
	var red: float = 0.0
	if equipped_weapon != null:
		red += equipped_weapon.bonus_mana_cost_red
	if equipped_armor != null:
		red += equipped_armor.bonus_mana_cost_red
	if is_using_mage_staff() and has_matching_ammo() and equipped_ammo != null:
		red += equipped_ammo.bonus_mana_cost_red
	return clampf(red, 0.0, 0.65)


func get_equipped_spell_power_bonus() -> float:
	if is_equipment_disabled():
		return 0.0
	var sp: float = 0.0
	if equipped_weapon != null:
		sp += equipped_weapon.bonus_spell_power_pct
	if equipped_armor != null:
		sp += equipped_armor.bonus_spell_power_pct
	if is_using_mage_staff() and has_matching_ammo() and equipped_ammo != null:
		sp += equipped_ammo.bonus_spell_power_pct
	return maxf(0.0, sp)


func get_effect_duration_multiplier() -> float:
	if is_equipment_disabled():
		return 1.0
	var bonus: float = 0.0
	if equipped_weapon != null:
		bonus += equipped_weapon.bonus_effect_duration_pct
	if equipped_armor != null:
		bonus += equipped_armor.bonus_effect_duration_pct
	if is_using_mage_staff() and has_matching_ammo() and equipped_ammo != null:
		bonus += equipped_ammo.bonus_effect_duration_pct
	return maxf(1.0, 1.0 + bonus)


func get_max_hp() -> float:
	var hp_val: float = 100.0 + float(get_total_endurance()) * 15.0
	if has_dark_skill("immortal_pact"):
		hp_val *= (1.0 + get_dark_bonus("immortal_pact"))
	if has_hero_class("troll"):
		hp_val *= 1.25
	elif has_hero_class("reflector"):
		hp_val *= 1.30
	return hp_val


func get_max_mana() -> float:
	return 40.0 + float(level) * 5.0 + float(get_total_endurance()) * 2.0 + float(get_total_intellect()) * 4.0 + get_skill_bonus("max_mana")


func get_mana_regen_per_sec() -> float:
	var regen: float = 2.5 + float(get_total_endurance()) * 0.25 + float(get_total_intellect()) * 0.45 + get_skill_bonus("mana_regen")
	regen *= (1.0 + float(magic_level - 1) * 0.04)
	regen *= (1.0 + get_dark_bonus("mana_fountain"))
	regen *= (1.0 + get_active_buff_sum("mana_regen_pct"))
	regen *= (1.0 + get_pet_secondary_value("aura_regen"))
	if has_hero_class("alchemist"):
		regen *= 1.15
	regen *= maxf(0.1, 1.0 - get_curse_value("mana_burn"))
	return regen


func spend_mana(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current_mana < amount:
		return false
	current_mana = maxf(0.0, current_mana - amount)
	mana_changed.emit(current_mana, get_max_mana())
	return true


func restore_mana(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var max_mana: float = get_max_mana()
	var prev_mana: float = current_mana
	current_mana = minf(max_mana, current_mana + amount)
	var actual: float = current_mana - prev_mana
	if actual > 0.0:
		mana_changed.emit(current_mana, max_mana)
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


func apply_ability_buff(ability: AbilityData, potency_scale: float = 1.0) -> void:
	if ability == null or ability.duration <= 0.0:
		return
	var final_dur: float = maxf(1.0, ability.duration * get_effect_duration_multiplier())
	var entry: Dictionary = {
		"id": ability.id,
		"title": ability.title,
		"icon_emoji": ability.icon_emoji,
		"remaining": final_dur,
		"duration": final_dur,
		"damage_pct": ability.buff_damage_pct * potency_scale,
		"attack_speed_pct": ability.buff_attack_speed_pct * potency_scale,
		"armor_pct": ability.buff_armor_pct * potency_scale,
		"dodge_bonus": ability.buff_dodge_bonus * potency_scale,
		"crit_chance_bonus": ability.buff_crit_chance_bonus * potency_scale,
		"crit_mult_bonus": ability.buff_crit_mult_bonus * potency_scale,
		"spell_power_pct": ability.buff_spell_power_pct * potency_scale,
		"mana_regen_pct": ability.buff_mana_regen_pct * potency_scale,
		"lifesteal_pct": ability.buff_lifesteal_pct * potency_scale,
		"thorns_pct": ability.buff_thorns_pct * potency_scale,
	}
	var replaced: bool = false
	for i: int in range(active_buffs.size()):
		if str(active_buffs[i]["id"]) == ability.id:
			active_buffs[i] = entry
			replaced = true
			break
	if not replaced:
		active_buffs.append(entry)
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
	return maxf(0.4, cd)


func get_ability_power_multiplier(ability: AbilityData) -> float:
	if ability == null:
		return 1.0
	var mult: float = ability.power_multiplier
	mult *= get_mastery_bonus_multiplier("magic")
	mult *= (1.0 + get_skill_bonus("spell_power") + get_active_buff_sum("spell_power_pct") + get_equipped_spell_power_bonus() + float(get_total_intellect()) * 0.015)
	if has_dark_skill("swift_runes"):
		mult *= 1.35
	if has_hero_class("blood_archmage"):
		mult *= 1.75
	if ability.effect_type == "heal":
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
	if not is_equipment_disabled() and equipped_weapon != null and equipped_weapon.bonus_damage > 0.0:
		dmg += equipped_weapon.bonus_damage * get_enchant_power_multiplier(total_weapon_elvl)

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
	return dmg


func get_player_armor_penetration() -> float:
	if is_equipment_disabled():
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
	if wind_speed > 0.0:
		base_interval /= (1.0 + wind_speed)
	return maxf(0.26, base_interval * (1.0 + get_curse_value("lead_shackles")))


func get_player_dps() -> float:
	if has_hero_class("reflector"):
		return 0.0
	var avg_crit_factor: float = 1.0 + get_crit_chance() * (get_crit_multiplier() - 1.0)
	return (get_player_damage() * avg_crit_factor) / get_player_attack_interval()


func get_dodge_chance() -> float:
	return clampf(float(get_total_agility()) * 0.008 + get_skill_bonus("dodge_chance") + get_active_buff_sum("dodge_bonus"), 0.0, 0.65)


func get_armor_reduction() -> float:
	var raw_armor: float = float(get_total_endurance()) * 0.6 + get_skill_bonus("flat_armor")
	if has_hero_class("spirit"):
		raw_armor *= 1.50
	elif has_hero_class("reflector"):
		raw_armor *= 1.40
	raw_armor *= (1.0 + get_active_buff_sum("armor_pct"))
	raw_armor *= maxf(0.15, 1.0 - get_curse_value("brittle_armor"))
	return raw_armor


func get_crit_chance() -> float:
	var extra: float = get_active_buff_sum("crit_chance_bonus") + get_pet_effect_value("crit_lightning")
	if not is_equipment_disabled() and equipped_weapon != null:
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
	return mult


func get_xp_multiplier() -> float:
	var dark_xp: float = 0.5 if has_dark_skill("abyssal_greed") else 0.0
	return (1.0 + get_skill_bonus("xp_mult") + dark_xp) * get_difficulty_xp_mult()


func get_xp_to_next_level() -> float:
	var lvl_idx: float = float(maxi(0, level - 1))
	return round(150.0 * pow(1.10, lvl_idx) + lvl_idx * lvl_idx * 55.0)


func get_train_cost(stat_name: String) -> float:
	var stat_val: int = 5
	match stat_name:
		"strength":
			stat_val = base_strength
		"agility":
			stat_val = base_agility
		"endurance":
			stat_val = base_endurance
	return round((10.0 + float(stat_val) * 5.0) * get_difficulty_train_mult())


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
		if item != null and item.item_type == ItemData.ItemType.CONSUMABLE and item.heal_amount > 0.0:
			total += int(entry["count"])
	return total


func get_total_mana_potion_count() -> int:
	var total: int = 0
	for entry: Dictionary in inventory:
		var item: ItemData = entry["item"] as ItemData
		if item != null and item.item_type == ItemData.ItemType.CONSUMABLE and item.mana_amount > 0.0:
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
		if item.heal_amount <= 0.0:
			continue
		var score: float = item.heal_amount - missing_hp if item.heal_amount >= missing_hp else 10000.0 - item.heal_amount
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
		if item.mana_amount <= 0.0:
			continue
		var score: float = item.mana_amount - missing_mp if item.mana_amount >= missing_mp else 10000.0 - item.mana_amount
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
		Engine.max_fps = AFK_FPS_LIMIT
		DisplayServer.screen_set_keep_on(true)
	else:
		RenderingServer.render_loop_enabled = true
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
	current_location = location
	location_changed.emit(current_location)
	save_game()
	return true


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
		var ore_item: ItemData = load("res://resources/items/abyss_ore.tres") as ItemData
		if ore_item != null:
			add_item(ore_item, 1, true)
			return "⛏️ Найдена жила: +1 Руда Бездны!"
	elif r < 0.78:
		var page_item: ItemData = load("res://resources/items/ancient_page.tres") as ItemData
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
	while current_xp >= get_xp_to_next_level():
		current_xp -= get_xp_to_next_level()
		level += 1
		skill_points += 1
		current_hp = get_max_hp()
		current_mana = get_max_mana()
		level_up.emit(level)
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
	stats_changed.emit()


func apply_damage(raw_damage: float) -> float:
	var reduced: float = maxf(1.0, raw_damage - get_armor_reduction())
	if has_dark_skill("arcane_barrier") and current_mana > 0.0:
		var mana_shield_cap: float = minf(current_mana, reduced * get_dark_bonus("arcane_barrier"))
		if mana_shield_cap > 0.0:
			spend_mana(mana_shield_cap)
			reduced = maxf(1.0, reduced - mana_shield_cap)
	current_hp = maxf(0.0, current_hp - reduced)
	hp_changed.emit(current_hp, get_max_hp())
	return reduced


func apply_rot_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	current_hp = maxf(0.0, current_hp - amount)
	hp_changed.emit(current_hp, get_max_hp())


func heal(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var max_hp: float = get_max_hp()
	var prev_hp: float = current_hp
	current_hp = minf(max_hp, current_hp + amount)
	var actual: float = current_hp - prev_hp
	if actual > 0.0:
		hp_changed.emit(current_hp, max_hp)
	return actual


func upgrade_stat_with_skill_point(stat_name: String) -> bool:
	if skill_points <= 0:
		return false
	if not _increment_base_stat(stat_name):
		return false
	skill_points -= 1
	if stat_name == "endurance":
		current_hp = minf(get_max_hp(), current_hp + 15.0)
		current_mana = minf(get_max_mana(), current_mana + 2.0)
	stats_changed.emit()
	skills_changed.emit()
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())
	save_game()
	return true


func train_stat_with_gold(stat_name: String) -> bool:
	var cost: float = get_train_cost(stat_name)
	if gold < cost:
		return false
	if not _increment_base_stat(stat_name):
		return false
	gold -= cost
	if stat_name == "endurance":
		current_hp = minf(get_max_hp(), current_hp + 15.0)
		current_mana = minf(get_max_mana(), current_mana + 2.0)
	stats_changed.emit()
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())
	save_game()
	return true


func _increment_base_stat(stat_name: String) -> bool:
	match stat_name:
		"strength":
			base_strength += 1
			return true
		"agility":
			base_agility += 1
			return true
		"endurance":
			base_endurance += 1
			return true
	return false


func add_item(item: ItemData, amount: int = 1, notify: bool = true) -> void:
	if item == null or amount <= 0:
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
			entry["count"] = int(entry["count"]) + amount
			inventory_changed.emit()
			if notify:
				item_acquired.emit(item, amount)
			return
	inventory.append({"item": item, "count": amount})
	inventory_changed.emit()
	if notify:
		item_acquired.emit(item, amount)


func remove_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	for i: int in range(inventory.size()):
		var entry: Dictionary = inventory[i]
		var existing: ItemData = entry["item"] as ItemData
		if existing != null and existing.id == item.id:
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
	for entry: Dictionary in inventory:
		var existing: ItemData = entry["item"] as ItemData
		if existing != null and existing.id == item.id:
			return int(entry["count"])
	return 0


func sell_item(item: ItemData, amount: int = 1) -> String:
	if item == null or amount <= 0:
		return ""
	if not remove_item(item, amount):
		return ""
	var total_gold: float = get_item_sell_value(item) * float(amount)
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


func use_or_equip_item(item: ItemData) -> String:
	if item == null:
		return ""
	match item.item_type:
		ItemData.ItemType.CONSUMABLE:
			var has_heal: bool = item.heal_amount > 0.0
			var has_mana: bool = item.mana_amount > 0.0
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
					var healed: float = heal(item.heal_amount * heal_mult)
					player_healed.emit(healed)
					parts.append("+%s HP" % NumberFormatter.format_number(healed))
				if has_mana:
					var mana_mult: float = alch_mult * cauldron_bonus
					var restored: float = restore_mana(item.mana_amount * mana_mult)
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
		ItemData.ItemType.WEAPON:
			if is_equipment_disabled():
				return "Класс Спирит не может носить оружие."
			if remove_item(item, 1):
				if equipped_weapon != null:
					add_item(equipped_weapon, 1, false)
				equipped_weapon = item
				current_hp = minf(current_hp, get_max_hp())
				current_mana = minf(current_mana, get_max_mana())
				stats_changed.emit()
				hp_changed.emit(current_hp, get_max_hp())
				mana_changed.emit(current_mana, get_max_mana())
				inventory_changed.emit()
				enchant_changed.emit()
				save_game()
				return "Экипировано оружие: %s." % item.get_display_name()
		ItemData.ItemType.ARMOR:
			if is_equipment_disabled():
				return "Класс Спирит не может носить броню."
			if remove_item(item, 1):
				if equipped_armor != null:
					add_item(equipped_armor, 1, false)
				equipped_armor = item
				current_hp = minf(current_hp, get_max_hp())
				current_mana = minf(current_mana, get_max_mana())
				stats_changed.emit()
				hp_changed.emit(current_hp, get_max_hp())
				mana_changed.emit(current_mana, get_max_mana())
				inventory_changed.emit()
				enchant_changed.emit()
				save_game()
				return "Экипирована броня: %s." % item.get_display_name()
		ItemData.ItemType.AMMO:
			if is_equipment_disabled():
				return "Класс Спирит не может использовать снаряды."
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
				equipped_weapon = null
				add_item(prev, 1, false)
		ItemData.ItemType.ARMOR:
			if equipped_armor != null:
				var prev: ItemData = equipped_armor
				equipped_armor = null
				add_item(prev, 1, false)
		ItemData.ItemType.AMMO:
			if equipped_ammo != null and equipped_ammo_count > 0:
				var prev_ammo: ItemData = equipped_ammo
				var prev_cnt: int = equipped_ammo_count
				equipped_ammo = null
				equipped_ammo_count = 0
				add_item(prev_ammo, prev_cnt, false)
	current_hp = minf(current_hp, get_max_hp())
	current_mana = minf(current_mana, get_max_mana())
	stats_changed.emit()
	hp_changed.emit(current_hp, get_max_hp())
	mana_changed.emit(current_mana, get_max_mana())
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

	if garden_dirty:
		garden_changed.emit()
		save_game()
	if brew_dirty:
		brewing_changed.emit()
		save_game()

	if any_active_timer:
		_sanctuary_ui_sync_timer += delta
		if _sanctuary_ui_sync_timer >= 0.25:
			_sanctuary_ui_sync_timer = 0.0
			garden_changed.emit()
			brewing_changed.emit()


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
			var seed_item: ItemData = load(crop.seed_item_path) as ItemData
			if seed_item != null:
				add_item(seed_item, 1, true)


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
	var harvest_item: ItemData = load(crop.harvest_item_path) as ItemData
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
		var req_item: ItemData = load("res://resources/items/%s.tres" % req_id) as ItemData
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
		var req_item: ItemData = load("res://resources/items/%s.tres" % req_id) as ItemData
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
	var harvest_item: ItemData = load(crop.harvest_item_path) as ItemData
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
	var fruit_item: ItemData = load("res://resources/items/spirit_primordial_harvest.tres") as ItemData
	if fruit_item == null or not remove_item(fruit_item, 1):
		return {"success": false, "message": "Нужен 🌟 Плод первоцвета духов (семя падает с 0.03% шансом ТОЛЬКО с Вечного титана)."}

	var next_lvl: int = get_spirit_training_level(spirit_key) + 1
	spirit_training_levels[spirit_key] = next_lvl
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
	var potion: ItemData = load(path) as ItemData
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
	save_data.dark_points_claimed_difficulties = dark_points_claimed_difficulties.duplicate()
	save_data.unlocked_dark_skills = unlocked_dark_skills.duplicate()
	save_data.difficulty_curses = difficulty_curses.duplicate()
	save_data.total_runs_completed = total_runs_completed
	save_data.selected_class_id = selected_class_id
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

	for entry: Dictionary in inventory:
		var item: ItemData = entry["item"] as ItemData
		if item != null and not item.resource_path.is_empty():
			save_data.inventory_paths.append(item.resource_path)
			save_data.inventory_counts.append(int(entry["count"]))

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

	difficulty_curses.clear()
	if save_data.difficulty_curses is Dictionary:
		for k: Variant in save_data.difficulty_curses.keys():
			difficulty_curses[int(k)] = str(save_data.difficulty_curses[k])

	unlocked_skills.clear()
	for skill_id: String in save_data.unlocked_skills:
		if _skills_by_id.has(skill_id) and not unlocked_skills.has(skill_id):
			unlocked_skills.append(skill_id)

	unlocked_dark_skills.clear()
	for dskill_id: String in save_data.unlocked_dark_skills:
		if _dark_skills_by_id.has(dskill_id) and not unlocked_dark_skills.has(dskill_id):
			unlocked_dark_skills.append(dskill_id)

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

	equipped_weapon = null
	if not is_equipment_disabled() and not save_data.equipped_weapon_path.is_empty() and ResourceLoader.exists(save_data.equipped_weapon_path):
		equipped_weapon = load(save_data.equipped_weapon_path) as ItemData

	equipped_armor = null
	if not is_equipment_disabled() and not save_data.equipped_armor_path.is_empty() and ResourceLoader.exists(save_data.equipped_armor_path):
		equipped_armor = load(save_data.equipped_armor_path) as ItemData

	equipped_ammo = null
	equipped_ammo_count = 0
	if not is_equipment_disabled() and not save_data.equipped_ammo_path.is_empty() and ResourceLoader.exists(save_data.equipped_ammo_path):
		equipped_ammo = load(save_data.equipped_ammo_path) as ItemData
		equipped_ammo_count = maxi(0, save_data.equipped_ammo_count)
		if equipped_ammo != null:
			if equipped_ammo.is_dark_forged:
				equipped_ammo_count = maxi(1, equipped_ammo_count)
			elif equipped_ammo_count == 0:
				equipped_ammo = null

	inventory.clear()
	var item_count: int = mini(save_data.inventory_paths.size(), save_data.inventory_counts.size())
	for i: int in range(item_count):
		var path: String = save_data.inventory_paths[i]
		if ResourceLoader.exists(path):
			var item: ItemData = load(path) as ItemData
			if item != null:
				add_item(item, save_data.inventory_counts[i], false)

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
	_ensure_sanctuary_slots()

	active_buffs.clear()
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		ability_cooldowns[i] = 0.0

	current_hp = clampf(save_data.current_hp, 0.0, get_max_hp())
	current_mana = clampf(save_data.current_mana, 0.0, get_max_mana())
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
		"unlocked_skills": save_data.unlocked_skills.duplicate(),
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
		"dark_points_claimed_difficulties": save_data.dark_points_claimed_difficulties.duplicate(),
		"unlocked_dark_skills": save_data.unlocked_dark_skills.duplicate(),
		"difficulty_curses": save_data.difficulty_curses.duplicate(true),
		"total_runs_completed": save_data.total_runs_completed,
		"selected_class_id": save_data.selected_class_id,
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
	save_data.current_hp = float(data.get("current_hp", 175.0))
	save_data.current_mana = float(data.get("current_mana", 55.0))
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
	if data.get("unlocked_skills") is Array:
		for s: Variant in data["unlocked_skills"]:
			save_data.unlocked_skills.append(str(s))
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
			"class_id": selected_class_id,
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


func save_game(force_immediate: bool = false) -> void:
	if not force_immediate and _save_throttle_timer > 0.0:
		_save_pending = true
		return
	_save_pending = false
	_save_throttle_timer = 0.35
	var save_data: SaveData = _build_save_data()

	var err: Error = ResourceSaver.save(save_data, SAVE_TEMP_PATH)
	if err != OK or not FileAccess.file_exists(SAVE_TEMP_PATH):
		return
	var tmp_file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.READ)
	if tmp_file == null:
		return
	var tmp_len: int = tmp_file.get_length()
	tmp_file.close()
	if tmp_len <= 0:
		return

	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(SAVE_BACKUP_PATH):
			DirAccess.remove_absolute(SAVE_BACKUP_PATH)
		DirAccess.rename_absolute(SAVE_PATH, SAVE_BACKUP_PATH)

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	var rename_err: Error = DirAccess.rename_absolute(SAVE_TEMP_PATH, SAVE_PATH)
	if rename_err == OK:
		save_status_changed.emit("Прогресс сохранён")


func load_game() -> bool:
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
