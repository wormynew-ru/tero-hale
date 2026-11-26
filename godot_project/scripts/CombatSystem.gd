class_name CombatSystem
extends Node

enum State {
	IDLE,
	FIGHTING,
	RESTING,
	SPAWNING,
}

signal state_changed(new_state: int)
signal battle_search_changed(is_seeking: bool)
signal enemy_spawned(enemy: EnemyData, current_hp: float, max_hp: float, current_mana: float, max_mana: float)
signal enemy_pack_changed(alive_count: int, total_count: int)
signal enemy_cleared
signal enemy_hp_changed(current_hp: float, max_hp: float)
signal enemy_mana_changed(current_mana: float, max_mana: float)
signal attack_progress_updated(player_progress: float, enemy_progress: float)
signal player_attack_landed(damage: float, is_crit: bool)
signal ranged_shot_fired(ammo_emoji: String, has_ammo: bool)
signal spirit_action_performed(spirit_name: String, emoji: String, value: float, is_heal: bool)
signal troll_shred_updated(stacks: int)
signal enemy_attack_landed(damage: float, dodged: bool)
signal enemy_defeated_reward(xp_earned: float, gold_earned: float)
signal ability_casted(slot_index: int, ability: AbilityData)
signal overcharge_tick_fired(tick_num: int, hp_burn: float, mana_burn: float, damage: float)
signal overcharge_state_changed(is_active: bool, slot_index: int, tick_num: int)
signal dot_tick_landed(emoji: String, title: String, damage: float)
signal enemy_stun_changed(remaining_seconds: float)
signal pet_action_performed(pet_emoji: String, text_value: String, color: Color)
signal mine_find_triggered(msg: String)
signal route_event_triggered(msg: String)

const SPAWN_DELAY: float = 0.25
const REGEN_RATE_PER_SEC: float = 0.15
const ENEMY_MANA_REGEN_PER_SEC: float = 3.0
const ENEMY_SPELL_MANA_COST: float = 20.0
const OVERCHARGE_TICKS_PER_SECOND: float = CombatAbilityHandler.OVERCHARGE_TICKS_PER_SECOND
const OVERCHARGE_TICK_INTERVAL: float = CombatAbilityHandler.OVERCHARGE_TICK_INTERVAL
const OVERCHARGE_MAX_TICKS: int = CombatAbilityHandler.OVERCHARGE_MAX_TICKS
const BLOOD_ARCHMAGE_QUICK_CAST_CHANCE: float = 0.10

var current_state: State = State.IDLE
var is_seeking_battle: bool = false
var current_enemy: EnemyData = null
var enemy_hp: float = 0.0
var enemy_max_hp: float = 0.0
var enemy_mana: float = 0.0
var enemy_attack_damage: float = 0.0
var enemy_defense: float = 0.0
var enemy_troll_armor_shred: int = 0

var pack_total_count: int = 1
var _unit_max_hp: float = 0.0
var _pack_hps: Array[float] = []
var _pack_max_hps: Array[float] = []
var _pack_manas: Array[float] = []
var _pack_atk_timers: Array[float] = []

var _player_attack_timer: float = 0.0
var _enemy_attack_timer: float = 0.0
var _spawn_timer: float = 0.0
var _enemy_stun_timer: float = 0.0
var _auto_potion_timer: float = 0.0
var _enemy_hud_sync_timer: float = 0.0
var _attack_progress_sync_timer: float = 0.0
var _last_emitted_p_prog: float = -1.0
var _last_emitted_e_prog: float = -1.0
var _was_wave_dungeon_active: bool = false

var ability_handler: CombatAbilityHandler = CombatAbilityHandler.new()
var class_pet_handler: CombatClassAndPetHandler = CombatClassAndPetHandler.new()
var reward_handler: CombatRewardHandler = CombatRewardHandler.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ability_handler.setup(self)
	class_pet_handler.setup(self)
	reward_handler.setup(self)
	add_child(ability_handler)
	add_child(class_pet_handler)
	add_child(reward_handler)

	GameManager.location_changed.connect(_on_location_changed)
	GameManager.abilities_changed.connect(ability_handler.on_abilities_changed)
	GameManager.wave_dungeon_changed.connect(_on_wave_dungeon_changed)
	GameManager.difficulty_run_auto_advanced.connect(_on_difficulty_run_auto_advanced)
	GameManager.parallel_battle_changed.connect(_on_parallel_battle_changed)
	GameManager.game_reset.connect(_on_game_reset)

	is_seeking_battle = false
	current_enemy = null
	enemy_troll_armor_shred = 0
	_set_state(State.RESTING if GameManager.current_hp < GameManager.get_max_hp() else State.IDLE)
	battle_search_changed.emit(is_seeking_battle)
	enemy_cleared.emit()
	enemy_pack_changed.emit(0, 0)
	troll_shred_updated.emit(0)
	overcharge_state_changed.emit(false, -1, 0)


func _process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.FIGHTING:
			_process_fighting(delta)
		State.RESTING:
			_process_resting(delta)
		State.SPAWNING:
			_process_spawning(delta)


func toggle_battle_search() -> void:
	if is_seeking_battle:
		is_seeking_battle = false
		_reset_active_enemy_state()
		_emit_attack_progress(0.0, 0.0)
		_set_state(State.RESTING if GameManager.current_hp < GameManager.get_max_hp() else State.IDLE)
		battle_search_changed.emit(false)
	else:
		is_seeking_battle = true
		battle_search_changed.emit(true)
		if GameManager.current_hp <= 0.0:
			_set_state(State.RESTING)
		else:
			_set_state(State.FIGHTING)
			_spawn_enemy()


func try_cast_ability(slot_index: int, is_auto: bool = false, ignore_cooldown: bool = false, trigger_cooldown: bool = true, power_scale: float = 1.0) -> bool:
	return ability_handler.try_cast_ability(slot_index, is_auto, ignore_cooldown, trigger_cooldown, power_scale)


func get_unit_max_hp() -> float:
	return _unit_max_hp


func set_enemy_stun_timer(dur: float) -> void:
	_enemy_stun_timer = dur


func get_effective_enemy_defense(ignore_flat_armor: bool = false) -> float:
	var def_val: float = 0.0 if ignore_flat_armor else enemy_defense
	if not ignore_flat_armor:
		if GameManager.has_dark_skill("armor_rend"):
			def_val *= maxf(0.0, 1.0 - GameManager.get_dark_bonus("armor_rend"))
		var pen: float = GameManager.get_player_armor_penetration()
		if pen > 0.0:
			def_val = maxf(0.0, def_val - pen)
	def_val -= float(enemy_troll_armor_shred)
	return def_val


func clear_combat_effects() -> void:
	ability_handler.clear_effects()
	_enemy_stun_timer = 0.0
	class_pet_handler.reset_combat_timers()
	enemy_stun_changed.emit(0.0)


func schedule_next_spawn(delay: float, clear_wave_flag: bool) -> void:
	if clear_wave_flag:
		_was_wave_dungeon_active = false
	_player_attack_timer = 0.0
	_enemy_attack_timer = 0.0
	_spawn_timer = delay
	_set_state(State.SPAWNING)


func _reset_active_enemy_state() -> void:
	_player_attack_timer = 0.0
	_enemy_attack_timer = 0.0
	_spawn_timer = 0.0
	reward_handler.reset_mine_timer()
	class_pet_handler.reset_spirit_timers()
	clear_combat_effects()
	clear_pack_state()
	current_enemy = null
	enemy_hp = 0.0
	enemy_max_hp = 0.0
	enemy_mana = 0.0
	enemy_troll_armor_shred = 0
	troll_shred_updated.emit(0)
	enemy_cleared.emit()
	enemy_pack_changed.emit(0, 0)


func _emit_attack_progress(player_progress: float, enemy_progress: float) -> void:
	var p_edge: bool = (is_zero_approx(player_progress) and not is_zero_approx(_last_emitted_p_prog)) or (player_progress >= 1.0 and _last_emitted_p_prog < 1.0)
	var e_edge: bool = (is_zero_approx(enemy_progress) and not is_zero_approx(_last_emitted_e_prog)) or (enemy_progress >= 1.0 and _last_emitted_e_prog < 1.0)
	if not (p_edge or e_edge or _last_emitted_p_prog < 0.0):
		if _attack_progress_sync_timer < 0.05:
			return
		if absf(player_progress - _last_emitted_p_prog) < 0.02 and absf(enemy_progress - _last_emitted_e_prog) < 0.02:
			return
	_attack_progress_sync_timer = 0.0
	_last_emitted_p_prog = player_progress
	_last_emitted_e_prog = enemy_progress
	attack_progress_updated.emit(player_progress, enemy_progress)


func _process_idle(delta: float) -> void:
	var max_hp: float = GameManager.get_max_hp()
	if GameManager.current_hp < max_hp:
		var regen_mult: float = 2.0 if GameManager.has_dark_skill("arcane_barrier") else 1.0
		GameManager.heal(max_hp * REGEN_RATE_PER_SEC * regen_mult * delta, false)
	_process_auto_potions(delta, false)
	_emit_attack_progress(0.0, 0.0)


func _process_auto_potions(delta: float, is_in_combat: bool) -> void:
	_auto_potion_timer += delta
	if _auto_potion_timer >= 0.25:
		_auto_potion_timer = 0.0
		GameManager.try_auto_use_all_potions(is_in_combat)


func _handle_player_death() -> void:
	_reset_active_enemy_state()
	if GameManager.wave_dungeon_active:
		_was_wave_dungeon_active = false
		GameManager.abort_wave_dungeon()
		is_seeking_battle = false
		battle_search_changed.emit(false)
		route_event_triggered.emit("🏰 Поражение в Данже волн — возврат в локацию.")
		_set_state(State.RESTING)
		return
	if GameManager.is_mine_location():
		is_seeking_battle = false
		battle_search_changed.emit(false)
		_set_state(State.RESTING)
		GameManager.fail_mine_run()
		return
	_set_state(State.RESTING)


func _process_fighting(delta: float) -> void:
	if not is_seeking_battle:
		_set_state(State.IDLE)
		return
	if current_enemy == null or _pack_hps.is_empty() or get_alive_pack_count() <= 0 or enemy_max_hp <= 0.0:
		if current_enemy != null:
			_reset_active_enemy_state()
		_spawn_enemy()
		if current_enemy == null or _pack_hps.is_empty():
			return

	var combat_regen_pct: float = (0.025 if GameManager.has_hero_class("troll") else 0.0) + (0.02 if GameManager.has_dark_skill("immortal_pact") else 0.0)
	if combat_regen_pct > 0.0 and GameManager.current_hp < GameManager.get_max_hp():
		GameManager.heal(GameManager.get_max_hp() * combat_regen_pct * delta, false)

	var bar_regen_pct: float = GameManager.get_barrier_regen_per_sec_pct()
	if bar_regen_pct > 0.0 and not GameManager.has_hero_class("reflector"):
		var max_bar_now: float = GameManager.get_max_barrier()
		if max_bar_now > 0.0 and GameManager.current_barrier < max_bar_now:
			GameManager.add_barrier(max_bar_now * bar_regen_pct * delta)

	var rot_pct: float = GameManager.get_curse_value("rot")
	if rot_pct > 0.0:
		GameManager.apply_rot_damage(GameManager.get_max_hp() * rot_pct * delta, false)
		if GameManager.current_hp <= 0.0:
			_handle_player_death()
			return

	_process_auto_potions(delta, true)
	reward_handler.process_mine_ambient(delta)
	ability_handler.process_overcharge(delta)
	if current_state != State.FIGHTING or current_enemy == null:
		return
	ability_handler.process_enemy_dots(delta)
	if current_state != State.FIGHTING or current_enemy == null:
		return
	if GameManager.has_hero_class("reflector"):
		class_pet_handler.process_reflector_aura(delta)
		if current_state != State.FIGHTING or current_enemy == null:
			return
	class_pet_handler.process_pet_combat(delta)
	if current_state != State.FIGHTING or current_enemy == null:
		return
	ability_handler.process_auto_abilities()
	if current_state != State.FIGHTING or current_enemy == null:
		return
	if GameManager.has_hero_class("spirit"):
		class_pet_handler.process_spirit_companions(delta)
		if current_state != State.FIGHTING or current_enemy == null:
			return

	_tick_combat_timers(delta)


func _tick_combat_timers(delta: float) -> void:
	var enemy_mana_dirty: bool = false
	var enemy_mana_full: bool = false
	var first_alive_idx: int = get_first_alive_pack_index()
	if current_enemy.max_mana > 0.0:
		for i: int in range(_pack_hps.size()):
			if _pack_hps[i] > 0.0 and _pack_manas[i] < current_enemy.max_mana:
				_pack_manas[i] = minf(current_enemy.max_mana, _pack_manas[i] + ENEMY_MANA_REGEN_PER_SEC * delta)
				if i == first_alive_idx:
					enemy_mana_dirty = true
					if _pack_manas[i] >= current_enemy.max_mana:
						enemy_mana_full = true
		if first_alive_idx >= 0:
			enemy_mana = _pack_manas[first_alive_idx]

	var player_interval: float = GameManager.get_player_attack_interval()
	var frenzy: float = GameManager.get_curse_value("abyss_frenzy")
	var enemy_interval: float = maxf(0.35, current_enemy.get_attack_interval() / (1.0 + frenzy))
	var pet_slow: float = GameManager.get_pet_secondary_value("crit_lightning")
	if pet_slow > 0.0:
		enemy_interval *= (1.0 + pet_slow)

	var is_reflector: bool = GameManager.has_hero_class("reflector")
	_player_attack_timer = 0.0 if is_reflector else (_player_attack_timer + delta)

	var stun_dirty: bool = false
	var stun_finished: bool = false
	if _enemy_stun_timer > 0.0:
		_enemy_stun_timer = maxf(0.0, _enemy_stun_timer - delta)
		stun_dirty = true
		stun_finished = _enemy_stun_timer <= 0.0
	else:
		var lead_timer: float = 0.0
		for i: int in range(_pack_hps.size()):
			if _pack_hps[i] > 0.0:
				_pack_atk_timers[i] += delta
				lead_timer = maxf(lead_timer, _pack_atk_timers[i])
		_enemy_attack_timer = lead_timer

	_enemy_hud_sync_timer += delta
	_attack_progress_sync_timer += delta
	if _enemy_hud_sync_timer >= 0.1 or enemy_mana_full or stun_finished:
		_enemy_hud_sync_timer = 0.0
		if enemy_mana_dirty:
			enemy_mana_changed.emit(enemy_mana, current_enemy.max_mana)
		if stun_dirty:
			enemy_stun_changed.emit(_enemy_stun_timer)

	_emit_attack_progress(0.0 if is_reflector else clampf(_player_attack_timer / player_interval, 0.0, 1.0), clampf(_enemy_attack_timer / enemy_interval, 0.0, 1.0))

	if not is_reflector:
		var player_hits: int = 0
		while _player_attack_timer >= player_interval and player_hits < 4:
			_player_attack_timer -= player_interval
			player_hits += 1
			_perform_player_attack()
			if current_state != State.FIGHTING or current_enemy == null:
				return

	if _enemy_stun_timer <= 0.0:
		for i: int in range(_pack_hps.size()):
			if i >= _pack_hps.size() or _pack_hps[i] <= 0.0:
				continue
			var enemy_hits: int = 0
			while i < _pack_atk_timers.size() and _pack_atk_timers[i] >= enemy_interval and enemy_hits < 4:
				_pack_atk_timers[i] -= enemy_interval
				enemy_hits += 1
				_perform_enemy_attack(i)
				if current_state != State.FIGHTING or current_enemy == null:
					return
				if i >= _pack_hps.size() or _pack_hps[i] <= 0.0:
					break


func _process_resting(delta: float) -> void:
	var max_hp: float = GameManager.get_max_hp()
	var regen_mult: float = 2.0 if GameManager.has_dark_skill("arcane_barrier") else 1.0
	GameManager.heal(max_hp * REGEN_RATE_PER_SEC * regen_mult * delta, false)
	_process_auto_potions(delta, false)
	_emit_attack_progress(0.0, 0.0)
	if GameManager.current_hp >= max_hp:
		if is_seeking_battle:
			_player_attack_timer = 0.0
			_enemy_attack_timer = 0.0
			_set_state(State.FIGHTING)
			if current_enemy == null or enemy_hp <= 0.0 or _pack_hps.is_empty() or get_alive_pack_count() <= 0 or enemy_max_hp <= 0.0:
				_spawn_enemy()
		else:
			_set_state(State.IDLE)


func _process_spawning(delta: float) -> void:
	if not is_seeking_battle:
		_set_state(State.IDLE)
		return
	_spawn_timer -= delta
	_emit_attack_progress(0.0, 0.0)
	if _spawn_timer <= 0.0:
		_set_state(State.FIGHTING)
		_spawn_enemy()


func _perform_player_attack(power_scale: float = 1.0, allow_echo: bool = true) -> void:
	if current_enemy == null or get_alive_pack_count() <= 0:
		return
	if GameManager.has_hero_class("blood_archmage") and randf() < BLOOD_ARCHMAGE_QUICK_CAST_CHANCE:
		if ability_handler.try_cast_random_quick_ability(power_scale):
			GameManager.reduce_all_ability_cooldowns(0.5)
			if allow_echo and current_enemy != null and current_state == State.FIGHTING and get_alive_pack_count() > 0:
				if GameManager.has_dark_skill("echo_strike") and randf() < GameManager.get_dark_bonus("echo_strike"):
					_perform_player_attack(0.75, false)
			return

	var is_ranged: bool = GameManager.is_using_ranged_weapon()
	var is_staff: bool = GameManager.is_using_mage_staff()
	var raw_damage: float = 0.0
	if is_ranged:
		var ammo_emoji: String = GameManager.equipped_ammo.icon_emoji if GameManager.equipped_ammo != null else "🏹"
		var has_ammo: bool = GameManager.consume_one_ammo()
		ranged_shot_fired.emit(ammo_emoji, has_ammo)
		raw_damage = GameManager.get_basic_attack_damage(has_ammo) * power_scale
		if has_ammo:
			GameManager.add_mastery_xp("ranged", 1.0)
	elif is_staff:
		var tome_emoji: String = GameManager.equipped_ammo.icon_emoji if GameManager.equipped_ammo != null else "✨"
		var has_tome: bool = GameManager.consume_one_ammo()
		ranged_shot_fired.emit(tome_emoji, has_tome)
		raw_damage = GameManager.get_basic_attack_damage(has_tome) * power_scale
		if has_tome:
			GameManager.add_mastery_xp("magic", 1.0)
	else:
		raw_damage = GameManager.get_basic_attack_damage(true) * power_scale
		GameManager.add_mastery_xp("melee", 1.0)

	if GameManager.is_training_grounds_location():
		GameManager.add_dark_mastery_xp(GameManager.active_dark_mastery_id, 2.5)
	if GameManager.has_hero_class("troll"):
		enemy_troll_armor_shred += 1
		troll_shred_updated.emit(enemy_troll_armor_shred)

	raw_damage *= (1.0 + GameManager.get_bestiary_damage_bonus(current_enemy.id)) * GameManager.get_pack_or_boss_damage_mult(current_enemy.id, pack_total_count)
	var is_crit: bool = randf() < GameManager.get_crit_chance()
	if is_crit:
		raw_damage *= GameManager.get_crit_multiplier()
	if GameManager.has_dark_skill("dark_execution") and get_active_target_hp_ratio() < 0.30:
		raw_damage *= (1.0 + GameManager.get_dark_bonus("dark_execution"))

	var ignore_armor: bool = is_crit and (GameManager.has_hero_class("abyss_ranger") or (is_ranged and GameManager.has_dark_skill("piercing_volley")))
	var final_damage: float = maxf(1.0, raw_damage - get_effective_enemy_defense(ignore_armor))
	player_attack_landed.emit(final_damage, is_crit)
	class_pet_handler.apply_vampirism(final_damage)
	if GameManager.has_hero_class("blood_archmage"):
		GameManager.reduce_all_ability_cooldowns(0.5)
	apply_damage_to_pack_rollover(final_damage)
	if current_state != State.FIGHTING or current_enemy == null or get_alive_pack_count() <= 0:
		return

	if allow_echo:
		if GameManager.has_dark_skill("echo_strike") and randf() < GameManager.get_dark_bonus("echo_strike"):
			_perform_player_attack(0.75, false)
			return
		if is_ranged:
			var double_shot_chance: float = GameManager.get_dark_bonus("phantom_arrows") + (0.30 if GameManager.has_hero_class("abyss_ranger") else 0.0)
			if double_shot_chance > 0.0 and randf() < clampf(double_shot_chance, 0.0, 0.75):
				_perform_player_attack(0.80, false)


func _perform_enemy_attack(attacker_idx: int = 0) -> void:
	if current_enemy == null or attacker_idx < 0 or attacker_idx >= _pack_hps.size() or _pack_hps[attacker_idx] <= 0.0:
		return
	if randf() < GameManager.get_dodge_chance():
		enemy_attack_landed.emit(0.0, true)
		return

	var raw_damage: float = enemy_attack_damage
	if current_enemy.max_mana > 0.0 and _pack_manas[attacker_idx] >= ENEMY_SPELL_MANA_COST:
		_pack_manas[attacker_idx] = maxf(0.0, _pack_manas[attacker_idx] - ENEMY_SPELL_MANA_COST)
		if attacker_idx == get_first_alive_pack_index():
			enemy_mana = _pack_manas[attacker_idx]
			enemy_mana_changed.emit(enemy_mana, current_enemy.max_mana)
		raw_damage *= 1.35

	var total_reflect_pct: float = GameManager.get_damage_reflection_pct()
	var taken: float = 0.0
	var reflect_dmg: float = 0.0
	if GameManager.has_hero_class("reflector"):
		var mitigated_pct: float = GameManager.get_reflector_mitigation_pct()
		taken = GameManager.apply_damage(raw_damage * (1.0 - mitigated_pct))
		enemy_attack_landed.emit(taken, false)
		reflect_dmg = raw_damage * total_reflect_pct
	else:
		taken = GameManager.apply_damage(raw_damage)
		enemy_attack_landed.emit(taken, false)
		reflect_dmg = raw_damage * total_reflect_pct if total_reflect_pct > 0.0 else 0.0
	if GameManager.has_dark_skill("thorn_apotheosis"):
		reflect_dmg += GameManager.get_max_hp() * 0.02
	var thorns_pct: float = GameManager.get_active_buff_sum("thorns_pct")
	var total_reflected: float = reflect_dmg + (taken * thorns_pct if (thorns_pct > 0.0 and taken > 0.0) else 0.0)

	if GameManager.is_training_grounds_location():
		GameManager.add_dark_mastery_xp(GameManager.active_dark_mastery_id, 2.5)

	if total_reflected > 0.0 and current_enemy != null and GameManager.current_hp > 0.0 and attacker_idx < _pack_hps.size() and _pack_hps[attacker_idx] > 0.0:
		var reflected_final: float = maxf(1.0, total_reflected)
		_pack_hps[attacker_idx] = maxf(0.0, _pack_hps[attacker_idx] - reflected_final)
		sync_pack_totals()
		enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
		dot_tick_landed.emit("🪞" if reflect_dmg > 0.0 else "🧣", "Отражение", reflected_final)
		if _pack_hps[attacker_idx] <= 0.0 and reward_handler.process_single_pack_kill(attacker_idx):
			return

	if GameManager.current_hp <= 0.0:
		_handle_player_death()
	else:
		GameManager.try_auto_use_all_potions(true)
		var max_hp_now: float = maxf(1.0, GameManager.get_max_hp())
		if GameManager.auto_route_enabled and not GameManager.wave_dungeon_active and not GameManager.is_mine_location() and not GameManager.is_training_grounds_location():
			if (GameManager.current_hp / max_hp_now) < 0.20 and GameManager.get_total_potion_count() <= 0:
				var retreat_msg: String = GameManager.retreat_to_safer_location()
				if not retreat_msg.is_empty():
					route_event_triggered.emit(retreat_msg)


func clear_pack_state() -> void:
	_pack_hps.clear()
	_pack_max_hps.clear()
	_pack_manas.clear()
	_pack_atk_timers.clear()
	pack_total_count = 1
	_unit_max_hp = 0.0


func get_alive_pack_count() -> int:
	var alive: int = 0
	for hp_val: float in _pack_hps:
		if hp_val > 0.0:
			alive += 1
	return alive


func get_first_alive_pack_index() -> int:
	for i: int in range(_pack_hps.size()):
		if _pack_hps[i] > 0.0:
			return i
	return -1


func get_active_target_hp_ratio() -> float:
	var idx: int = get_first_alive_pack_index()
	if idx >= 0 and idx < _pack_max_hps.size() and _pack_max_hps[idx] > 0.0:
		return clampf(_pack_hps[idx] / _pack_max_hps[idx], 0.0, 1.0)
	return clampf(enemy_hp / enemy_max_hp, 0.0, 1.0) if enemy_max_hp > 0.0 else 1.0


func sync_pack_totals() -> void:
	var sum_hp: float = 0.0
	var sum_max: float = 0.0
	for i: int in range(_pack_hps.size()):
		sum_hp += maxf(0.0, _pack_hps[i])
		sum_max += maxf(0.0, _pack_max_hps[i])
	enemy_hp = sum_hp
	enemy_max_hp = sum_max
	var first_idx: int = get_first_alive_pack_index()
	if first_idx >= 0 and first_idx < _pack_manas.size():
		enemy_mana = _pack_manas[first_idx]


func apply_damage_to_pack_rollover(damage: float) -> void:
	if damage <= 0.0 or current_state != State.FIGHTING or current_enemy == null or _pack_hps.is_empty() or get_alive_pack_count() <= 0:
		return
	var remaining_dmg: float = damage
	for i: int in range(_pack_hps.size()):
		if remaining_dmg <= 0.0 or current_enemy == null or current_state != State.FIGHTING:
			break
		var unit_hp: float = _pack_hps[i]
		if unit_hp <= 0.0:
			continue
		if remaining_dmg >= unit_hp:
			remaining_dmg -= unit_hp
			_pack_hps[i] = 0.0
			sync_pack_totals()
			enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
			if reward_handler.process_single_pack_kill(i):
				return
		else:
			_pack_hps[i] = unit_hp - remaining_dmg
			remaining_dmg = 0.0
			sync_pack_totals()
			enemy_hp_changed.emit(enemy_hp, enemy_max_hp)


func apply_damage_to_all_alive_in_pack(dmg_amount: float) -> bool:
	if dmg_amount <= 0.0 or current_state != State.FIGHTING or current_enemy == null or _pack_hps.is_empty() or get_alive_pack_count() <= 0:
		return false
	var killed_indices: Array[int] = []
	for i: int in range(_pack_hps.size()):
		if _pack_hps[i] > 0.0:
			_pack_hps[i] = maxf(0.0, _pack_hps[i] - dmg_amount)
			if _pack_hps[i] <= 0.0:
				killed_indices.append(i)
	sync_pack_totals()
	enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
	for kill_idx: int in killed_indices:
		if reward_handler.process_single_pack_kill(kill_idx):
			return true
	return false


func _spawn_enemy() -> void:
	var next_enemy: EnemyData = GameManager.get_wave_dungeon_enemy_for_wave(GameManager.wave_dungeon_wave) if GameManager.wave_dungeon_active else (GameManager.current_location.pick_random_enemy() if GameManager.current_location != null else null)
	if next_enemy == null:
		return

	GameManager.restore_barrier_full()
	ability_handler.clear_dots()
	clear_pack_state()
	current_enemy = next_enemy
	enemy_troll_armor_shred = 0
	troll_shred_updated.emit(0)

	var single_max_hp: float = round(current_enemy.max_hp * GameManager.get_difficulty_enemy_hp_mult())
	enemy_attack_damage = current_enemy.attack_damage * GameManager.get_difficulty_enemy_dmg_mult() * (1.0 + GameManager.get_curse_value("blood_tax"))
	var base_scaled_def: float = current_enemy.defense * GameManager.get_difficulty_enemy_armor_mult() + GameManager.get_difficulty_enemy_flat_armor()
	enemy_defense = base_scaled_def * (1.0 + GameManager.get_curse_value("stone_skin"))

	if GameManager.wave_dungeon_active:
		var wave_scale: float = 1.0 + float(maxi(0, GameManager.wave_dungeon_wave - 1)) * 0.15
		single_max_hp = round(single_max_hp * wave_scale)
		enemy_attack_damage *= wave_scale
		enemy_defense *= wave_scale
	elif current_enemy.id == GameManager.CURSE_WARDEN_ID and GameManager.reroll_boss_kills_in_run > 0:
		var kills_f: float = float(GameManager.reroll_boss_kills_in_run)
		single_max_hp = round(single_max_hp * pow(1.85, kills_f))
		enemy_attack_damage *= pow(1.55, kills_f)
		enemy_defense *= (1.0 + kills_f * 0.45)
	elif GameManager.is_mine_location() and GameManager.mine_depth > 0:
		var depth_scale: float = 1.0 + float(GameManager.mine_depth) * 0.08
		single_max_hp = round(single_max_hp * depth_scale)
		enemy_attack_damage *= depth_scale
		enemy_defense *= depth_scale

	_unit_max_hp = maxf(1.0, single_max_hp)
	pack_total_count = GameManager.get_effective_parallel_battle_count(current_enemy)
	for i: int in range(pack_total_count):
		_pack_hps.append(_unit_max_hp)
		_pack_max_hps.append(_unit_max_hp)
		_pack_manas.append(current_enemy.max_mana)
		_pack_atk_timers.append(0.0)
	sync_pack_totals()

	_player_attack_timer = 0.0
	_enemy_attack_timer = 0.0
	_enemy_stun_timer = 0.0
	_enemy_hud_sync_timer = 0.0
	_attack_progress_sync_timer = 0.0
	class_pet_handler.reset_for_spawn()

	enemy_spawned.emit(current_enemy, enemy_hp, enemy_max_hp, enemy_mana, current_enemy.max_mana)
	enemy_pack_changed.emit(pack_total_count, pack_total_count)
	class_pet_handler.apply_start_of_battle_effects()


func _set_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(int(current_state))


func _on_location_changed(_location: LocationData) -> void:
	var keep_spawning: bool = current_state == State.SPAWNING
	var prev_spawn_timer: float = _spawn_timer
	_reset_active_enemy_state()
	if not is_seeking_battle:
		return
	if current_state == State.RESTING or GameManager.current_hp <= 0.0:
		_set_state(State.RESTING)
		return
	if keep_spawning:
		_spawn_timer = maxf(0.05, prev_spawn_timer)
		return
	_set_state(State.FIGHTING)
	_spawn_enemy()


func _on_wave_dungeon_changed() -> void:
	if GameManager.wave_dungeon_active and not _was_wave_dungeon_active:
		_was_wave_dungeon_active = true
		_reset_active_enemy_state()
		is_seeking_battle = true
		battle_search_changed.emit(true)
		_set_state(State.FIGHTING)
		_spawn_enemy()
	elif not GameManager.wave_dungeon_active:
		_was_wave_dungeon_active = false


func _on_difficulty_run_auto_advanced(new_diff: int) -> void:
	_reset_active_enemy_state()
	_spawn_timer = SPAWN_DELAY
	if is_seeking_battle:
		_set_state(State.RESTING if GameManager.current_hp <= 0.0 else State.SPAWNING)
	else:
		_set_state(State.IDLE)
	route_event_triggered.emit("⏩ Авто-сложность: Ран на Сл.%d!" % new_diff)


func _on_parallel_battle_changed(_cnt: int) -> void:
	if current_state == State.FIGHTING and current_enemy != null and enemy_max_hp > 0.0 and enemy_hp >= enemy_max_hp * 0.999:
		if GameManager.get_effective_parallel_battle_count(current_enemy) != pack_total_count:
			_spawn_enemy()


func _on_game_reset() -> void:
	is_seeking_battle = false
	_was_wave_dungeon_active = false
	_reset_active_enemy_state()
	_auto_potion_timer = 0.0
	_enemy_hud_sync_timer = 0.0
	_attack_progress_sync_timer = 0.0
	_last_emitted_p_prog = -1.0
	_last_emitted_e_prog = -1.0
	enemy_attack_damage = 0.0
	enemy_defense = 0.0
	battle_search_changed.emit(false)
	_set_state(State.IDLE)
