class_name WaveAndWellService
extends Node

var _gm: Node = null


func setup(host: Node) -> void:
	_gm = host


func can_sacrifice_to_well() -> Dictionary:
	if _gm.well_greed_cooldown_remaining > 0.0:
		var mins: int = ceili(_gm.well_greed_cooldown_remaining / 60.0)
		return {"ok": false, "reason": "Колодец Жадности восстанавливается (%d мин)." % mins}
	if _gm.gold < 100.0:
		return {"ok": false, "reason": "Минимум для жертвы — 100 золота."}
	return {"ok": true, "reason": "Готов принять всё золото (%s з.)." % NumberFormatter.format_number(_gm.gold)}


func get_well_blessing_label() -> String:
	match _gm.well_run_blessing:
		"damage_surge":
			return "🔥 Благословение: +15% урона"
		"barrier_surge":
			return "🛡️ Благословение: +25% Барьера, +12% Max HP"
		"greed_fortune":
			return "🪙 Благословение: +25% золота"
		"arcane_overdrive":
			return "🔮 Благословение: +20% Чар, -15% КД"
	return "Нет активного благословения рана"


func sacrifice_all_gold_to_well() -> Dictionary:
	var check: Dictionary = can_sacrifice_to_well()
	if not bool(check.get("ok", false)):
		return {"success": false, "message": str(check.get("reason", ""))}
	var sacrificed: float = _gm.gold
	_gm.gold = 0.0
	_gm.well_greed_cooldown_remaining = _gm.WELL_OF_GREED_COOLDOWN

	var tier: int = clampi(int(floor(log(maxf(10.0, sacrificed)) / log(10.0))) - 1, 1, 6)
	var rewards: Array[String] = []
	var ore_amt: int = maxi(1, tier)
	var ore_item: ItemData = _gm.get_cached_item("res://resources/items/abyss_ore.tres")
	if ore_item != null:
		_gm.add_item(ore_item, ore_amt, true)
		rewards.append("⛏️ Руда Бездны x%d" % ore_amt)

	var page_amt: int = maxi(1, floori(float(tier + 1) / 2.0))
	var page_item: ItemData = _gm.get_cached_item("res://resources/items/ancient_page.tres")
	if page_item != null:
		_gm.add_item(page_item, page_amt, true)
		rewards.append("📜 Древний лист x%d" % page_amt)

	if tier >= 3:
		_gm.curse_reroll_tokens += 1
		rewards.append("🎲 Жетон реролла x1")

	var seed_paths: Array[String] = [
		"res://resources/items/moon_mint_seed.tres",
		"res://resources/items/sun_root_seed.tres",
		"res://resources/items/light_clover_seed.tres",
		"res://resources/items/honey_berry_seed.tres",
	]
	var s_item: ItemData = _gm.get_cached_item(seed_paths[randi() % seed_paths.size()])
	if s_item != null:
		_gm.add_item(s_item, 1, true)
		rewards.append(s_item.get_display_name())

	var blessings: Array[String] = ["damage_surge", "barrier_surge", "greed_fortune", "arcane_overdrive"]
	_gm.well_run_blessing = blessings[randi() % blessings.size()]
	_gm.mark_stats_dirty()
	_gm.stats_changed.emit()
	_gm.hp_changed.emit(_gm.current_hp, _gm.get_max_hp())
	_gm.barrier_changed.emit(_gm.current_barrier, _gm.get_max_barrier())
	_gm.save_game()
	return {
		"success": true,
		"message": "⛲ Пожертвовано %s з.! Получено: %s | %s" % [
			NumberFormatter.format_number(sacrificed),
			", ".join(rewards),
			get_well_blessing_label(),
		],
	}


func start_wave_dungeon() -> Dictionary:
	if _gm.wave_dungeon_active:
		return {"success": false, "message": "Данж волн уже запущен!"}
	_gm._wave_dungeon_return_location_id = _gm.current_location.id if _gm.current_location != null else "quiet_glade"
	_gm.wave_dungeon_active = true
	_gm.wave_dungeon_wave = 1
	_gm.restore_barrier_full()
	_gm.wave_dungeon_changed.emit()
	return {"success": true, "message": "🏰 Вход в Данж волн (10 волн)! Бой начался!"}


func abort_wave_dungeon() -> void:
	if not _gm.wave_dungeon_active:
		return
	_gm.wave_dungeon_active = false
	_gm.wave_dungeon_wave = 0
	var ret_loc: LocationData = _gm.get_location_by_id(_gm._wave_dungeon_return_location_id)
	if ret_loc != null and _gm.is_location_unlocked(ret_loc):
		_gm.current_location = ret_loc
		_gm.location_changed.emit(_gm.current_location)
	_gm.wave_dungeon_changed.emit()


func get_wave_dungeon_enemy_for_wave(wave_idx: int) -> EnemyData:
	if _gm.all_enemies.is_empty():
		return null
	if wave_idx >= _gm.WAVE_DUNGEON_TOTAL_WAVES:
		if _gm._enemies_by_id.has("curse_warden"):
			return _gm._enemies_by_id["curse_warden"] as EnemyData
	var unlocked_pool: Array[EnemyData] = []
	for loc: LocationData in _gm.locations:
		if loc != null and not loc.is_one_attempt_mine and not loc.is_training_grounds and loc.id != _gm.FINAL_BOSS_LOCATION_ID and _gm.is_location_unlocked(loc):
			for e: EnemyData in loc.enemies:
				if e != null and not unlocked_pool.has(e):
					unlocked_pool.append(e)
	if unlocked_pool.is_empty():
		unlocked_pool = _gm.all_enemies.duplicate()
	var idx: int = clampi(floori(float(wave_idx - 1) * float(unlocked_pool.size()) / float(_gm.WAVE_DUNGEON_TOTAL_WAVES)), 0, unlocked_pool.size() - 1)
	return unlocked_pool[idx]


func advance_wave_dungeon_on_kill() -> Dictionary:
	if not _gm.wave_dungeon_active:
		return {"completed": false, "message": ""}
	if _gm.wave_dungeon_wave < _gm.WAVE_DUNGEON_TOTAL_WAVES:
		_gm.wave_dungeon_wave += 1
		_gm.wave_dungeon_changed.emit()
		return {"completed": false, "message": "🏰 Волна %d / %d!" % [_gm.wave_dungeon_wave, _gm.WAVE_DUNGEON_TOTAL_WAVES]}

	_gm.wave_dungeon_active = false
	_gm.wave_dungeon_wave = 0
	_gm.wave_dungeon_clears += 1
	var ore_item: ItemData = _gm.get_cached_item("res://resources/items/abyss_ore.tres")
	if ore_item != null:
		_gm.add_item(ore_item, 2, true)
	var page_item: ItemData = _gm.get_cached_item("res://resources/items/ancient_page.tres")
	if page_item != null:
		_gm.add_item(page_item, 2, true)
	var chest_gold: float = round(450.0 * _gm.get_gold_multiplier())
	_gm.add_gold(chest_gold)
	var chest_offhand: ItemData = _gm.get_cached_item("res://resources/items/aegis_bulwark_shield.tres" if randf() < 0.5 else "res://resources/items/astral_arcane_talisman.tres")
	var bonus_drop: String = ""
	if chest_offhand != null and _gm.max_unlocked_difficulty >= 5:
		_gm.add_item(chest_offhand, 1, true, 100, 1, true)
		bonus_drop = " + %s" % chest_offhand.get_display_name()

	var ret_loc: LocationData = _gm.get_location_by_id(_gm._wave_dungeon_return_location_id)
	if ret_loc != null and _gm.is_location_unlocked(ret_loc) and _gm.current_location != ret_loc:
		_gm.current_location = ret_loc
		_gm.location_changed.emit(_gm.current_location)
	_gm.wave_dungeon_changed.emit()
	_gm.save_game()
	return {
		"completed": true,
		"message": "🏆 Сундук Данжа волн: +%s з., ⛏️ Руда x2, 📜 Листы x2%s!" % [
			NumberFormatter.format_number(chest_gold),
			bonus_drop,
		],
	}
