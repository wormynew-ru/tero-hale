class_name ForgeService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func get_max_enchant_level() -> int:
	if _gm.has_hero_class("alchemist"):
		return _gm.ALCHEMIST_MAX_ENCHANT_LEVEL
	return _gm.MAX_ENCHANT_LEVEL


func get_quality_multiplier(quality_pct: int) -> float:
	return float(clampi(quality_pct, 50, 200)) / 100.0


func get_star_multiplier(star_level: int) -> float:
	return 1.0 + float(maxi(0, star_level - 1)) * 0.20


func get_equipped_slot_item(slot_type: ItemData.ItemType) -> ItemData:
	if slot_type == ItemData.ItemType.WEAPON:
		return _gm.equipped_weapon
	if slot_type == ItemData.ItemType.ARMOR:
		return _gm.equipped_armor
	if slot_type == ItemData.ItemType.OFFHAND:
		return _gm.equipped_offhand
	return null


func get_equipped_slot_quality(slot_type: ItemData.ItemType) -> int:
	if slot_type == ItemData.ItemType.WEAPON:
		return _gm.equipped_weapon_quality
	if slot_type == ItemData.ItemType.ARMOR:
		return _gm.equipped_armor_quality
	if slot_type == ItemData.ItemType.OFFHAND:
		return _gm.equipped_offhand_quality
	return 100


func get_equipped_slot_stars(slot_type: ItemData.ItemType) -> int:
	if slot_type == ItemData.ItemType.WEAPON:
		return _gm.equipped_weapon_stars
	if slot_type == ItemData.ItemType.ARMOR:
		return _gm.equipped_armor_stars
	if slot_type == ItemData.ItemType.OFFHAND:
		return _gm.equipped_offhand_stars
	return 1


func get_enchant_level(slot_type: ItemData.ItemType) -> int:
	if slot_type == ItemData.ItemType.WEAPON:
		return _gm.weapon_enchant_level
	if slot_type == ItemData.ItemType.ARMOR:
		return _gm.armor_enchant_level
	if slot_type == ItemData.ItemType.OFFHAND:
		return _gm.offhand_enchant_level
	return 0


func get_enchant_success_chance(current_lvl: int) -> float:
	var max_lvl: int = get_max_enchant_level()
	if current_lvl >= max_lvl:
		return 0.0
	var base_chance: float = clampf(95.0 - float(current_lvl) * (94.5 / 99.0), 0.5, 95.0)
	if _gm.has_hero_class("alchemist"):
		return clampf(base_chance * 1.6, 1.5, 98.0)
	return base_chance


func get_enchant_cost(current_lvl: int) -> float:
	var base_cost: float = 50.0 * pow(1.82, float(current_lvl))
	var mult: float = _gm.get_difficulty_price_mult() * (1.0 + _gm.get_curse_value("greedy_curse"))
	if _gm.has_dark_skill("blacksmith_brand"):
		mult *= 0.75
	if _gm.has_hero_class("alchemist"):
		mult *= 0.60
	return maxf(1.0, round(base_cost * mult))


func get_dark_enchant_level(slot_type: ItemData.ItemType) -> int:
	if slot_type == ItemData.ItemType.WEAPON:
		return _gm.dark_weapon_enchant_level
	if slot_type == ItemData.ItemType.ARMOR:
		return _gm.dark_armor_enchant_level
	if slot_type == ItemData.ItemType.OFFHAND:
		return _gm.dark_offhand_enchant_level
	return 0


func get_total_slot_enchant_level(slot_type: ItemData.ItemType) -> int:
	return get_enchant_level(slot_type) + get_dark_enchant_level(slot_type)


func get_enchant_power_multiplier(enchant_lvl: int) -> float:
	var per_level: float = 0.15 * (1.25 if _gm.has_dark_skill("blacksmith_brand") else 1.0)
	return 1.0 + float(enchant_lvl) * per_level


func get_equipped_stat_bonuses(slot_type: ItemData.ItemType) -> Dictionary:
	if _gm.is_equipment_disabled() or _gm.is_gear_blocked_by_challenge():
		return {"strength": 0, "agility": 0, "endurance": 0, "intellect": 0}
	var item: ItemData = get_equipped_slot_item(slot_type)
	if item == null:
		return {"strength": 0, "agility": 0, "endurance": 0, "intellect": 0}
	var run_elvl: int = get_enchant_level(slot_type)
	var dark_elvl: int = get_dark_enchant_level(slot_type)
	var total_elvl: int = run_elvl + dark_elvl
	var gear_scale: float = get_quality_multiplier(get_equipped_slot_quality(slot_type)) * get_star_multiplier(get_equipped_slot_stars(slot_type))
	var mult: float = get_enchant_power_multiplier(total_elvl) * gear_scale
	var flat_per_lvl: int = 2 if _gm.has_dark_skill("blacksmith_brand") else 1

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
	if _gm.is_equipment_disabled():
		return {"success": false, "message": "Класс Спирит не может использовать и ковать экипировку."}
	if _gm.is_gear_blocked_by_challenge():
		return {"success": false, "message": "Активное испытание запрещает экипировку и заточку."}
	var item: ItemData = get_equipped_slot_item(slot_type)
	if item == null:
		return {"success": false, "message": "Сначала экипируйте предмет в этот слот."}

	var current_lvl: int = get_enchant_level(slot_type)
	var max_lvl: int = get_max_enchant_level()
	if current_lvl >= max_lvl:
		return {"success": false, "message": "Достигнут максимальный уровень зачарования (+%d)." % max_lvl}

	var cost: float = get_enchant_cost(current_lvl)
	if _gm.gold < cost:
		return {
			"success": false,
			"message": "Нужно %s золота (у вас %s)." % [
				NumberFormatter.format_number(cost),
				NumberFormatter.format_number(_gm.gold),
			],
		}

	_gm.gold -= cost
	var chance: float = get_enchant_success_chance(current_lvl)
	var roll: float = randf() * 100.0
	var succeeded: bool = roll < chance

	if succeeded:
		var prev_max_hp: float = _gm.get_max_hp()
		var prev_max_mana: float = _gm.get_max_mana()
		if slot_type == ItemData.ItemType.WEAPON:
			_gm.weapon_enchant_level += 1
		elif slot_type == ItemData.ItemType.ARMOR:
			_gm.armor_enchant_level += 1
		elif slot_type == ItemData.ItemType.OFFHAND:
			_gm.offhand_enchant_level += 1

		_gm.mark_stats_dirty()
		var new_max_hp: float = _gm.get_max_hp()
		if new_max_hp > prev_max_hp:
			_gm.current_hp = minf(new_max_hp, _gm.current_hp + (new_max_hp - prev_max_hp))
		var new_max_mana: float = _gm.get_max_mana()
		if new_max_mana > prev_max_mana:
			_gm.current_mana = minf(new_max_mana, _gm.current_mana + (new_max_mana - prev_max_mana))
		var max_bar: float = _gm.get_max_barrier()
		_gm.current_barrier = 0.0 if _gm.has_hero_class("reflector") else minf(maxf(_gm.current_barrier, max_bar), max_bar)

		_gm.stats_changed.emit()
		_gm.hp_changed.emit(_gm.current_hp, new_max_hp)
		_gm.mana_changed.emit(_gm.current_mana, new_max_mana)
		_gm.barrier_changed.emit(_gm.current_barrier, max_bar)
		_gm.enchant_changed.emit()
		_gm.save_game()
		return {
			"success": true,
			"message": "✨ Успех! Слот усилен до +%d (шанс %.2f%%)." % [current_lvl + 1, chance],
		}

	_gm.stats_changed.emit()
	_gm.enchant_changed.emit()
	_gm.save_game()
	return {
		"success": false,
		"message": "💨 Неудача (шанс был %.2f%%). Уровень сохранён на +%d." % [chance, current_lvl],
	}


func get_dark_forge_enchant_chance(current_lvl: int) -> float:
	if current_lvl <= 0:
		return 25.0
	return maxf(15.0, 20.0 - float(current_lvl - 1) * 1.0)


func get_dark_forge_enchant_cost(current_lvl: int) -> int:
	return 4 + maxi(0, current_lvl) * 2


func try_dark_forge_enchant(slot_type: ItemData.ItemType) -> Dictionary:
	if _gm.is_equipment_disabled():
		return {"success": false, "message": "Класс Спирит не может использовать Тёмную заточку."}
	if _gm.is_gear_blocked_by_challenge():
		return {"success": false, "message": "Активное испытание запрещает экипировку."}
	var item: ItemData = get_equipped_slot_item(slot_type)
	if item == null:
		return {"success": false, "message": "Сначала экипируйте предмет в этот слот."}

	var current_lvl: int = get_dark_enchant_level(slot_type)
	var cost: int = get_dark_forge_enchant_cost(current_lvl)
	if _gm.dark_points < cost:
		return {"success": false, "message": "Нужно %d 🌑 Очков Тьмы (у вас %d 🌑)." % [cost, _gm.dark_points]}

	_gm.dark_points -= cost
	var chance: float = get_dark_forge_enchant_chance(current_lvl)
	var succeeded: bool = (randf() * 100.0) < chance

	if succeeded:
		var prev_max_hp: float = _gm.get_max_hp()
		var prev_max_mana: float = _gm.get_max_mana()
		if slot_type == ItemData.ItemType.WEAPON:
			_gm.dark_weapon_enchant_level += 1
		elif slot_type == ItemData.ItemType.ARMOR:
			_gm.dark_armor_enchant_level += 1
		elif slot_type == ItemData.ItemType.OFFHAND:
			_gm.dark_offhand_enchant_level += 1

		_gm.mark_stats_dirty()
		var new_max_hp: float = _gm.get_max_hp()
		if new_max_hp > prev_max_hp:
			_gm.current_hp = minf(new_max_hp, _gm.current_hp + (new_max_hp - prev_max_hp))
		var new_max_mana: float = _gm.get_max_mana()
		if new_max_mana > prev_max_mana:
			_gm.current_mana = minf(new_max_mana, _gm.current_mana + (new_max_mana - prev_max_mana))
		var max_bar: float = _gm.get_max_barrier()
		_gm.current_barrier = 0.0 if _gm.has_hero_class("reflector") else minf(maxf(_gm.current_barrier, max_bar), max_bar)

		_gm.stats_changed.emit()
		_gm.dark_skills_changed.emit()
		_gm.enchant_changed.emit()
		_gm.dark_forge_changed.emit()
		_gm.barrier_changed.emit(_gm.current_barrier, max_bar)
		_gm.hp_changed.emit(_gm.current_hp, new_max_hp)
		_gm.mana_changed.emit(_gm.current_mana, new_max_mana)
		_gm.save_game()
		return {
			"success": true,
			"message": "🔥 Тёмный успех! Вечная заточка слота повышена до 🌑+%d (шанс %.0f%%) — сохранится навсегда!" % [current_lvl + 1, chance],
		}

	_gm.stats_changed.emit()
	_gm.dark_skills_changed.emit()
	_gm.dark_forge_changed.emit()
	_gm.save_game()
	return {
		"success": false,
		"message": "💨 Пламя Тёмной кузни дрогнуло (шанс %.0f%%). Уровень сохранён на 🌑+%d." % [chance, current_lvl],
	}


func get_dark_forge_material_count(item_id: String) -> int:
	var item: ItemData = _gm.get_cached_item("res://resources/items/%s.tres" % item_id)
	if item == null:
		return 0
	return _gm.get_item_count_in_inventory(item)


func get_dark_forge_recipe(recipe_id: String) -> Dictionary:
	for r: Dictionary in SanctuaryAndForgeCatalog.DARK_FORGE_RECIPES:
		if str(r.get("id", "")) == recipe_id:
			return r
	return {}


func can_craft_dark_forge_recipe(recipe_id: String) -> bool:
	var r: Dictionary = get_dark_forge_recipe(recipe_id)
	if r.is_empty():
		return false
	if _gm.dark_points < int(r.get("dark_points", 0)):
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
	var r: Dictionary = get_dark_forge_recipe(recipe_id)
	if r.is_empty():
		return {"success": false, "message": "Рецепт не найден."}
	var need_dp: int = int(r.get("dark_points", 0))
	var need_ore: int = int(r.get("abyss_ore", 0))
	var need_page: int = int(r.get("ancient_page", 0))

	if _gm.dark_points < need_dp:
		return {"success": false, "message": "Недостаточно 🌑 Очков Тьмы (нужно %d, у вас %d)." % [need_dp, _gm.dark_points]}
	var ore_item: ItemData = _gm.get_cached_item("res://resources/items/abyss_ore.tres")
	var page_item: ItemData = _gm.get_cached_item("res://resources/items/ancient_page.tres")
	if need_ore > 0 and (ore_item == null or _gm.get_item_count_in_inventory(ore_item) < need_ore):
		return {"success": false, "message": "Недостаточно ⛏️ Руды Бездны (нужно %d)." % need_ore}
	if need_page > 0 and (page_item == null or _gm.get_item_count_in_inventory(page_item) < need_page):
		return {"success": false, "message": "Недостаточно 📜 Древних листов (нужно %d)." % need_page}

	var extra_consume: Array[Dictionary] = []
	var req_items: Variant = r.get("required_items", {})
	if req_items is Dictionary:
		for req_id_var: Variant in (req_items as Dictionary).keys():
			var req_id: String = str(req_id_var)
			var req_cnt: int = int((req_items as Dictionary)[req_id_var])
			var req_item: ItemData = _gm.get_cached_item("res://resources/items/%s.tres" % req_id)
			if req_item == null or _gm.get_item_count_in_inventory(req_item) < req_cnt:
				var title: String = req_item.get_display_name() if req_item != null else req_id
				return {"success": false, "message": "Нужен предмет в инвентаре: %s x%d." % [title, req_cnt]}
			extra_consume.append({"item": req_item, "count": req_cnt})

	var result_item: ItemData = _gm.get_cached_item(str(r.get("result_path", "")))
	if result_item == null:
		return {"success": false, "message": "Предмет рецепта повреждён."}

	_gm.dark_points -= need_dp
	if need_ore > 0 and ore_item != null:
		_gm.remove_item(ore_item, need_ore)
	if need_page > 0 and page_item != null:
		_gm.remove_item(page_item, need_page)
	for entry: Dictionary in extra_consume:
		_gm.remove_item(entry["item"] as ItemData, int(entry["count"]))

	var amt: int = maxi(1, int(r.get("amount", 1)))
	_gm.add_item(result_item, amt, true, 100, 1, false)
	_gm.dark_skills_changed.emit()
	_gm.dark_forge_changed.emit()
	_gm.stats_changed.emit()
	_gm.save_game()
	var eternal_note: String = " (Вечный — не сбрасывается между ранами!)" if bool(r.get("eternal", false)) else ""
	return {
		"success": true,
		"message": "🔥 Выковано: %s x%d%s" % [result_item.get_display_name(), amt, eternal_note],
	}
