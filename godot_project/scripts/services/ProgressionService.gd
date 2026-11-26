class_name ProgressionService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func add_xp(amount: float) -> void:
	if amount <= 0.0:
		return
	_gm.current_xp += amount
	var leveled_up_any: bool = false
	while _gm.current_xp >= _gm.get_xp_to_next_level():
		_gm.current_xp -= _gm.get_xp_to_next_level()
		_gm.level += 1
		_gm.skill_points += 1
		_gm.current_hp = _gm.get_max_hp()
		_gm.current_mana = _gm.get_max_mana()
		leveled_up_any = true
		_gm.level_up.emit(_gm.level)
	if leveled_up_any and _gm.skill_auto_upgrade_enabled:
		_gm.try_apply_skill_preset(false)
	_gm.stats_changed.emit()
	_gm.skills_changed.emit()
	_gm.hp_changed.emit(_gm.current_hp, _gm.get_max_hp())
	_gm.mana_changed.emit(_gm.current_mana, _gm.get_max_mana())


func add_gold(amount: float) -> void:
	if amount <= 0.0:
		return
	_gm.gold += amount
	_gm.stats_changed.emit()


func record_kill(defeated_enemy: EnemyData = null) -> void:
	_gm.enemies_defeated += 1
	_gm.kills_in_run += 1
	if _gm.has_hero_class("reflector"):
		var stack_gain: int = 1
		if defeated_enemy != null:
			if defeated_enemy.id == _gm.FINAL_BOSS_ID:
				stack_gain = 50
			elif defeated_enemy.id == _gm.CURSE_WARDEN_ID:
				stack_gain = 15
			elif defeated_enemy.id == "mine_overseer":
				stack_gain = 5
		var prev_max_hp: float = _gm.get_max_hp()
		_gm.reflector_kill_hp_stacks += stack_gain
		_gm.mark_stats_dirty()
		var new_max_hp: float = _gm.get_max_hp()
		var hp_gain: float = maxf(20.0 * float(stack_gain), new_max_hp - prev_max_hp)
		_gm.current_hp = minf(new_max_hp, _gm.current_hp + hp_gain)
		_gm.hp_changed.emit(_gm.current_hp, new_max_hp)
	_gm.stats_changed.emit()


func apply_damage(raw_damage: float) -> float:
	var reduced: float = maxf(1.0, raw_damage - _gm.get_armor_reduction())
	if _gm.has_dark_skill("arcane_barrier") and _gm.current_mana > 0.0:
		var mana_shield_cap: float = minf(_gm.current_mana, reduced * _gm.get_dark_bonus("arcane_barrier"))
		if mana_shield_cap > 0.0:
			_gm.spend_mana(mana_shield_cap)
			reduced = maxf(1.0, reduced - mana_shield_cap)
	if not _gm.has_hero_class("reflector") and _gm.current_barrier > 0.0:
		var absorbed: float = minf(_gm.current_barrier, reduced)
		_gm.current_barrier = maxf(0.0, _gm.current_barrier - absorbed)
		reduced = maxf(0.0, reduced - absorbed)
		_gm.barrier_changed.emit(_gm.current_barrier, maxf(_gm.get_max_barrier(), _gm.current_barrier))
	if reduced > 0.0:
		_gm.current_hp = maxf(0.0, _gm.current_hp - reduced)
		_gm.hp_changed.emit(_gm.current_hp, _gm.get_max_hp())
	return reduced


func apply_rot_damage(amount: float, emit_signal_immediately: bool = true) -> void:
	if amount <= 0.0:
		return
	_gm.current_hp = maxf(0.0, _gm.current_hp - amount)
	if emit_signal_immediately or _gm.current_hp <= 0.0:
		_gm._hp_ui_dirty = false
		_gm.hp_changed.emit(_gm.current_hp, _gm.get_max_hp())
	else:
		_gm._hp_ui_dirty = true


func heal(amount: float, emit_signal_immediately: bool = true) -> float:
	if amount <= 0.0:
		return 0.0
	var max_hp: float = _gm.get_max_hp()
	var prev_hp: float = _gm.current_hp
	_gm.current_hp = minf(max_hp, _gm.current_hp + amount)
	var actual: float = _gm.current_hp - prev_hp
	if actual > 0.0:
		if emit_signal_immediately or _gm.current_hp >= max_hp:
			_gm._hp_ui_dirty = false
			_gm.hp_changed.emit(_gm.current_hp, max_hp)
		else:
			_gm._hp_ui_dirty = true
	return actual


func upgrade_stat_with_skill_point(stat_name: String) -> bool:
	return upgrade_stat_with_skill_points_bulk(stat_name, 1) > 0


func upgrade_stat_with_skill_points_bulk(stat_name: String, target_count: int) -> int:
	if _gm.skill_points <= 0:
		return 0
	var actual_count: int = _gm.skill_points if target_count <= 0 else mini(target_count, _gm.skill_points)
	if actual_count <= 0:
		return 0
	var prev_max_hp: float = _gm.get_max_hp()
	var prev_max_mana: float = _gm.get_max_mana()
	if not add_base_stat(stat_name, actual_count):
		return 0
	_gm.skill_points -= actual_count
	_gm.mark_stats_dirty()
	var new_max_hp: float = _gm.get_max_hp()
	var new_max_mana: float = _gm.get_max_mana()
	if new_max_hp > prev_max_hp:
		_gm.current_hp = minf(new_max_hp, _gm.current_hp + (new_max_hp - prev_max_hp))
	if new_max_mana > prev_max_mana:
		_gm.current_mana = minf(new_max_mana, _gm.current_mana + (new_max_mana - prev_max_mana))
	_gm.stats_changed.emit()
	_gm.skills_changed.emit()
	_gm.hp_changed.emit(_gm.current_hp, new_max_hp)
	_gm.mana_changed.emit(_gm.current_mana, new_max_mana)
	_gm.barrier_changed.emit(_gm.current_barrier, _gm.get_max_barrier())
	_gm.save_game()
	return actual_count


func train_stat_with_gold(stat_name: String) -> bool:
	return train_stat_with_gold_bulk(stat_name, 1) > 0


func train_stat_with_gold_bulk(stat_name: String, target_count: int) -> int:
	var bulk_info: Dictionary = _gm.get_train_bulk_cost(stat_name, target_count)
	var actual_count: int = int(bulk_info.get("count", 0))
	var cost: float = float(bulk_info.get("cost", 0.0))
	if actual_count <= 0 or _gm.gold < cost:
		return 0
	var prev_max_hp: float = _gm.get_max_hp()
	var prev_max_mana: float = _gm.get_max_mana()
	if not add_base_stat(stat_name, actual_count):
		return 0
	_gm.gold -= cost
	_gm.mark_stats_dirty()
	var new_max_hp: float = _gm.get_max_hp()
	var new_max_mana: float = _gm.get_max_mana()
	if new_max_hp > prev_max_hp:
		_gm.current_hp = minf(new_max_hp, _gm.current_hp + (new_max_hp - prev_max_hp))
	if new_max_mana > prev_max_mana:
		_gm.current_mana = minf(new_max_mana, _gm.current_mana + (new_max_mana - prev_max_mana))
	_gm.stats_changed.emit()
	_gm.hp_changed.emit(_gm.current_hp, new_max_hp)
	_gm.mana_changed.emit(_gm.current_mana, new_max_mana)
	_gm.barrier_changed.emit(_gm.current_barrier, _gm.get_max_barrier())
	_gm.save_game()
	return actual_count


func increment_base_stat(stat_name: String) -> bool:
	return add_base_stat(stat_name, 1)


func add_base_stat(stat_name: String, amount: int) -> bool:
	if amount <= 0:
		return false
	match stat_name:
		"strength":
			_gm.base_strength += amount
			return true
		"agility":
			_gm.base_agility += amount
			return true
		"endurance":
			_gm.base_endurance += amount
			return true
		"intellect":
			_gm.base_intellect += amount
			return true
	return false
