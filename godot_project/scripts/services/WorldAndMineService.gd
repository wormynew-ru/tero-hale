class_name WorldAndMineService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func set_afk_mode(enabled: bool) -> void:
	if _gm.is_afk_mode == enabled:
		return
	_gm.is_afk_mode = enabled
	if _gm.is_afk_mode:
		_gm.afk_elapsed_seconds = 0.0
		_gm.afk_kills = 0
		_gm.afk_gold_earned = 0.0
		_gm.afk_xp_earned = 0.0
		_gm._afk_ui_sync_timer = 0.0
		Engine.max_fps = _gm.afk_target_fps
		DisplayServer.screen_set_keep_on(true)
	else:
		DisplayServer.screen_set_keep_on(false)
		Engine.max_fps = _gm.NORMAL_FPS_LIMIT
		_gm.save_game()
	_gm.afk_mode_changed.emit(_gm.is_afk_mode)
	_gm.afk_stats_updated.emit(_gm.afk_elapsed_seconds, _gm.afk_kills, _gm.afk_gold_earned, _gm.afk_xp_earned)


func record_afk_rewards(xp_earned: float, gold_earned: float) -> void:
	if not _gm.is_afk_mode:
		return
	_gm.afk_kills += 1
	_gm.afk_xp_earned += xp_earned
	_gm.afk_gold_earned += gold_earned
	_gm.afk_stats_updated.emit(_gm.afk_elapsed_seconds, _gm.afk_kills, _gm.afk_gold_earned, _gm.afk_xp_earned)


func get_location_by_id(location_id: String) -> LocationData:
	for loc: LocationData in _gm.locations:
		if loc != null and loc.id == location_id:
			return loc
	return null


func is_training_grounds_location(loc: LocationData = null) -> bool:
	var target: LocationData = loc if loc != null else _gm.current_location
	return target != null and target.is_training_grounds


func is_mine_location(loc: LocationData = null) -> bool:
	var target: LocationData = loc if loc != null else _gm.current_location
	return target != null and target.is_one_attempt_mine


func is_location_unlocked(location: LocationData) -> bool:
	if location == null:
		return false
	if location.is_one_attempt_mine and _gm.mine_locked_this_run:
		return false
	if _gm.max_unlocked_difficulty < location.required_difficulty:
		return false
	if location.always_open_once_unlocked:
		return true
	return _gm.level >= location.required_level


func select_location(location: LocationData) -> bool:
	if location == null or not is_location_unlocked(location):
		return false
	if _gm.current_location == location:
		return false
	if _gm.wave_dungeon_active:
		_gm.wave_dungeon_active = false
		_gm.wave_dungeon_wave = 0
		_gm.wave_dungeon_changed.emit()
	_gm.current_location = location
	_gm.consecutive_location_wins = 0
	if _gm.current_location.is_one_attempt_mine and _gm.mine_depth < maxi(0, _gm.mine_start_depth - 1):
		_gm.mine_depth = maxi(0, _gm.mine_start_depth - 1)
		_gm.mine_state_changed.emit()
	_gm.location_changed.emit(_gm.current_location)
	_gm.save_game()
	return true


func set_parallel_battle_count(cnt: int) -> void:
	var next_cnt: int = cnt if _gm.PARALLEL_BATTLE_OPTIONS.has(cnt) else 1
	if _gm.parallel_battle_count == next_cnt:
		return
	_gm.parallel_battle_count = next_cnt
	_gm.parallel_battle_changed.emit(_gm.parallel_battle_count)
	_gm.stats_changed.emit()
	_gm.save_game()


func cycle_parallel_battle_count() -> int:
	var idx: int = _gm.PARALLEL_BATTLE_OPTIONS.find(_gm.parallel_battle_count)
	var next_cnt: int = _gm.PARALLEL_BATTLE_OPTIONS[(idx + 1) % _gm.PARALLEL_BATTLE_OPTIONS.size()] if idx >= 0 else 1
	set_parallel_battle_count(next_cnt)
	return next_cnt


func get_effective_parallel_battle_count(enemy: EnemyData = null) -> int:
	if _gm.wave_dungeon_active or is_training_grounds_location():
		return 1
	if enemy != null and (enemy.id == _gm.FINAL_BOSS_ID or enemy.id == _gm.CURSE_WARDEN_ID or enemy.id == "mine_overseer"):
		return 1
	return _gm.parallel_battle_count if _gm.PARALLEL_BATTLE_OPTIONS.has(_gm.parallel_battle_count) else 1


func is_mine_checkpoint_unlocked(depth: int) -> bool:
	return depth <= 1 or _gm.unlocked_mine_checkpoints.has(depth)


func get_mine_checkpoint_cost(depth: int) -> int:
	return int(_gm.MINE_CHECKPOINT_COSTS.get(depth, 10))


func buy_mine_checkpoint(depth: int) -> Dictionary:
	if not _gm.MINE_CHECKPOINT_DEPTHS.has(depth):
		return {"success": false, "message": "Неизвестный чекпоинт."}
	if is_mine_checkpoint_unlocked(depth):
		_gm.mine_start_depth = depth
		_gm.mine_state_changed.emit()
		_gm.save_game()
		return {"success": true, "message": "⛏️ Точка старта в Шахте установлена: Глубина %d." % depth}
	var cost: int = get_mine_checkpoint_cost(depth)
	var ore_item: ItemData = _gm.get_cached_item("res://resources/items/abyss_ore.tres")
	if ore_item == null or not _gm.remove_item(ore_item, cost):
		return {"success": false, "message": "Нужно %d ⛏️ Руды Бездны для открытия Глубины %d." % [cost, depth]}
	_gm.unlocked_mine_checkpoints.append(depth)
	_gm.mine_start_depth = depth
	_gm.mine_state_changed.emit()
	_gm.save_game()
	return {"success": true, "message": "⛏️ Чекпоинт Шахты (Глубина %d) открыт навсегда!" % depth}


func set_mine_start_depth(depth: int) -> void:
	if not is_mine_checkpoint_unlocked(depth):
		return
	_gm.mine_start_depth = maxi(1, depth)
	_gm.mine_state_changed.emit()
	_gm.save_game()


func set_auto_route_settings(enabled: bool, threshold: int) -> void:
	_gm.auto_route_enabled = enabled
	_gm.auto_route_wins_threshold = clampi(threshold, 3, 25)
	if not _gm.auto_route_enabled:
		_gm.consecutive_location_wins = 0
	_gm.stats_changed.emit()
	_gm.save_game()


func record_location_win_for_auto_route() -> String:
	if _gm.wave_dungeon_active or is_mine_location() or is_training_grounds_location():
		return ""
	_gm.consecutive_location_wins += 1
	if not _gm.auto_route_enabled or _gm.consecutive_location_wins < _gm.auto_route_wins_threshold:
		return ""
	var cur_idx: int = _gm.locations.find(_gm.current_location)
	if cur_idx < 0:
		return ""
	for next_i: int in range(cur_idx + 1, _gm.locations.size()):
		var candidate: LocationData = _gm.locations[next_i]
		if candidate != null and not candidate.is_one_attempt_mine and not candidate.is_training_grounds and is_location_unlocked(candidate):
			if select_location(candidate):
				return "🧭 Авто-маршрут: переход в «%s»!" % candidate.location_name
	return ""


func retreat_to_safer_location() -> String:
	if _gm.locations.is_empty():
		return ""
	var cur_idx: int = _gm.locations.find(_gm.current_location)
	if cur_idx <= 0:
		_gm.heal(_gm.get_max_hp() * 0.25)
		return ""
	for prev_i: int in range(cur_idx - 1, -1, -1):
		var candidate: LocationData = _gm.locations[prev_i]
		if candidate != null and not candidate.is_one_attempt_mine and not candidate.is_training_grounds and is_location_unlocked(candidate):
			select_location(candidate)
			_gm.heal(_gm.get_max_hp() * 0.25)
			return "🧭 Отступление в «%s» при критическом HP!" % candidate.location_name
	return ""


func record_bestiary_kill(enemy_id: String) -> void:
	if enemy_id.is_empty():
		return
	_gm.bestiary_kills[enemy_id] = get_bestiary_kills(enemy_id) + 1
	_gm.bestiary_changed.emit()


func get_bestiary_kills(enemy_id: String) -> int:
	return maxi(0, int(_gm.bestiary_kills.get(enemy_id, 0)))


func get_bestiary_damage_bonus(enemy_id: String) -> float:
	var kills: int = get_bestiary_kills(enemy_id)
	var bonus: float = 0.0
	for m: Dictionary in _gm.BESTIARY_MILESTONES:
		if kills >= int(m["kills"]):
			bonus += float(m["dmg_bonus"])
	return bonus


func get_bestiary_gold_bonus(enemy_id: String) -> float:
	return 0.03 if get_bestiary_kills(enemy_id) >= 1000 else 0.0


func get_bestiary_drop_bonus(enemy_id: String) -> float:
	return 0.10 if get_bestiary_kills(enemy_id) >= 10000 else 0.0


func record_mine_kill() -> void:
	if not is_mine_location():
		return
	_gm.mine_depth += 1
	_gm.mine_state_changed.emit()


func fail_mine_run() -> void:
	if not is_mine_location():
		return
	var reached: int = _gm.mine_depth
	_gm.mine_locked_this_run = true
	if not _gm.locations.is_empty():
		_gm.current_location = _gm.locations[0]
	_gm.mine_state_changed.emit()
	_gm.mine_run_failed.emit(reached)
	if _gm.current_location != null:
		_gm.location_changed.emit(_gm.current_location)
	_gm.save_game(true)


func roll_mine_ambient_find() -> String:
	if not is_mine_location():
		return ""
	var r: float = randf()
	if r < 0.44:
		var ore_item: ItemData = _gm.get_cached_item("res://resources/items/abyss_ore.tres")
		if ore_item != null:
			_gm.add_item(ore_item, 1, true)
			return "⛏️ Найдена жила: +1 Руда Бездны!"
	elif r < 0.78:
		var page_item: ItemData = _gm.get_cached_item("res://resources/items/ancient_page.tres")
		if page_item != null:
			_gm.add_item(page_item, 1, true)
			return "📜 Найден тайник: +1 Древний лист!"
	else:
		var bonus_gold: float = round((25.0 + float(_gm.mine_depth) * 8.0) * _gm.get_gold_multiplier())
		_gm.add_gold(bonus_gold)
		return "🪙 Золотая жила: +%s з." % NumberFormatter.format_number(bonus_gold)
	return ""
