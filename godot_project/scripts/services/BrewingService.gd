class_name BrewingService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func plant_light_seed_on_plot(plot_index: int, seed_item: ItemData) -> Dictionary:
	if seed_item == null or seed_item.item_type != ItemData.ItemType.SEED:
		return {"success": false, "message": "Выберите подходящие семена Светлого сада."}
	_gm._ensure_sanctuary_slots()
	if plot_index < 0 or plot_index >= _gm.light_garden_plots.size():
		return {"success": false, "message": "Грядка Светлого сада не найдена."}
	var plot: Dictionary = _gm.light_garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "empty":
		return {"success": false, "message": "На этой грядке Светлого сада уже растёт растение."}
	var crop: CropData = _gm.get_crop_by_id(seed_item.seed_crop_id)
	if crop == null or not crop.is_light_crop():
		return {"success": false, "message": "Сюда можно сажать только простые растения ☀️ Светлого сада!"}
	if not _gm.remove_item(seed_item, 1):
		return {"success": false, "message": "Недостаточно семян в рюкзаке."}

	_gm.light_garden_plots[plot_index] = {
		"crop_id": crop.id,
		"status": "growing",
		"elapsed": 0.0,
	}
	_gm.garden_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"message": "%s Посажено в Светлый сад (слот #%d): %s!" % [crop.icon_emoji, plot_index + 1, crop.crop_name],
	}


func plant_light_seed_in_first_empty_plot(seed_item: ItemData) -> Dictionary:
	_gm._ensure_sanctuary_slots()
	for i: int in range(_gm.light_garden_plots.size()):
		if str(_gm.light_garden_plots[i].get("status", "empty")) == "empty":
			return plant_light_seed_on_plot(i, seed_item)
	return {"success": false, "message": "Все 3 грядки Светлого сада заняты!"}


func harvest_light_garden_plot(plot_index: int) -> Dictionary:
	_gm._ensure_sanctuary_slots()
	if plot_index < 0 or plot_index >= _gm.light_garden_plots.size():
		return {"success": false, "message": "Грядка Светлого сада не найдена."}
	var plot: Dictionary = _gm.light_garden_plots[plot_index]
	if str(plot.get("status", "empty")) != "ready":
		return {"success": false, "message": "Растение ещё не выросло."}
	var crop: CropData = _gm.get_crop_by_id(str(plot.get("crop_id", "")))
	if crop == null:
		_gm.light_garden_plots[plot_index] = _gm.sanctuary_service.make_empty_light_garden_plot()
		_gm.garden_changed.emit()
		return {"success": false, "message": "Растение испорчено."}

	var yield_amt: int = randi_range(crop.harvest_min, maxi(crop.harvest_min, crop.harvest_max))
	var harvest_item: ItemData = _gm.get_cached_item(crop.harvest_item_path)
	if harvest_item != null:
		_gm.add_item(harvest_item, yield_amt, true)

	_gm.light_garden_plots[plot_index] = _gm.sanctuary_service.make_empty_light_garden_plot()
	_gm.garden_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"message": "%s Собрано из Светлого сада (#%d): %s x%d (для пряников и подкормки духов)!" % [
			crop.icon_emoji,
			plot_index + 1,
			harvest_item.item_name if harvest_item != null else crop.crop_name,
			yield_amt,
		],
	}


func can_lure_pet_from_light_garden() -> bool:
	_gm._ensure_sanctuary_slots()
	if _gm.light_garden_plots.size() < _gm.BASE_LIGHT_GARDEN_PLOTS:
		return false
	for i: int in range(_gm.BASE_LIGHT_GARDEN_PLOTS):
		if str(_gm.light_garden_plots[i].get("status", "empty")) != "ready":
			return false
	return true


func lure_pet_from_light_garden() -> Dictionary:
	_gm._ensure_sanctuary_slots()
	if not can_lure_pet_from_light_garden():
		return {"success": false, "withered": false, "duplicate": false, "message": "Чтобы приманить путника, должны созреть все 3 грядки Светлого сада!"}

	var planted_pattern: Array[String] = []
	for i: int in range(_gm.BASE_LIGHT_GARDEN_PLOTS):
		planted_pattern.append(str(_gm.light_garden_plots[i].get("crop_id", "")))

	var matched_pet_id: String = ""
	for recipe: Dictionary in _gm.PET_LURE_RECIPES:
		var pat: Array = recipe.get("pattern", []) as Array
		if pat.size() == _gm.BASE_LIGHT_GARDEN_PLOTS and str(pat[0]) == planted_pattern[0] and str(pat[1]) == planted_pattern[1] and str(pat[2]) == planted_pattern[2]:
			matched_pet_id = str(recipe.get("pet_id", ""))
			break

	for i: int in range(_gm.BASE_LIGHT_GARDEN_PLOTS):
		_gm.light_garden_plots[i] = _gm.sanctuary_service.make_empty_light_garden_plot()

	if matched_pet_id.is_empty():
		_gm.garden_changed.emit()
		_gm.save_game()
		return {
			"success": false,
			"withered": true,
			"duplicate": false,
			"message": "🥀 На эту высадку никто не откликнулся — ничего не произошло, растения на 3 грядках завяли.",
		}

	var pet: PetData = _gm.get_pet_by_id(matched_pet_id)
	if _gm.has_pet_owned(matched_pet_id):
		_gm.garden_changed.emit()
		_gm.save_game()
		var pet_title: String = "%s %s" % [pet.icon_emoji, pet.pet_name] if pet != null else matched_pet_id
		return {
			"success": false,
			"withered": true,
			"duplicate": true,
			"message": "🥀 На аромат заглянул %s, но этот путник уже приручён (повторка) — ничего не произошло, растения на 3 грядках завяли." % pet_title,
		}

	_gm.owned_pet_ids.append(matched_pet_id)
	if _gm.equipped_pet_id.is_empty():
		_gm.equipped_pet_id = matched_pet_id
	_gm.pets_changed.emit()
	_gm.garden_changed.emit()
	_gm.stats_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"withered": false,
		"duplicate": false,
		"message": "🐾 Чудо Светлого сада! На высадку прибежал и приручился %s %s!" % [
			pet.icon_emoji if pet != null else "🐾",
			pet.pet_name if pet != null else matched_pet_id,
		],
	}


func get_spirit_training_level(spirit_key: String) -> int:
	return maxi(0, int(_gm.spirit_training_levels.get(spirit_key, 0)))


func get_spirit_power_multiplier(spirit_key: String) -> float:
	return 1.0 + float(get_spirit_training_level(spirit_key)) * 0.15


func get_spirit_speed_multiplier(spirit_key: String) -> float:
	return 1.0 + float(get_spirit_training_level(spirit_key)) * 0.03


func train_spirit(spirit_key: String) -> Dictionary:
	if not _gm.SPIRIT_KEYS.has(spirit_key):
		return {"success": false, "message": "Неизвестный дух природы."}
	if not _gm.has_hero_class("spirit"):
		return {"success": false, "message": "Дрессировка духов доступна только классу 🌿 Спирит (Сл.50+)."}
	var fruit_item: ItemData = _gm.get_cached_item("res://resources/items/spirit_primordial_harvest.tres")
	if fruit_item == null or not _gm.remove_item(fruit_item, 1):
		return {"success": false, "message": "Нужен 🌟 Плод первоцвета духов (семя падает с 0.03% шансом ТОЛЬКО с Вечного титана)."}

	var next_lvl: int = get_spirit_training_level(spirit_key) + 1
	_gm.spirit_training_levels[spirit_key] = next_lvl
	_gm.mark_stats_dirty()
	_gm.stats_changed.emit()
	_gm.garden_changed.emit()
	_gm.save_game()

	var spirit_titles: Dictionary = {
		"fire": "🔥 Дух Огня",
		"wind": "🌪️ Дух Ветра",
		"forest": "🌿 Дух Леса",
		"earth": "🪨 Дух Земли",
	}
	return {
		"success": true,
		"message": "🌟 %s надрессирован до Ур.%d (+%d%% сила, +%d%% скорость)!" % [
			str(spirit_titles.get(spirit_key, spirit_key)),
			next_lvl,
			next_lvl * 15,
			next_lvl * 3,
		],
	}


func get_brewing_speed_mult() -> float:
	var mult: float = 1.0
	if _gm.has_hero_class("alchemist"):
		mult *= 2.0
	mult *= (1.0 + _gm.get_dark_bonus("brew_speed_mult"))
	return mult


func start_brewing_water(slot_index: int) -> Dictionary:
	if not _gm.is_alchemy_unlocked():
		return {"success": false, "message": "Зельеварение открывается после 10-й сложности."}
	_gm._ensure_sanctuary_slots()
	if slot_index < 0 or slot_index >= _gm.brewing_slots.size() or not _gm.is_brewing_slot_accessible(slot_index):
		return {"success": false, "message": "Этот котёл ещё не открыт."}
	var cauldron: Dictionary = _gm.brewing_slots[slot_index]
	var st: String = str(cauldron.get("state", "empty"))
	if st != "empty" and st != "exploded":
		return {"success": false, "message": "Котёл уже используется."}

	_gm.brewing_slots[slot_index] = {
		"state": "ready",
		"brew_id": "water",
		"brew_title": "Колба с водой (Основа)",
		"brew_emoji": "💧",
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
	_gm.brewing_changed.emit()
	_gm.save_game()
	return {"success": true, "message": "💧 Вода налита в котёл #%d. Добавьте базовую траву (Шаг 1)!" % (slot_index + 1)}


func add_brewing_ingredient(slot_index: int, ingredient_item: ItemData) -> Dictionary:
	if not _gm.is_alchemy_unlocked():
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Зельеварение открывается после 10-й сложности."}
	if ingredient_item == null or ingredient_item.item_type != ItemData.ItemType.HARVEST:
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "В котёл можно добавлять только урожай из Тёмного сада."}
	if ingredient_item.garden_category == "light" or ingredient_item.id == "spirit_primordial_harvest":
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Растения Светлого сада и плоды духов не варятся в котле — используйте их для путников и духов!"}
	_gm._ensure_sanctuary_slots()
	if slot_index < 0 or slot_index >= _gm.brewing_slots.size() or not _gm.is_brewing_slot_accessible(slot_index):
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Котёл не открыт."}

	var cauldron: Dictionary = _gm.brewing_slots[slot_index]
	if str(cauldron.get("state", "empty")) != "ready":
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Сначала налейте воду или дождитесь окончания варки."}

	var current_brew_id: String = str(cauldron.get("brew_id", ""))
	var stage_transitions: Dictionary = SanctuaryAndForgeCatalog.BREW_STEP_TRANSITIONS.get(current_brew_id, {}) as Dictionary
	var is_valid_step: bool = stage_transitions.has(ingredient_item.id)

	if not is_valid_step:
		if _gm.has_hero_class("alchemist"):
			if _gm.alchemist_next_mistake_safe:
				_gm.alchemist_next_mistake_safe = false
				_gm.brewing_changed.emit()
				_gm.save_game()
				return {
					"success": false,
					"exploded": false,
					"saved_by_alchemist": true,
					"message": "⚗️ Спас-флаг Алхимика сработал! Неверный ингредиент «%s» нейтрализован — зелье НЕ взорвалось и осталось на %d-м этапе." % [
						ingredient_item.item_name,
						int(cauldron.get("stage", 0)),
					],
				}
			else:
				_gm.alchemist_next_mistake_safe = true
		_gm.remove_item(ingredient_item, 1)
		var empty_exploded: Dictionary = _gm.sanctuary_service.make_empty_brewing_slot()
		empty_exploded["state"] = "exploded"
		empty_exploded["brew_emoji"] = "💥"
		empty_exploded["brew_title"] = "Взорвано!"
		_gm.brewing_slots[slot_index] = empty_exploded
		_gm.brewing_changed.emit()
		_gm.save_game()
		var alch_note: String = " (Следующая ошибка защищена флагом Алхимика ✅!)" if _gm.has_hero_class("alchemist") else ""
		return {
			"success": false,
			"exploded": true,
			"saved_by_alchemist": false,
			"message": "💥 ВЗРЫВ КОТЛА #%d! Неподходящий ингредиент «%s» уничтожил текущее зелье (100%% шанс).%s" % [
				slot_index + 1,
				ingredient_item.item_name,
				alch_note,
			],
		}

	if not _gm.remove_item(ingredient_item, 1):
		return {"success": false, "exploded": false, "saved_by_alchemist": false, "message": "Недостаточно «%s» в рюкзаке." % ingredient_item.item_name}

	var recipe: Dictionary = stage_transitions[ingredient_item.id] as Dictionary
	cauldron["state"] = "brewing"
	cauldron["elapsed"] = 0.0
	cauldron["duration"] = float(recipe["duration"])
	cauldron["pending_next_id"] = str(recipe["next_id"])
	cauldron["pending_title"] = str(recipe["title"])
	cauldron["pending_emoji"] = str(recipe["emoji"])
	cauldron["pending_stage"] = int(recipe["stage"])
	cauldron["pending_can_collect"] = bool(recipe["can_collect"])
	cauldron["pending_result_item_path"] = str(recipe["result_item_path"])
	cauldron["pending_result_count"] = int(recipe["result_count"])
	_gm.brewing_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"exploded": false,
		"saved_by_alchemist": false,
		"message": "🔥 Шаг %d запущен в котле #%d: варим %s %s!" % [
			int(recipe["stage"]),
			slot_index + 1,
			str(recipe["emoji"]),
			str(recipe["title"]),
		],
	}


func collect_brewed_potion(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= _gm.brewing_slots.size():
		return {"success": false, "message": "Котёл не найден."}
	var cauldron: Dictionary = _gm.brewing_slots[slot_index]
	if str(cauldron.get("state", "empty")) != "ready" or not bool(cauldron.get("can_collect", false)):
		return {"success": false, "message": "Зелье ещё не доведено до готовой ступени (нужен минимум Шаг 2)."}
	var path: String = str(cauldron.get("result_item_path", ""))
	var cnt: int = maxi(1, int(cauldron.get("result_count", 1)))
	var potion: ItemData = _gm.get_cached_item(path)
	if potion == null:
		return {"success": false, "message": "Рецепт зелья повреждён."}

	_gm.add_item(potion, cnt, true)
	_gm.brewing_slots[slot_index] = _gm.sanctuary_service.make_empty_brewing_slot()
	_gm.brewing_changed.emit()
	_gm.save_game()
	return {
		"success": true,
		"message": "🧪 Сварено и получено: %s %s x%d!" % [potion.icon_emoji, potion.item_name, cnt],
	}


func clear_brewing_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _gm.brewing_slots.size():
		return
	_gm.brewing_slots[slot_index] = _gm.sanctuary_service.make_empty_brewing_slot()
	_gm.brewing_changed.emit()
	_gm.save_game()
