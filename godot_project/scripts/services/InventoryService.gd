class_name InventoryService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func get_entry_quality(entry: Dictionary) -> int:
	return clampi(int(entry.get("quality_pct", 100)), 80, 125)


func get_entry_stars(entry: Dictionary) -> int:
	return clampi(int(entry.get("star_level", 1)), 1, 5)


func set_auto_salvage_settings(mode: String, min_quality: int) -> void:
	if mode == "sell" or mode == "salvage":
		_gm.auto_salvage_mode = mode
	else:
		_gm.auto_salvage_mode = "off"
	_gm.auto_salvage_min_quality = clampi(min_quality, 80, 125)
	_gm.inventory_changed.emit()
	_gm.save_game()


func add_item(item: ItemData, amount: int = 1, notify: bool = true, quality_pct: int = 100, star_level: int = 1, from_loot: bool = false) -> void:
	if item == null or amount <= 0:
		return
	var is_gear: bool = item.is_equipment()
	var final_q: int = randi_range(80, 125) if (from_loot and is_gear) else (clampi(quality_pct, 80, 125) if is_gear else 100)
	var final_s: int = clampi(star_level, 1, 5) if is_gear else 1

	if from_loot and is_gear and not item.is_dark_forged and _gm.auto_salvage_mode != "off" and final_q < _gm.auto_salvage_min_quality:
		if _gm.auto_salvage_mode == "sell":
			var sell_g: float = maxf(1.0, round(_gm.get_item_sell_value(item) * _gm.get_quality_multiplier(final_q) * float(amount)))
			_gm.add_gold(sell_g)
			return
		elif _gm.auto_salvage_mode == "salvage":
			_gm.abyss_ore_shards += amount
			var forged_ores: int = floori(float(_gm.abyss_ore_shards) / 10.0)
			if forged_ores > 0:
				_gm.abyss_ore_shards -= forged_ores * 10
				var ore_item: ItemData = _gm.get_cached_item("res://resources/items/abyss_ore.tres")
				if ore_item != null:
					add_item(ore_item, forged_ores, true, 100, 1, false)
			_gm.inventory_changed.emit()
			_gm.stats_changed.emit()
			return

	if item.item_type == ItemData.ItemType.AMMO and _gm.equipped_ammo != null and _gm.equipped_ammo.id == item.id and not _gm.is_equipment_disabled():
		_gm.equipped_ammo_count += amount
		_gm.inventory_changed.emit()
		_gm.stats_changed.emit()
		if notify:
			_gm.item_acquired.emit(item, amount)
		return
	for entry: Dictionary in _gm.inventory:
		var existing: ItemData = entry["item"] as ItemData
		if existing != null and existing.id == item.id:
			if not is_gear or (get_entry_quality(entry) == final_q and get_entry_stars(entry) == final_s):
				entry["count"] = int(entry["count"]) + amount
				_gm.inventory_changed.emit()
				if notify:
					_gm.item_acquired.emit(item, amount)
				return
	_gm.inventory.append({"item": item, "count": amount, "quality_pct": final_q, "star_level": final_s})
	_gm.inventory_changed.emit()
	if notify:
		_gm.item_acquired.emit(item, amount)


func remove_item(item: ItemData, amount: int = 1, quality_pct: int = -1, star_level: int = -1) -> bool:
	if item == null or amount <= 0:
		return false
	for i: int in range(_gm.inventory.size()):
		var entry: Dictionary = _gm.inventory[i]
		var existing: ItemData = entry["item"] as ItemData
		if existing != null and existing.id == item.id:
			if quality_pct >= 0 and get_entry_quality(entry) != quality_pct:
				continue
			if star_level >= 1 and get_entry_stars(entry) != star_level:
				continue
			var cnt: int = int(entry["count"])
			if cnt < amount:
				return false
			var remaining: int = cnt - amount
			if remaining <= 0:
				_gm.inventory.remove_at(i)
			else:
				entry["count"] = remaining
			_gm.inventory_changed.emit()
			return true
	return false


func get_item_count_in_inventory(item: ItemData) -> int:
	if item == null:
		return 0
	var total: int = 0
	for entry: Dictionary in _gm.inventory:
		var existing: ItemData = entry["item"] as ItemData
		if existing != null and existing.id == item.id:
			total += int(entry["count"])
	return total


func get_merge_candidates() -> Array[Dictionary]:
	var buckets: Dictionary = {}
	for entry: Dictionary in _gm.inventory:
		var it: ItemData = entry["item"] as ItemData
		if it == null or not it.is_equipment():
			continue
		var stars: int = get_entry_stars(entry)
		if stars >= 5:
			continue
		var key: String = "%s|%d" % [it.id, stars]
		if not buckets.has(key):
			buckets[key] = {"item": it, "star_level": stars, "total": 0, "max_quality": 80}
		var b: Dictionary = buckets[key] as Dictionary
		b["total"] = int(b["total"]) + int(entry["count"])
		b["max_quality"] = maxi(int(b["max_quality"]), get_entry_quality(entry))
	var res: Array[Dictionary] = []
	for k: Variant in buckets.keys():
		var b: Dictionary = buckets[k] as Dictionary
		if int(b["total"]) >= 2:
			res.append(b)
	return res


func merge_duplicate_item(item_id: String, star_level: int) -> Dictionary:
	if star_level < 1 or star_level >= 5:
		return {"success": false, "message": "Максимальный уровень слияния: ★5."}
	var matching: Array[Dictionary] = []
	var total_cnt: int = 0
	var target_item: ItemData = null
	var best_q: int = 80
	for entry: Dictionary in _gm.inventory:
		var it: ItemData = entry["item"] as ItemData
		if it != null and it.id == item_id and get_entry_stars(entry) == star_level:
			matching.append(entry)
			total_cnt += int(entry["count"])
			target_item = it
			best_q = maxi(best_q, get_entry_quality(entry))
	if target_item == null or total_cnt < 2:
		return {"success": false, "message": "Нужно минимум 2 дубликата одного ★ уровня."}

	matching.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return get_entry_quality(a) < get_entry_quality(b)
	)
	var consumed: int = 0
	for m: Dictionary in matching:
		var q: int = get_entry_quality(m)
		var avail: int = int(m["count"])
		var take: int = mini(2 - consumed, avail)
		if take > 0 and remove_item(target_item, take, q, star_level):
			consumed += take
		if consumed >= 2:
			break
	if consumed < 2:
		return {"success": false, "message": "Не удалось объединить дубликаты."}

	var next_star: int = star_level + 1
	add_item(target_item, 1, true, best_q, next_star, false)
	_gm.save_game()
	return {
		"success": true,
		"message": "⭐ Слияние! %s улучшен до ★%d (%d%% кач.)!" % [target_item.get_display_name(), next_star, best_q],
	}


func sell_item(item: ItemData, amount: int = 1, quality_pct: int = -1, star_level: int = -1) -> String:
	if item == null or amount <= 0:
		return ""
	var use_q: int = quality_pct
	var use_s: int = star_level
	if use_q < 0 or use_s < 1:
		for entry: Dictionary in _gm.inventory:
			var ex: ItemData = entry["item"] as ItemData
			if ex != null and ex.id == item.id:
				use_q = get_entry_quality(entry)
				use_s = get_entry_stars(entry)
				break
	if not remove_item(item, amount, quality_pct, star_level):
		return ""
	var gear_scale: float = (_gm.get_quality_multiplier(use_q) * _gm.get_star_multiplier(use_s)) if item.is_equipment() else 1.0
	var total_gold: float = maxf(1.0, round(_gm.get_item_sell_value(item) * gear_scale)) * float(amount)
	_gm.add_gold(total_gold)
	_gm.save_game()
	return "Продано %s x%d (+%s з.)." % [
		item.get_display_name(),
		amount,
		NumberFormatter.format_number(total_gold),
	]


func buy_item(item: ItemData) -> String:
	if item == null:
		return ""
	var price: float = _gm.get_item_buy_price(item)
	if _gm.gold < price:
		return "Недостаточно золота для покупки %s." % item.get_display_name()
	_gm.gold -= price
	var pack_amt: int = maxi(1, item.shop_pack_amount)
	if item.item_type == ItemData.ItemType.AMMO and _gm.equipped_ammo == null and not _gm.is_equipment_disabled():
		_gm.equipped_ammo = item
		_gm.equipped_ammo_count = pack_amt
		_gm.inventory_changed.emit()
	else:
		add_item(item, pack_amt, false)
	_gm.stats_changed.emit()
	_gm.save_game()
	return "Куплено: %s x%d за %s з." % [
		item.get_display_name(),
		pack_amt,
		NumberFormatter.format_number(price),
	]


func get_dark_shop_item_price(item: ItemData) -> int:
	if item == null:
		return 1
	return maxi(1, item.dark_shop_coin_price)


func buy_dark_shop_item(item: ItemData) -> Dictionary:
	if item == null:
		return {"success": false, "message": "Товар не найден."}
	var price: int = get_dark_shop_item_price(item)
	if _gm.dark_shop_coins < price:
		return {
			"success": false,
			"message": "Недостаточно монет Тёмного магазина (нужно %d 🪙, есть %d)." % [price, _gm.dark_shop_coins],
		}
	_gm.dark_shop_coins -= price
	var pack_amt: int = maxi(1, item.shop_pack_amount)
	add_item(item, pack_amt, false)
	_gm.dark_shop_changed.emit()
	_gm.stats_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"message": "✅ Куплено: %s x%d за %d 🪙! (Внимание: неиспользованные расходники пропадут при Новом ране)" % [
			item.get_display_name(),
			pack_amt,
			price,
		],
	}


func use_or_equip_item(item: ItemData, quality_pct: int = -1, star_level: int = -1) -> String:
	if item == null:
		return ""
	match item.item_type:
		ItemData.ItemType.CONSUMABLE:
			return _gm.potion_service.use_consumable_item(item)
		ItemData.ItemType.SEED:
			var seed_crop: CropData = _gm.get_crop_by_id(item.seed_crop_id)
			var plant_res: Dictionary = _gm.plant_light_seed_in_first_empty_plot(item) if (seed_crop != null and seed_crop.is_light_crop()) else _gm.plant_seed_in_first_empty_plot(item)
			return str(plant_res.get("message", ""))
		ItemData.ItemType.HARVEST:
			if item.garden_category == "light":
				return "Светлое растение %s используется для дрессировки путников (пряник) или подкормки духов (Убежище)." % item.get_display_name()
			if item.id == "spirit_primordial_harvest":
				return "Сакральный плод %s используется для дрессировки духов класса Спирит в Убежище." % item.get_display_name()
			return "Урожай %s используется в котле зельеварения Убежища (или продаётся в лавке)." % item.get_display_name()
		ItemData.ItemType.MATERIAL:
			return "Ресурс Шахты %s используется в 🔥 Тёмной кузне для ковки вечного снаряжения и древних книг (не сбрасывается между ранами)." % item.get_display_name()
		ItemData.ItemType.WEAPON, ItemData.ItemType.ARMOR, ItemData.ItemType.OFFHAND:
			return _gm.loadout_service.equip_gear_item(item, quality_pct, star_level)
		ItemData.ItemType.AMMO:
			return _gm.loadout_service.equip_ammo_item(item)
	return ""
