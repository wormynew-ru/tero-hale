class_name CombatStatsCalculator
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func get_soul_harvest_bonus() -> float:
	if not _gm.has_dark_skill("soul_harvest"):
		return 0.0
	return float(floori(float(_gm.kills_in_run) / 100.0)) * _gm.get_dark_bonus("soul_harvest")


func get_berserk_bonus() -> float:
	if not _gm.has_dark_skill("berserk_fury"):
		return 0.0
	var max_hp: float = maxf(1.0, _gm.get_max_hp())
	var missing_ratio: float = clampf(1.0 - (_gm.current_hp / max_hp), 0.0, 1.0)
	return missing_ratio * _gm.get_dark_bonus("berserk_fury")


func get_player_damage(preview_ammo_ready: bool = true) -> float:
	if _gm.has_hero_class("reflector"):
		return 0.0
	var total_weapon_elvl: int = _gm.get_total_slot_enchant_level(ItemData.ItemType.WEAPON)
	var dmg: float = _gm.BASE_DAMAGE + float(_gm.get_total_strength()) * 1.5
	if _gm.is_using_mage_staff():
		dmg = _gm.BASE_DAMAGE + float(_gm.get_total_strength()) * 0.8 + float(_gm.get_total_intellect()) * 2.2
	if not _gm.is_equipment_disabled() and not _gm.is_gear_blocked_by_challenge() and _gm.equipped_weapon != null and _gm.equipped_weapon.bonus_damage > 0.0:
		var w_scale: float = _gm.get_quality_multiplier(_gm.equipped_weapon_quality) * _gm.get_star_multiplier(_gm.equipped_weapon_stars)
		dmg += _gm.equipped_weapon.bonus_damage * _gm.get_enchant_power_multiplier(total_weapon_elvl) * w_scale

	if _gm.is_using_ranged_weapon():
		if preview_ammo_ready and _gm.has_matching_ammo():
			if _gm.equipped_ammo != null:
				dmg += _gm.equipped_ammo.bonus_damage
			dmg *= _gm.get_mastery_bonus_multiplier("ranged")
			dmg *= (1.0 + _gm.get_skill_bonus("ranged_dmg") + _gm.get_dark_mastery_bonus("dark_ranged"))
			dmg *= (1.0 + _gm.get_dark_bonus("shadow_quiver"))
			if _gm.has_dark_skill("deadeye_abyss"):
				dmg *= 1.40
			if _gm.has_hero_class("abyss_ranger"):
				dmg *= 1.40
		else:
			dmg *= 0.45
	elif _gm.is_using_mage_staff():
		if preview_ammo_ready and _gm.has_matching_ammo():
			if _gm.equipped_ammo != null:
				dmg += _gm.equipped_ammo.bonus_damage
			dmg *= _gm.get_mastery_bonus_multiplier("magic")
			dmg *= (1.0 + _gm.get_skill_bonus("spell_power") * 0.5 + _gm.get_equipped_spell_power_bonus() * 0.5 + _gm.get_dark_mastery_bonus("dark_magic"))
		else:
			dmg *= 0.45
	else:
		dmg *= _gm.get_mastery_bonus_multiplier("melee")
		dmg *= (1.0 + _gm.get_skill_bonus("melee_dmg") + _gm.get_dark_mastery_bonus("dark_melee"))

	dmg *= (1.0 + _gm.get_dark_bonus("awakening_power") + get_soul_harvest_bonus() + get_berserk_bonus() + _gm.get_active_buff_sum("damage_pct") + _gm.get_pet_secondary_value("enemy_burn"))
	if _gm.well_run_blessing == "damage_surge":
		dmg *= 1.15
	return dmg


func get_pack_or_boss_damage_mult(enemy_id: String, pack_count: int = 1) -> float:
	var bonus: float = _gm.get_dark_bonus("pack_slayer_dmg")
	if bonus <= 0.0:
		return 1.0
	if pack_count > 1 or enemy_id == _gm.FINAL_BOSS_ID or enemy_id == _gm.CURSE_WARDEN_ID or enemy_id == "mine_overseer":
		return 1.0 + bonus
	return 1.0


func get_alchemist_gold_reaction_bonus() -> float:
	if not _gm.has_hero_class("alchemist") or _gm.gold <= 0.0:
		return 0.0
	return _gm.gold * _gm.ALCHEMIST_GOLD_REACTION_RATIO


func get_basic_attack_damage(preview_ammo_ready: bool = true) -> float:
	if _gm.has_hero_class("reflector"):
		return 0.0
	return get_player_damage(preview_ammo_ready) + get_alchemist_gold_reaction_bonus()


func get_player_armor_penetration() -> float:
	if _gm.is_equipment_disabled() or _gm.is_gear_blocked_by_challenge():
		return 0.0
	var pen: float = 0.0
	if _gm.equipped_weapon != null:
		pen += _gm.equipped_weapon.armor_penetration
	if _gm.is_using_ammo_weapon() and _gm.has_matching_ammo() and _gm.equipped_ammo != null:
		pen += _gm.equipped_ammo.armor_penetration
	return pen


func get_player_attack_interval() -> float:
	var base_interval: float = maxf(0.42, 2.4 / (1.0 + float(_gm.get_total_agility()) * 0.08))
	var wind_speed: float = _gm.get_dark_bonus("wind_mastery_dark") + _gm.get_dark_bonus("abyssal_haste") + _gm.get_active_buff_sum("attack_speed_pct")
	if _gm.is_challenge_completed("speedrun_titan"):
		wind_speed += 0.08
	if wind_speed > 0.0:
		base_interval /= (1.0 + wind_speed)
	return maxf(0.26, base_interval * (1.0 + _gm.get_curse_value("lead_shackles")))


func get_player_dps() -> float:
	if _gm.has_hero_class("reflector"):
		return 0.0
	var avg_crit_factor: float = 1.0 + get_crit_chance() * (get_crit_multiplier() - 1.0)
	return (get_basic_attack_damage() * avg_crit_factor) / get_player_attack_interval()


func get_dodge_chance() -> float:
	if _gm.has_hero_class("reflector"):
		return 0.0
	return clampf(float(_gm.get_total_agility()) * 0.008 + _gm.get_skill_bonus("dodge_chance") + _gm.get_active_buff_sum("dodge_bonus"), 0.0, 0.65)


func get_armor_reduction() -> float:
	var raw_armor: float = float(_gm.get_total_endurance()) * 0.6 + _gm.get_skill_bonus("flat_armor") + _gm.get_dark_bonus("void_plating")
	if not _gm.is_equipment_disabled() and not _gm.is_gear_blocked_by_challenge():
		if _gm.equipped_weapon != null and _gm.equipped_weapon.bonus_defense > 0.0:
			raw_armor += _gm.equipped_weapon.bonus_defense * _gm.get_enchant_power_multiplier(_gm.get_total_slot_enchant_level(ItemData.ItemType.WEAPON)) * _gm.get_quality_multiplier(_gm.equipped_weapon_quality) * _gm.get_star_multiplier(_gm.equipped_weapon_stars)
		if _gm.equipped_armor != null and _gm.equipped_armor.bonus_defense > 0.0:
			raw_armor += _gm.equipped_armor.bonus_defense * _gm.get_enchant_power_multiplier(_gm.get_total_slot_enchant_level(ItemData.ItemType.ARMOR)) * _gm.get_quality_multiplier(_gm.equipped_armor_quality) * _gm.get_star_multiplier(_gm.equipped_armor_stars)
		if _gm.equipped_offhand != null and _gm.equipped_offhand.bonus_defense > 0.0:
			raw_armor += _gm.equipped_offhand.bonus_defense * _gm.get_enchant_power_multiplier(_gm.get_total_slot_enchant_level(ItemData.ItemType.OFFHAND)) * _gm.get_quality_multiplier(_gm.equipped_offhand_quality) * _gm.get_star_multiplier(_gm.equipped_offhand_stars)
	var total_armor_pct: float = (0.25 if _gm.has_dark_skill("void_plating") else 0.0) + (0.35 if _gm.has_dark_skill("obsidian_bulwark") else 0.0) + _gm.get_skill_bonus("armor_pct") + _gm.get_dark_mastery_bonus("dark_armor")
	if total_armor_pct > 0.0:
		raw_armor *= (1.0 + total_armor_pct)
	if _gm.has_hero_class("spirit"):
		raw_armor *= 1.50
	elif _gm.has_hero_class("reflector"):
		raw_armor *= 1.40
	raw_armor *= (1.0 + _gm.get_active_buff_sum("armor_pct"))
	raw_armor *= maxf(0.15, 1.0 - _gm.get_curse_value("brittle_armor"))
	return raw_armor


func get_damage_reflection_pct() -> float:
	var base_reflect: float = 0.20 if _gm.has_hero_class("reflector") else 0.0
	return base_reflect + _gm.get_equipped_reflection_bonus() + _gm.get_skill_bonus("reflect_pct") + _gm.get_dark_bonus("mirror_carapace") + _gm.get_dark_bonus("thorn_apotheosis") + _gm.get_dark_bonus("reflect_fortress") + _gm.get_dark_mastery_bonus("dark_reflect") + _gm.get_active_buff_sum("reflect_pct")


func get_reflector_mitigation_pct() -> float:
	if not _gm.has_hero_class("reflector"):
		return 0.0
	return minf(get_damage_reflection_pct(), 0.99)


func get_crit_chance() -> float:
	var extra: float = _gm.get_active_buff_sum("crit_chance_bonus") + _gm.get_pet_effect_value("crit_lightning")
	if not _gm.is_equipment_disabled() and not _gm.is_gear_blocked_by_challenge() and _gm.equipped_weapon != null:
		extra += _gm.equipped_weapon.bonus_crit_chance
	if _gm.is_using_ranged_weapon():
		extra += float(maxi(0, _gm.ranged_level - 1)) * 0.003
		if _gm.has_matching_ammo() and _gm.equipped_ammo != null:
			extra += _gm.equipped_ammo.bonus_crit_chance
	elif _gm.is_using_mage_staff() and _gm.has_matching_ammo() and _gm.equipped_ammo != null:
		extra += _gm.equipped_ammo.bonus_crit_chance
	extra += _gm.get_dark_bonus("deadeye_abyss")
	return clampf(_gm.BASE_CRIT_CHANCE + _gm.get_skill_bonus("crit_chance") + extra - _gm.get_curse_value("dull_edge"), 0.02, 0.95)


func get_crit_multiplier() -> float:
	var penalty: float = 0.25 if _gm.get_curse_value("dull_edge") > 0.0 else 0.0
	var bonus: float = _gm.get_skill_bonus("crit_mult") + _gm.get_dark_bonus("piercing_volley") + _gm.get_active_buff_sum("crit_mult_bonus")
	if _gm.has_hero_class("abyss_ranger"):
		bonus += float(_gm.get_total_agility()) * 0.015
	return maxf(1.25, _gm.CRIT_MULTIPLIER + bonus - penalty)


func get_gold_multiplier() -> float:
	var mult: float = (1.0 + _gm.get_skill_bonus("gold_mult") + _gm.get_dark_bonus("abyssal_greed") + _gm.get_pet_effect_value("gold_echo")) * _gm.get_difficulty_gold_mult()
	if _gm.has_hero_class("alchemist"):
		mult *= 1.15
	if _gm.well_run_blessing == "greed_fortune":
		mult *= 1.25
	return mult


func get_xp_multiplier() -> float:
	var dark_xp: float = 0.5 if _gm.has_dark_skill("abyssal_greed") else 0.0
	return (1.0 + _gm.get_skill_bonus("xp_mult") + dark_xp) * _gm.get_difficulty_xp_mult()


func get_xp_to_next_level() -> float:
	var lvl_idx: float = float(maxi(0, _gm.level - 1))
	return round(150.0 * pow(1.10, lvl_idx) + lvl_idx * lvl_idx * 55.0)


func get_base_stat_value(stat_name: String) -> int:
	match stat_name:
		"strength":
			return _gm.base_strength
		"agility":
			return _gm.base_agility
		"endurance":
			return _gm.base_endurance
		"intellect":
			return _gm.base_intellect
	return 5


func get_train_cost(stat_name: String) -> float:
	var stat_val: int = get_base_stat_value(stat_name)
	return round((10.0 + float(stat_val) * 5.0) * _gm.get_difficulty_train_mult())


func sum_train_cost_for_steps(start_val: int, steps: int, diff_mult: float) -> float:
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
	var start_val: int = get_base_stat_value(stat_name)
	var diff_mult: float = _gm.get_difficulty_train_mult()
	if target_count > 0:
		return {
			"count": target_count,
			"cost": sum_train_cost_for_steps(start_val, target_count, diff_mult),
		}
	var one_cost: float = round((10.0 + float(start_val) * 5.0) * diff_mult)
	if _gm.gold < one_cost:
		return {"count": 0, "cost": one_cost}
	var upper_bound: int = 1
	while upper_bound < 100000000 and sum_train_cost_for_steps(start_val, upper_bound, diff_mult) <= _gm.gold:
		upper_bound *= 2
	var lo: int = 1
	var hi_bound: int = upper_bound
	var best_k: int = 0
	var best_cost: float = 0.0
	while lo <= hi_bound:
		var mid: int = floori(float(lo + hi_bound) * 0.5)
		var c: float = sum_train_cost_for_steps(start_val, mid, diff_mult)
		if c <= _gm.gold:
			best_k = mid
			best_cost = c
			lo = mid + 1
		else:
			hi_bound = mid - 1
	return {"count": best_k, "cost": best_cost}


func get_item_buy_price(item: ItemData) -> float:
	if item == null:
		return 0.0
	var mult: float = _gm.get_difficulty_price_mult() * (1.0 + _gm.get_curse_value("greedy_curse"))
	return maxf(1.0, round(float(item.buy_price) * mult))


func get_item_sell_value(item: ItemData) -> float:
	if item == null:
		return 0.0
	var mult: float = pow(1.35, float(_gm.difficulty_level - 1))
	return maxf(1.0, round(float(item.sell_value) * mult))
