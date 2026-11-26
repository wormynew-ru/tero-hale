class_name CombatRewardHandler
extends Node

var _cs: CombatSystem = null
var _mine_ambient_timer: float = 0.0


func setup(host: CombatSystem) -> void:
	_cs = host


func reset_mine_timer() -> void:
	_mine_ambient_timer = 0.0


func process_mine_ambient(delta: float) -> void:
	if not GameManager.is_mine_location():
		return
	_mine_ambient_timer += delta
	if _mine_ambient_timer >= 5.5:
		_mine_ambient_timer = 0.0
		var find_msg: String = GameManager.roll_mine_ambient_find()
		if not find_msg.is_empty():
			_cs.mine_find_triggered.emit(find_msg)


func process_single_pack_kill(_unit_idx: int) -> bool:
	var defeated: EnemyData = _cs.current_enemy
	if defeated == null:
		return true

	var xp_earned: float = round(float(defeated.xp_reward) * GameManager.get_xp_multiplier())
	var bestiary_gold_mult: float = 1.0 + GameManager.get_bestiary_gold_bonus(defeated.id)
	var gold_earned: float = round(float(defeated.gold_reward) * GameManager.get_gold_multiplier() * bestiary_gold_mult)

	var mimic_double_chance: float = GameManager.get_pet_secondary_value("gold_echo")
	if mimic_double_chance > 0.0 and randf() < mimic_double_chance:
		gold_earned *= 2.0
		_cs.pet_action_performed.emit("🪙", "x2 Золото!", Color(0.98, 0.85, 0.28, 1.0))

	GameManager.record_kill(defeated)
	GameManager.record_bestiary_kill(defeated.id)
	if GameManager.is_mine_location():
		GameManager.record_mine_kill()
	GameManager.add_gold(gold_earned)
	GameManager.add_xp(xp_earned)
	GameManager.record_afk_rewards(xp_earned, gold_earned)
	_cs.enemy_defeated_reward.emit(xp_earned, gold_earned)
	roll_drops(defeated)

	var kill_bar_pct: float = GameManager.get_on_kill_barrier_restore_pct()
	if kill_bar_pct > 0.0 and not GameManager.has_hero_class("reflector"):
		GameManager.add_barrier(GameManager.get_max_barrier() * kill_bar_pct)
	var kill_heal_pct: float = GameManager.get_dark_bonus("kill_barrier_heal")
	if kill_heal_pct > 0.0:
		GameManager.heal(GameManager.get_max_hp() * kill_heal_pct, false)

	if GameManager.is_training_grounds_location():
		GameManager.add_dark_mastery_xp(GameManager.active_dark_mastery_id, 10.0)

	var alive_left: int = _cs.get_alive_pack_count()
	_cs.enemy_pack_changed.emit(alive_left, _cs.pack_total_count)
	if alive_left <= 0:
		finish_pack_victory(defeated)
		return true
	return false


func finish_pack_victory(defeated: EnemyData) -> void:
	_cs.clear_combat_effects()
	_cs.clear_pack_state()

	if GameManager.wave_dungeon_active:
		var is_final_wave: bool = GameManager.wave_dungeon_wave >= GameManager.WAVE_DUNGEON_TOTAL_WAVES
		_cs.schedule_next_spawn(CombatSystem.SPAWN_DELAY if is_final_wave else 0.2, is_final_wave)
		var wd_res: Dictionary = GameManager.advance_wave_dungeon_on_kill()
		var wd_msg: String = str(wd_res.get("message", ""))
		if not wd_msg.is_empty():
			_cs.route_event_triggered.emit(wd_msg)
		return

	if defeated.id == GameManager.FINAL_BOSS_ID:
		var did_auto_advance: bool = GameManager.on_final_boss_defeated()
		GameManager.on_final_boss_killed_for_garden()
		if did_auto_advance:
			return
	elif defeated.id == GameManager.CURSE_WARDEN_ID:
		GameManager.on_curse_warden_defeated()

	var route_msg: String = GameManager.record_location_win_for_auto_route()
	if not route_msg.is_empty():
		_cs.route_event_triggered.emit(route_msg)
		return

	_cs.schedule_next_spawn(CombatSystem.SPAWN_DELAY, false)


func roll_drops(enemy: EnemyData) -> void:
	var drop_count: int = mini(enemy.drop_items.size(), enemy.drop_chances.size())
	var bestiary_drop_bonus: float = GameManager.get_bestiary_drop_bonus(enemy.id)
	for i: int in range(drop_count):
		var item: ItemData = enemy.drop_items[i]
		var chance: float = clampf(enemy.drop_chances[i] * (1.0 + bestiary_drop_bonus), 0.0, 1.0)
		if item != null and randf() <= chance:
			var amount: int = maxi(1, floori(float(item.shop_pack_amount) / 2.0)) if item.item_type == ItemData.ItemType.AMMO else 1
			GameManager.add_item(item, amount, true, 100, 1, true)
	GameManager.roll_rare_seed_drops(enemy)
	GameManager.roll_difficulty_reset_item_drop()
