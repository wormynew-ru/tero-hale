class_name SkillAndClassService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func is_classes_unlocked() -> bool:
	return _gm.max_unlocked_difficulty >= _gm.CLASSES_UNLOCK_DIFFICULTY


func get_class_by_id(class_id: String) -> HeroClassData:
	if _gm._classes_by_id.has(class_id):
		return _gm._classes_by_id[class_id] as HeroClassData
	return null


func get_current_class() -> HeroClassData:
	var hc: HeroClassData = get_class_by_id(_gm.selected_class_id)
	if hc != null:
		return hc
	if not _gm.hero_classes.is_empty():
		return _gm.hero_classes[0]
	return null


func has_hero_class(class_id: String) -> bool:
	return _gm.selected_class_id == class_id


func is_equipment_disabled() -> bool:
	var hc: HeroClassData = get_current_class()
	return hc != null and hc.disables_equipment


func select_hero_class(class_id: String) -> bool:
	var target: HeroClassData = get_class_by_id(class_id)
	if target == null:
		return false
	if target.required_difficulty > 1 and not is_classes_unlocked():
		return false
	if _gm.selected_class_id == class_id:
		return false

	var prev_max_hp: float = _gm.get_max_hp()
	var prev_max_mana: float = _gm.get_max_mana()
	_gm.selected_class_id = class_id
	_gm.mark_stats_dirty()
	_gm._validate_equipped_abilities_for_class()
	_gm.clear_active_buffs()

	if target.disables_equipment:
		if _gm.equipped_weapon != null:
			_gm.add_item(_gm.equipped_weapon, 1, false, _gm.equipped_weapon_quality, _gm.equipped_weapon_stars, false)
			_gm.equipped_weapon = null
			_gm.equipped_weapon_quality = 100
			_gm.equipped_weapon_stars = 1
		if _gm.equipped_armor != null:
			_gm.add_item(_gm.equipped_armor, 1, false, _gm.equipped_armor_quality, _gm.equipped_armor_stars, false)
			_gm.equipped_armor = null
			_gm.equipped_armor_quality = 100
			_gm.equipped_armor_stars = 1
		if _gm.equipped_offhand != null:
			_gm.add_item(_gm.equipped_offhand, 1, false, _gm.equipped_offhand_quality, _gm.equipped_offhand_stars, false)
			_gm.equipped_offhand = null
			_gm.equipped_offhand_quality = 100
			_gm.equipped_offhand_stars = 1
		if _gm.equipped_ammo != null and _gm.equipped_ammo_count > 0:
			_gm.add_item(_gm.equipped_ammo, _gm.equipped_ammo_count, false)
			_gm.equipped_ammo = null
			_gm.equipped_ammo_count = 0

	_gm.mark_stats_dirty()
	var new_max_hp: float = _gm.get_max_hp()
	if new_max_hp > prev_max_hp:
		_gm.current_hp = minf(new_max_hp, _gm.current_hp + (new_max_hp - prev_max_hp))
	else:
		_gm.current_hp = minf(new_max_hp, _gm.current_hp)

	var new_max_mana: float = _gm.get_max_mana()
	if new_max_mana > prev_max_mana:
		_gm.current_mana = minf(new_max_mana, _gm.current_mana + (new_max_mana - prev_max_mana))
	else:
		_gm.current_mana = minf(new_max_mana, _gm.current_mana)

	_gm.current_barrier = 0.0 if has_hero_class("reflector") else minf(_gm.current_barrier, _gm.get_max_barrier())
	_gm.class_changed.emit(target)
	_gm.stats_changed.emit()
	_gm.inventory_changed.emit()
	_gm.enchant_changed.emit()
	_gm.abilities_changed.emit()
	_gm.buffs_changed.emit()
	_gm.barrier_changed.emit(_gm.current_barrier, _gm.get_max_barrier())
	_gm.hp_changed.emit(_gm.current_hp, new_max_hp)
	_gm.mana_changed.emit(_gm.current_mana, new_max_mana)
	_gm.save_game()
	return true


func get_dark_skill_by_id(skill_id: String) -> DarkSkillNodeData:
	if _gm._dark_skills_by_id.has(skill_id):
		return _gm._dark_skills_by_id[skill_id] as DarkSkillNodeData
	return null


func has_dark_skill(skill_id: String) -> bool:
	_gm._ensure_progression_caches()
	return _gm._unlocked_dark_skill_set.has(skill_id)


func are_dark_prerequisites_met(skill_id: String) -> bool:
	var dskill: DarkSkillNodeData = get_dark_skill_by_id(skill_id)
	if dskill == null:
		return false
	for prereq_id: String in dskill.prerequisites:
		if not has_dark_skill(prereq_id):
			return false
	return true


func can_unlock_dark_skill(skill_id: String) -> bool:
	var dskill: DarkSkillNodeData = get_dark_skill_by_id(skill_id)
	if dskill == null:
		return false
	if dskill.requires_alchemy and not _gm.is_alchemy_unlocked():
		return false
	if has_dark_skill(skill_id):
		return false
	if _gm.dark_points < dskill.cost_dark_points:
		return false
	return are_dark_prerequisites_met(skill_id)


func unlock_dark_skill(skill_id: String) -> bool:
	if not can_unlock_dark_skill(skill_id):
		return false
	var dskill: DarkSkillNodeData = get_dark_skill_by_id(skill_id)
	if dskill == null:
		return false

	var prev_max_hp: float = _gm.get_max_hp()
	var prev_max_mana: float = _gm.get_max_mana()
	_gm.dark_points -= dskill.cost_dark_points
	_gm.unlocked_dark_skills.append(skill_id)
	_gm._invalidate_progression_caches()

	var new_max_hp: float = _gm.get_max_hp()
	if new_max_hp > prev_max_hp:
		_gm.current_hp = minf(new_max_hp, _gm.current_hp + (new_max_hp - prev_max_hp))
	var new_max_mana: float = _gm.get_max_mana()
	if new_max_mana > prev_max_mana:
		_gm.current_mana = minf(new_max_mana, _gm.current_mana + (new_max_mana - prev_max_mana))

	_gm.dark_skills_changed.emit()
	_gm.difficulty_changed.emit()
	_gm.enchant_changed.emit()
	_gm.abilities_changed.emit()
	_gm.stats_changed.emit()
	_gm.hp_changed.emit(_gm.current_hp, new_max_hp)
	_gm.mana_changed.emit(_gm.current_mana, new_max_mana)
	_gm.save_game()
	return true


func get_dark_bonus(effect_type: String) -> float:
	_gm._ensure_progression_caches()
	return float(_gm._dark_bonus_cache.get(effect_type, 0.0))


func get_skill_by_id(skill_id: String) -> SkillNodeData:
	if _gm._skills_by_id.has(skill_id):
		return _gm._skills_by_id[skill_id] as SkillNodeData
	return null


func is_skill_unlocked(skill_id: String) -> bool:
	_gm._ensure_progression_caches()
	return _gm._unlocked_skill_set.has(skill_id)


func are_prerequisites_met(skill_id: String) -> bool:
	var skill: SkillNodeData = get_skill_by_id(skill_id)
	if skill == null:
		return false
	for prereq_id: String in skill.prerequisites:
		if not is_skill_unlocked(prereq_id):
			return false
	return true


func can_unlock_skill(skill_id: String) -> bool:
	var skill: SkillNodeData = get_skill_by_id(skill_id)
	if skill == null:
		return false
	if skill.requires_alchemy and not _gm.is_alchemy_unlocked():
		return false
	if is_skill_unlocked(skill_id):
		return false
	if _gm.skill_points < skill.cost_skill_points:
		return false
	return are_prerequisites_met(skill_id)


func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false
	var skill: SkillNodeData = get_skill_by_id(skill_id)
	if skill == null:
		return false

	var prev_max_hp: float = _gm.get_max_hp()
	var prev_max_mana: float = _gm.get_max_mana()
	_gm.skill_points -= skill.cost_skill_points
	_gm.unlocked_skills.append(skill_id)
	_gm._invalidate_progression_caches()

	var new_max_hp: float = _gm.get_max_hp()
	if new_max_hp > prev_max_hp:
		_gm.current_hp = minf(new_max_hp, _gm.current_hp + (new_max_hp - prev_max_hp))
	var new_max_mana: float = _gm.get_max_mana()
	if new_max_mana > prev_max_mana:
		_gm.current_mana = minf(new_max_mana, _gm.current_mana + (new_max_mana - prev_max_mana))

	_gm.skills_changed.emit()
	_gm.stats_changed.emit()
	_gm.hp_changed.emit(_gm.current_hp, new_max_hp)
	_gm.mana_changed.emit(_gm.current_mana, new_max_mana)
	_gm.save_game()
	return true


func get_skill_bonus(bonus_type: String) -> float:
	_gm._ensure_progression_caches()
	return float(_gm._skill_bonus_cache.get(bonus_type, 0.0))


func ensure_skill_presets() -> void:
	var sanitized: Array[Dictionary] = []
	for i: int in range(_gm.SKILL_PRESET_COUNT):
		var default_name: String = "Профиль %d" % (i + 1)
		var preset_name: String = default_name
		var clean_order: Array[String] = []
		if i < _gm.skill_presets.size() and _gm.skill_presets[i] is Dictionary:
			var raw: Dictionary = _gm.skill_presets[i] as Dictionary
			var candidate_name: String = str(raw.get("name", default_name)).strip_edges()
			if not candidate_name.is_empty():
				preset_name = candidate_name
			if raw.get("order") is Array:
				for raw_id: Variant in raw["order"]:
					var sid: String = str(raw_id)
					if _gm._skills_by_id.has(sid) and not clean_order.has(sid):
						clean_order.append(sid)
		sanitized.append({"name": preset_name, "order": clean_order})
	_gm.skill_presets = sanitized
	_gm.active_skill_preset_index = clampi(_gm.active_skill_preset_index, 0, _gm.SKILL_PRESET_COUNT - 1)


func get_skill_preset_name(index: int) -> String:
	ensure_skill_presets()
	var idx: int = clampi(index, 0, _gm.SKILL_PRESET_COUNT - 1)
	return str(_gm.skill_presets[idx].get("name", "Профиль %d" % (idx + 1)))


func get_active_skill_preset_order() -> Array[String]:
	ensure_skill_presets()
	var order: Array[String] = []
	var raw_order: Variant = _gm.skill_presets[_gm.active_skill_preset_index].get("order", [])
	if raw_order is Array:
		for s: Variant in raw_order:
			order.append(str(s))
	return order


func get_skill_preset_position(skill_id: String) -> int:
	var order: Array[String] = get_active_skill_preset_order()
	var idx: int = order.find(skill_id)
	return (idx + 1) if idx >= 0 else 0


func set_active_skill_preset(index: int) -> void:
	ensure_skill_presets()
	var next_idx: int = clampi(index, 0, _gm.SKILL_PRESET_COUNT - 1)
	if _gm.active_skill_preset_index == next_idx:
		return
	_gm.active_skill_preset_index = next_idx
	if _gm.skill_auto_upgrade_enabled:
		try_apply_skill_preset(false)
	_gm.skills_changed.emit()
	_gm.save_game()


func set_skill_auto_upgrade_enabled(enabled: bool) -> void:
	ensure_skill_presets()
	if _gm.skill_auto_upgrade_enabled == enabled:
		return
	_gm.skill_auto_upgrade_enabled = enabled
	if _gm.skill_auto_upgrade_enabled:
		try_apply_skill_preset(false)
	_gm.skills_changed.emit()
	_gm.save_game()


func toggle_skill_in_active_preset(skill_id: String) -> bool:
	ensure_skill_presets()
	if not _gm._skills_by_id.has(skill_id):
		return false
	var order: Array[String] = get_active_skill_preset_order()
	var existing_idx: int = order.find(skill_id)
	var added: bool = false
	if existing_idx >= 0:
		order.remove_at(existing_idx)
	else:
		order.append(skill_id)
		added = true
	_gm.skill_presets[_gm.active_skill_preset_index]["order"] = order
	if added and _gm.skill_auto_upgrade_enabled:
		try_apply_skill_preset(false)
	_gm.skills_changed.emit()
	_gm.save_game()
	return added


func clear_active_skill_preset() -> void:
	ensure_skill_presets()
	var empty_order: Array[String] = []
	_gm.skill_presets[_gm.active_skill_preset_index]["order"] = empty_order
	_gm.skills_changed.emit()
	_gm.save_game()


func try_apply_skill_preset(should_save: bool = true) -> int:
	ensure_skill_presets()
	if not _gm.skill_auto_upgrade_enabled or _gm.skill_points <= 0:
		return 0
	var order: Array[String] = get_active_skill_preset_order()
	if order.is_empty():
		return 0

	var prev_max_hp: float = _gm.get_max_hp()
	var prev_max_mana: float = _gm.get_max_mana()
	var applied_count: int = 0

	while _gm.skill_points > 0:
		var picked_id: String = ""
		for sid: String in order:
			if can_unlock_skill(sid):
				picked_id = sid
				break
		if picked_id.is_empty():
			break
		var skill: SkillNodeData = get_skill_by_id(picked_id)
		if skill == null:
			break
		_gm.skill_points -= skill.cost_skill_points
		_gm.unlocked_skills.append(picked_id)
		_gm._invalidate_progression_caches()
		applied_count += 1

	if applied_count > 0:
		var new_max_hp: float = _gm.get_max_hp()
		if new_max_hp > prev_max_hp:
			_gm.current_hp = minf(new_max_hp, _gm.current_hp + (new_max_hp - prev_max_hp))
		var new_max_mana: float = _gm.get_max_mana()
		if new_max_mana > prev_max_mana:
			_gm.current_mana = minf(new_max_mana, _gm.current_mana + (new_max_mana - prev_max_mana))
		_gm.skills_changed.emit()
		_gm.stats_changed.emit()
		_gm.hp_changed.emit(_gm.current_hp, new_max_hp)
		_gm.mana_changed.emit(_gm.current_mana, new_max_mana)
		if should_save:
			_gm.save_game()

	return applied_count
