class_name StatsCalculator
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func get_total_strength() -> int:
	if not _gm._stats_cache_dirty and _gm._stats_cache.has("strength"):
		return int(_gm._stats_cache["strength"])
	var wb: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var ob: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.OFFHAND)
	var total: float = float(_gm.base_strength + roundi(_gm.get_skill_bonus("strength")) + int(wb["strength"]) + int(ab["strength"]) + int(ob["strength"]))
	if _gm.is_challenge_completed("naked_ascetic"):
		total *= 1.10
	if _gm.has_hero_class("spirit"):
		total *= 1.35
	elif _gm.has_hero_class("troll"):
		total *= 1.20
	var res: int = maxi(1, roundi(total))
	_gm._stats_cache["strength"] = res
	_gm._stats_cache_dirty = false
	return res


func get_total_agility() -> int:
	if not _gm._stats_cache_dirty and _gm._stats_cache.has("agility"):
		return int(_gm._stats_cache["agility"])
	var wb: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var ob: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.OFFHAND)
	var total: float = float(_gm.base_agility + roundi(_gm.get_skill_bonus("agility")) + int(wb["agility"]) + int(ab["agility"]) + int(ob["agility"]))
	if _gm.is_challenge_completed("naked_ascetic"):
		total *= 1.10
	if _gm.has_hero_class("spirit"):
		total *= 1.35
	var res: int = maxi(1, roundi(total))
	_gm._stats_cache["agility"] = res
	_gm._stats_cache_dirty = false
	return res


func get_total_endurance() -> int:
	if not _gm._stats_cache_dirty and _gm._stats_cache.has("endurance"):
		return int(_gm._stats_cache["endurance"])
	var wb: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var ob: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.OFFHAND)
	var total: float = float(_gm.base_endurance + roundi(_gm.get_skill_bonus("endurance")) + int(wb["endurance"]) + int(ab["endurance"]) + int(ob["endurance"]))
	if _gm.is_challenge_completed("naked_ascetic"):
		total *= 1.10
	if _gm.has_hero_class("spirit"):
		total *= 1.35
	var res: int = maxi(1, roundi(total))
	_gm._stats_cache["endurance"] = res
	_gm._stats_cache_dirty = false
	return res


func get_total_intellect() -> int:
	if not _gm._stats_cache_dirty and _gm._stats_cache.has("intellect"):
		return int(_gm._stats_cache["intellect"])
	var wb: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
	var ab: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
	var ob: Dictionary = _gm.get_equipped_stat_bonuses(ItemData.ItemType.OFFHAND)
	var tome_int: int = 0
	if _gm.is_using_mage_staff() and _gm.has_matching_ammo() and _gm.equipped_ammo != null:
		tome_int = _gm.equipped_ammo.bonus_intellect
	var total: float = float(_gm.base_intellect + roundi(_gm.get_skill_bonus("intellect")) + int(wb["intellect"]) + int(ab["intellect"]) + int(ob["intellect"]) + tome_int)
	if _gm.is_challenge_completed("naked_ascetic"):
		total *= 1.10
	if _gm.has_hero_class("spirit"):
		total *= 1.35
	elif _gm.has_hero_class("blood_archmage"):
		total *= 2.0
	var res: int = maxi(1, roundi(total))
	_gm._stats_cache["intellect"] = res
	_gm._stats_cache_dirty = false
	return res


func get_equipped_mana_cost_reduction() -> float:
	if _gm.is_equipment_disabled() or _gm.is_gear_blocked_by_challenge():
		return 0.0
	var red: float = 0.0
	if _gm.equipped_weapon != null:
		red += _gm.equipped_weapon.bonus_mana_cost_red * _gm.get_quality_multiplier(_gm.equipped_weapon_quality) * _gm.get_star_multiplier(_gm.equipped_weapon_stars)
	if _gm.equipped_armor != null:
		red += _gm.equipped_armor.bonus_mana_cost_red * _gm.get_quality_multiplier(_gm.equipped_armor_quality) * _gm.get_star_multiplier(_gm.equipped_armor_stars)
	if _gm.equipped_offhand != null:
		red += _gm.equipped_offhand.bonus_mana_cost_red * _gm.get_quality_multiplier(_gm.equipped_offhand_quality) * _gm.get_star_multiplier(_gm.equipped_offhand_stars)
	if _gm.is_using_mage_staff() and _gm.has_matching_ammo() and _gm.equipped_ammo != null:
		red += _gm.equipped_ammo.bonus_mana_cost_red
	return clampf(red, 0.0, 0.65)


func get_equipped_spell_power_bonus() -> float:
	if _gm.is_equipment_disabled() or _gm.is_gear_blocked_by_challenge():
		return 0.0
	var sp: float = 0.0
	if _gm.equipped_weapon != null:
		sp += _gm.equipped_weapon.bonus_spell_power_pct * _gm.get_quality_multiplier(_gm.equipped_weapon_quality) * _gm.get_star_multiplier(_gm.equipped_weapon_stars)
	if _gm.equipped_armor != null:
		sp += _gm.equipped_armor.bonus_spell_power_pct * _gm.get_quality_multiplier(_gm.equipped_armor_quality) * _gm.get_star_multiplier(_gm.equipped_armor_stars)
	if _gm.equipped_offhand != null:
		sp += _gm.equipped_offhand.bonus_spell_power_pct * _gm.get_quality_multiplier(_gm.equipped_offhand_quality) * _gm.get_star_multiplier(_gm.equipped_offhand_stars)
	if _gm.is_using_mage_staff() and _gm.has_matching_ammo() and _gm.equipped_ammo != null:
		sp += _gm.equipped_ammo.bonus_spell_power_pct
	return maxf(0.0, sp)


func get_effect_duration_multiplier() -> float:
	if _gm.is_equipment_disabled() or _gm.is_gear_blocked_by_challenge():
		return 1.0
	var bonus: float = 0.0
	if _gm.equipped_weapon != null:
		bonus += _gm.equipped_weapon.bonus_effect_duration_pct * _gm.get_quality_multiplier(_gm.equipped_weapon_quality) * _gm.get_star_multiplier(_gm.equipped_weapon_stars)
	if _gm.equipped_armor != null:
		bonus += _gm.equipped_armor.bonus_effect_duration_pct * _gm.get_quality_multiplier(_gm.equipped_armor_quality) * _gm.get_star_multiplier(_gm.equipped_armor_stars)
	if _gm.equipped_offhand != null:
		bonus += _gm.equipped_offhand.bonus_effect_duration_pct * _gm.get_quality_multiplier(_gm.equipped_offhand_quality) * _gm.get_star_multiplier(_gm.equipped_offhand_stars)
	if _gm.is_using_mage_staff() and _gm.has_matching_ammo() and _gm.equipped_ammo != null:
		bonus += _gm.equipped_ammo.bonus_effect_duration_pct
	return maxf(1.0, 1.0 + bonus)


func get_raw_max_barrier() -> float:
	if _gm.is_equipment_disabled() or _gm.is_gear_blocked_by_challenge():
		return 0.0
	var raw_bar: float = 0.0
	if _gm.equipped_offhand != null:
		var total_elvl: int = _gm.get_total_slot_enchant_level(ItemData.ItemType.OFFHAND)
		var mult: float = _gm.get_enchant_power_multiplier(total_elvl) * _gm.get_quality_multiplier(_gm.equipped_offhand_quality) * _gm.get_star_multiplier(_gm.equipped_offhand_stars)
		var stat_val: float = float(get_total_intellect()) if _gm.equipped_offhand.offhand_kind == ItemData.OffhandKind.TALISMAN else float(get_total_endurance())
		raw_bar += (_gm.equipped_offhand.bonus_barrier + _gm.equipped_offhand.bonus_barrier_scale * stat_val) * mult
	if _gm.equipped_armor != null and (_gm.equipped_armor.bonus_barrier > 0.0 or _gm.equipped_armor.bonus_barrier_scale > 0.0):
		var total_alvl: int = _gm.get_total_slot_enchant_level(ItemData.ItemType.ARMOR)
		var amult: float = _gm.get_enchant_power_multiplier(total_alvl) * _gm.get_quality_multiplier(_gm.equipped_armor_quality) * _gm.get_star_multiplier(_gm.equipped_armor_stars)
		raw_bar += (_gm.equipped_armor.bonus_barrier + _gm.equipped_armor.bonus_barrier_scale * float(get_total_endurance())) * amult
	var bar_pct_bonus: float = _gm.get_skill_bonus("barrier_pct") + _gm.get_dark_bonus("barrier_fortress") + float(_gm.get_dark_mastery_level("dark_armor")) * 0.05
	if bar_pct_bonus > 0.0:
		raw_bar *= (1.0 + bar_pct_bonus)
	if _gm.well_run_blessing == "barrier_surge":
		raw_bar *= 1.25
	return maxf(0.0, raw_bar)


func get_barrier_regen_per_sec_pct() -> float:
	return _gm.get_skill_bonus("barrier_regen_pct") + _gm.get_dark_bonus("barrier_regen")


func get_on_kill_barrier_restore_pct() -> float:
	var pct: float = 0.10 if _gm.has_dark_skill("barrier_regen") or _gm.has_dark_skill("aegis_regeneration") else 0.0
	pct += _gm.get_dark_bonus("kill_barrier_heal")
	return pct


func get_equipped_reflection_bonus() -> float:
	if _gm.is_equipment_disabled() or _gm.is_gear_blocked_by_challenge():
		return 0.0
	var ref_sum: float = 0.0
	if _gm.equipped_offhand != null and _gm.equipped_offhand.bonus_reflect_pct > 0.0:
		var total_elvl: int = _gm.get_total_slot_enchant_level(ItemData.ItemType.OFFHAND)
		var slot_mult: float = (1.0 + float(total_elvl) * 0.015) * _gm.get_quality_multiplier(_gm.equipped_offhand_quality) * _gm.get_star_multiplier(_gm.equipped_offhand_stars)
		ref_sum += _gm.equipped_offhand.bonus_reflect_pct * slot_mult
	if _gm.equipped_armor != null and _gm.equipped_armor.bonus_reflect_pct > 0.0:
		var armor_elvl: int = _gm.get_total_slot_enchant_level(ItemData.ItemType.ARMOR)
		var armor_mult: float = (1.0 + float(armor_elvl) * 0.015) * _gm.get_quality_multiplier(_gm.equipped_armor_quality) * _gm.get_star_multiplier(_gm.equipped_armor_stars)
		ref_sum += _gm.equipped_armor.bonus_reflect_pct * armor_mult
	if _gm.equipped_weapon != null and _gm.equipped_weapon.bonus_reflect_pct > 0.0:
		var weapon_elvl: int = _gm.get_total_slot_enchant_level(ItemData.ItemType.WEAPON)
		var weapon_mult: float = (1.0 + float(weapon_elvl) * 0.015) * _gm.get_quality_multiplier(_gm.equipped_weapon_quality) * _gm.get_star_multiplier(_gm.equipped_weapon_stars)
		ref_sum += _gm.equipped_weapon.bonus_reflect_pct * weapon_mult
	return maxf(0.0, ref_sum)


func get_max_barrier() -> float:
	if _gm.has_hero_class("reflector"):
		return 0.0
	return get_raw_max_barrier()


func add_barrier(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	if _gm.has_hero_class("reflector"):
		return _gm.heal(amount)
	var cap: float = maxf(get_max_barrier() * 1.5, get_max_hp() * 0.50)
	var prev: float = _gm.current_barrier
	_gm.current_barrier = minf(cap, _gm.current_barrier + amount)
	var gained: float = _gm.current_barrier - prev
	if gained > 0.0:
		_gm.barrier_changed.emit(_gm.current_barrier, maxf(get_max_barrier(), _gm.current_barrier))
	return gained


func restore_barrier_full() -> void:
	if _gm.has_hero_class("reflector"):
		_gm.current_barrier = 0.0
		_gm.barrier_changed.emit(0.0, 0.0)
		return
	var max_bar: float = get_max_barrier()
	_gm.current_barrier = maxf(_gm.current_barrier, max_bar)
	_gm.barrier_changed.emit(_gm.current_barrier, maxf(max_bar, _gm.current_barrier))


func get_max_hp() -> float:
	if not _gm._stats_cache_dirty and _gm._stats_cache.has("max_hp"):
		return float(_gm._stats_cache["max_hp"])
	var hp_val: float = 100.0 + float(get_total_endurance()) * 60.0
	var hp_mult: float = _gm.get_dark_bonus("immortal_pact") + _gm.get_dark_bonus("abyssal_vitality") + _gm.get_dark_bonus("obsidian_bulwark") + _gm.get_skill_bonus("max_hp_pct") + _gm.get_dark_mastery_bonus("dark_temper")
	if hp_mult > 0.0:
		hp_val *= (1.0 + hp_mult)
	if _gm.well_run_blessing == "barrier_surge":
		hp_val *= 1.12
	if _gm.has_hero_class("troll"):
		hp_val *= 1.25
	elif _gm.has_hero_class("reflector"):
		var total_hp_gain: float = maxf(0.0, hp_val - 100.0) + float(_gm.reflector_kill_hp_stacks) + get_raw_max_barrier()
		total_hp_gain *= 1.30
		hp_val = 100.0 + total_hp_gain * 20.0
	_gm._stats_cache["max_hp"] = hp_val
	_gm._stats_cache_dirty = false
	return hp_val


func get_max_mana() -> float:
	if not _gm._stats_cache_dirty and _gm._stats_cache.has("max_mana"):
		return float(_gm._stats_cache["max_mana"])
	var mana_from_int: float = float(get_total_intellect()) * 32.0
	if _gm.has_hero_class("blood_archmage"):
		mana_from_int *= 3.0
	var mp_val: float = 40.0 + float(_gm.level) * 5.0 + float(get_total_endurance()) * 16.0 + mana_from_int + _gm.get_skill_bonus("max_mana")
	_gm._stats_cache["max_mana"] = mp_val
	_gm._stats_cache_dirty = false
	return mp_val


func get_mana_regen_per_sec() -> float:
	if not _gm._stats_cache_dirty and _gm._stats_cache.has("mana_regen"):
		return float(_gm._stats_cache["mana_regen"])
	var regen: float = 2.5 + float(get_total_endurance()) * 0.25 + float(get_total_intellect()) * 0.45 + _gm.get_skill_bonus("mana_regen")
	regen *= (1.0 + float(_gm.magic_level - 1) * 0.04)
	regen *= (1.0 + _gm.get_dark_bonus("mana_fountain"))
	regen *= (1.0 + _gm.get_active_buff_sum("mana_regen_pct"))
	regen *= (1.0 + _gm.get_pet_secondary_value("aura_regen"))
	if _gm.has_hero_class("alchemist"):
		regen *= 1.15
	regen *= maxf(0.1, 1.0 - _gm.get_curse_value("mana_burn"))
	_gm._stats_cache["mana_regen"] = regen
	_gm._stats_cache_dirty = false
	return regen


func spend_mana(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if _gm.current_mana < amount:
		return false
	_gm.current_mana = maxf(0.0, _gm.current_mana - amount)
	_gm.mana_changed.emit(_gm.current_mana, get_max_mana())
	return true


func restore_mana(amount: float, emit_signal_immediately: bool = true) -> float:
	if amount <= 0.0:
		return 0.0
	var max_mana: float = get_max_mana()
	var prev_mana: float = _gm.current_mana
	_gm.current_mana = minf(max_mana, _gm.current_mana + amount)
	var actual: float = _gm.current_mana - prev_mana
	if actual > 0.0:
		if emit_signal_immediately or _gm.current_mana >= max_mana:
			_gm._mana_ui_dirty = false
			_gm.mana_changed.emit(_gm.current_mana, max_mana)
		else:
			_gm._mana_ui_dirty = true
	return actual
