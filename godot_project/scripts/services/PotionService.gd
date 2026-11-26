class_name PotionService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func set_auto_potion(enabled: bool) -> void:
	_gm.auto_potion_enabled = enabled
	_gm.stats_changed.emit()
	_gm.save_game()


func set_auto_hp_settings(enabled: bool, threshold_pct: int, condition: String) -> void:
	_gm.auto_potion_enabled = enabled
	_gm.auto_hp_threshold_pct = clampi(threshold_pct, 10, 95)
	_gm.auto_hp_condition = "always" if condition == "always" else "combat"
	_gm.stats_changed.emit()
	_gm.save_game()


func set_auto_mana_settings(enabled: bool, threshold_pct: int, condition: String) -> void:
	_gm.auto_mana_enabled = enabled
	_gm.auto_mana_threshold_pct = clampi(threshold_pct, 10, 95)
	_gm.auto_mana_condition = "always" if condition == "always" else "combat"
	_gm.stats_changed.emit()
	_gm.save_game()


func set_auto_buff_settings(enabled: bool, condition: String) -> void:
	_gm.auto_buff_enabled = enabled
	_gm.auto_buff_condition = "on_expire_always" if condition == "on_expire_always" else "on_expire_combat"
	_gm.stats_changed.emit()
	_gm.save_game()


func is_buff_potion_whitelisted(potion_id: String) -> bool:
	if _gm.auto_buff_whitelist.is_empty():
		return true
	return _gm.auto_buff_whitelist.has(potion_id)


func toggle_buff_potion_whitelist(potion_id: String) -> void:
	if _gm.auto_buff_whitelist.is_empty():
		for entry: Dictionary in _gm.BUFF_POTION_CATALOG:
			var bid: String = str(entry.get("id", ""))
			if not bid.is_empty() and bid != potion_id:
				_gm.auto_buff_whitelist.append(bid)
	elif _gm.auto_buff_whitelist.has(potion_id):
		_gm.auto_buff_whitelist.erase(potion_id)
	else:
		_gm.auto_buff_whitelist.append(potion_id)
		if _gm.auto_buff_whitelist.size() >= _gm.BUFF_POTION_CATALOG.size():
			_gm.auto_buff_whitelist.clear()
	_gm.stats_changed.emit()
	_gm.save_game()


func get_total_potion_count() -> int:
	var total: int = 0
	for entry: Dictionary in _gm.inventory:
		var item: ItemData = entry["item"] as ItemData
		if item != null and item.item_type == ItemData.ItemType.CONSUMABLE and (item.heal_amount > 0.0 or item.heal_pct > 0.0):
			total += int(entry["count"])
	return total


func get_total_mana_potion_count() -> int:
	var total: int = 0
	for entry: Dictionary in _gm.inventory:
		var item: ItemData = entry["item"] as ItemData
		if item != null and item.item_type == ItemData.ItemType.CONSUMABLE and (item.mana_amount > 0.0 or item.mana_pct > 0.0):
			total += int(entry["count"])
	return total


func use_best_healing_potion() -> String:
	var max_hp: float = _gm.get_max_hp()
	if _gm.current_hp >= max_hp:
		return "Здоровье уже полное."

	var missing_hp: float = max_hp - _gm.current_hp
	var best_item: ItemData = null
	var best_score: float = INF

	for entry: Dictionary in _gm.inventory:
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

	return _gm.use_or_equip_item(best_item)


func use_best_mana_potion() -> String:
	var max_mp: float = _gm.get_max_mana()
	if _gm.current_mana >= max_mp:
		return "Мана уже полная."

	var missing_mp: float = max_mp - _gm.current_mana
	var best_item: ItemData = null
	var best_score: float = INF

	for entry: Dictionary in _gm.inventory:
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

	return _gm.use_or_equip_item(best_item)


func try_auto_use_potion(is_in_combat: bool = true) -> String:
	if not _gm.auto_potion_enabled:
		return ""
	if _gm.auto_hp_condition == "combat" and not is_in_combat:
		return ""
	var max_hp: float = _gm.get_max_hp()
	if _gm.current_hp <= 0.0 or max_hp <= 0.0:
		return ""
	var hp_ratio: float = float(_gm.auto_hp_threshold_pct) / 100.0
	if (_gm.current_hp / max_hp) >= hp_ratio:
		return ""
	if get_total_potion_count() <= 0:
		return ""
	return use_best_healing_potion()


func try_auto_use_mana_potion(is_in_combat: bool = true) -> String:
	if not _gm.auto_mana_enabled:
		return ""
	if _gm.auto_mana_condition == "combat" and not is_in_combat:
		return ""
	var max_mp: float = _gm.get_max_mana()
	if _gm.current_hp <= 0.0 or max_mp <= 0.0:
		return ""
	var mp_ratio: float = float(_gm.auto_mana_threshold_pct) / 100.0
	if (_gm.current_mana / max_mp) >= mp_ratio:
		return ""
	if get_total_mana_potion_count() <= 0:
		return ""
	return use_best_mana_potion()


func try_auto_use_buff_potions(is_in_combat: bool = true) -> String:
	if not _gm.auto_buff_enabled:
		return ""
	if _gm.current_hp <= 0.0:
		return ""
	if _gm.auto_buff_condition == "on_expire_combat" and not is_in_combat:
		return ""
	for entry: Dictionary in _gm.inventory:
		var item: ItemData = entry["item"] as ItemData
		var cnt: int = int(entry["count"])
		if item == null or cnt <= 0 or not item.is_buff_potion():
			continue
		if not is_buff_potion_whitelisted(item.id):
			continue
		var buff_key: String = item.buff_id if not item.buff_id.is_empty() else ("potion_" + item.id)
		if not _gm.has_active_buff(buff_key):
			return _gm.use_or_equip_item(item)
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
	for i: int in range(_gm.active_buffs.size()):
		if str(_gm.active_buffs[i]["id"]) == buff_key:
			_gm.active_buffs[i] = entry
			replaced = true
			break
	if not replaced:
		_gm.active_buffs.append(entry)
	_gm.buffs_changed.emit()
	_gm.stats_changed.emit()


func use_consumable_item(item: ItemData) -> String:
	if item.resets_claimed_difficulties:
		if _gm.dark_points_claimed_difficulties.is_empty():
			return "Отметки пройденных сложностей уже пусты — все 🌑 награды доступны."
		if _gm.remove_item(item, 1):
			var reset_res: Dictionary = _gm.reset_claimed_difficulties_rewards()
			return str(reset_res.get("message", ""))
		return "Не найден предмет в инвентаре."
	if _gm.is_potions_blocked_by_challenge():
		return "🏆 Испытание «Без зелий до Титана» блокирует использование зелий!"
	var has_heal: bool = item.heal_amount > 0.0 or item.heal_pct > 0.0
	var has_mana: bool = item.mana_amount > 0.0 or item.mana_pct > 0.0
	var has_buff: bool = item.is_buff_potion()
	var need_heal: bool = _gm.current_hp < _gm.get_max_hp()
	var need_mana: bool = _gm.current_mana < _gm.get_max_mana()

	if not has_buff:
		if has_heal and not has_mana and not need_heal:
			return "Здоровье уже полное."
		if has_mana and not has_heal and not need_mana:
			return "Мана уже полная."
		if has_heal and has_mana and not need_heal and not need_mana:
			return "Здоровье и мана уже полные."

	var saved_potion: bool = _gm.has_hero_class("alchemist") and randf() < 0.20
	var consumed: bool = true if saved_potion else _gm.remove_item(item, 1)
	if not consumed:
		return ""
	var parts: Array[String] = []
	var cauldron_bonus: float = 1.0 + _gm.get_skill_bonus("alchemy_cauldron")
	var alch_mult: float = 1.60 if _gm.has_hero_class("alchemist") else 1.0
	if has_heal:
		var heal_mult: float = maxf(0.25, 1.0 - _gm.get_curse_value("blood_tax")) * alch_mult * cauldron_bonus
		var raw_heal: float = item.heal_amount * heal_mult + _gm.get_max_hp() * item.heal_pct
		var healed: float = _gm.heal(raw_heal)
		_gm.player_healed.emit(healed)
		parts.append("+%s HP" % NumberFormatter.format_number(healed))
	if has_mana:
		var mana_mult: float = alch_mult * cauldron_bonus
		var raw_mana: float = item.mana_amount * mana_mult + _gm.get_max_mana() * item.mana_pct
		var restored: float = _gm.restore_mana(raw_mana)
		parts.append("+%s MP" % NumberFormatter.format_number(restored))
	if has_buff:
		var dur_scale: float = cauldron_bonus * (1.30 if _gm.has_hero_class("alchemist") else 1.0) * _gm.get_effect_duration_multiplier()
		apply_potion_buff(item, dur_scale)
		parts.append("бафф %.0fс" % (item.buff_duration * dur_scale))
	_gm.save_game()
	var suffix: String = " (⚗️ Зелье сохранено!)" if saved_potion else ""
	return "Использовано %s (%s)%s." % [
		item.get_display_name(),
		", ".join(parts),
		suffix,
	]
