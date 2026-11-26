class_name SaveSerializer
extends RefCounted


static func build_save_data(gm: Node) -> SaveData:
	var save_data: SaveData = SaveData.new()
	save_data.save_version = gm.SAVE_SCHEMA_VERSION
	save_data.level = gm.level
	save_data.current_xp = gm.current_xp
	save_data.gold = gm.gold
	save_data.skill_points = gm.skill_points
	save_data.enemies_defeated = gm.enemies_defeated
	save_data.kills_in_run = gm.kills_in_run
	save_data.base_strength = gm.base_strength
	save_data.base_agility = gm.base_agility
	save_data.base_endurance = gm.base_endurance
	save_data.base_intellect = gm.base_intellect
	save_data.current_hp = gm.current_hp
	save_data.current_mana = gm.current_mana
	save_data.melee_level = gm.melee_level
	save_data.melee_xp = gm.melee_xp
	save_data.ranged_level = gm.ranged_level
	save_data.ranged_xp = gm.ranged_xp
	save_data.magic_level = gm.magic_level
	save_data.magic_xp = gm.magic_xp
	save_data.current_location_id = gm.current_location.id if gm.current_location != null else "quiet_glade"
	save_data.equipped_weapon_path = gm.equipped_weapon.resource_path if gm.equipped_weapon != null else ""
	save_data.equipped_armor_path = gm.equipped_armor.resource_path if gm.equipped_armor != null else ""
	save_data.equipped_ammo_path = gm.equipped_ammo.resource_path if gm.equipped_ammo != null else ""
	save_data.equipped_ammo_count = gm.equipped_ammo_count
	save_data.weapon_enchant_level = gm.weapon_enchant_level
	save_data.armor_enchant_level = gm.armor_enchant_level
	save_data.unlocked_skills = gm.unlocked_skills.duplicate()
	save_data.skill_presets = gm.skill_presets.duplicate(true)
	save_data.active_skill_preset_index = gm.active_skill_preset_index
	save_data.skill_auto_upgrade_enabled = gm.skill_auto_upgrade_enabled
	save_data.equipped_ability_ids = gm.equipped_ability_ids.duplicate()
	save_data.ability_auto_cast = gm.ability_auto_cast.duplicate()
	save_data.auto_potion_enabled = gm.auto_potion_enabled
	save_data.auto_hp_threshold_pct = gm.auto_hp_threshold_pct
	save_data.auto_hp_condition = gm.auto_hp_condition
	save_data.auto_mana_enabled = gm.auto_mana_enabled
	save_data.auto_mana_threshold_pct = gm.auto_mana_threshold_pct
	save_data.auto_mana_condition = gm.auto_mana_condition
	save_data.auto_buff_enabled = gm.auto_buff_enabled
	save_data.auto_buff_condition = gm.auto_buff_condition
	save_data.auto_buff_whitelist = gm.auto_buff_whitelist.duplicate()
	save_data.dark_weapon_enchant_level = gm.dark_weapon_enchant_level
	save_data.dark_armor_enchant_level = gm.dark_armor_enchant_level
	save_data.mine_locked_this_run = gm.mine_locked_this_run
	save_data.mine_depth = gm.mine_depth
	save_data.difficulty_level = gm.difficulty_level
	save_data.max_unlocked_difficulty = gm.max_unlocked_difficulty
	save_data.boss_defeated_this_run = gm.boss_defeated_this_run
	save_data.dark_points = gm.dark_points
	save_data.dark_shop_coins = gm.dark_shop_coins
	save_data.dark_points_claimed_difficulties = gm.dark_points_claimed_difficulties.duplicate()
	save_data.unlocked_dark_skills = gm.unlocked_dark_skills.duplicate()
	save_data.difficulty_curses = gm.difficulty_curses.duplicate()
	save_data.total_runs_completed = gm.total_runs_completed
	save_data.selected_class_id = gm.selected_class_id
	save_data.reflector_kill_hp_stacks = gm.reflector_kill_hp_stacks
	save_data.curse_reroll_tokens = gm.curse_reroll_tokens
	save_data.reroll_boss_kills_in_run = gm.reroll_boss_kills_in_run
	save_data.owned_pet_ids = gm.owned_pet_ids.duplicate()
	save_data.equipped_pet_id = gm.equipped_pet_id
	save_data.garden_plots = gm.garden_plots.duplicate(true)
	save_data.light_garden_plots = gm.light_garden_plots.duplicate(true)
	save_data.brewing_slots = gm.brewing_slots.duplicate(true)
	save_data.alchemist_next_mistake_safe = gm.alchemist_next_mistake_safe
	save_data.pet_training_levels = gm.pet_training_levels.duplicate(true)
	save_data.spirit_training_levels = gm.spirit_training_levels.duplicate(true)
	save_data.afk_target_fps = gm.afk_target_fps
	save_data.equipped_weapon_quality = gm.equipped_weapon_quality
	save_data.equipped_weapon_stars = gm.equipped_weapon_stars
	save_data.equipped_armor_quality = gm.equipped_armor_quality
	save_data.equipped_armor_stars = gm.equipped_armor_stars
	save_data.equipped_offhand_path = gm.equipped_offhand.resource_path if gm.equipped_offhand != null else ""
	save_data.equipped_offhand_quality = gm.equipped_offhand_quality
	save_data.equipped_offhand_stars = gm.equipped_offhand_stars
	save_data.offhand_enchant_level = gm.offhand_enchant_level
	save_data.dark_offhand_enchant_level = gm.dark_offhand_enchant_level
	save_data.auto_salvage_mode = gm.auto_salvage_mode
	save_data.auto_salvage_min_quality = gm.auto_salvage_min_quality
	save_data.abyss_ore_shards = gm.abyss_ore_shards
	save_data.bestiary_kills = gm.bestiary_kills.duplicate(true)
	save_data.active_challenge_id = gm.active_challenge_id
	save_data.completed_challenges = gm.completed_challenges.duplicate()
	save_data.run_elapsed_seconds = gm.run_elapsed_seconds
	save_data.combat_loadouts = gm.combat_loadouts.duplicate(true)
	save_data.auto_route_enabled = gm.auto_route_enabled
	save_data.auto_route_wins_threshold = gm.auto_route_wins_threshold
	save_data.consecutive_location_wins = gm.consecutive_location_wins
	save_data.well_greed_cooldown_remaining = gm.well_greed_cooldown_remaining
	save_data.well_run_blessing = gm.well_run_blessing
	save_data.ability_casts = gm.ability_casts.duplicate(true)
	save_data.ability_levels = gm.ability_levels.duplicate(true)
	save_data.ability_runes = gm.ability_runes.duplicate(true)
	save_data.pet_expeditions = gm.pet_expeditions.duplicate(true)
	save_data.unlocked_mine_checkpoints = gm.unlocked_mine_checkpoints.duplicate()
	save_data.mine_start_depth = gm.mine_start_depth
	save_data.wave_dungeon_clears = gm.wave_dungeon_clears
	save_data.auto_advance_next_boss = gm.auto_advance_next_boss
	save_data.parallel_battle_count = gm.parallel_battle_count
	save_data.active_dark_mastery_id = gm.active_dark_mastery_id
	save_data.dark_mastery_levels = gm.dark_mastery_levels.duplicate(true)
	save_data.dark_mastery_xp = gm.dark_mastery_xp.duplicate(true)

	for entry: Dictionary in gm.inventory:
		var item: ItemData = entry["item"] as ItemData
		if item != null and not item.resource_path.is_empty():
			save_data.inventory_paths.append(item.resource_path)
			save_data.inventory_counts.append(int(entry["count"]))
			save_data.inventory_qualities.append(gm.get_entry_quality(entry))
			save_data.inventory_stars.append(gm.get_entry_stars(entry))
	return save_data


static func apply_save_data(gm: Node, save_data: SaveData) -> void:
	gm.level = maxi(1, save_data.level)
	gm.current_xp = maxf(0.0, float(save_data.current_xp))
	gm.gold = maxf(0.0, float(save_data.gold))
	gm.skill_points = maxi(0, save_data.skill_points)
	gm.enemies_defeated = maxi(0, save_data.enemies_defeated)
	gm.kills_in_run = maxi(0, save_data.kills_in_run)
	gm.base_strength = maxi(1, save_data.base_strength)
	gm.base_agility = maxi(1, save_data.base_agility)
	gm.base_endurance = maxi(1, save_data.base_endurance)
	gm.base_intellect = maxi(1, save_data.base_intellect)
	gm.melee_level = maxi(1, save_data.melee_level)
	gm.melee_xp = maxf(0.0, save_data.melee_xp)
	gm.ranged_level = maxi(1, save_data.ranged_level)
	gm.ranged_xp = maxf(0.0, save_data.ranged_xp)
	gm.magic_level = maxi(1, save_data.magic_level)
	gm.magic_xp = maxf(0.0, save_data.magic_xp)
	gm.auto_potion_enabled = save_data.auto_potion_enabled
	gm.auto_hp_threshold_pct = clampi(save_data.auto_hp_threshold_pct, 10, 95)
	gm.auto_hp_condition = "always" if save_data.auto_hp_condition == "always" else "combat"
	gm.auto_mana_enabled = save_data.auto_mana_enabled
	gm.auto_mana_threshold_pct = clampi(save_data.auto_mana_threshold_pct, 10, 95)
	gm.auto_mana_condition = "always" if save_data.auto_mana_condition == "always" else "combat"
	gm.auto_buff_enabled = save_data.auto_buff_enabled
	gm.auto_buff_condition = "on_expire_always" if save_data.auto_buff_condition == "on_expire_always" else "on_expire_combat"
	gm.auto_buff_whitelist.clear()
	for bw: String in save_data.auto_buff_whitelist:
		if not bw.is_empty() and not gm.auto_buff_whitelist.has(bw):
			gm.auto_buff_whitelist.append(bw)
	gm.dark_weapon_enchant_level = maxi(0, save_data.dark_weapon_enchant_level)
	gm.dark_armor_enchant_level = maxi(0, save_data.dark_armor_enchant_level)
	gm.mine_locked_this_run = save_data.mine_locked_this_run
	gm.mine_depth = maxi(0, save_data.mine_depth)
	gm.max_unlocked_difficulty = maxi(1, save_data.max_unlocked_difficulty)
	gm.difficulty_level = clampi(save_data.difficulty_level, 1, gm.max_unlocked_difficulty)
	gm.boss_defeated_this_run = save_data.boss_defeated_this_run
	gm.dark_points = maxi(0, save_data.dark_points)
	gm.dark_shop_coins = maxi(0, save_data.dark_shop_coins)
	gm.dark_points_claimed_difficulties.clear()
	for diff_num: int in save_data.dark_points_claimed_difficulties:
		if diff_num >= 1 and not gm.dark_points_claimed_difficulties.has(diff_num):
			gm.dark_points_claimed_difficulties.append(diff_num)
	if gm.dark_points_claimed_difficulties.is_empty() and gm.max_unlocked_difficulty > 1:
		for cleared_d: int in range(1, gm.max_unlocked_difficulty):
			gm.dark_points_claimed_difficulties.append(cleared_d)
		if gm.boss_defeated_this_run and not gm.dark_points_claimed_difficulties.has(gm.difficulty_level):
			gm.dark_points_claimed_difficulties.append(gm.difficulty_level)
	gm.total_runs_completed = maxi(0, save_data.total_runs_completed)
	gm.curse_reroll_tokens = maxi(0, save_data.curse_reroll_tokens)
	gm.reroll_boss_kills_in_run = maxi(0, save_data.reroll_boss_kills_in_run)
	gm.reflector_kill_hp_stacks = maxi(0, save_data.reflector_kill_hp_stacks)

	if gm._classes_by_id.has(save_data.selected_class_id) and (gm.is_classes_unlocked() or save_data.selected_class_id == "wanderer"):
		gm.selected_class_id = save_data.selected_class_id
	else:
		gm.selected_class_id = "wanderer"

	gm.owned_pet_ids.clear()
	for pet_id: String in save_data.owned_pet_ids:
		if gm._pets_by_id.has(pet_id) and not gm.owned_pet_ids.has(pet_id):
			gm.owned_pet_ids.append(pet_id)
	gm.equipped_pet_id = save_data.equipped_pet_id if (not save_data.equipped_pet_id.is_empty() and gm.owned_pet_ids.has(save_data.equipped_pet_id)) else ""

	var max_ench: int = gm.get_max_enchant_level()
	gm.weapon_enchant_level = clampi(save_data.weapon_enchant_level, 0, max_ench)
	gm.armor_enchant_level = clampi(save_data.armor_enchant_level, 0, max_ench)
	gm.offhand_enchant_level = clampi(save_data.offhand_enchant_level, 0, max_ench)
	gm.dark_offhand_enchant_level = maxi(0, save_data.dark_offhand_enchant_level)
	gm.afk_target_fps = save_data.afk_target_fps if gm.AFK_FPS_OPTIONS.has(save_data.afk_target_fps) else gm.DEFAULT_AFK_MAX_FPS

	gm.difficulty_curses.clear()
	if save_data.difficulty_curses is Dictionary:
		for k: Variant in save_data.difficulty_curses.keys():
			gm.difficulty_curses[int(k)] = str(save_data.difficulty_curses[k])

	gm.unlocked_skills.clear()
	for skill_id: String in save_data.unlocked_skills:
		if gm._skills_by_id.has(skill_id) and not gm.unlocked_skills.has(skill_id):
			gm.unlocked_skills.append(skill_id)

	gm.skill_presets = save_data.skill_presets.duplicate(true)
	gm.active_skill_preset_index = clampi(save_data.active_skill_preset_index, 0, gm.SKILL_PRESET_COUNT - 1)
	gm.skill_auto_upgrade_enabled = save_data.skill_auto_upgrade_enabled
	gm.ensure_skill_presets()

	gm.unlocked_dark_skills.clear()
	for dskill_id: String in save_data.unlocked_dark_skills:
		if gm._dark_skills_by_id.has(dskill_id) and not gm.unlocked_dark_skills.has(dskill_id):
			gm.unlocked_dark_skills.append(dskill_id)
	gm._invalidate_progression_caches()

	gm.equipped_ability_ids = save_data.equipped_ability_ids.duplicate() if save_data.equipped_ability_ids.size() > 0 else gm.DEFAULT_EQUIPPED_ABILITIES.duplicate()
	gm._validate_equipped_abilities_for_class()
	for i: int in range(gm.MAX_ACTIVE_ABILITY_SLOTS):
		gm.ability_auto_cast[i] = save_data.ability_auto_cast[i] if i < save_data.ability_auto_cast.size() else false

	gm.active_challenge_id = save_data.active_challenge_id if not gm.get_challenge_def(save_data.active_challenge_id).is_empty() else ""
	gm.run_elapsed_seconds = maxf(0.0, save_data.run_elapsed_seconds)
	gm.completed_challenges.clear()
	for cid: String in save_data.completed_challenges:
		if not cid.is_empty() and not gm.completed_challenges.has(cid):
			gm.completed_challenges.append(cid)

	gm.bestiary_kills.clear()
	if save_data.bestiary_kills is Dictionary:
		for bk: Variant in save_data.bestiary_kills.keys():
			gm.bestiary_kills[str(bk)] = maxi(0, int(save_data.bestiary_kills[bk]))

	gm.ability_casts.clear()
	if save_data.ability_casts is Dictionary:
		for ack: Variant in save_data.ability_casts.keys():
			gm.ability_casts[str(ack)] = maxi(0, int(save_data.ability_casts[ack]))
	gm.ability_levels.clear()
	if save_data.ability_levels is Dictionary:
		for alk: Variant in save_data.ability_levels.keys():
			gm.ability_levels[str(alk)] = clampi(int(save_data.ability_levels[alk]), 1, AbilityData.MAX_SPELL_LEVEL)
	gm.ability_runes.clear()
	if save_data.ability_runes is Dictionary:
		for ark: Variant in save_data.ability_runes.keys():
			var rk: String = str(save_data.ability_runes[ark])
			if rk == "a" or rk == "b":
				gm.ability_runes[str(ark)] = rk

	gm.combat_loadouts.clear()
	for cl: Dictionary in save_data.combat_loadouts:
		gm.combat_loadouts.append(cl.duplicate(true))
	gm._ensure_loadouts()

	gm.auto_salvage_mode = save_data.auto_salvage_mode if (save_data.auto_salvage_mode == "sell" or save_data.auto_salvage_mode == "salvage") else "off"
	gm.auto_salvage_min_quality = clampi(save_data.auto_salvage_min_quality, 80, 125)
	gm.abyss_ore_shards = maxi(0, save_data.abyss_ore_shards)
	gm.auto_route_enabled = save_data.auto_route_enabled
	gm.auto_route_wins_threshold = clampi(save_data.auto_route_wins_threshold, 3, 25)
	gm.consecutive_location_wins = maxi(0, save_data.consecutive_location_wins)
	gm.well_greed_cooldown_remaining = maxf(0.0, save_data.well_greed_cooldown_remaining)
	gm.well_run_blessing = save_data.well_run_blessing
	gm.wave_dungeon_clears = maxi(0, save_data.wave_dungeon_clears)
	gm.wave_dungeon_active = false
	gm.wave_dungeon_wave = 0
	gm.unlocked_mine_checkpoints.clear()
	for cp: int in save_data.unlocked_mine_checkpoints:
		if gm.MINE_CHECKPOINT_DEPTHS.has(cp) and not gm.unlocked_mine_checkpoints.has(cp):
			gm.unlocked_mine_checkpoints.append(cp)
	gm.mine_start_depth = save_data.mine_start_depth if gm.is_mine_checkpoint_unlocked(save_data.mine_start_depth) else 1
	gm.auto_advance_next_boss = save_data.auto_advance_next_boss
	gm.parallel_battle_count = save_data.parallel_battle_count if gm.PARALLEL_BATTLE_OPTIONS.has(save_data.parallel_battle_count) else 1
	gm.active_dark_mastery_id = save_data.active_dark_mastery_id if WorldAndAbilityCatalog.DARK_MASTERY_KEYS.has(save_data.active_dark_mastery_id) else "dark_melee"
	for dmk: String in WorldAndAbilityCatalog.DARK_MASTERY_KEYS:
		gm.dark_mastery_levels[dmk] = maxi(0, int(save_data.dark_mastery_levels.get(dmk, 0))) if save_data.dark_mastery_levels is Dictionary else 0
		gm.dark_mastery_xp[dmk] = maxf(0.0, float(save_data.dark_mastery_xp.get(dmk, 0.0))) if save_data.dark_mastery_xp is Dictionary else 0.0

	_apply_equipment_and_inventory(gm, save_data)
	_apply_sanctuary_and_finalize(gm, save_data)


static func _apply_equipment_and_inventory(gm: Node, save_data: SaveData) -> void:
	var blocked: bool = gm.is_equipment_disabled() or gm.is_gear_blocked_by_challenge()
	var staff_only: bool = gm.is_non_staff_blocked_by_challenge()

	gm.equipped_weapon = null
	gm.equipped_weapon_quality = clampi(save_data.equipped_weapon_quality, 80, 125)
	gm.equipped_weapon_stars = clampi(save_data.equipped_weapon_stars, 1, 5)
	if not blocked and not save_data.equipped_weapon_path.is_empty():
		var w_cand: ItemData = gm.get_cached_item(save_data.equipped_weapon_path)
		if w_cand != null and (not staff_only or w_cand.is_mage_staff()):
			gm.equipped_weapon = w_cand

	gm.equipped_armor = null
	gm.equipped_armor_quality = clampi(save_data.equipped_armor_quality, 80, 125)
	gm.equipped_armor_stars = clampi(save_data.equipped_armor_stars, 1, 5)
	if not blocked and not save_data.equipped_armor_path.is_empty():
		gm.equipped_armor = gm.get_cached_item(save_data.equipped_armor_path)

	gm.equipped_offhand = null
	gm.equipped_offhand_quality = clampi(save_data.equipped_offhand_quality, 80, 125)
	gm.equipped_offhand_stars = clampi(save_data.equipped_offhand_stars, 1, 5)
	if not blocked and not save_data.equipped_offhand_path.is_empty():
		var o_cand: ItemData = gm.get_cached_item(save_data.equipped_offhand_path)
		if o_cand != null and (not staff_only or o_cand.offhand_kind == ItemData.OffhandKind.TALISMAN):
			gm.equipped_offhand = o_cand

	gm.equipped_ammo = null
	gm.equipped_ammo_count = 0
	if not blocked and not save_data.equipped_ammo_path.is_empty():
		var am_cand: ItemData = gm.get_cached_item(save_data.equipped_ammo_path)
		if am_cand != null and (not staff_only or am_cand.ammo_kind == ItemData.AmmoKind.TOME):
			gm.equipped_ammo = am_cand
			gm.equipped_ammo_count = maxi(0, save_data.equipped_ammo_count)
			if gm.equipped_ammo.is_dark_forged:
				gm.equipped_ammo_count = maxi(1, gm.equipped_ammo_count)
			elif gm.equipped_ammo_count == 0:
				gm.equipped_ammo = null

	gm.inventory.clear()
	var item_count: int = mini(save_data.inventory_paths.size(), save_data.inventory_counts.size())
	for i: int in range(item_count):
		var path: String = save_data.inventory_paths[i]
		var item: ItemData = gm.get_cached_item(path)
		if item != null:
			var iq: int = save_data.inventory_qualities[i] if i < save_data.inventory_qualities.size() else 100
			var is_val: int = save_data.inventory_stars[i] if i < save_data.inventory_stars.size() else 1
			gm.add_item(item, save_data.inventory_counts[i], false, iq, is_val, false)


static func _apply_sanctuary_and_finalize(gm: Node, save_data: SaveData) -> void:
	gm.garden_plots.clear()
	for gp: Dictionary in save_data.garden_plots:
		gm.garden_plots.append(gp.duplicate(true))
	gm.light_garden_plots.clear()
	for lgp: Dictionary in save_data.light_garden_plots:
		gm.light_garden_plots.append(lgp.duplicate(true))
	gm.brewing_slots.clear()
	for bs: Dictionary in save_data.brewing_slots:
		gm.brewing_slots.append(bs.duplicate(true))
	gm.alchemist_next_mistake_safe = save_data.alchemist_next_mistake_safe

	gm.pet_training_levels.clear()
	if save_data.pet_training_levels is Dictionary:
		for pk: Variant in save_data.pet_training_levels.keys():
			var pid: String = str(pk)
			if gm._pets_by_id.has(pid):
				gm.pet_training_levels[pid] = clampi(int(save_data.pet_training_levels[pk]), 0, gm.MAX_PET_TRAINING_LEVEL)

	gm.spirit_training_levels = {"fire": 0, "wind": 0, "forest": 0, "earth": 0}
	if save_data.spirit_training_levels is Dictionary:
		for sk: String in gm.SPIRIT_KEYS:
			if save_data.spirit_training_levels.has(sk):
				gm.spirit_training_levels[sk] = maxi(0, int(save_data.spirit_training_levels[sk]))

	gm.pet_expeditions.clear()
	for pe: Dictionary in save_data.pet_expeditions:
		var pe_copy: Dictionary = pe.duplicate(true)
		var pe_pid: String = str(pe_copy.get("pet_id", ""))
		if gm.has_pet_owned(pe_pid) and gm.equipped_pet_id != pe_pid:
			gm.pet_expeditions.append(pe_copy)
	gm._ensure_sanctuary_slots()

	gm.active_buffs.clear()
	for i: int in range(gm.MAX_ACTIVE_ABILITY_SLOTS):
		gm.ability_cooldowns[i] = 0.0

	gm.mark_stats_dirty()
	gm.current_hp = clampf(save_data.current_hp, 0.0, gm.get_max_hp())
	gm.current_mana = clampf(save_data.current_mana, 0.0, gm.get_max_mana())
	gm.current_barrier = gm.get_max_barrier()
	gm.current_location = gm.locations[0] if not gm.locations.is_empty() else null
	for loc: LocationData in gm.locations:
		if loc.id == save_data.current_location_id and gm.is_location_unlocked(loc):
			gm.current_location = loc
			break
