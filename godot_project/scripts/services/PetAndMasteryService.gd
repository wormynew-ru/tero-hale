class_name PetAndMasteryService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func get_pet_by_id(pet_id: String) -> PetData:
	if _gm._pets_by_id.has(pet_id):
		return _gm._pets_by_id[pet_id] as PetData
	return null


func get_equipped_pet() -> PetData:
	if _gm.equipped_pet_id.is_empty():
		return null
	return get_pet_by_id(_gm.equipped_pet_id)


func has_pet_owned(pet_id: String) -> bool:
	return _gm.owned_pet_ids.has(pet_id)


func get_pet_training_level(pet_id: String) -> int:
	return clampi(int(_gm.pet_training_levels.get(pet_id, 0)), 0, _gm.MAX_PET_TRAINING_LEVEL)


func get_pet_training_multiplier(pet_id: String) -> float:
	var lvl: int = get_pet_training_level(pet_id)
	return 1.0 + float(lvl) * 0.12


func get_pet_effect_value(effect_type: String) -> float:
	var pet: PetData = get_equipped_pet()
	if pet != null and pet.effect_type == effect_type:
		var raw: float = pet.effect_value * get_pet_training_multiplier(pet.id)
		if effect_type == "crit_lightning":
			return clampf(raw, 0.0, 0.90)
		return raw
	return 0.0


func get_pet_secondary_value(effect_type: String) -> float:
	var pet: PetData = get_equipped_pet()
	if pet != null and pet.effect_type == effect_type:
		var raw: float = pet.effect_secondary * get_pet_training_multiplier(pet.id)
		if effect_type == "gold_echo" or effect_type == "cooldown_haste":
			return clampf(raw, 0.0, 0.95)
		return raw
	return 0.0


func get_pet_buy_price(pet: PetData) -> float:
	if pet == null:
		return 0.0
	var mult: float = _gm.get_difficulty_price_mult() * (1.0 + _gm.get_curse_value("greedy_curse"))
	return maxf(1.0, round(pet.buy_price * mult))


func buy_pet(_pet_id: String) -> Dictionary:
	return {
		"success": false,
		"message": "Путников нельзя купить за золото — приманите их узором растений в ☀️ Светлом саду!",
	}


func get_pet_treat_success_chance(pet_id: String, treat_item: ItemData) -> float:
	var pet: PetData = get_pet_by_id(pet_id)
	if pet == null or treat_item == null or treat_item.item_type != ItemData.ItemType.HARVEST:
		return 0.0
	if treat_item.garden_category != "light":
		return 0.0
	var lvl: int = get_pet_training_level(pet_id)
	if lvl >= _gm.MAX_PET_TRAINING_LEVEL:
		return 0.0
	if treat_item.id == pet.favorite_treat_id:
		return maxf(0.15, 0.55 - float(lvl) * 0.04)
	if treat_item.id == pet.secondary_treat_id:
		return maxf(0.08, 0.30 - float(lvl) * 0.025)
	return maxf(0.05, 0.12 - float(lvl) * 0.01)


func train_pet_with_treat(pet_id: String, treat_item: ItemData) -> Dictionary:
	var pet: PetData = get_pet_by_id(pet_id)
	if pet == null:
		return {"success": false, "leveled_up": false, "message": "Путник не найден."}
	if not has_pet_owned(pet_id):
		return {"success": false, "leveled_up": false, "message": "Сначала приманите этого путника в Светлом саду."}
	var cur_lvl: int = get_pet_training_level(pet_id)
	if cur_lvl >= _gm.MAX_PET_TRAINING_LEVEL:
		return {"success": false, "leveled_up": false, "message": "%s %s уже достиг максимального уровня дрессировки (%d/%d)!" % [pet.icon_emoji, pet.pet_name, cur_lvl, _gm.MAX_PET_TRAINING_LEVEL]}
	if treat_item == null or treat_item.item_type != ItemData.ItemType.HARVEST or treat_item.garden_category != "light":
		return {"success": false, "leveled_up": false, "message": "Для дрессировки подходят только растения Светлого сада."}

	var chance: float = get_pet_treat_success_chance(pet_id, treat_item)
	if not _gm.remove_item(treat_item, 1):
		return {"success": false, "leveled_up": false, "message": "Недостаточно «%s» в рюкзаке." % treat_item.item_name}

	var treat_tag: String = "★ любимый пряник" if treat_item.id == pet.favorite_treat_id else ("👍 хороший пряник" if treat_item.id == pet.secondary_treat_id else "🍪 пряник")
	if randf() <= chance:
		var new_lvl: int = cur_lvl + 1
		_gm.pet_training_levels[pet_id] = new_lvl
		_gm.mark_stats_dirty()
		_gm.pets_changed.emit()
		_gm.stats_changed.emit()
		_gm.save_game()
		return {
			"success": true,
			"leveled_up": true,
			"message": "🎉 %s %s с радостью съел %s (%s, шанс %d%%) и поднял дрессировку до Ур.%d (+%d%% эффекта)!" % [
				pet.icon_emoji,
				pet.pet_name,
				treat_item.get_display_name(),
				treat_tag,
				roundi(chance * 100.0),
				new_lvl,
				new_lvl * 12,
			],
		}

	_gm.pets_changed.emit()
	_gm.save_game()
	return {
		"success": false,
		"leveled_up": false,
		"message": "😋 %s %s скушал %s (%s, шанс %d%%), но уровень остался Ур.%d. Попробуйте ещё!" % [
			pet.icon_emoji,
			pet.pet_name,
			treat_item.get_display_name(),
			treat_tag,
			roundi(chance * 100.0),
			cur_lvl,
		],
	}


func equip_pet(pet_id: String) -> bool:
	if not has_pet_owned(pet_id) or is_pet_on_expedition(pet_id) or _gm.equipped_pet_id == pet_id:
		return false
	_gm.equipped_pet_id = pet_id
	_gm.mark_stats_dirty()
	_gm.pets_changed.emit()
	_gm.stats_changed.emit()
	_gm.save_game()
	return true


func unequip_pet() -> void:
	if _gm.equipped_pet_id.is_empty():
		return
	_gm.equipped_pet_id = ""
	_gm.mark_stats_dirty()
	_gm.pets_changed.emit()
	_gm.stats_changed.emit()
	_gm.save_game()


func is_pet_on_expedition(pet_id: String) -> bool:
	for pet_exp: Dictionary in _gm.pet_expeditions:
		if str(pet_exp.get("pet_id", "")) == pet_id:
			return true
	return false


func get_pet_expedition(pet_id: String) -> Dictionary:
	for pet_exp: Dictionary in _gm.pet_expeditions:
		if str(pet_exp.get("pet_id", "")) == pet_id:
			return pet_exp
	return {}


func get_expedition_plan(plan_id: String) -> Dictionary:
	for p: Dictionary in _gm.PET_EXPEDITION_PLANS:
		if str(p.get("id", "")) == plan_id:
			return p
	return {}


func start_pet_expedition(pet_id: String, plan_id: String) -> Dictionary:
	if not has_pet_owned(pet_id):
		return {"success": false, "message": "Путник не приручён."}
	if _gm.equipped_pet_id == pet_id:
		return {"success": false, "message": "Сначала снимите активного путника перед отправкой в экспедицию."}
	if is_pet_on_expedition(pet_id):
		return {"success": false, "message": "Этот путник уже в экспедиции."}
	var plan: Dictionary = get_expedition_plan(plan_id)
	if plan.is_empty():
		return {"success": false, "message": "Неизвестный план экспедиции."}
	_gm.pet_expeditions.append({
		"pet_id": pet_id,
		"plan_id": plan_id,
		"elapsed": 0.0,
		"duration": float(plan["duration"]),
		"completed": false,
	})
	_gm.pets_changed.emit()
	_gm.save_game()
	return {"success": true, "message": "🧭 Путник отправлен в экспедицию: %s!" % str(plan["title"])}


func claim_pet_expedition(pet_id: String) -> Dictionary:
	var idx: int = -1
	for i: int in range(_gm.pet_expeditions.size()):
		if str(_gm.pet_expeditions[i].get("pet_id", "")) == pet_id:
			idx = i
			break
	if idx < 0:
		return {"success": false, "message": "Экспедиция не найдена."}
	var pet_exp: Dictionary = _gm.pet_expeditions[idx]
	if not bool(pet_exp.get("completed", false)):
		return {"success": false, "message": "Экспедиция ещё не завершена."}
	var plan: Dictionary = get_expedition_plan(str(pet_exp.get("plan_id", "short")))
	var ore_chance: float = float(plan.get("ore_chance", 0.45))
	var seed_rolls: int = int(plan.get("seed_rolls", 2))
	var rewards: Array[String] = []

	var bonus_gold: float = round((120.0 + float(seed_rolls) * 60.0) * _gm.get_gold_multiplier())
	_gm.add_gold(bonus_gold)
	rewards.append("+%s з." % NumberFormatter.format_number(bonus_gold))

	if randf() <= ore_chance:
		var ore_item: ItemData = _gm.get_cached_item("res://resources/items/abyss_ore.tres")
		if ore_item != null:
			var ore_amt: int = 1 if seed_rolls <= 2 else 2
			_gm.add_item(ore_item, ore_amt, true)
			rewards.append("⛏️ Руда Бездны x%d" % ore_amt)

	var light_seeds: Array[String] = [
		"res://resources/items/light_clover_seed.tres",
		"res://resources/items/honey_berry_seed.tres",
		"res://resources/items/sky_chamomile_seed.tres",
		"res://resources/items/spark_chili_seed.tres",
	]
	for _r: int in range(seed_rolls):
		var s_path: String = light_seeds[randi() % light_seeds.size()]
		var s_item: ItemData = _gm.get_cached_item(s_path)
		if s_item != null:
			_gm.add_item(s_item, 1, true)
			rewards.append(s_item.get_display_name())

	if seed_rolls >= 5:
		var page_item: ItemData = _gm.get_cached_item("res://resources/items/ancient_page.tres")
		if page_item != null:
			_gm.add_item(page_item, 1, true)
			rewards.append("📜 Древний лист x1")

	_gm.pet_expeditions.remove_at(idx)
	_gm.pets_changed.emit()
	_gm.inventory_changed.emit()
	_gm.stats_changed.emit()
	_gm.save_game()
	return {"success": true, "message": "🎒 Награда экспедиции: %s" % ", ".join(rewards)}


func get_mastery_level(skill_id: String) -> int:
	match skill_id:
		"melee":
			return _gm.melee_level
		"ranged":
			return _gm.ranged_level
		"magic":
			return _gm.magic_level
	return 1


func get_mastery_xp(skill_id: String) -> float:
	match skill_id:
		"melee":
			return _gm.melee_xp
		"ranged":
			return _gm.ranged_xp
		"magic":
			return _gm.magic_xp
	return 0.0


func get_mastery_xp_required(skill_id: String, lvl: int) -> float:
	if skill_id == "magic":
		return 30.0 + float(maxi(1, lvl) - 1) * 25.0
	return 15.0 + float(maxi(1, lvl) - 1) * 12.0


func get_mastery_xp_multiplier() -> float:
	return 1.0 + _gm.get_skill_bonus("mastery_xp_mult") + _gm.get_dark_bonus("ancient_memory")


func get_mastery_bonus_multiplier(skill_id: String) -> float:
	var lvl: int = get_mastery_level(skill_id)
	var per_lvl: float = 0.03 if skill_id == "melee" else 0.035
	return 1.0 + float(maxi(0, lvl - 1)) * per_lvl


func add_mastery_xp(skill_id: String, base_amount: float) -> void:
	if base_amount <= 0.0:
		return
	var gained: float = base_amount * get_mastery_xp_multiplier()
	var leveled_up: bool = false
	var new_lvl: int = 1

	match skill_id:
		"melee":
			_gm.melee_xp += gained
			while _gm.melee_xp >= get_mastery_xp_required("melee", _gm.melee_level):
				_gm.melee_xp -= get_mastery_xp_required("melee", _gm.melee_level)
				_gm.melee_level += 1
				leveled_up = true
			new_lvl = _gm.melee_level
		"ranged":
			_gm.ranged_xp += gained
			while _gm.ranged_xp >= get_mastery_xp_required("ranged", _gm.ranged_level):
				_gm.ranged_xp -= get_mastery_xp_required("ranged", _gm.ranged_level)
				_gm.ranged_level += 1
				leveled_up = true
			new_lvl = _gm.ranged_level
		"magic":
			_gm.magic_xp += gained
			while _gm.magic_xp >= get_mastery_xp_required("magic", _gm.magic_level):
				_gm.magic_xp -= get_mastery_xp_required("magic", _gm.magic_level)
				_gm.magic_level += 1
				leveled_up = true
			new_lvl = _gm.magic_level
		_:
			return

	_gm.mastery_changed.emit(skill_id, new_lvl, leveled_up)
	if leveled_up:
		_gm.mark_stats_dirty()
		_gm.stats_changed.emit()


func get_dark_mastery_level(mastery_id: String) -> int:
	return maxi(0, int(_gm.dark_mastery_levels.get(mastery_id, 0)))


func get_dark_mastery_xp(mastery_id: String) -> float:
	return maxf(0.0, float(_gm.dark_mastery_xp.get(mastery_id, 0.0)))


func get_dark_mastery_xp_required(lvl: int) -> float:
	return 30.0 + float(maxi(0, lvl)) * 25.0


func get_dark_mastery_bonus(mastery_id: String) -> float:
	var lvl: int = get_dark_mastery_level(mastery_id)
	if lvl <= 0:
		return 0.0
	for entry: Dictionary in _gm.DARK_MASTERY_CATALOG:
		if str(entry.get("id", "")) == mastery_id:
			return float(lvl) * float(entry.get("per_level", 0.04))
	return float(lvl) * 0.04


func set_active_dark_mastery(mastery_id: String) -> void:
	if not _gm.DARK_MASTERY_KEYS.has(mastery_id):
		return
	_gm.active_dark_mastery_id = mastery_id
	_gm.dark_mastery_changed.emit(_gm.active_dark_mastery_id, get_dark_mastery_level(_gm.active_dark_mastery_id), false)
	_gm.save_game()


func add_dark_mastery_xp(mastery_id: String, base_amount: float) -> void:
	if base_amount <= 0.0 or not _gm.DARK_MASTERY_KEYS.has(mastery_id):
		return
	var gained: float = base_amount * get_mastery_xp_multiplier()
	var cur_xp: float = get_dark_mastery_xp(mastery_id) + gained
	var cur_lvl: int = get_dark_mastery_level(mastery_id)
	var leveled_up: bool = false
	while cur_xp >= get_dark_mastery_xp_required(cur_lvl):
		cur_xp -= get_dark_mastery_xp_required(cur_lvl)
		cur_lvl += 1
		leveled_up = true
	_gm.dark_mastery_levels[mastery_id] = cur_lvl
	_gm.dark_mastery_xp[mastery_id] = cur_xp
	_gm.dark_mastery_changed.emit(mastery_id, cur_lvl, leveled_up)
	if leveled_up:
		_gm.mark_stats_dirty()
		_gm.stats_changed.emit()
		_gm.hp_changed.emit(_gm.current_hp, _gm.get_max_hp())
		_gm.barrier_changed.emit(_gm.current_barrier, _gm.get_max_barrier())
