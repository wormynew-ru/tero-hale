class_name SaveDictCodec
extends RefCounted


static func save_data_to_dict(save_data: SaveData) -> Dictionary:
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
		"auto_advance_next_boss": save_data.auto_advance_next_boss,
		"parallel_battle_count": save_data.parallel_battle_count,
		"active_dark_mastery_id": save_data.active_dark_mastery_id,
		"dark_mastery_levels": save_data.dark_mastery_levels.duplicate(true),
		"dark_mastery_xp": save_data.dark_mastery_xp.duplicate(true),
	}


static func dict_to_save_data(data: Dictionary, default_afk_fps: int = 20) -> SaveData:
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

	save_data.afk_target_fps = int(data.get("afk_target_fps", default_afk_fps))
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
	save_data.auto_advance_next_boss = bool(data.get("auto_advance_next_boss", false))
	save_data.parallel_battle_count = int(data.get("parallel_battle_count", 1))
	save_data.active_dark_mastery_id = str(data.get("active_dark_mastery_id", "dark_melee"))
	if data.get("dark_mastery_levels") is Dictionary:
		for dmk: String in WorldAndAbilityCatalog.DARK_MASTERY_KEYS:
			save_data.dark_mastery_levels[dmk] = maxi(0, int((data["dark_mastery_levels"] as Dictionary).get(dmk, 0)))
	if data.get("dark_mastery_xp") is Dictionary:
		for dmk: String in WorldAndAbilityCatalog.DARK_MASTERY_KEYS:
			save_data.dark_mastery_xp[dmk] = maxf(0.0, float((data["dark_mastery_xp"] as Dictionary).get(dmk, 0.0)))
	return save_data
