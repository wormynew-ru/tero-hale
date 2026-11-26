class_name DifficultyAndChallengeService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func get_difficulty_enemy_hp_mult() -> float:
	return pow(1.65, float(_gm.difficulty_level - 1))


func get_difficulty_enemy_dmg_mult() -> float:
	return pow(1.42, float(_gm.difficulty_level - 1))


func get_difficulty_enemy_armor_mult() -> float:
	return pow(1.38, float(_gm.difficulty_level - 1))


func get_difficulty_enemy_flat_armor() -> float:
	return float(_gm.difficulty_level - 1) * 4.0


func get_difficulty_price_mult() -> float:
	return pow(1.45, float(_gm.difficulty_level - 1))


func get_difficulty_train_mult() -> float:
	return pow(1.35, float(_gm.difficulty_level - 1))


func get_difficulty_gold_mult() -> float:
	return pow(1.50, float(_gm.difficulty_level - 1))


func get_difficulty_xp_mult() -> float:
	return pow(1.25, float(_gm.difficulty_level - 1))


func get_curse_attenuation() -> float:
	return 0.6 if _gm.has_dark_skill("curse_ward") else 1.0


func ensure_curses_for_difficulty(target_diff: int) -> void:
	var max_tier: int = floori(float(target_diff) / 10.0) * 10
	if max_tier < 10:
		return

	var used_ids: Array[String] = []
	for tier_key: Variant in _gm.difficulty_curses.keys():
		var cid: String = str(_gm.difficulty_curses[tier_key])
		if not cid.is_empty() and not used_ids.has(cid):
			used_ids.append(cid)

	var added_any: bool = false
	for tier: int in range(10, max_tier + 1, 10):
		if _gm.difficulty_curses.has(tier) and not str(_gm.difficulty_curses[tier]).is_empty():
			continue
		var candidates: Array[Dictionary] = []
		for entry: Dictionary in WorldAndAbilityCatalog.CURSE_CATALOG:
			if not used_ids.has(str(entry["id"])):
				candidates.append(entry)
		if candidates.is_empty():
			candidates = WorldAndAbilityCatalog.CURSE_CATALOG.duplicate()
		var picked: Dictionary = candidates[randi() % candidates.size()]
		var picked_id: String = str(picked["id"])
		_gm.difficulty_curses[tier] = picked_id
		added_any = true
		if not used_ids.has(picked_id):
			used_ids.append(picked_id)
	if added_any:
		_gm._invalidate_progression_caches()


func get_curse_definition(curse_id: String) -> Dictionary:
	for entry: Dictionary in WorldAndAbilityCatalog.CURSE_CATALOG:
		if str(entry["id"]) == curse_id:
			return entry
	return {}


func get_active_curses() -> Array[Dictionary]:
	_gm._ensure_progression_caches()
	return _gm._active_curses_cache


func format_curse_description(def: Dictionary, eff_val: float) -> String:
	var cid: String = str(def.get("id", ""))
	var fmt: String = str(def.get("desc_fmt", ""))
	if cid == "rot":
		return fmt % [eff_val * 100.0]
	elif cid == "blood_tax":
		var pct: int = roundi(eff_val * 100.0)
		return fmt % [pct, pct]
	return fmt % [roundi(eff_val * 100.0)]


func get_curse_value(curse_id: String) -> float:
	if curse_id == "greedy_curse" and _gm.has_hero_class("alchemist"):
		return 0.0
	_gm._ensure_progression_caches()
	return float(_gm._curse_value_cache.get(curse_id, 0.0))


func reroll_curse_at_tier(tier: int) -> Dictionary:
	if _gm.curse_reroll_tokens <= 0:
		return {"success": false, "message": "Нет жетонов реролла проклятий."}
	if not _gm.difficulty_curses.has(tier):
		return {"success": false, "message": "На уровне %d нет проклятия." % tier}

	var current_cid: String = str(_gm.difficulty_curses[tier])
	var used_elsewhere: Array[String] = []
	for t_key: Variant in _gm.difficulty_curses.keys():
		if int(t_key) != tier:
			used_elsewhere.append(str(_gm.difficulty_curses[t_key]))

	var preferred: Array[Dictionary] = []
	var fallback: Array[Dictionary] = []
	for entry: Dictionary in WorldAndAbilityCatalog.CURSE_CATALOG:
		var cid: String = str(entry["id"])
		if cid == current_cid:
			continue
		fallback.append(entry)
		if not used_elsewhere.has(cid):
			preferred.append(entry)

	var pool: Array[Dictionary] = preferred if not preferred.is_empty() else fallback
	if pool.is_empty():
		return {"success": false, "message": "Нет альтернативных проклятий."}

	var picked: Dictionary = pool[randi() % pool.size()]
	var new_cid: String = str(picked["id"])
	_gm.difficulty_curses[tier] = new_cid
	_gm.curse_reroll_tokens -= 1
	_gm._invalidate_progression_caches()

	_gm.difficulty_changed.emit()
	_gm.stats_changed.emit()
	_gm.hp_changed.emit(_gm.current_hp, _gm.get_max_hp())
	_gm.mana_changed.emit(_gm.current_mana, _gm.get_max_mana())
	_gm.save_game()
	return {
		"success": true,
		"message": "🎲 Проклятие Сл.%d заменено на %s!" % [tier, str(picked["title"])],
	}


func is_dark_points_claimed_for_difficulty(diff: int) -> bool:
	return _gm.dark_points_claimed_difficulties.has(diff)


func get_challenge_def(challenge_id: String) -> Dictionary:
	for ch: Dictionary in WorldAndAbilityCatalog.CHALLENGE_CATALOG:
		if str(ch.get("id", "")) == challenge_id:
			return ch
	return {}


func is_challenge_completed(challenge_id: String) -> bool:
	return _gm.completed_challenges.has(challenge_id)


func is_potions_blocked_by_challenge() -> bool:
	return _gm.active_challenge_id == "no_potions_titan"


func is_non_staff_blocked_by_challenge() -> bool:
	return _gm.active_challenge_id == "staff_master"


func is_gear_blocked_by_challenge() -> bool:
	return _gm.active_challenge_id == "naked_ascetic"


func on_final_boss_defeated() -> void:
	if _gm.boss_defeated_this_run:
		return
	_gm.boss_defeated_this_run = true
	var gained: int = 0
	if not _gm.dark_points_claimed_difficulties.has(_gm.difficulty_level):
		_gm.dark_points_claimed_difficulties.append(_gm.difficulty_level)
		gained = 2
		_gm.dark_points += gained
	var coins_gained: int = maxi(1, _gm.difficulty_level)
	_gm.dark_shop_coins += coins_gained
	if _gm.difficulty_level >= _gm.max_unlocked_difficulty:
		_gm.max_unlocked_difficulty = _gm.difficulty_level + 1
	if not _gm.active_challenge_id.is_empty():
		var passed: bool = (_gm.active_challenge_id != "speedrun_titan") or (_gm.run_elapsed_seconds <= 300.0)
		if passed and not _gm.completed_challenges.has(_gm.active_challenge_id):
			_gm.completed_challenges.append(_gm.active_challenge_id)
		_gm.active_challenge_id = ""
		_gm.challenge_changed.emit()
	ensure_curses_for_difficulty(_gm.max_unlocked_difficulty)
	_gm._invalidate_progression_caches()
	_gm.dark_skills_changed.emit()
	_gm.dark_shop_changed.emit()
	_gm.difficulty_changed.emit()
	_gm.stats_changed.emit()
	_gm.final_boss_cleared.emit(gained, _gm.max_unlocked_difficulty)
	if _gm.auto_advance_next_boss and not _gm.wave_dungeon_active:
		_gm.total_runs_completed += 1
		_gm._init_run_state(_gm.difficulty_level + 1, "")
		_gm.save_game(true)
		_gm._emit_all_refresh_signals()
		_gm.difficulty_run_auto_advanced.emit(_gm.difficulty_level)
	else:
		_gm.save_game()


func on_curse_warden_defeated() -> void:
	_gm.curse_reroll_tokens += 1
	_gm.reroll_boss_kills_in_run += 1
	_gm.difficulty_changed.emit()
	_gm.stats_changed.emit()
	_gm.curse_warden_defeated.emit(_gm.curse_reroll_tokens, _gm.reroll_boss_kills_in_run)
	_gm.save_game()
