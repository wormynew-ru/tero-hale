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
signal difficulty_run_auto_advanced(new_difficulty: int)
signal parallel_battle_changed(count: int)
signal dark_mastery_changed(mastery_id: String, new_level: int, leveled_up: bool)
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
const ALCHEMIST_GOLD_REACTION_RATIO: float = 0.05
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
const PARALLEL_BATTLE_OPTIONS: Array[int] = [1, 3, 5, 10]
const SPELL_LEVEL_CAST_THRESHOLDS: Array[int] = [0, 25, 100, 300, 750]

const STARTER_POTION_PATH: String = ItemAndShopCatalog.STARTER_POTION_PATH
const BUFF_POTION_CATALOG: Array[Dictionary] = ItemAndShopCatalog.BUFF_POTION_CATALOG
const SHOP_ITEM_PATHS: Array[String] = ItemAndShopCatalog.SHOP_ITEM_PATHS
const DARK_SHOP_ITEM_PATHS: Array[String] = ItemAndShopCatalog.DARK_SHOP_ITEM_PATHS
const DARK_FORGE_RECIPES: Array[Dictionary] = ItemAndShopCatalog.DARK_FORGE_RECIPES
const DARK_MASTERY_KEYS: Array[String] = WorldAndAbilityCatalog.DARK_MASTERY_KEYS
const DARK_MASTERY_CATALOG: Array[Dictionary] = WorldAndAbilityCatalog.DARK_MASTERY_CATALOG
const BESTIARY_MILESTONES: Array[Dictionary] = WorldAndAbilityCatalog.BESTIARY_MILESTONES
const CHALLENGE_CATALOG: Array[Dictionary] = WorldAndAbilityCatalog.CHALLENGE_CATALOG
const CURSE_CATALOG: Array[Dictionary] = WorldAndAbilityCatalog.CURSE_CATALOG
const LOCATION_PATHS: Array[String] = WorldAndAbilityCatalog.LOCATION_PATHS
const SKILL_PATHS: Array[String] = WorldAndAbilityCatalog.SKILL_PATHS
const DARK_SKILL_PATHS: Array[String] = WorldAndAbilityCatalog.DARK_SKILL_PATHS
const ABILITY_PATHS: Array[String] = WorldAndAbilityCatalog.ABILITY_PATHS
const CLASS_PATHS: Array[String] = WorldAndAbilityCatalog.CLASS_PATHS
const PET_PATHS: Array[String] = WorldAndAbilityCatalog.PET_PATHS
const ENEMY_PATHS: Array[String] = WorldAndAbilityCatalog.ENEMY_PATHS
const CROP_PATHS: Array[String] = SanctuaryAndForgeCatalog.CROP_PATHS
const PET_LURE_RECIPES: Array[Dictionary] = SanctuaryAndForgeCatalog.PET_LURE_RECIPES
const SPELL_RUNES_CATALOG: Dictionary = SanctuaryAndForgeCatalog.SPELL_RUNES_CATALOG
const BREW_STEP_TRANSITIONS: Dictionary = SanctuaryAndForgeCatalog.BREW_STEP_TRANSITIONS
const PET_EXPEDITION_PLANS: Array[Dictionary] = SanctuaryAndForgeCatalog.PET_EXPEDITION_PLANS

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
var auto_salvage_mode: String = "off"
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
var auto_advance_next_boss: bool = false
var parallel_battle_count: int = 1
var active_dark_mastery_id: String = "dark_melee"
var dark_mastery_levels: Dictionary = {"dark_melee": 0, "dark_ranged": 0, "dark_magic": 0, "dark_reflect": 0, "dark_armor": 0, "dark_temper": 0}
var dark_mastery_xp: Dictionary = {"dark_melee": 0.0, "dark_ranged": 0.0, "dark_magic": 0.0, "dark_reflect": 0.0, "dark_armor": 0.0, "dark_temper": 0.0}

var _afk_ui_sync_timer: float = 0.0
var _buff_ui_sync_timer: float = 0.0
var _hp_mp_ui_sync_timer: float = 0.0
var _ability_ui_sync_timer: float = 0.0
var _hp_ui_dirty: bool = false
var _mana_ui_dirty: bool = false
var _abilities_ui_dirty: bool = false

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

var save_service: SaveService = SaveService.new()
var stats_calc: StatsCalculator = StatsCalculator.new()
var combat_stats_calc: CombatStatsCalculator = CombatStatsCalculator.new()
var forge_service: ForgeService = ForgeService.new()
var inventory_service: InventoryService = InventoryService.new()
var potion_service: PotionService = PotionService.new()
var loadout_service: CombatLoadoutService = CombatLoadoutService.new()
var run_service: RunAndDifficultyService = RunAndDifficultyService.new()
var difficulty_service: DifficultyAndChallengeService = DifficultyAndChallengeService.new()
var progression_service: ProgressionService = ProgressionService.new()
var skill_class_service: SkillAndClassService = SkillAndClassService.new()
var pet_mastery_service: PetAndMasteryService = PetAndMasteryService.new()
var ability_buff_service: AbilityAndBuffService = AbilityAndBuffService.new()
var sanctuary_service: SanctuaryService = SanctuaryService.new()
var brewing_service: BrewingService = BrewingService.new()
var world_mine_service: WorldAndMineService = WorldAndMineService.new()
var wave_well_service: WaveAndWellService = WaveAndWellService.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var services: Array[Node] = [
		save_service, stats_calc, combat_stats_calc, forge_service, inventory_service,
		potion_service, loadout_service, run_service, difficulty_service, progression_service,
		skill_class_service, pet_mastery_service, ability_buff_service, sanctuary_service,
		brewing_service, world_mine_service, wave_well_service,
	]
	for svc: Node in services:
		svc.call("setup", self)
		add_child(svc)
	_load_catalogs()
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


func _load_catalogs() -> void:
	_load_list(LOCATION_PATHS, locations)
	_load_list(SHOP_ITEM_PATHS, shop_items)
	_load_list(DARK_SHOP_ITEM_PATHS, dark_shop_items)
	_load_indexed(ENEMY_PATHS, all_enemies, _enemies_by_id)
	_load_indexed(SKILL_PATHS, skill_nodes, _skills_by_id)
	_load_indexed(DARK_SKILL_PATHS, dark_skill_nodes, _dark_skills_by_id)
	_load_indexed(CLASS_PATHS, hero_classes, _classes_by_id)
	_load_indexed(PET_PATHS, all_pets, _pets_by_id)
	_load_indexed(CROP_PATHS, crops, _crops_by_id)
	_load_indexed(ABILITY_PATHS, all_abilities, _abilities_by_id)
	_sync_equipped_abilities()
	ability_cooldowns.resize(MAX_ACTIVE_ABILITY_SLOTS)
	ability_auto_cast.resize(MAX_ACTIVE_ABILITY_SLOTS)
	for i: int in range(MAX_ACTIVE_ABILITY_SLOTS):
		ability_cooldowns[i] = 0.0
		ability_auto_cast[i] = false


func _load_list(paths: Array[String], target: Array) -> void:
	target.clear()
	for path: String in paths:
		var res: Resource = load(path)
		if res != null:
			target.append(res)


func _load_indexed(paths: Array[String], target: Array, index_map: Dictionary) -> void:
	target.clear()
	index_map.clear()
	for path: String in paths:
		var res: Resource = load(path)
		if res != null:
			var id_val: String = str(res.get("id"))
			if not id_val.is_empty():
				target.append(res)
				index_map[id_val] = res


func _exit_tree() -> void:
	_wait_for_save_thread()


func _process(delta: float) -> void:
	save_service.process_tick(delta)
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
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
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
	parallel_battle_changed.emit(parallel_battle_count)
	dark_mastery_changed.emit(active_dark_mastery_id, get_dark_mastery_level(active_dark_mastery_id), false)
	mastery_changed.emit("melee", melee_level, false)
	mastery_changed.emit("ranged", ranged_level, false)
	mastery_changed.emit("magic", magic_level, false)
	if current_location != null:
		location_changed.emit(current_location)


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


func _invalidate_progression_caches() -> void: run_service.invalidate_progression_caches()
func _ensure_progression_caches() -> void: run_service.ensure_progression_caches()
func _init_full_reset_state() -> void: run_service.init_full_reset_state()
func _init_run_state(target_difficulty: int, challenge_id: String = "") -> void: run_service.init_run_state(target_difficulty, challenge_id)
func start_new_run(target_difficulty: int, challenge_id: String = "") -> void: run_service.start_new_run(target_difficulty, challenge_id)
func reset_progress() -> void: run_service.reset_progress()
func roll_difficulty_reset_item_drop() -> void: run_service.roll_difficulty_reset_item_drop()
func reset_claimed_difficulties_rewards() -> Dictionary: return run_service.reset_claimed_difficulties_rewards()
func set_auto_advance_next_boss(enabled: bool) -> void: run_service.set_auto_advance_next_boss(enabled)

func get_difficulty_enemy_hp_mult() -> float: return difficulty_service.get_difficulty_enemy_hp_mult()
func get_difficulty_enemy_dmg_mult() -> float: return difficulty_service.get_difficulty_enemy_dmg_mult()
func get_difficulty_enemy_armor_mult() -> float: return difficulty_service.get_difficulty_enemy_armor_mult()
func get_difficulty_enemy_flat_armor() -> float: return difficulty_service.get_difficulty_enemy_flat_armor()
func get_difficulty_price_mult() -> float: return difficulty_service.get_difficulty_price_mult()
func get_difficulty_train_mult() -> float: return difficulty_service.get_difficulty_train_mult()
func get_difficulty_gold_mult() -> float: return difficulty_service.get_difficulty_gold_mult()
func get_difficulty_xp_mult() -> float: return difficulty_service.get_difficulty_xp_mult()
func get_curse_attenuation() -> float: return difficulty_service.get_curse_attenuation()
func ensure_curses_for_difficulty(target_diff: int) -> void: difficulty_service.ensure_curses_for_difficulty(target_diff)
func get_curse_definition(curse_id: String) -> Dictionary: return difficulty_service.get_curse_definition(curse_id)
func get_active_curses() -> Array[Dictionary]: return difficulty_service.get_active_curses()
func format_curse_description(def: Dictionary, eff_val: float) -> String: return difficulty_service.format_curse_description(def, eff_val)
func get_curse_value(curse_id: String) -> float: return difficulty_service.get_curse_value(curse_id)
func reroll_curse_at_tier(tier: int) -> Dictionary: return difficulty_service.reroll_curse_at_tier(tier)
func is_dark_points_claimed_for_difficulty(diff: int) -> bool: return difficulty_service.is_dark_points_claimed_for_difficulty(diff)
func get_challenge_def(challenge_id: String) -> Dictionary: return difficulty_service.get_challenge_def(challenge_id)
func is_challenge_completed(challenge_id: String) -> bool: return difficulty_service.is_challenge_completed(challenge_id)
func is_potions_blocked_by_challenge() -> bool: return difficulty_service.is_potions_blocked_by_challenge()
func is_non_staff_blocked_by_challenge() -> bool: return difficulty_service.is_non_staff_blocked_by_challenge()
func is_gear_blocked_by_challenge() -> bool: return difficulty_service.is_gear_blocked_by_challenge()
func on_final_boss_defeated() -> void: difficulty_service.on_final_boss_defeated()
func on_curse_warden_defeated() -> void: difficulty_service.on_curse_warden_defeated()

func get_total_strength() -> int: return stats_calc.get_total_strength()
func get_total_agility() -> int: return stats_calc.get_total_agility()
func get_total_endurance() -> int: return stats_calc.get_total_endurance()
func get_total_intellect() -> int: return stats_calc.get_total_intellect()
func get_equipped_mana_cost_reduction() -> float: return stats_calc.get_equipped_mana_cost_reduction()
func get_equipped_spell_power_bonus() -> float: return stats_calc.get_equipped_spell_power_bonus()
func get_effect_duration_multiplier() -> float: return stats_calc.get_effect_duration_multiplier()
func get_raw_max_barrier() -> float: return stats_calc.get_raw_max_barrier()
func get_barrier_regen_per_sec_pct() -> float: return stats_calc.get_barrier_regen_per_sec_pct()
func get_on_kill_barrier_restore_pct() -> float: return stats_calc.get_on_kill_barrier_restore_pct()
func get_equipped_reflection_bonus() -> float: return stats_calc.get_equipped_reflection_bonus()
func get_max_barrier() -> float: return stats_calc.get_max_barrier()
func add_barrier(amount: float) -> float: return stats_calc.add_barrier(amount)
func restore_barrier_full() -> void: stats_calc.restore_barrier_full()
func get_max_hp() -> float: return stats_calc.get_max_hp()
func get_max_mana() -> float: return stats_calc.get_max_mana()
func get_mana_regen_per_sec() -> float: return stats_calc.get_mana_regen_per_sec()
func spend_mana(amount: float) -> bool: return stats_calc.spend_mana(amount)
func restore_mana(amount: float, emit_signal_immediately: bool = true) -> float: return stats_calc.restore_mana(amount, emit_signal_immediately)

func get_player_damage(preview_ammo_ready: bool = true) -> float: return combat_stats_calc.get_player_damage(preview_ammo_ready)
func get_pack_or_boss_damage_mult(enemy_id: String, pack_count: int = 1) -> float: return combat_stats_calc.get_pack_or_boss_damage_mult(enemy_id, pack_count)
func get_alchemist_gold_reaction_bonus() -> float: return combat_stats_calc.get_alchemist_gold_reaction_bonus()
func get_basic_attack_damage(preview_ammo_ready: bool = true) -> float: return combat_stats_calc.get_basic_attack_damage(preview_ammo_ready)
func get_player_armor_penetration() -> float: return combat_stats_calc.get_player_armor_penetration()
func get_player_attack_interval() -> float: return combat_stats_calc.get_player_attack_interval()
func get_player_dps() -> float: return combat_stats_calc.get_player_dps()
func get_dodge_chance() -> float: return combat_stats_calc.get_dodge_chance()
func get_armor_reduction() -> float: return combat_stats_calc.get_armor_reduction()
func get_damage_reflection_pct() -> float: return combat_stats_calc.get_damage_reflection_pct()
func get_reflector_mitigation_pct() -> float: return combat_stats_calc.get_reflector_mitigation_pct()
func get_crit_chance() -> float: return combat_stats_calc.get_crit_chance()
func get_crit_multiplier() -> float: return combat_stats_calc.get_crit_multiplier()
func get_gold_multiplier() -> float: return combat_stats_calc.get_gold_multiplier()
func get_xp_multiplier() -> float: return combat_stats_calc.get_xp_multiplier()
func get_xp_to_next_level() -> float: return combat_stats_calc.get_xp_to_next_level()
func get_train_bulk_cost(stat_name: String, target_count: int) -> Dictionary: return combat_stats_calc.get_train_bulk_cost(stat_name, target_count)
func get_item_buy_price(item: ItemData) -> float: return combat_stats_calc.get_item_buy_price(item)
func get_item_sell_value(item: ItemData) -> float: return combat_stats_calc.get_item_sell_value(item)

func add_xp(amount: float) -> void: progression_service.add_xp(amount)
func add_gold(amount: float) -> void: progression_service.add_gold(amount)
func record_kill(defeated_enemy: EnemyData = null) -> void: progression_service.record_kill(defeated_enemy)
func apply_damage(raw_damage: float) -> float: return progression_service.apply_damage(raw_damage)
func apply_rot_damage(amount: float, emit_signal_immediately: bool = true) -> void: progression_service.apply_rot_damage(amount, emit_signal_immediately)
func heal(amount: float, emit_signal_immediately: bool = true) -> float: return progression_service.heal(amount, emit_signal_immediately)
func upgrade_stat_with_skill_point(stat_name: String) -> bool: return progression_service.upgrade_stat_with_skill_point(stat_name)
func upgrade_stat_with_skill_points_bulk(stat_name: String, target_count: int) -> int: return progression_service.upgrade_stat_with_skill_points_bulk(stat_name, target_count)
func train_stat_with_gold(stat_name: String) -> bool: return progression_service.train_stat_with_gold(stat_name)
func train_stat_with_gold_bulk(stat_name: String, target_count: int) -> int: return progression_service.train_stat_with_gold_bulk(stat_name, target_count)

func get_max_enchant_level() -> int: return forge_service.get_max_enchant_level()
func get_quality_multiplier(quality_pct: int) -> float: return forge_service.get_quality_multiplier(quality_pct)
func get_star_multiplier(star_level: int) -> float: return forge_service.get_star_multiplier(star_level)
func get_equipped_slot_item(slot_type: ItemData.ItemType) -> ItemData: return forge_service.get_equipped_slot_item(slot_type)
func get_enchant_level(slot_type: ItemData.ItemType) -> int: return forge_service.get_enchant_level(slot_type)
func get_enchant_success_chance(current_lvl: int) -> float: return forge_service.get_enchant_success_chance(current_lvl)
func get_enchant_cost(current_lvl: int) -> float: return forge_service.get_enchant_cost(current_lvl)
func get_dark_enchant_level(slot_type: ItemData.ItemType) -> int: return forge_service.get_dark_enchant_level(slot_type)
func get_total_slot_enchant_level(slot_type: ItemData.ItemType) -> int: return forge_service.get_total_slot_enchant_level(slot_type)
func get_enchant_power_multiplier(enchant_lvl: int) -> float: return forge_service.get_enchant_power_multiplier(enchant_lvl)
func get_equipped_stat_bonuses(slot_type: ItemData.ItemType) -> Dictionary: return forge_service.get_equipped_stat_bonuses(slot_type)
func try_enchant_slot(slot_type: ItemData.ItemType) -> Dictionary: return forge_service.try_enchant_slot(slot_type)
func get_dark_forge_enchant_chance(current_lvl: int) -> float: return forge_service.get_dark_forge_enchant_chance(current_lvl)
func get_dark_forge_enchant_cost(current_lvl: int) -> int: return forge_service.get_dark_forge_enchant_cost(current_lvl)
func try_dark_forge_enchant(slot_type: ItemData.ItemType) -> Dictionary: return forge_service.try_dark_forge_enchant(slot_type)
func get_dark_forge_material_count(item_id: String) -> int: return forge_service.get_dark_forge_material_count(item_id)
func can_craft_dark_forge_recipe(recipe_id: String) -> bool: return forge_service.can_craft_dark_forge_recipe(recipe_id)
func craft_dark_forge_item(recipe_id: String) -> Dictionary: return forge_service.craft_dark_forge_item(recipe_id)

func get_entry_quality(entry: Dictionary) -> int: return inventory_service.get_entry_quality(entry)
func get_entry_stars(entry: Dictionary) -> int: return inventory_service.get_entry_stars(entry)
func set_auto_salvage_settings(mode: String, min_quality: int) -> void: inventory_service.set_auto_salvage_settings(mode, min_quality)
func add_item(item: ItemData, amount: int = 1, notify: bool = true, quality_pct: int = 100, star_level: int = 1, from_loot: bool = false) -> void: inventory_service.add_item(item, amount, notify, quality_pct, star_level, from_loot)
func remove_item(item: ItemData, amount: int = 1, quality_pct: int = -1, star_level: int = -1) -> bool: return inventory_service.remove_item(item, amount, quality_pct, star_level)
func get_item_count_in_inventory(item: ItemData) -> int: return inventory_service.get_item_count_in_inventory(item)
func get_merge_candidates() -> Array[Dictionary]: return inventory_service.get_merge_candidates()
func merge_duplicate_item(item_id: String, star_level: int) -> Dictionary: return inventory_service.merge_duplicate_item(item_id, star_level)
func sell_item(item: ItemData, amount: int = 1, quality_pct: int = -1, star_level: int = -1) -> String: return inventory_service.sell_item(item, amount, quality_pct, star_level)
func buy_item(item: ItemData) -> String: return inventory_service.buy_item(item)
func get_dark_shop_item_price(item: ItemData) -> int: return inventory_service.get_dark_shop_item_price(item)
func buy_dark_shop_item(item: ItemData) -> Dictionary: return inventory_service.buy_dark_shop_item(item)
func use_or_equip_item(item: ItemData, quality_pct: int = -1, star_level: int = -1) -> String: return inventory_service.use_or_equip_item(item, quality_pct, star_level)

func set_auto_hp_settings(enabled: bool, threshold_pct: int, condition: String) -> void: potion_service.set_auto_hp_settings(enabled, threshold_pct, condition)
func set_auto_mana_settings(enabled: bool, threshold_pct: int, condition: String) -> void: potion_service.set_auto_mana_settings(enabled, threshold_pct, condition)
func set_auto_buff_settings(enabled: bool, condition: String) -> void: potion_service.set_auto_buff_settings(enabled, condition)
func is_buff_potion_whitelisted(potion_id: String) -> bool: return potion_service.is_buff_potion_whitelisted(potion_id)
func toggle_buff_potion_whitelist(potion_id: String) -> void: potion_service.toggle_buff_potion_whitelist(potion_id)
func get_total_potion_count() -> int: return potion_service.get_total_potion_count()
func get_total_mana_potion_count() -> int: return potion_service.get_total_mana_potion_count()
func use_best_healing_potion() -> String: return potion_service.use_best_healing_potion()
func use_best_mana_potion() -> String: return potion_service.use_best_mana_potion()
func try_auto_use_all_potions(is_in_combat: bool) -> String: return potion_service.try_auto_use_all_potions(is_in_combat)

func is_using_ranged_weapon() -> bool: return loadout_service.is_using_ranged_weapon()
func is_using_mage_staff() -> bool: return loadout_service.is_using_mage_staff()
func is_using_ammo_weapon() -> bool: return loadout_service.is_using_ammo_weapon()
func has_matching_ammo() -> bool: return loadout_service.has_matching_ammo()
func consume_one_ammo() -> bool: return loadout_service.consume_one_ammo()
func _ensure_loadouts() -> void: loadout_service.ensure_loadouts()
func has_combat_loadout_saved(idx: int) -> bool: return loadout_service.has_combat_loadout_saved(idx)
func get_combat_loadout_summary(idx: int) -> String: return loadout_service.get_combat_loadout_summary(idx)
func save_combat_loadout(idx: int) -> Dictionary: return loadout_service.save_combat_loadout(idx)
func apply_combat_loadout(idx: int) -> Dictionary: return loadout_service.apply_combat_loadout(idx)
func unequip_slot(slot_type: ItemData.ItemType) -> void: loadout_service.unequip_slot(slot_type)

func is_classes_unlocked() -> bool: return skill_class_service.is_classes_unlocked()
func get_class_by_id(class_id: String) -> HeroClassData: return skill_class_service.get_class_by_id(class_id)
func get_current_class() -> HeroClassData: return skill_class_service.get_current_class()
func has_hero_class(class_id: String) -> bool: return skill_class_service.has_hero_class(class_id)
func is_equipment_disabled() -> bool: return skill_class_service.is_equipment_disabled()
func select_hero_class(class_id: String) -> bool: return skill_class_service.select_hero_class(class_id)
func get_dark_skill_by_id(skill_id: String) -> DarkSkillNodeData: return skill_class_service.get_dark_skill_by_id(skill_id)
func has_dark_skill(skill_id: String) -> bool: return skill_class_service.has_dark_skill(skill_id)
func are_dark_prerequisites_met(skill_id: String) -> bool: return skill_class_service.are_dark_prerequisites_met(skill_id)
func can_unlock_dark_skill(skill_id: String) -> bool: return skill_class_service.can_unlock_dark_skill(skill_id)
func unlock_dark_skill(skill_id: String) -> bool: return skill_class_service.unlock_dark_skill(skill_id)
func get_dark_bonus(effect_type: String) -> float: return skill_class_service.get_dark_bonus(effect_type)
func get_skill_by_id(skill_id: String) -> SkillNodeData: return skill_class_service.get_skill_by_id(skill_id)
func is_skill_unlocked(skill_id: String) -> bool: return skill_class_service.is_skill_unlocked(skill_id)
func are_prerequisites_met(skill_id: String) -> bool: return skill_class_service.are_prerequisites_met(skill_id)
func can_unlock_skill(skill_id: String) -> bool: return skill_class_service.can_unlock_skill(skill_id)
func unlock_skill(skill_id: String) -> bool: return skill_class_service.unlock_skill(skill_id)
func get_skill_bonus(bonus_type: String) -> float: return skill_class_service.get_skill_bonus(bonus_type)
func ensure_skill_presets() -> void: skill_class_service.ensure_skill_presets()
func get_skill_preset_name(index: int) -> String: return skill_class_service.get_skill_preset_name(index)
func get_active_skill_preset_order() -> Array[String]: return skill_class_service.get_active_skill_preset_order()
func get_skill_preset_position(skill_id: String) -> int: return skill_class_service.get_skill_preset_position(skill_id)
func set_active_skill_preset(index: int) -> void: skill_class_service.set_active_skill_preset(index)
func set_skill_auto_upgrade_enabled(enabled: bool) -> void: skill_class_service.set_skill_auto_upgrade_enabled(enabled)
func toggle_skill_in_active_preset(skill_id: String) -> bool: return skill_class_service.toggle_skill_in_active_preset(skill_id)
func clear_active_skill_preset() -> void: skill_class_service.clear_active_skill_preset()
func try_apply_skill_preset(should_save: bool = true) -> int: return skill_class_service.try_apply_skill_preset(should_save)

func get_pet_by_id(pet_id: String) -> PetData: return pet_mastery_service.get_pet_by_id(pet_id)
func get_equipped_pet() -> PetData: return pet_mastery_service.get_equipped_pet()
func has_pet_owned(pet_id: String) -> bool: return pet_mastery_service.has_pet_owned(pet_id)
func get_pet_training_level(pet_id: String) -> int: return pet_mastery_service.get_pet_training_level(pet_id)
func get_pet_training_multiplier(pet_id: String) -> float: return pet_mastery_service.get_pet_training_multiplier(pet_id)
func get_pet_effect_value(effect_type: String) -> float: return pet_mastery_service.get_pet_effect_value(effect_type)
func get_pet_secondary_value(effect_type: String) -> float: return pet_mastery_service.get_pet_secondary_value(effect_type)
func get_pet_buy_price(pet: PetData) -> float: return pet_mastery_service.get_pet_buy_price(pet)
func buy_pet(pet_id: String) -> Dictionary: return pet_mastery_service.buy_pet(pet_id)
func get_pet_treat_success_chance(pet_id: String, treat_item: ItemData) -> float: return pet_mastery_service.get_pet_treat_success_chance(pet_id, treat_item)
func train_pet_with_treat(pet_id: String, treat_item: ItemData) -> Dictionary: return pet_mastery_service.train_pet_with_treat(pet_id, treat_item)
func equip_pet(pet_id: String) -> bool: return pet_mastery_service.equip_pet(pet_id)
func unequip_pet() -> void: pet_mastery_service.unequip_pet()
func is_pet_on_expedition(pet_id: String) -> bool: return pet_mastery_service.is_pet_on_expedition(pet_id)
func get_pet_expedition(pet_id: String) -> Dictionary: return pet_mastery_service.get_pet_expedition(pet_id)
func start_pet_expedition(pet_id: String, plan_id: String) -> Dictionary: return pet_mastery_service.start_pet_expedition(pet_id, plan_id)
func claim_pet_expedition(pet_id: String) -> Dictionary: return pet_mastery_service.claim_pet_expedition(pet_id)
func get_mastery_level(skill_id: String) -> int: return pet_mastery_service.get_mastery_level(skill_id)
func get_mastery_xp(skill_id: String) -> float: return pet_mastery_service.get_mastery_xp(skill_id)
func get_mastery_xp_required(skill_id: String, lvl: int) -> float: return pet_mastery_service.get_mastery_xp_required(skill_id, lvl)
func get_mastery_bonus_multiplier(skill_id: String) -> float: return pet_mastery_service.get_mastery_bonus_multiplier(skill_id)
func add_mastery_xp(skill_id: String, base_amount: float) -> void: pet_mastery_service.add_mastery_xp(skill_id, base_amount)
func get_dark_mastery_level(mastery_id: String) -> int: return pet_mastery_service.get_dark_mastery_level(mastery_id)
func get_dark_mastery_xp(mastery_id: String) -> float: return pet_mastery_service.get_dark_mastery_xp(mastery_id)
func get_dark_mastery_xp_required(lvl: int) -> float: return pet_mastery_service.get_dark_mastery_xp_required(lvl)
func get_dark_mastery_bonus(mastery_id: String) -> float: return pet_mastery_service.get_dark_mastery_bonus(mastery_id)
func set_active_dark_mastery(mastery_id: String) -> void: pet_mastery_service.set_active_dark_mastery(mastery_id)
func add_dark_mastery_xp(mastery_id: String, base_amount: float) -> void: pet_mastery_service.add_dark_mastery_xp(mastery_id, base_amount)

func get_ability_by_id(ability_id: String) -> AbilityData: return ability_buff_service.get_ability_by_id(ability_id)
func is_ability_unlocked(ability: AbilityData) -> bool: return ability_buff_service.is_ability_unlocked(ability)
func get_equipped_slot_for_ability(ability_id: String) -> int: return ability_buff_service.get_equipped_slot_for_ability(ability_id)
func _sync_equipped_abilities() -> void: ability_buff_service.sync_equipped_abilities()
func _validate_equipped_abilities_for_class() -> void: ability_buff_service.validate_equipped_abilities_for_class()
func equip_ability_to_slot(ability_id: String, slot_index: int) -> bool: return ability_buff_service.equip_ability_to_slot(ability_id, slot_index)
func clear_ability_slot(slot_index: int) -> void: ability_buff_service.clear_ability_slot(slot_index)
func get_ability_casts(ability_id: String) -> int: return ability_buff_service.get_ability_casts(ability_id)
func get_ability_level(ability_id: String) -> int: return ability_buff_service.get_ability_level(ability_id)
func get_next_spell_level_casts(ability_id: String) -> int: return ability_buff_service.get_next_spell_level_casts(ability_id)
func get_ability_upgrade_page_cost(ability_id: String) -> int: return ability_buff_service.get_ability_upgrade_page_cost(ability_id)
func upgrade_ability_with_page(ability_id: String) -> Dictionary: return ability_buff_service.upgrade_ability_with_page(ability_id)
func record_ability_cast(ability_id: String) -> void: ability_buff_service.record_ability_cast(ability_id)
func get_ability_rune(ability_id: String) -> String: return ability_buff_service.get_ability_rune(ability_id)
func get_ability_rune_data(ability_id: String) -> Dictionary: return ability_buff_service.get_ability_rune_data(ability_id)
func set_ability_rune(ability_id: String, rune_key: String) -> void: ability_buff_service.set_ability_rune(ability_id, rune_key)
func apply_ability_buff(ability: AbilityData, potency_scale: float = 1.0) -> void: ability_buff_service.apply_ability_buff(ability, potency_scale)
func has_active_buff(buff_id: String) -> bool: return ability_buff_service.has_active_buff(buff_id)
func get_active_buff_remaining(buff_id: String) -> float: return ability_buff_service.get_active_buff_remaining(buff_id)
func get_active_buff_sum(stat_key: String) -> float: return ability_buff_service.get_active_buff_sum(stat_key)
func clear_active_buffs() -> void: ability_buff_service.clear_active_buffs()
func get_ability(slot_index: int) -> AbilityData: return ability_buff_service.get_ability(slot_index)
func get_ability_mana_cost(ability: AbilityData) -> float: return ability_buff_service.get_ability_mana_cost(ability)
func get_ability_cooldown_duration(ability: AbilityData) -> float: return ability_buff_service.get_ability_cooldown_duration(ability)
func get_ability_power_multiplier(ability: AbilityData) -> float: return ability_buff_service.get_ability_power_multiplier(ability)
func get_ability_cooldown(slot_index: int) -> float: return ability_buff_service.get_ability_cooldown(slot_index)
func is_ability_auto_cast(slot_index: int) -> bool: return ability_buff_service.is_ability_auto_cast(slot_index)
func toggle_ability_auto_cast(slot_index: int) -> void: ability_buff_service.toggle_ability_auto_cast(slot_index)
func start_ability_cooldown(slot_index: int, duration: float) -> void: ability_buff_service.start_ability_cooldown(slot_index, duration)
func reduce_all_ability_cooldowns(seconds: float) -> void: ability_buff_service.reduce_all_ability_cooldowns(seconds)

func is_alchemy_unlocked() -> bool: return sanctuary_service.is_alchemy_unlocked()
func get_crop_by_id(crop_id: String) -> CropData: return sanctuary_service.get_crop_by_id(crop_id)
func get_garden_plot_count() -> int: return sanctuary_service.get_garden_plot_count()
func get_light_garden_plot_count() -> int: return sanctuary_service.get_light_garden_plot_count()
func is_garden_plot_accessible(plot_index: int) -> bool: return sanctuary_service.is_garden_plot_accessible(plot_index)
func get_brewing_slot_count() -> int: return sanctuary_service.get_brewing_slot_count()
func is_brewing_slot_accessible(slot_index: int) -> bool: return sanctuary_service.is_brewing_slot_accessible(slot_index)
func _ensure_sanctuary_slots() -> void: sanctuary_service.ensure_sanctuary_slots()
func get_garden_growth_speed_mult() -> float: return sanctuary_service.get_garden_growth_speed_mult()
func get_seed_drop_multiplier() -> float: return sanctuary_service.get_seed_drop_multiplier()
func _process_sanctuary(delta: float) -> void: sanctuary_service.process_sanctuary(delta)
func roll_rare_seed_drops(enemy: EnemyData) -> void: sanctuary_service.roll_rare_seed_drops(enemy)
func on_final_boss_killed_for_garden() -> void: sanctuary_service.on_final_boss_killed_for_garden()
func plant_seed_on_plot(plot_index: int, seed_item: ItemData) -> Dictionary: return sanctuary_service.plant_seed_on_plot(plot_index, seed_item)
func plant_seed_in_first_empty_plot(seed_item: ItemData) -> Dictionary: return sanctuary_service.plant_seed_in_first_empty_plot(seed_item)
func harvest_garden_plot(plot_index: int) -> Dictionary: return sanctuary_service.harvest_garden_plot(plot_index)
func can_instant_grow_plot(plot_index: int) -> bool: return sanctuary_service.can_instant_grow_plot(plot_index)
func feed_growing_crop_for_instant_growth(plot_index: int) -> Dictionary: return sanctuary_service.feed_growing_crop_for_instant_growth(plot_index)

func plant_light_seed_on_plot(plot_index: int, seed_item: ItemData) -> Dictionary: return brewing_service.plant_light_seed_on_plot(plot_index, seed_item)
func plant_light_seed_in_first_empty_plot(seed_item: ItemData) -> Dictionary: return brewing_service.plant_light_seed_in_first_empty_plot(seed_item)
func harvest_light_garden_plot(plot_index: int) -> Dictionary: return brewing_service.harvest_light_garden_plot(plot_index)
func can_lure_pet_from_light_garden() -> bool: return brewing_service.can_lure_pet_from_light_garden()
func lure_pet_from_light_garden() -> Dictionary: return brewing_service.lure_pet_from_light_garden()
func get_spirit_training_level(spirit_key: String) -> int: return brewing_service.get_spirit_training_level(spirit_key)
func get_spirit_power_multiplier(spirit_key: String) -> float: return brewing_service.get_spirit_power_multiplier(spirit_key)
func get_spirit_speed_multiplier(spirit_key: String) -> float: return brewing_service.get_spirit_speed_multiplier(spirit_key)
func train_spirit(spirit_key: String) -> Dictionary: return brewing_service.train_spirit(spirit_key)
func get_brewing_speed_mult() -> float: return brewing_service.get_brewing_speed_mult()
func start_brewing_water(slot_index: int) -> Dictionary: return brewing_service.start_brewing_water(slot_index)
func add_brewing_ingredient(slot_index: int, ingredient_item: ItemData) -> Dictionary: return brewing_service.add_brewing_ingredient(slot_index, ingredient_item)
func collect_brewed_potion(slot_index: int) -> Dictionary: return brewing_service.collect_brewed_potion(slot_index)
func clear_brewing_slot(slot_index: int) -> void: brewing_service.clear_brewing_slot(slot_index)

func set_afk_mode(enabled: bool) -> void: world_mine_service.set_afk_mode(enabled)
func record_afk_rewards(xp_earned: float, gold_earned: float) -> void: world_mine_service.record_afk_rewards(xp_earned, gold_earned)
func get_location_by_id(location_id: String) -> LocationData: return world_mine_service.get_location_by_id(location_id)
func is_training_grounds_location(loc: LocationData = null) -> bool: return world_mine_service.is_training_grounds_location(loc)
func is_mine_location(loc: LocationData = null) -> bool: return world_mine_service.is_mine_location(loc)
func is_location_unlocked(location: LocationData) -> bool: return world_mine_service.is_location_unlocked(location)
func select_location(location: LocationData) -> bool: return world_mine_service.select_location(location)
func set_parallel_battle_count(cnt: int) -> void: world_mine_service.set_parallel_battle_count(cnt)
func cycle_parallel_battle_count() -> int: return world_mine_service.cycle_parallel_battle_count()
func get_effective_parallel_battle_count(enemy: EnemyData = null) -> int: return world_mine_service.get_effective_parallel_battle_count(enemy)
func is_mine_checkpoint_unlocked(depth: int) -> bool: return world_mine_service.is_mine_checkpoint_unlocked(depth)
func get_mine_checkpoint_cost(depth: int) -> int: return world_mine_service.get_mine_checkpoint_cost(depth)
func buy_mine_checkpoint(depth: int) -> Dictionary: return world_mine_service.buy_mine_checkpoint(depth)
func set_mine_start_depth(depth: int) -> void: world_mine_service.set_mine_start_depth(depth)
func set_auto_route_settings(enabled: bool, threshold: int) -> void: world_mine_service.set_auto_route_settings(enabled, threshold)
func record_location_win_for_auto_route() -> String: return world_mine_service.record_location_win_for_auto_route()
func retreat_to_safer_location() -> String: return world_mine_service.retreat_to_safer_location()
func record_bestiary_kill(enemy_id: String) -> void: world_mine_service.record_bestiary_kill(enemy_id)
func get_bestiary_kills(enemy_id: String) -> int: return world_mine_service.get_bestiary_kills(enemy_id)
func get_bestiary_damage_bonus(enemy_id: String) -> float: return world_mine_service.get_bestiary_damage_bonus(enemy_id)
func get_bestiary_gold_bonus(enemy_id: String) -> float: return world_mine_service.get_bestiary_gold_bonus(enemy_id)
func get_bestiary_drop_bonus(enemy_id: String) -> float: return world_mine_service.get_bestiary_drop_bonus(enemy_id)
func record_mine_kill() -> void: world_mine_service.record_mine_kill()
func fail_mine_run() -> void: world_mine_service.fail_mine_run()
func roll_mine_ambient_find() -> String: return world_mine_service.roll_mine_ambient_find()

func can_sacrifice_to_well() -> Dictionary: return wave_well_service.can_sacrifice_to_well()
func get_well_blessing_label() -> String: return wave_well_service.get_well_blessing_label()
func sacrifice_all_gold_to_well() -> Dictionary: return wave_well_service.sacrifice_all_gold_to_well()
func start_wave_dungeon() -> Dictionary: return wave_well_service.start_wave_dungeon()
func abort_wave_dungeon() -> void: wave_well_service.abort_wave_dungeon()
func get_wave_dungeon_enemy_for_wave(wave_idx: int) -> EnemyData: return wave_well_service.get_wave_dungeon_enemy_for_wave(wave_idx)
func advance_wave_dungeon_on_kill() -> Dictionary: return wave_well_service.advance_wave_dungeon_on_kill()

func _wait_for_save_thread() -> void: save_service.wait_for_save_thread()
func save_game(force_immediate: bool = false) -> void: save_service.save_game(force_immediate)
func load_game() -> bool: return save_service.load_game()
func export_save_to_text() -> String: return save_service.export_save_to_text()
func export_save_to_txt_file(file_path: String) -> Dictionary: return save_service.export_save_to_txt_file(file_path)
func import_save_from_text(raw_text: String) -> Dictionary: return save_service.import_save_from_text(raw_text)
func import_save_from_txt_file(file_path: String) -> Dictionary: return save_service.import_save_from_txt_file(file_path)
