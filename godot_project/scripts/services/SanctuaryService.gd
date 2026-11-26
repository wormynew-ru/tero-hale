class_name SanctuaryService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func is_alchemy_unlocked() -> bool:
	return _gm.max_unlocked_difficulty >= _gm.ALCHEMY_UNLOCK_DIFFICULTY


func get_crop_by_id(crop_id: String) -> CropData:
	if _gm._crops_by_id.has(crop_id):
		return _gm._crops_by_id[crop_id] as CropData
	return null


func get_garden_plot_count() -> int:
	var extra: int = 1 if _gm.is_skill_unlocked("herbal_mastery") else 0
	return maxi(_gm.BASE_GARDEN_PLOTS + extra, _gm.garden_plots.size())


func get_light_garden_plot_count() -> int:
	return maxi(_gm.BASE_LIGHT_GARDEN_PLOTS, _gm.light_garden_plots.size())


func is_garden_plot_accessible(plot_index: int) -> bool:
	var unlocked_cap: int = _gm.BASE_GARDEN_PLOTS + (1 if _gm.is_skill_unlocked("herbal_mastery") else 0)
	if plot_index < unlocked_cap:
		return true
	if plot_index < _gm.garden_plots.size() and str(_gm.garden_plots[plot_index].get("status", "empty")) != "empty":
		return true
	return false


func get_brewing_slot_count() -> int:
	var extra: int = 1 if _gm.is_skill_unlocked("master_brewer") else 0
	return maxi(_gm.BASE_BREWING_SLOTS + extra, _gm.brewing_slots.size())


func is_brewing_slot_accessible(slot_index: int) -> bool:
	var unlocked_cap: int = _gm.BASE_BREWING_SLOTS + (1 if _gm.is_skill_unlocked("master_brewer") else 0)
	if slot_index < unlocked_cap:
		return true
	if slot_index < _gm.brewing_slots.size() and str(_gm.brewing_slots[slot_index].get("state", "empty")) != "empty":
		return true
	return false


func make_empty_garden_plot() -> Dictionary:
	return {
		"crop_id": "",
		"status": "empty",
		"elapsed": 0.0,
		"boss_kills": 0,
	}


func make_empty_light_garden_plot() -> Dictionary:
	return {
		"crop_id": "",
		"status": "empty",
		"elapsed": 0.0,
	}


func make_empty_brewing_slot() -> Dictionary:
	return {
		"state": "empty",
		"brew_id": "",
		"brew_title": "",
		"brew_emoji": "⚗️",
		"stage": 0,
		"elapsed": 0.0,
		"duration": 0.0,
		"can_collect": false,
		"result_item_path": "",
		"result_count": 0,
		"pending_next_id": "",
		"pending_title": "",
		"pending_emoji": "",
		"pending_stage": 0,
		"pending_can_collect": false,
		"pending_result_item_path": "",
		"pending_result_count": 0,
	}


func ensure_sanctuary_slots() -> void:
	var target_plots: int = _gm.BASE_GARDEN_PLOTS + (1 if _gm.is_skill_unlocked("herbal_mastery") else 0)
	while _gm.garden_plots.size() < target_plots:
		_gm.garden_plots.append(make_empty_garden_plot())
	while _gm.light_garden_plots.size() < _gm.BASE_LIGHT_GARDEN_PLOTS:
		_gm.light_garden_plots.append(make_empty_light_garden_plot())
	if _gm.light_garden_plots.size() > _gm.BASE_LIGHT_GARDEN_PLOTS:
		_gm.light_garden_plots.resize(_gm.BASE_LIGHT_GARDEN_PLOTS)
	var target_cauldrons: int = _gm.BASE_BREWING_SLOTS + (1 if _gm.is_skill_unlocked("master_brewer") else 0)
	while _gm.brewing_slots.size() < target_cauldrons:
		_gm.brewing_slots.append(make_empty_brewing_slot())
	for sk: String in _gm.SPIRIT_KEYS:
		if not _gm.spirit_training_levels.has(sk):
			_gm.spirit_training_levels[sk] = 0


func get_garden_growth_speed_mult() -> float:
	return 1.0 + _gm.get_skill_bonus("garden_mastery")


func get_seed_drop_multiplier() -> float:
	var mult: float = 1.0
	if _gm.has_hero_class("alchemist"):
		mult *= 2.0
	mult *= (1.0 + _gm.get_dark_bonus("seed_drop_mult"))
	return mult


func process_sanctuary(delta: float) -> void:
	var garden_dirty: bool = false
	var brew_dirty: bool = false
	var any_active_timer: bool = false
	var garden_mult: float = get_garden_growth_speed_mult()
	var brew_mult: float = _gm.get_brewing_speed_mult()

	for i: int in range(_gm.garden_plots.size()):
		var plot: Dictionary = _gm.garden_plots[i]
		if str(plot.get("status", "empty")) != "growing":
			continue
		var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
		if crop == null or crop.is_boss_kill_crop():
			continue
		any_active_timer = true
		var next_elapsed: float = float(plot.get("elapsed", 0.0)) + delta * garden_mult
		if next_elapsed >= crop.grow_seconds:
			plot["elapsed"] = crop.grow_seconds
			plot["status"] = "ready"
			garden_dirty = true
		else:
			plot["elapsed"] = next_elapsed

	for i: int in range(_gm.light_garden_plots.size()):
		var lplot: Dictionary = _gm.light_garden_plots[i]
		if str(lplot.get("status", "empty")) != "growing":
			continue
		var lcrop: CropData = get_crop_by_id(str(lplot.get("crop_id", "")))
		if lcrop == null:
			continue
		any_active_timer = true
		var next_l_elapsed: float = float(lplot.get("elapsed", 0.0)) + delta * garden_mult
		if next_l_elapsed >= lcrop.grow_seconds:
			lplot["elapsed"] = lcrop.grow_seconds
			lplot["status"] = "ready"
			garden_dirty = true
		else:
			lplot["elapsed"] = next_l_elapsed

	for i: int in range(_gm.brewing_slots.size()):
		var cauldron: Dictionary = _gm.brewing_slots[i]
		if str(cauldron.get("state", "empty")) != "brewing":
			continue
		any_active_timer = true
		var dur: float = maxf(0.1, float(cauldron.get("duration", 10.0)))
		var next_elapsed: float = float(cauldron.get("elapsed", 0.0)) + delta * brew_mult
		if next_elapsed >= dur:
			cauldron["state"] = "ready"
			cauldron["brew_id"] = str(cauldron.get("pending_next_id", ""))
			cauldron["brew_title"] = str(cauldron.get("pending_title", ""))
			cauldron["brew_emoji"] = str(cauldron.get("pending_emoji", "⚗️"))
			cauldron["stage"] = int(cauldron.get("pending_stage", 1))
			cauldron["can_collect"] = bool(cauldron.get("pending_can_collect", false))
			cauldron["result_item_path"] = str(cauldron.get("pending_result_item_path", ""))
			cauldron["result_count"] = int(cauldron.get("pending_result_count", 0))
			cauldron["elapsed"] = 0.0
			cauldron["duration"] = 0.0
			brew_dirty = true
		else:
			cauldron["elapsed"] = next_elapsed

	var exp_dirty: bool = false
	for i: int in range(_gm.pet_expeditions.size()):
		var pet_exp: Dictionary = _gm.pet_expeditions[i]
		if bool(pet_exp.get("completed", false)):
			continue
		any_active_timer = true
		var dur: float = maxf(1.0, float(pet_exp.get("duration", 900.0)))
		var next_elapsed: float = float(pet_exp.get("elapsed", 0.0)) + delta
		if next_elapsed >= dur:
			pet_exp["elapsed"] = dur
			pet_exp["completed"] = true
			exp_dirty = true
		else:
			pet_exp["elapsed"] = next_elapsed

	if garden_dirty:
		_gm.garden_changed.emit()
		_gm.save_game()
	if brew_dirty:
		_gm.brewing_changed.emit()
		_gm.save_game()
	if exp_dirty:
		_gm.pets_changed.emit()
		_gm.save_game()

	if any_active_timer:
		_gm._sanctuary_ui_sync_timer += delta
		if _gm._sanctuary_ui_sync_timer >= 0.25:
			_gm._sanctuary_ui_sync_timer = 0.0
			_gm.garden_changed.emit()
			_gm.brewing_changed.emit()
			if not _gm.pet_expeditions.is_empty():
				_gm.pets_changed.emit()


func roll_rare_seed_drops(enemy: EnemyData) -> void:
	if enemy == null or _gm.crops.is_empty():
		return
	var is_final_boss: bool = (enemy.id == _gm.FINAL_BOSS_ID)
	var is_boss_enemy: bool = (is_final_boss or enemy.id == _gm.CURSE_WARDEN_ID)
	var mult: float = get_seed_drop_multiplier()
	for crop: CropData in _gm.crops:
		if crop == null or enemy.xp_reward < crop.min_enemy_xp:
			continue
		if crop.final_boss_only and not is_final_boss:
			continue
		var raw_chance: float = crop.boss_drop_chance if (is_boss_enemy and crop.boss_drop_chance > 0.0) else crop.base_drop_chance
		var effective_chance: float = raw_chance if crop.final_boss_only else (raw_chance * mult)
		if effective_chance > 0.0 and randf() <= effective_chance:
			var seed_item: ItemData = _gm.get_cached_item(crop.seed_item_path)
			if seed_item != null:
				_gm.add_item(seed_item, 1, true)


func on_final_boss_killed_for_garden() -> void:
	var changed: bool = false
	var any_became_ready: bool = false
	for i: int in range(_gm.garden_plots.size()):
		var plot: Dictionary = _gm.garden_plots[i]
		if str(plot.get("status", "empty")) != "growing":
			continue
		var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
		if crop == null or not crop.is_boss_kill_crop():
			continue
		var next_kills: int = int(plot.get("boss_kills", 0)) + 1
		plot["boss_kills"] = next_kills
		changed = true
		if next_kills >= crop.required_final_boss_kills:
			plot["status"] = "ready"
			any_became_ready = true
	if changed:
		_gm.garden_changed.emit()
		if any_became_ready:
			_gm.save_game()


func plant_seed_on_plot(plot_index: int, seed_item: ItemData) -> Dictionary:
	if not is_alchemy_unlocked():
		return {"success": false, "message": "Тёмный сад откроется после победы на 10-й сложности."}
	if seed_item == null or seed_item.item_type != ItemData.ItemType.SEED:
		return {"success": false, "message": "Выберите подходящие семена."}
	ensure_sanctuary_slots()
	if plot_index < 0 or plot_index >= _gm.garden_plots.size() or not is_garden_plot_accessible(plot_index):
		return {"success": false, "message": "Эта грядка Тёмного сада ещё не открыта."}
	var plot: Dictionary = _gm.garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "empty":
		return {"success": false, "message": "На этой грядке уже растёт культура."}
	var crop: CropData = get_crop_by_id(seed_item.seed_crop_id)
	if crop == null:
		return {"success": false, "message": "Неизвестная культура для этих семян."}
	if crop.is_light_crop():
		return {"success": false, "message": "Это семя Светлого сада — высаживайте его на грядках ☀️ Светлого сада!"}
	if not _gm.remove_item(seed_item, 1):
		return {"success": false, "message": "Недостаточно семян в рюкзаке."}

	_gm.garden_plots[plot_index] = {
		"crop_id": crop.id,
		"status": "growing",
		"elapsed": 0.0,
		"boss_kills": 0,
	}
	_gm.garden_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"message": "%s Посажено в Тёмном саду (грядка #%d): %s!" % [crop.icon_emoji, plot_index + 1, crop.crop_name],
	}


func plant_seed_in_first_empty_plot(seed_item: ItemData) -> Dictionary:
	if not is_alchemy_unlocked():
		return {"success": false, "message": "Тёмный сад откроется после победы на 10-й сложности."}
	ensure_sanctuary_slots()
	for i: int in range(_gm.garden_plots.size()):
		if is_garden_plot_accessible(i) and str(_gm.garden_plots[i].get("status", "empty")) == "empty":
			return plant_seed_on_plot(i, seed_item)
	return {"success": false, "message": "Все доступные грядки Тёмного сада заняты!"}


func harvest_garden_plot(plot_index: int) -> Dictionary:
	if not is_alchemy_unlocked():
		return {"success": false, "message": "Тёмный сад открывается после 10-й сложности."}
	if plot_index < 0 or plot_index >= _gm.garden_plots.size():
		return {"success": false, "message": "Грядка не найдена."}
	var plot: Dictionary = _gm.garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "ready":
		return {"success": false, "message": "Урожай ещё не созрел."}
	var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
	if crop == null:
		_gm.garden_plots[plot_index] = make_empty_garden_plot()
		_gm.garden_changed.emit()
		return {"success": false, "message": "Культура повреждена."}

	var yield_amt: int = randi_range(crop.harvest_min, maxi(crop.harvest_min, crop.harvest_max))
	var harvest_item: ItemData = _gm.get_cached_item(crop.harvest_item_path)
	if harvest_item != null:
		_gm.add_item(harvest_item, yield_amt, true)

	_gm.garden_plots[plot_index] = make_empty_garden_plot()
	_gm.garden_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"message": "%s Собрано с Тёмного сада (грядка #%d): %s x%d!" % [
			crop.icon_emoji,
			plot_index + 1,
			harvest_item.item_name if harvest_item != null else crop.crop_name,
			yield_amt,
		],
	}


func can_instant_grow_plot(plot_index: int) -> bool:
	if plot_index < 0 or plot_index >= _gm.garden_plots.size():
		return false
	var plot: Dictionary = _gm.garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "growing":
		return false
	var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
	if crop == null or not crop.has_instant_grow_feed():
		return false
	for item_id_var: Variant in crop.instant_grow_feed_items.keys():
		var req_id: String = str(item_id_var)
		var req_cnt: int = int(crop.instant_grow_feed_items[item_id_var])
		var req_item: ItemData = _gm.get_cached_item("res://resources/items/%s.tres" % req_id)
		if req_item == null or _gm.get_item_count_in_inventory(req_item) < req_cnt:
			return false
	return true


func feed_growing_crop_for_instant_growth(plot_index: int) -> Dictionary:
	if plot_index < 0 or plot_index >= _gm.garden_plots.size():
		return {"success": false, "message": "Грядка не найдена."}
	var plot: Dictionary = _gm.garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "growing":
		return {"success": false, "message": "Культура уже созрела или грядка пуста."}
	var crop: CropData = get_crop_by_id(str(plot.get("crop_id", "")))
	if crop == null or not crop.has_instant_grow_feed():
		return {"success": false, "message": "Эту культуру нельзя ускорить подкормкой духов."}

	var to_consume: Array[Dictionary] = []
	for item_id_var: Variant in crop.instant_grow_feed_items.keys():
		var req_id: String = str(item_id_var)
		var req_cnt: int = int(crop.instant_grow_feed_items[item_id_var])
		var req_item: ItemData = _gm.get_cached_item("res://resources/items/%s.tres" % req_id)
		if req_item == null:
			return {"success": false, "message": "Не найден ресурс растения %s." % req_id}
		var owned_cnt: int = _gm.get_item_count_in_inventory(req_item)
		if owned_cnt < req_cnt:
			return {"success": false, "message": "Нужно %s %s x%d (у вас %d)." % [req_item.icon_emoji, req_item.item_name, req_cnt, owned_cnt]}
		to_consume.append({"item": req_item, "count": req_cnt})

	for entry: Dictionary in to_consume:
		_gm.remove_item(entry["item"] as ItemData, int(entry["count"]))

	plot["elapsed"] = crop.grow_seconds
	plot["status"] = "ready"
	_gm.garden_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"message": "🌟 Духи вкусили базовые растения Светлого сада — %s %s на грядке #%d созрел МОМЕНТАЛЬНО!" % [
			crop.icon_emoji,
			crop.crop_name,
			plot_index + 1,
		],
	}
