class_name CombatLoadoutService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func is_using_ranged_weapon() -> bool:
	if _gm.is_equipment_disabled() or _gm.equipped_weapon == null:
		return false
	return _gm.equipped_weapon.is_ranged_weapon()


func is_using_mage_staff() -> bool:
	if _gm.is_equipment_disabled() or _gm.equipped_weapon == null:
		return false
	return _gm.equipped_weapon.is_mage_staff()


func is_using_ammo_weapon() -> bool:
	return is_using_ranged_weapon() or is_using_mage_staff()


func try_refill_ammo_from_inventory(required_kind: ItemData.AmmoKind) -> bool:
	if required_kind == ItemData.AmmoKind.NONE or _gm.is_equipment_disabled():
		return false
	for i: int in range(_gm.inventory.size()):
		var entry: Dictionary = _gm.inventory[i]
		var item: ItemData = entry["item"] as ItemData
		var cnt: int = int(entry["count"])
		if item != null and item.item_type == ItemData.ItemType.AMMO and item.ammo_kind == required_kind and cnt > 0:
			_gm.equipped_ammo = item
			_gm.equipped_ammo_count = cnt
			_gm.inventory.remove_at(i)
			_gm.inventory_changed.emit()
			return true
	return false


func has_matching_ammo() -> bool:
	if not is_using_ammo_weapon():
		return false
	var req_kind: ItemData.AmmoKind = _gm.equipped_weapon.required_ammo
	if _gm.equipped_ammo != null and _gm.equipped_ammo.ammo_kind == req_kind and (_gm.equipped_ammo_count > 0 or _gm.equipped_ammo.is_dark_forged):
		return true
	return try_refill_ammo_from_inventory(req_kind)


func get_ammo_save_chance() -> float:
	var chance: float = _gm.get_skill_bonus("ammo_save")
	if _gm.has_dark_skill("shadow_quiver"):
		chance += 0.30
	if _gm.has_hero_class("abyss_ranger") and is_using_ranged_weapon():
		chance += 0.60
	return clampf(chance, 0.0, 0.92)


func consume_one_ammo() -> bool:
	if not has_matching_ammo():
		return false
	if _gm.equipped_ammo != null and _gm.equipped_ammo.is_dark_forged:
		return true
	if randf() < get_ammo_save_chance():
		return true
	_gm.equipped_ammo_count = maxi(0, _gm.equipped_ammo_count - 1)
	if _gm.equipped_ammo_count == 0:
		var req_kind: ItemData.AmmoKind = _gm.equipped_weapon.required_ammo
		_gm.equipped_ammo = null
		try_refill_ammo_from_inventory(req_kind)
	_gm.inventory_changed.emit()
	_gm.stats_changed.emit()
	return true


func ensure_loadouts() -> void:
	while _gm.combat_loadouts.size() < _gm.LOADOUT_COUNT:
		var idx: int = _gm.combat_loadouts.size() + 1
		_gm.combat_loadouts.append({
			"saved": false,
			"name": "Комплект %d" % idx,
			"class_id": "",
			"weapon_path": "",
			"armor_path": "",
			"offhand_path": "",
			"ammo_path": "",
			"ability_ids": [],
			"pet_id": "",
		})
	if _gm.combat_loadouts.size() > _gm.LOADOUT_COUNT:
		_gm.combat_loadouts.resize(_gm.LOADOUT_COUNT)


func has_combat_loadout_saved(idx: int) -> bool:
	ensure_loadouts()
	if idx < 0 or idx >= _gm.combat_loadouts.size():
		return false
	return bool(_gm.combat_loadouts[idx].get("saved", false))


func get_combat_loadout_summary(idx: int) -> String:
	ensure_loadouts()
	if idx < 0 or idx >= _gm.combat_loadouts.size():
		return "Пусто"
	var l: Dictionary = _gm.combat_loadouts[idx]
	if not bool(l.get("saved", false)):
		return "Пустой слот — нажмите «💾 Сохранить»"
	var hc: HeroClassData = _gm.get_class_by_id(str(l.get("class_id", "wanderer")))
	var cls_title: String = hc.title if hc != null else str(l.get("class_id", ""))
	var w_item: ItemData = _gm.get_cached_item(str(l.get("weapon_path", "")))
	var o_item: ItemData = _gm.get_cached_item(str(l.get("offhand_path", "")))
	return "%s | %s | %s" % [
		cls_title,
		w_item.item_name if w_item != null else "без оружия",
		o_item.item_name if o_item != null else "без оффхенда",
	]


func save_combat_loadout(idx: int) -> Dictionary:
	ensure_loadouts()
	if idx < 0 or idx >= _gm.combat_loadouts.size():
		return {"success": false, "message": "Неверный слот комплекта."}
	_gm.combat_loadouts[idx] = {
		"saved": true,
		"name": "Комплект %d" % (idx + 1),
		"class_id": _gm.selected_class_id,
		"weapon_path": _gm.equipped_weapon.resource_path if _gm.equipped_weapon != null else "",
		"armor_path": _gm.equipped_armor.resource_path if _gm.equipped_armor != null else "",
		"offhand_path": _gm.equipped_offhand.resource_path if _gm.equipped_offhand != null else "",
		"ammo_path": _gm.equipped_ammo.resource_path if _gm.equipped_ammo != null else "",
		"ability_ids": _gm.equipped_ability_ids.duplicate(),
		"pet_id": _gm.equipped_pet_id,
	}
	_gm.loadouts_changed.emit()
	_gm.save_game()
	return {"success": true, "message": "💾 Комплект %d сохранён!" % (idx + 1)}


func _equip_best_matching_path(target_path: String, expected_type: ItemData.ItemType) -> void:
	if target_path.is_empty():
		return
	var current_item: ItemData = _gm.get_equipped_slot_item(expected_type)
	if current_item != null and current_item.resource_path == target_path:
		return
	var best_idx: int = -1
	var best_score: int = -1
	for i: int in range(_gm.inventory.size()):
		var entry: Dictionary = _gm.inventory[i]
		var it: ItemData = entry["item"] as ItemData
		if it != null and it.item_type == expected_type and it.resource_path == target_path:
			var sc: int = _gm.get_entry_stars(entry) * 1000 + _gm.get_entry_quality(entry)
			if sc > best_score:
				best_score = sc
				best_idx = i
	if best_idx >= 0:
		var chosen: Dictionary = _gm.inventory[best_idx]
		_gm.use_or_equip_item(chosen["item"] as ItemData, _gm.get_entry_quality(chosen), _gm.get_entry_stars(chosen))


func apply_combat_loadout(idx: int) -> Dictionary:
	ensure_loadouts()
	if idx < 0 or idx >= _gm.combat_loadouts.size():
		return {"success": false, "message": "Комплект не найден."}
	var l: Dictionary = _gm.combat_loadouts[idx]
	if not bool(l.get("saved", false)):
		return {"success": false, "message": "Комплект %d ещё пуст." % (idx + 1)}
	var cls_id: String = str(l.get("class_id", ""))
	if not cls_id.is_empty() and cls_id != _gm.selected_class_id:
		_gm.select_hero_class(cls_id)

	var w_path: String = str(l.get("weapon_path", ""))
	if w_path.is_empty():
		_gm.unequip_slot(ItemData.ItemType.WEAPON)
	else:
		_equip_best_matching_path(w_path, ItemData.ItemType.WEAPON)

	var a_path: String = str(l.get("armor_path", ""))
	if a_path.is_empty():
		_gm.unequip_slot(ItemData.ItemType.ARMOR)
	else:
		_equip_best_matching_path(a_path, ItemData.ItemType.ARMOR)

	var o_path: String = str(l.get("offhand_path", ""))
	if o_path.is_empty():
		_gm.unequip_slot(ItemData.ItemType.OFFHAND)
	else:
		_equip_best_matching_path(o_path, ItemData.ItemType.OFFHAND)

	var am_path: String = str(l.get("ammo_path", ""))
	if not am_path.is_empty() and (_gm.equipped_ammo == null or _gm.equipped_ammo.resource_path != am_path):
		var am_item: ItemData = _gm.get_cached_item(am_path)
		if am_item != null and _gm.get_item_count_in_inventory(am_item) > 0:
			_gm.use_or_equip_item(am_item)

	var saved_ab: Variant = l.get("ability_ids", [])
	if saved_ab is Array:
		var ab_arr: Array = saved_ab as Array
		for s_i: int in range(mini(_gm.MAX_ACTIVE_ABILITY_SLOTS, ab_arr.size())):
			var aid: String = str(ab_arr[s_i])
			if aid.is_empty():
				_gm.clear_ability_slot(s_i)
			else:
				_gm.equip_ability_to_slot(aid, s_i)

	var p_id: String = str(l.get("pet_id", ""))
	if p_id.is_empty():
		_gm.unequip_pet()
	elif _gm.has_pet_owned(p_id) and not _gm.is_pet_on_expedition(p_id):
		_gm.equip_pet(p_id)

	_gm.mark_stats_dirty()
	_gm.loadouts_changed.emit()
	_gm.save_game()
	return {"success": true, "message": "🎒 Применён Комплект %d!" % (idx + 1)}


func equip_gear_item(item: ItemData, quality_pct: int, star_level: int) -> String:
	if _gm.is_equipment_disabled():
		return "Класс Спирит не может носить экипировку."
	if _gm.is_gear_blocked_by_challenge():
		return "🏆 Испытание «Аскет» запрещает экипировку!"
	if _gm.is_non_staff_blocked_by_challenge():
		if item.item_type == ItemData.ItemType.WEAPON and not item.is_mage_staff():
			return "🏆 Испытание «Путь Арканы» разрешает только магические посохи!"
		if item.item_type == ItemData.ItemType.OFFHAND and item.offhand_kind != ItemData.OffhandKind.TALISMAN:
			return "🏆 Испытание «Путь Арканы» разрешает только талисманы!"
	var target_q: int = quality_pct
	var target_s: int = star_level
	if target_q < 0 or target_s < 1:
		var best_sc: int = -1
		for entry: Dictionary in _gm.inventory:
			var ex: ItemData = entry["item"] as ItemData
			if ex != null and ex.id == item.id:
				var sc: int = _gm.get_entry_stars(entry) * 1000 + _gm.get_entry_quality(entry)
				if sc > best_sc:
					best_sc = sc
					target_q = _gm.get_entry_quality(entry)
					target_s = _gm.get_entry_stars(entry)
	if target_q < 0:
		target_q = 100
	if target_s < 1:
		target_s = 1
	var removed_ok: bool = _gm.remove_item(item, 1, target_q, target_s)
	if not removed_ok:
		for fb_entry: Dictionary in _gm.inventory:
			var fb_item: ItemData = fb_entry["item"] as ItemData
			if fb_item != null and fb_item.id == item.id and int(fb_entry.get("count", 0)) > 0:
				target_q = _gm.get_entry_quality(fb_entry)
				target_s = _gm.get_entry_stars(fb_entry)
				removed_ok = _gm.remove_item(item, 1, target_q, target_s)
				if removed_ok:
					break
	if not removed_ok:
		return "Предмет %s не найден в рюкзаке." % item.get_display_name()

	if item.item_type == ItemData.ItemType.WEAPON:
		if _gm.equipped_weapon != null:
			_gm.add_item(_gm.equipped_weapon, 1, false, _gm.equipped_weapon_quality, _gm.equipped_weapon_stars, false)
		_gm.equipped_weapon = item
		_gm.equipped_weapon_quality = target_q
		_gm.equipped_weapon_stars = target_s
	elif item.item_type == ItemData.ItemType.ARMOR:
		if _gm.equipped_armor != null:
			_gm.add_item(_gm.equipped_armor, 1, false, _gm.equipped_armor_quality, _gm.equipped_armor_stars, false)
		_gm.equipped_armor = item
		_gm.equipped_armor_quality = target_q
		_gm.equipped_armor_stars = target_s
	else:
		if _gm.equipped_offhand != null:
			_gm.add_item(_gm.equipped_offhand, 1, false, _gm.equipped_offhand_quality, _gm.equipped_offhand_stars, false)
		_gm.equipped_offhand = item
		_gm.equipped_offhand_quality = target_q
		_gm.equipped_offhand_stars = target_s
	_gm.mark_stats_dirty()
	_gm.current_hp = minf(_gm.current_hp, _gm.get_max_hp())
	_gm.current_mana = minf(_gm.current_mana, _gm.get_max_mana())
	var max_bar: float = _gm.get_max_barrier()
	_gm.current_barrier = 0.0 if _gm.has_hero_class("reflector") else minf(maxf(_gm.current_barrier, max_bar), max_bar)
	_gm.stats_changed.emit()
	_gm.hp_changed.emit(_gm.current_hp, _gm.get_max_hp())
	_gm.mana_changed.emit(_gm.current_mana, _gm.get_max_mana())
	_gm.barrier_changed.emit(_gm.current_barrier, max_bar)
	_gm.inventory_changed.emit()
	_gm.enchant_changed.emit()
	_gm.save_game()
	return "Экипировано: %s (%d%% ★%d)." % [item.get_display_name(), target_q, target_s]


func equip_ammo_item(item: ItemData) -> String:
	if _gm.is_equipment_disabled():
		return "Класс Спирит не может использовать снаряды."
	if _gm.is_gear_blocked_by_challenge():
		return "🏆 Испытание «Аскет» запрещает экипировку и снаряды!"
	if _gm.is_non_staff_blocked_by_challenge() and item.ammo_kind != ItemData.AmmoKind.TOME:
		return "🏆 Испытание «Путь Арканы» разрешает только магические книги-фолианты!"
	var stack_count: int = _gm.get_item_count_in_inventory(item)
	if stack_count <= 0:
		return ""
	if _gm.remove_item(item, stack_count):
		if _gm.equipped_ammo != null and _gm.equipped_ammo_count > 0:
			if _gm.equipped_ammo.id == item.id:
				_gm.equipped_ammo_count += stack_count
			else:
				var prev_ammo: ItemData = _gm.equipped_ammo
				var prev_cnt: int = _gm.equipped_ammo_count
				_gm.equipped_ammo = item
				_gm.equipped_ammo_count = stack_count
				_gm.add_item(prev_ammo, prev_cnt, false)
		else:
			_gm.equipped_ammo = item
			_gm.equipped_ammo_count = stack_count
		_gm.mark_stats_dirty()
		_gm.stats_changed.emit()
		_gm.inventory_changed.emit()
		_gm.save_game()
		return "Экипированы снаряды: %s x%d." % [item.get_display_name(), _gm.equipped_ammo_count]
	return ""


func unequip_slot(slot_type: ItemData.ItemType) -> void:
	match slot_type:
		ItemData.ItemType.WEAPON:
			if _gm.equipped_weapon != null:
				var prev: ItemData = _gm.equipped_weapon
				var pq: int = _gm.equipped_weapon_quality
				var ps: int = _gm.equipped_weapon_stars
				_gm.equipped_weapon = null
				_gm.equipped_weapon_quality = 100
				_gm.equipped_weapon_stars = 1
				_gm.add_item(prev, 1, false, pq, ps, false)
		ItemData.ItemType.ARMOR:
			if _gm.equipped_armor != null:
				var prev: ItemData = _gm.equipped_armor
				var pq: int = _gm.equipped_armor_quality
				var ps: int = _gm.equipped_armor_stars
				_gm.equipped_armor = null
				_gm.equipped_armor_quality = 100
				_gm.equipped_armor_stars = 1
				_gm.add_item(prev, 1, false, pq, ps, false)
		ItemData.ItemType.OFFHAND:
			if _gm.equipped_offhand != null:
				var prev: ItemData = _gm.equipped_offhand
				var pq: int = _gm.equipped_offhand_quality
				var ps: int = _gm.equipped_offhand_stars
				_gm.equipped_offhand = null
				_gm.equipped_offhand_quality = 100
				_gm.equipped_offhand_stars = 1
				_gm.add_item(prev, 1, false, pq, ps, false)
		ItemData.ItemType.AMMO:
			if _gm.equipped_ammo != null and _gm.equipped_ammo_count > 0:
				var prev_ammo: ItemData = _gm.equipped_ammo
				var prev_cnt: int = _gm.equipped_ammo_count
				_gm.equipped_ammo = null
				_gm.equipped_ammo_count = 0
				_gm.add_item(prev_ammo, prev_cnt, false)
	_gm.mark_stats_dirty()
	_gm.current_hp = minf(_gm.current_hp, _gm.get_max_hp())
	_gm.current_mana = minf(_gm.current_mana, _gm.get_max_mana())
	var max_bar: float = _gm.get_max_barrier()
	_gm.current_barrier = 0.0 if _gm.has_hero_class("reflector") else minf(_gm.current_barrier, max_bar)
	_gm.stats_changed.emit()
	_gm.hp_changed.emit(_gm.current_hp, _gm.get_max_hp())
	_gm.mana_changed.emit(_gm.current_mana, _gm.get_max_mana())
	_gm.barrier_changed.emit(_gm.current_barrier, max_bar)
	_gm.inventory_changed.emit()
	_gm.enchant_changed.emit()
	_gm.save_game()
