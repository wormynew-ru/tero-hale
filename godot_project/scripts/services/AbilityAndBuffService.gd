class_name AbilityAndBuffService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func get_ability_by_id(ability_id: String) -> AbilityData:
	if _gm._abilities_by_id.has(ability_id):
		return _gm._abilities_by_id[ability_id] as AbilityData
	return null


func is_ability_unlocked(ability: AbilityData) -> bool:
	if ability == null:
		return false
	if ability.required_class_id.is_empty():
		return true
	return _gm.has_hero_class(ability.required_class_id)


func get_equipped_slot_for_ability(ability_id: String) -> int:
	if ability_id.is_empty():
		return -1
	for i: int in range(mini(_gm.MAX_ACTIVE_ABILITY_SLOTS, _gm.equipped_ability_ids.size())):
		if _gm.equipped_ability_ids[i] == ability_id:
			return i
	return -1


func sync_equipped_abilities() -> void:
	while _gm.equipped_ability_ids.size() < _gm.MAX_ACTIVE_ABILITY_SLOTS:
		_gm.equipped_ability_ids.append("")
	if _gm.equipped_ability_ids.size() > _gm.MAX_ACTIVE_ABILITY_SLOTS:
		_gm.equipped_ability_ids.resize(_gm.MAX_ACTIVE_ABILITY_SLOTS)

	_gm.abilities.resize(_gm.MAX_ACTIVE_ABILITY_SLOTS)
	for i: int in range(_gm.MAX_ACTIVE_ABILITY_SLOTS):
		var aid: String = _gm.equipped_ability_ids[i]
		var ab: AbilityData = get_ability_by_id(aid) if not aid.is_empty() else null
		if ab != null and is_ability_unlocked(ab):
			_gm.abilities[i] = ab
		else:
			_gm.abilities[i] = null
			_gm.equipped_ability_ids[i] = ""


func validate_equipped_abilities_for_class() -> void:
	while _gm.equipped_ability_ids.size() < _gm.MAX_ACTIVE_ABILITY_SLOTS:
		_gm.equipped_ability_ids.append("")
	for i: int in range(_gm.MAX_ACTIVE_ABILITY_SLOTS):
		var ab: AbilityData = get_ability_by_id(_gm.equipped_ability_ids[i])
		if ab == null or not is_ability_unlocked(ab):
			_gm.equipped_ability_ids[i] = ""
			if i < _gm.ability_auto_cast.size():
				_gm.ability_auto_cast[i] = false
			if i < _gm.ability_cooldowns.size():
				_gm.ability_cooldowns[i] = 0.0
	sync_equipped_abilities()


func equip_ability_to_slot(ability_id: String, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _gm.MAX_ACTIVE_ABILITY_SLOTS:
		return false
	var target: AbilityData = get_ability_by_id(ability_id)
	if target == null or not is_ability_unlocked(target):
		return false

	sync_equipped_abilities()
	var existing_slot: int = get_equipped_slot_for_ability(ability_id)
	if existing_slot == slot_index:
		return true
	if existing_slot != -1:
		var prev_id: String = _gm.equipped_ability_ids[slot_index]
		_gm.equipped_ability_ids[existing_slot] = prev_id
		_gm.equipped_ability_ids[slot_index] = ability_id
		var tmp_cd: float = _gm.ability_cooldowns[existing_slot]
		_gm.ability_cooldowns[existing_slot] = _gm.ability_cooldowns[slot_index]
		_gm.ability_cooldowns[slot_index] = tmp_cd
		var tmp_auto: bool = _gm.ability_auto_cast[existing_slot]
		_gm.ability_auto_cast[existing_slot] = _gm.ability_auto_cast[slot_index]
		_gm.ability_auto_cast[slot_index] = tmp_auto
	else:
		_gm.equipped_ability_ids[slot_index] = ability_id
		_gm.ability_cooldowns[slot_index] = 0.0

	sync_equipped_abilities()
	_gm.abilities_changed.emit()
	_gm.save_game()
	return true


func clear_ability_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _gm.MAX_ACTIVE_ABILITY_SLOTS:
		return
	sync_equipped_abilities()
	_gm.equipped_ability_ids[slot_index] = ""
	_gm.ability_cooldowns[slot_index] = 0.0
	_gm.ability_auto_cast[slot_index] = false
	sync_equipped_abilities()
	_gm.abilities_changed.emit()
	_gm.save_game()


func get_ability_casts(ability_id: String) -> int:
	return maxi(0, int(_gm.ability_casts.get(ability_id, 0)))


func get_ability_level(ability_id: String) -> int:
	return clampi(int(_gm.ability_levels.get(ability_id, 1)), 1, AbilityData.MAX_SPELL_LEVEL)


func get_next_spell_level_casts(ability_id: String) -> int:
	var lvl: int = get_ability_level(ability_id)
	if lvl >= AbilityData.MAX_SPELL_LEVEL:
		return 0
	return _gm.SPELL_LEVEL_CAST_THRESHOLDS[lvl]


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
	var page_item: ItemData = _gm.get_cached_item("res://resources/items/ancient_page.tres")
	if page_item == null or not _gm.remove_item(page_item, page_cost):
		return {"success": false, "message": "Нужно %d 📜 Древних листов для улучшения чар." % page_cost}
	_gm.ability_levels[ability_id] = lvl + 1
	_gm.abilities_changed.emit()
	_gm.stats_changed.emit()
	_gm.save_game()
	return {"success": true, "message": "📖 %s повышено до Ур.%d!" % [ab.title, lvl + 1]}


func record_ability_cast(ability_id: String) -> void:
	if ability_id.is_empty():
		return
	var next_casts: int = get_ability_casts(ability_id) + 1
	_gm.ability_casts[ability_id] = next_casts
	var cur_lvl: int = get_ability_level(ability_id)
	while cur_lvl < AbilityData.MAX_SPELL_LEVEL and next_casts >= _gm.SPELL_LEVEL_CAST_THRESHOLDS[cur_lvl]:
		cur_lvl += 1
		_gm.ability_levels[ability_id] = cur_lvl
	_gm.abilities_changed.emit()


func get_ability_rune(ability_id: String) -> String:
	var key: String = str(_gm.ability_runes.get(ability_id, ""))
	return key if (key == "a" or key == "b") else ""


func get_ability_rune_data(ability_id: String) -> Dictionary:
	var r_key: String = get_ability_rune(ability_id)
	if r_key.is_empty() or not WorldAndAbilityCatalog.SPELL_RUNES_CATALOG.has(ability_id):
		return {}
	var pair: Dictionary = WorldAndAbilityCatalog.SPELL_RUNES_CATALOG[ability_id] as Dictionary
	if pair.has(r_key):
		return pair[r_key] as Dictionary
	return {}


func set_ability_rune(ability_id: String, rune_key: String) -> void:
	if rune_key != "" and rune_key != "a" and rune_key != "b":
		return
	if rune_key.is_empty():
		_gm.ability_runes.erase(ability_id)
	else:
		_gm.ability_runes[ability_id] = rune_key
	_gm.abilities_changed.emit()
	_gm.save_game()


func apply_ability_buff(ability: AbilityData, potency_scale: float = 1.0) -> void:
	if ability == null or ability.duration <= 0.0:
		return
	var rune_data: Dictionary = get_ability_rune_data(ability.id)
	var dur_mult: float = float(rune_data.get("duration_mult", 1.0))
	var lvl_mult: float = AbilityData.get_level_multiplier(get_ability_level(ability.id))
	var final_scale: float = potency_scale * lvl_mult * float(rune_data.get("power_mult", 1.0))
	var final_dur: float = maxf(1.0, ability.duration * _gm.get_effect_duration_multiplier() * dur_mult)
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
	for i: int in range(_gm.active_buffs.size()):
		if str(_gm.active_buffs[i]["id"]) == ability.id:
			_gm.active_buffs[i] = entry
			replaced = true
			break
	if not replaced:
		_gm.active_buffs.append(entry)
	_gm.mark_stats_dirty()
	_gm.buffs_changed.emit()
	_gm.stats_changed.emit()


func has_active_buff(buff_id: String) -> bool:
	for b: Dictionary in _gm.active_buffs:
		if str(b["id"]) == buff_id and float(b["remaining"]) > 0.0:
			return true
	return false


func get_active_buff_remaining(buff_id: String) -> float:
	for b: Dictionary in _gm.active_buffs:
		if str(b["id"]) == buff_id:
			return maxf(0.0, float(b["remaining"]))
	return 0.0


func get_active_buff_sum(stat_key: String) -> float:
	var total: float = 0.0
	for b: Dictionary in _gm.active_buffs:
		if float(b.get("remaining", 0.0)) > 0.0:
			total += float(b.get(stat_key, 0.0))
	return total


func clear_active_buffs() -> void:
	if _gm.active_buffs.is_empty():
		return
	_gm.active_buffs.clear()
	_gm.mark_stats_dirty()
	_gm.buffs_changed.emit()
	_gm.stats_changed.emit()


func get_ability(slot_index: int) -> AbilityData:
	if slot_index < 0 or slot_index >= _gm.abilities.size():
		return null
	return _gm.abilities[slot_index]


func get_ability_mana_cost(ability: AbilityData) -> float:
	if ability == null:
		return 0.0
	var cost: float = ability.mana_cost
	if _gm.has_dark_skill("mana_fountain"):
		cost *= 0.80
	cost *= maxf(0.35, 1.0 - _gm.get_skill_bonus("mana_cost_red"))
	cost *= maxf(0.25, 1.0 - _gm.get_equipped_mana_cost_reduction())
	if _gm.has_hero_class("blood_archmage"):
		cost *= 0.50
	var rune_data: Dictionary = get_ability_rune_data(ability.id)
	cost *= float(rune_data.get("cost_mult", 1.0))
	cost *= (1.0 + _gm.get_curse_value("clumsy_hands"))
	return maxf(1.0, round(cost))


func get_ability_cooldown_duration(ability: AbilityData) -> float:
	if ability == null:
		return 0.0
	var cd: float = ability.cooldown
	if _gm.has_dark_skill("swift_runes"):
		cd *= 0.75
	if _gm.has_dark_skill("abyssal_haste"):
		cd *= 0.85
	cd *= maxf(0.35, 1.0 - _gm.get_skill_bonus("ability_cd_red"))
	if _gm.has_hero_class("blood_archmage"):
		cd *= 0.70
	if _gm.is_challenge_completed("speedrun_titan"):
		cd *= 0.92
	if _gm.well_run_blessing == "arcane_overdrive":
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
	mult *= _gm.get_mastery_bonus_multiplier("magic")
	var spell_bonus: float = _gm.get_skill_bonus("spell_power") + get_active_buff_sum("spell_power_pct") + _gm.get_equipped_spell_power_bonus() + _gm.get_dark_mastery_bonus("dark_magic") + float(_gm.get_total_intellect()) * 0.015
	if _gm.is_challenge_completed("staff_master"):
		spell_bonus += 0.12
	if _gm.well_run_blessing == "arcane_overdrive":
		spell_bonus += 0.20
	mult *= (1.0 + spell_bonus)
	if _gm.has_dark_skill("swift_runes"):
		mult *= 1.35
	if _gm.has_hero_class("blood_archmage"):
		mult *= 1.75
	if ability.effect_type == "heal":
		if _gm.is_challenge_completed("no_potions_titan"):
			mult *= 1.15
		mult *= maxf(0.25, 1.0 - _gm.get_curse_value("blood_tax"))
	return mult


func get_ability_cooldown(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= _gm.ability_cooldowns.size():
		return 0.0
	return _gm.ability_cooldowns[slot_index]


func is_ability_auto_cast(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _gm.ability_auto_cast.size():
		return false
	return _gm.ability_auto_cast[slot_index]


func toggle_ability_auto_cast(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _gm.ability_auto_cast.size():
		return
	_gm.ability_auto_cast[slot_index] = not _gm.ability_auto_cast[slot_index]
	_gm.abilities_changed.emit()
	_gm.save_game()


func start_ability_cooldown(slot_index: int, duration: float) -> void:
	if slot_index < 0 or slot_index >= _gm.ability_cooldowns.size():
		return
	_gm.ability_cooldowns[slot_index] = maxf(0.0, duration)
	_gm.abilities_changed.emit()


func reduce_all_ability_cooldowns(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var changed: bool = false
	for i: int in range(_gm.ability_cooldowns.size()):
		if _gm.ability_cooldowns[i] > 0.0:
			_gm.ability_cooldowns[i] = maxf(0.0, _gm.ability_cooldowns[i] - seconds)
			changed = true
	if changed:
		_gm.abilities_changed.emit()
