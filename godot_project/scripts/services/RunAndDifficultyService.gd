class_name RunAndDifficultyService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func invalidate_progression_caches() -> void:
	_gm._progression_caches_dirty = true
	_gm.mark_stats_dirty()


func ensure_progression_caches() -> void:
	if not _gm._progression_caches_dirty and _gm._cached_curse_difficulty == _gm.difficulty_level:
		return
	_gm._progression_caches_dirty = false
	_gm._cached_curse_difficulty = _gm.difficulty_level

	_gm._unlocked_skill_set.clear()
	_gm._skill_bonus_cache.clear()
	for skill_id: String in _gm.unlocked_skills:
		_gm._unlocked_skill_set[skill_id] = true
		var skill: SkillNodeData = _gm.get_skill_by_id(skill_id)
		if skill != null and not skill.bonus_type.is_empty():
			_gm._skill_bonus_cache[skill.bonus_type] = float(_gm._skill_bonus_cache.get(skill.bonus_type, 0.0)) + skill.bonus_value

	_gm._unlocked_dark_skill_set.clear()
	_gm._dark_bonus_cache.clear()
	for dskill_id: String in _gm.unlocked_dark_skills:
		_gm._unlocked_dark_skill_set[dskill_id] = true
		var dskill: DarkSkillNodeData = _gm.get_dark_skill_by_id(dskill_id)
		if dskill != null and not dskill.effect_type.is_empty():
			_gm._dark_bonus_cache[dskill.effect_type] = float(_gm._dark_bonus_cache.get(dskill.effect_type, 0.0)) + dskill.effect_value

	_gm._curse_value_cache.clear()
	_gm._active_curses_cache.clear()
	var max_tier: int = floori(float(_gm.difficulty_level) / 10.0) * 10
	if max_tier >= 10:
		_gm.ensure_curses_for_difficulty(_gm.difficulty_level)
		var atten: float = 0.6 if _gm._unlocked_dark_skill_set.has("curse_ward") else 1.0
		for tier: int in range(10, max_tier + 1, 10):
			var cid: String = str(_gm.difficulty_curses.get(tier, ""))
			var def: Dictionary = _gm.difficulty_service.get_curse_definition(cid)
			if def.is_empty():
				continue
			var eff_val: float = float(def["base_value"]) * atten
			_gm._active_curses_cache.append({
				"tier": tier,
				"id": cid,
				"title": str(def["title"]),
				"value": eff_val,
				"description": _gm.format_curse_description(def, eff_val),
			})
			_gm._curse_value_cache[cid] = float(_gm._curse_value_cache.get(cid, 0.0)) + eff_val


func init_full_reset_state() -> void:
	_gm.difficulty_level = 1
	_gm.max_unlocked_difficulty = 1
	_gm.afk_target_fps = _gm.DEFAULT_AFK_MAX_FPS
	_gm.dark_points = 0
	_gm.dark_shop_coins = 0
	_gm.dark_points_claimed_difficulties.clear()
	_gm.unlocked_dark_skills.clear()
	_gm.difficulty_curses.clear()
	_gm.total_runs_completed = 0
	_gm.curse_reroll_tokens = 0
	_gm.selected_class_id = "wanderer"
	_gm.reflector_kill_hp_stacks = 0
	_gm.owned_pet_ids.clear()
	_gm.equipped_pet_id = ""
	_gm.pet_expeditions.clear()
	_gm.auto_potion_enabled = false
	_gm.auto_hp_threshold_pct = 35
	_gm.auto_hp_condition = "combat"
	_gm.auto_mana_enabled = false
	_gm.auto_mana_threshold_pct = 30
	_gm.auto_mana_condition = "combat"
	_gm.auto_buff_enabled = false
	_gm.auto_buff_condition = "on_expire_combat"
	_gm.auto_buff_whitelist.clear()
	_gm.auto_salvage_mode = "off"
	_gm.auto_salvage_min_quality = 95
	_gm.abyss_ore_shards = 0
	_gm.dark_weapon_enchant_level = 0
	_gm.dark_armor_enchant_level = 0
	_gm.dark_offhand_enchant_level = 0
	_gm.mine_locked_this_run = false
	_gm.mine_depth = 0
	_gm.unlocked_mine_checkpoints.clear()
	_gm.mine_start_depth = 1
	_gm.equipped_weapon = null
	_gm.equipped_weapon_quality = 100
	_gm.equipped_weapon_stars = 1
	_gm.equipped_armor = null
	_gm.equipped_armor_quality = 100
	_gm.equipped_armor_stars = 1
	_gm.equipped_offhand = null
	_gm.equipped_offhand_quality = 100
	_gm.equipped_offhand_stars = 1
	_gm.equipped_ammo = null
	_gm.equipped_ammo_count = 0
	_gm.inventory.clear()
	_gm.enemies_defeated = 0
	_gm.bestiary_kills.clear()
	_gm.active_challenge_id = ""
	_gm.completed_challenges.clear()
	_gm.run_elapsed_seconds = 0.0
	_gm.combat_loadouts.clear()
	_gm.auto_route_enabled = false
	_gm.auto_route_wins_threshold = 5
	_gm.consecutive_location_wins = 0
	_gm.well_greed_cooldown_remaining = 0.0
	_gm.well_run_blessing = ""
	_gm.wave_dungeon_active = false
	_gm.wave_dungeon_wave = 0
	_gm.wave_dungeon_clears = 0
	_gm._wave_dungeon_return_location_id = ""
	_gm.garden_plots.clear()
	_gm.light_garden_plots.clear()
	_gm.brewing_slots.clear()
	_gm.alchemist_next_mistake_safe = false
	_gm.pet_training_levels.clear()
	_gm.spirit_training_levels = {"fire": 0, "wind": 0, "forest": 0, "earth": 0}
	_gm.auto_advance_next_boss = false
	_gm.parallel_battle_count = 1
	_gm.active_dark_mastery_id = "dark_melee"
	for dmk: String in _gm.DARK_MASTERY_KEYS:
		_gm.dark_mastery_levels[dmk] = 0
		_gm.dark_mastery_xp[dmk] = 0.0
	_gm.equipped_ability_ids = _gm.DEFAULT_EQUIPPED_ABILITIES.duplicate()
	_gm.ability_casts.clear()
	_gm.ability_levels.clear()
	_gm.ability_runes.clear()
	_gm._sync_equipped_abilities()
	for i: int in range(_gm.MAX_ACTIVE_ABILITY_SLOTS):
		_gm.ability_auto_cast[i] = false
	_gm.skill_presets.clear()
	_gm.active_skill_preset_index = 0
	_gm.skill_auto_upgrade_enabled = false
	_gm.ensure_skill_presets()
	_gm._ensure_loadouts()
	invalidate_progression_caches()
	init_run_state(1, "")
	_gm._ensure_sanctuary_slots()


func init_run_state(target_difficulty: int, challenge_id: String = "") -> void:
	_gm.difficulty_level = clampi(target_difficulty, 1, maxi(1, _gm.max_unlocked_difficulty))
	_gm.ensure_curses_for_difficulty(_gm.difficulty_level)
	_gm.active_challenge_id = challenge_id if not _gm.get_challenge_def(challenge_id).is_empty() else ""
	_gm.run_elapsed_seconds = 0.0
	_gm.consecutive_location_wins = 0
	_gm.well_greed_cooldown_remaining = 0.0
	_gm.well_run_blessing = ""
	_gm.wave_dungeon_active = false
	_gm.wave_dungeon_wave = 0
	_gm._wave_dungeon_return_location_id = ""
	invalidate_progression_caches()

	_gm.level = 1
	_gm.current_xp = 0.0
	_gm.skill_points = 1
	_gm.boss_defeated_this_run = false
	_gm.reroll_boss_kills_in_run = 0
	_gm.kills_in_run = 0
	_gm.mine_locked_this_run = false
	_gm.mine_depth = 0

	var start_mastery_lvl: int = 3 if _gm.has_dark_skill("ancient_memory") else 1
	_gm.melee_level = start_mastery_lvl
	_gm.melee_xp = 0.0
	_gm.ranged_level = start_mastery_lvl
	_gm.ranged_xp = 0.0
	_gm.magic_level = start_mastery_lvl
	_gm.magic_xp = 0.0

	var base_start: int = 5
	if _gm.has_dark_skill("abyss_awakening"):
		base_start += 1
	if _gm.has_dark_skill("titan_heritage"):
		base_start += 5

	_gm.base_strength = base_start
	_gm.base_agility = base_start
	_gm.base_endurance = base_start
	_gm.base_intellect = base_start

	var start_gold: float = 20.0
	if _gm.has_dark_skill("titan_heritage"):
		start_gold += 1000.0 * _gm.get_difficulty_gold_mult()
	_gm.gold = start_gold

	var preserved_garden_items: Array[Dictionary] = []
	for entry: Dictionary in _gm.inventory:
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

	var gear_blocked: bool = _gm.is_gear_blocked_by_challenge() or _gm.is_equipment_disabled()
	var preserved_weapon: ItemData = _gm.equipped_weapon if (_gm.equipped_weapon != null and _gm.equipped_weapon.is_dark_forged) else null
	var preserved_weapon_q: int = _gm.equipped_weapon_quality
	var preserved_weapon_s: int = _gm.equipped_weapon_stars
	var preserved_armor: ItemData = _gm.equipped_armor if (_gm.equipped_armor != null and _gm.equipped_armor.is_dark_forged) else null
	var preserved_armor_q: int = _gm.equipped_armor_quality
	var preserved_armor_s: int = _gm.equipped_armor_stars
	var preserved_offhand: ItemData = _gm.equipped_offhand if (_gm.equipped_offhand != null and _gm.equipped_offhand.is_dark_forged) else null
	var preserved_offhand_q: int = _gm.equipped_offhand_quality
	var preserved_offhand_s: int = _gm.equipped_offhand_stars
	var preserved_ammo: ItemData = _gm.equipped_ammo if (_gm.equipped_ammo != null and _gm.equipped_ammo.is_dark_forged) else null
	var preserved_ammo_cnt: int = _gm.equipped_ammo_count if preserved_ammo != null else 0

	_gm.equipped_weapon = null
	_gm.equipped_weapon_quality = 100
	_gm.equipped_weapon_stars = 1
	_gm.equipped_armor = null
	_gm.equipped_armor_quality = 100
	_gm.equipped_armor_stars = 1
	_gm.equipped_offhand = null
	_gm.equipped_offhand_quality = 100
	_gm.equipped_offhand_stars = 1
	_gm.equipped_ammo = null
	_gm.equipped_ammo_count = 0

	if not gear_blocked:
		if preserved_weapon != null:
			if _gm.is_non_staff_blocked_by_challenge() and not preserved_weapon.is_mage_staff():
				preserved_garden_items.append({"item": preserved_weapon, "count": 1, "quality_pct": preserved_weapon_q, "star_level": preserved_weapon_s})
			else:
				_gm.equipped_weapon = preserved_weapon
				_gm.equipped_weapon_quality = preserved_weapon_q
				_gm.equipped_weapon_stars = preserved_weapon_s
		if preserved_armor != null:
			_gm.equipped_armor = preserved_armor
			_gm.equipped_armor_quality = preserved_armor_q
			_gm.equipped_armor_stars = preserved_armor_s
		if preserved_offhand != null:
			if _gm.is_non_staff_blocked_by_challenge() and preserved_offhand.offhand_kind != ItemData.OffhandKind.TALISMAN:
				preserved_garden_items.append({"item": preserved_offhand, "count": 1, "quality_pct": preserved_offhand_q, "star_level": preserved_offhand_s})
			else:
				_gm.equipped_offhand = preserved_offhand
				_gm.equipped_offhand_quality = preserved_offhand_q
				_gm.equipped_offhand_stars = preserved_offhand_s
		if preserved_ammo != null:
			if _gm.is_non_staff_blocked_by_challenge() and preserved_ammo.ammo_kind != ItemData.AmmoKind.TOME:
				preserved_garden_items.append({"item": preserved_ammo, "count": maxi(1, preserved_ammo_cnt), "quality_pct": 100, "star_level": 1})
			else:
				_gm.equipped_ammo = preserved_ammo
				_gm.equipped_ammo_count = maxi(1, preserved_ammo_cnt)
	else:
		if preserved_weapon != null:
			preserved_garden_items.append({"item": preserved_weapon, "count": 1, "quality_pct": preserved_weapon_q, "star_level": preserved_weapon_s})
		if preserved_armor != null:
			preserved_garden_items.append({"item": preserved_armor, "count": 1, "quality_pct": preserved_armor_q, "star_level": preserved_armor_s})
		if preserved_offhand != null:
			preserved_garden_items.append({"item": preserved_offhand, "count": 1, "quality_pct": preserved_offhand_q, "star_level": preserved_offhand_s})
		if preserved_ammo != null:
			preserved_garden_items.append({"item": preserved_ammo, "count": maxi(1, preserved_ammo_cnt), "quality_pct": 100, "star_level": 1})

	_gm.weapon_enchant_level = 0
	_gm.armor_enchant_level = 0
	_gm.offhand_enchant_level = 0
	_gm.inventory.clear()
	_gm.unlocked_skills.clear()
	invalidate_progression_caches()
	_gm.active_buffs.clear()
	_gm._validate_equipped_abilities_for_class()
	for i: int in range(_gm.MAX_ACTIVE_ABILITY_SLOTS):
		_gm.ability_cooldowns[i] = 0.0

	var starter_potion: ItemData = _gm.get_cached_item(_gm.STARTER_POTION_PATH)
	if starter_potion != null:
		_gm.add_item(starter_potion, 2, false)

	for saved_garden: Dictionary in preserved_garden_items:
		var g_item: ItemData = saved_garden["item"] as ItemData
		var g_cnt: int = int(saved_garden["count"])
		var g_q: int = int(saved_garden.get("quality_pct", 100))
		var g_s: int = int(saved_garden.get("star_level", 1))
		_gm.add_item(g_item, g_cnt, false, g_q, g_s, false)

	_gm._ensure_sanctuary_slots()
	_gm.ensure_skill_presets()
	_gm._ensure_loadouts()
	if _gm.skill_auto_upgrade_enabled:
		_gm.try_apply_skill_preset(false)

	_gm.mark_stats_dirty()
	_gm.current_barrier = _gm.get_max_barrier()
	_gm.current_hp = _gm.get_max_hp()
	_gm.current_mana = _gm.get_max_mana()
	if not _gm.locations.is_empty():
		_gm.current_location = _gm.locations[0]


func start_new_run(target_difficulty: int, challenge_id: String = "") -> void:
	_gm._wait_for_save_thread()
	var clamped_diff: int = clampi(target_difficulty, 1, maxi(1, _gm.max_unlocked_difficulty))
	if _gm.boss_defeated_this_run:
		_gm.total_runs_completed += 1
	init_run_state(clamped_diff, challenge_id)
	_gm.save_game(true)
	_gm._emit_all_refresh_signals()
	_gm.game_reset.emit()


func reset_progress() -> void:
	_gm._wait_for_save_thread()
	for path: String in [_gm.SAVE_PATH, _gm.SAVE_BACKUP_PATH, _gm.SAVE_TEMP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_gm.set_afk_mode(false)
	init_full_reset_state()
	_gm.save_game(true)
	_gm._emit_all_refresh_signals()
	_gm.game_reset.emit()


func roll_difficulty_reset_item_drop() -> void:
	if randf() <= _gm.DIFFICULTY_RESET_DROP_CHANCE:
		var orb: ItemData = _gm.get_cached_item(_gm.DIFFICULTY_RESET_ITEM_PATH)
		if orb != null:
			_gm.add_item(orb, 1, true, 100, 1, false)


func reset_claimed_difficulties_rewards() -> Dictionary:
	var cleared_cnt: int = _gm.dark_points_claimed_difficulties.size()
	if cleared_cnt == 0:
		return {"success": false, "message": "Награды 🌑 за сложности ещё не получены."}
	_gm.dark_points_claimed_difficulties.clear()
	_gm.difficulty_changed.emit()
	_gm.dark_skills_changed.emit()
	_gm.stats_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"message": "⏳ Сброшено %d пройденных сложностей! Макс. Сл.%d сохранена — за каждую сложность можно снова получить +2 🌑!" % [cleared_cnt, _gm.max_unlocked_difficulty],
	}


func set_auto_advance_next_boss(enabled: bool) -> void:
	if _gm.auto_advance_next_boss == enabled:
		return
	_gm.auto_advance_next_boss = enabled
	_gm.difficulty_changed.emit()
	_gm.stats_changed.emit()
	_gm.save_game()
