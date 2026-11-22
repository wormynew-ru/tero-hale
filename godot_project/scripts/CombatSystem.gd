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

const SPAWN_DELAY: float = 1.5
const REGEN_RATE_PER_SEC: float = 0.15
const ENEMY_MANA_REGEN_PER_SEC: float = 3.0
const ENEMY_SPELL_MANA_COST: float = 20.0

const SPIRIT_FIRE_INTERVAL: float = 1.4
const SPIRIT_WIND_INTERVAL: float = 0.95
const SPIRIT_FOREST_INTERVAL: float = 2.5
const SPIRIT_EARTH_INTERVAL: float = 2.0

const OVERCHARGE_TICKS_PER_SECOND: float = 12.0
const OVERCHARGE_TICK_INTERVAL: float = 1.0 / OVERCHARGE_TICKS_PER_SECOND
const OVERCHARGE_MAX_TICKS: int = 12

var current_state: State = State.IDLE
var is_seeking_battle: bool = false
var current_enemy: EnemyData = null
var enemy_hp: float = 0.0
var enemy_max_hp: float = 0.0
var enemy_mana: float = 0.0
var enemy_attack_damage: float = 0.0
var enemy_defense: float = 0.0
var enemy_troll_armor_shred: int = 0

var _player_attack_timer: float = 0.0
var _enemy_attack_timer: float = 0.0
var _spawn_timer: float = 0.0

var _spirit_fire_timer: float = 0.0
var _spirit_wind_timer: float = 0.0
var _spirit_forest_timer: float = 0.0
var _spirit_earth_timer: float = 0.0

var _enemy_dots: Array[Dictionary] = []

var overcharge_active: bool = false
var overcharge_slot_index: int = -1
var overcharge_tick_count: int = 0
var _overcharge_timer: float = 0.0
var _overcharge_ability: AbilityData = null

var _enemy_stun_timer: float = 0.0
var _pet_stun_used_this_fight: bool = false
var _pet_pulse_timer: float = 0.0
var _pet_lightning_timer: float = 0.0
var _reflector_pulse_timer: float = 0.0
var _mine_ambient_timer: float = 0.0
var _auto_potion_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.location_changed.connect(_on_location_changed)
	GameManager.abilities_changed.connect(_on_abilities_changed)
	GameManager.game_reset.connect(_on_game_reset)

	is_seeking_battle = false
	current_enemy = null
	enemy_troll_armor_shred = 0
	if GameManager.current_hp < GameManager.get_max_hp():
		_set_state(State.RESTING)
	else:
		_set_state(State.IDLE)
	battle_search_changed.emit(is_seeking_battle)
	enemy_cleared.emit()
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


func _on_abilities_changed() -> void:
	if overcharge_active and overcharge_slot_index >= 0:
		var slot_ab: AbilityData = GameManager.get_ability(overcharge_slot_index)
		if slot_ab == null or slot_ab != _overcharge_ability:
			_stop_overcharge(true)


func toggle_battle_search() -> void:
	if is_seeking_battle:
		is_seeking_battle = false
		_player_attack_timer = 0.0
		_enemy_attack_timer = 0.0
		_spawn_timer = 0.0
		_reset_spirit_timers()
		_clear_combat_effects()
		current_enemy = null
		enemy_hp = 0.0
		enemy_max_hp = 0.0
		enemy_mana = 0.0
		enemy_troll_armor_shred = 0
		troll_shred_updated.emit(0)
		enemy_cleared.emit()
		attack_progress_updated.emit(0.0, 0.0)
		if GameManager.current_hp < GameManager.get_max_hp():
			_set_state(State.RESTING)
		else:
			_set_state(State.IDLE)
		battle_search_changed.emit(false)
	else:
		is_seeking_battle = true
		battle_search_changed.emit(true)
		if GameManager.current_hp <= 0.0:
			_set_state(State.RESTING)
		else:
			_spawn_enemy()
			_set_state(State.FIGHTING)


func try_cast_ability(slot_index: int, is_auto: bool = false) -> bool:
	var ability: AbilityData = GameManager.get_ability(slot_index)
	if ability == null or not GameManager.is_ability_unlocked(ability):
		return false

	# If channeling overcharge_burn: manual tap stops the channel early & triggers cooldown
	if overcharge_active and ability.effect_type == "overcharge_burn" and overcharge_slot_index == slot_index:
		if not is_auto:
			_stop_overcharge(true)
			return true
		return false

	if GameManager.get_ability_cooldown(slot_index) > 0.0:
		return false

	var mana_cost: float = GameManager.get_ability_mana_cost(ability)
	var use_blood_cast: bool = false
	var blood_hp_cost: float = 0.0

	if GameManager.current_mana < mana_cost:
		if GameManager.has_hero_class("blood_archmage"):
			blood_hp_cost = maxf(1.0, GameManager.current_hp * 0.08)
			if GameManager.current_hp > blood_hp_cost + 1.0:
				use_blood_cast = true
			else:
				return false
		else:
			return false

	var cd_duration: float = GameManager.get_ability_cooldown_duration(ability)
	var power_mult: float = GameManager.get_ability_power_multiplier(ability)

	# 1) Heal Spell
	if ability.effect_type == "heal":
		var max_hp: float = GameManager.get_max_hp()
		if GameManager.current_hp >= max_hp:
			return false
		if is_auto and (GameManager.current_hp / max_hp) > 0.85:
			return false
		if not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
			return false
		GameManager.add_mastery_xp("magic", mana_cost)
		GameManager.start_ability_cooldown(slot_index, cd_duration)
		var healed: float = GameManager.heal(max_hp * power_mult)
		GameManager.player_healed.emit(healed)
		ability_casted.emit(slot_index, ability)
		return true

	# 2) Timed Buff Spell (can be cast anytime manually, or during battle on auto)
	if ability.effect_type == "buff":
		if is_auto and (current_state != State.FIGHTING or GameManager.has_active_buff(ability.id)):
			return false
		if not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
			return false
		GameManager.add_mastery_xp("magic", mana_cost)
		GameManager.start_ability_cooldown(slot_index, 0.0 if _should_reset_ability_cooldown() else cd_duration)
		var buff_scale: float = 1.0 + float(maxi(0, GameManager.magic_level - 1)) * 0.012
		GameManager.apply_ability_buff(ability, buff_scale)
		ability_casted.emit(slot_index, ability)
		return true

	# Reflector cannot deal direct damage via offensive spells
	if GameManager.has_hero_class("reflector"):
		return false

	# Combat-only spells require active enemy
	if current_state != State.FIGHTING or current_enemy == null:
		return false

	# 3) Escalating HP + Mana Burn Burst Spell ("overcharge_burn")
	if ability.effect_type == "overcharge_burn":
		if overcharge_active:
			return false
		if not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
			return false
		GameManager.add_mastery_xp("magic", mana_cost)
		overcharge_active = true
		overcharge_slot_index = slot_index
		overcharge_tick_count = 0
		_overcharge_timer = 0.0
		_overcharge_ability = ability
		ability_casted.emit(slot_index, ability)
		_execute_overcharge_tick()
		return true

	# 4) Damage Over Time Spell ("dot")
	if ability.effect_type == "dot":
		if is_auto and _has_enemy_dot(ability.id):
			return false
		if not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
			return false
		GameManager.add_mastery_xp("magic", mana_cost)
		GameManager.start_ability_cooldown(slot_index, 0.0 if _should_reset_ability_cooldown() else cd_duration)
		_apply_enemy_dot(ability, power_mult)
		ability_casted.emit(slot_index, ability)
		return true

	# 5) Offensive Direct / Multi-hit / Execute / Blood / Pierce / Lifesteal Spells
	var extra_hp_sac: float = 0.0
	if ability.hp_sacrifice_pct > 0.0:
		extra_hp_sac = maxf(1.0, GameManager.current_hp * ability.hp_sacrifice_pct)
		if GameManager.current_hp <= extra_hp_sac + blood_hp_cost + 1.0:
			return false

	if not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
		return false
	if extra_hp_sac > 0.0:
		GameManager.apply_rot_damage(extra_hp_sac)

	GameManager.add_mastery_xp("magic", mana_cost)

	GameManager.start_ability_cooldown(slot_index, 0.0 if _should_reset_ability_cooldown() else cd_duration)

	var hits: int = maxi(1, ability.hit_count)
	var total_dealt: float = 0.0
	for _h: int in range(hits):
		if current_enemy == null or enemy_hp <= 0.0:
			break
		var effective_power: float = power_mult
		var ignore_pct: float = clampf(ability.armor_ignore_pct, 0.0, 1.0)
		if ability.effect_type == "execute_damage" and enemy_max_hp > 0.0 and (enemy_hp / enemy_max_hp) < 0.40:
			effective_power *= 2.0
			ignore_pct = 1.0

		var raw_damage: float = GameManager.get_player_damage() * effective_power
		if extra_hp_sac > 0.0:
			raw_damage += extra_hp_sac * 2.5
		if GameManager.has_dark_skill("arcane_echo"):
			raw_damage += GameManager.current_mana * GameManager.get_dark_bonus("arcane_echo")

		var is_crit: bool = randf() < GameManager.get_crit_chance()
		if is_crit:
			raw_damage *= GameManager.get_crit_multiplier()
		if GameManager.has_dark_skill("dark_execution") and enemy_max_hp > 0.0 and (enemy_hp / enemy_max_hp) < 0.30:
			raw_damage *= (1.0 + GameManager.get_dark_bonus("dark_execution"))

		var full_def_bypass: bool = ignore_pct >= 0.999 or (is_crit and GameManager.has_hero_class("abyss_ranger"))
		var eff_def: float = _get_effective_enemy_defense(full_def_bypass) * (1.0 - ignore_pct)
		var final_damage: float = maxf(1.0, raw_damage - eff_def)
		enemy_hp = maxf(0.0, enemy_hp - final_damage)
		total_dealt += final_damage
		enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
		player_attack_landed.emit(final_damage, is_crit)
		_apply_vampirism(final_damage)

	if ability.lifesteal_ratio > 0.0 and total_dealt > 0.0:
		var spell_heal: float = total_dealt * ability.lifesteal_ratio * maxf(0.25, 1.0 - GameManager.get_curse_value("blood_tax"))
		var actual_healed: float = GameManager.heal(spell_heal)
		if actual_healed > 0.0:
			GameManager.player_healed.emit(actual_healed)

	if ability.mana_restore_flat > 0.0:
		GameManager.restore_mana(ability.mana_restore_flat)

	ability_casted.emit(slot_index, ability)
	if enemy_hp <= 0.0:
		_handle_enemy_defeated()
	return true


func _should_reset_ability_cooldown() -> bool:
	var reset_chance: float = 0.0
	if GameManager.has_dark_skill("spell_overload"):
		reset_chance += GameManager.get_dark_bonus("spell_overload")
	var owl_reset: float = GameManager.get_pet_secondary_value("cooldown_haste")
	if owl_reset > 0.0:
		reset_chance += owl_reset
	return reset_chance > 0.0 and randf() < clampf(reset_chance, 0.0, 0.85)


func _consume_spell_cost(mana_cost: float, use_blood_cast: bool, blood_hp_cost: float) -> bool:
	if use_blood_cast:
		GameManager.apply_rot_damage(blood_hp_cost)
		return true
	return GameManager.spend_mana(mana_cost)


func _execute_overcharge_tick() -> void:
	if not overcharge_active or _overcharge_ability == null or current_enemy == null or current_state != State.FIGHTING:
		_stop_overcharge(true)
		return

	var next_tick: int = overcharge_tick_count + 1
	if next_tick > OVERCHARGE_MAX_TICKS:
		_stop_overcharge(true)
		return

	# Exact progression requested:
	# Tick 1 -> 1 HP / 1 MP
	# Tick 2 -> 2 HP / 2 MP
	# Tick 3 -> 4 HP / 4+1 (5) MP
	# Tick 4 -> 8 HP / 8+2 (10) MP
	var hp_burn: float = pow(2.0, float(next_tick - 1))
	var extra_mana: float = float(maxi(0, next_tick - 2))
	var mana_burn: float = hp_burn + extra_mana

	if GameManager.current_hp <= hp_burn + 1.0 or GameManager.current_mana < mana_burn:
		_stop_overcharge(true)
		return

	GameManager.apply_rot_damage(hp_burn)
	if not GameManager.spend_mana(mana_burn):
		_stop_overcharge(true)
		return

	GameManager.add_mastery_xp("magic", mana_burn)
	overcharge_tick_count = next_tick
	overcharge_state_changed.emit(true, overcharge_slot_index, overcharge_tick_count)

	var power_mult: float = GameManager.get_ability_power_multiplier(_overcharge_ability)
	var burst_scale: float = pow(1.75, float(next_tick - 1))
	var raw_damage: float = (GameManager.get_player_damage() * power_mult + (hp_burn + mana_burn) * 4.0) * burst_scale
	if GameManager.has_dark_skill("arcane_echo"):
		raw_damage += GameManager.current_mana * GameManager.get_dark_bonus("arcane_echo")

	var is_crit: bool = randf() < GameManager.get_crit_chance()
	if is_crit:
		raw_damage *= GameManager.get_crit_multiplier()
	if GameManager.has_dark_skill("dark_execution") and enemy_max_hp > 0.0 and (enemy_hp / enemy_max_hp) < 0.30:
		raw_damage *= (1.0 + GameManager.get_dark_bonus("dark_execution"))

	var ignore_pct: float = clampf(_overcharge_ability.armor_ignore_pct, 0.0, 1.0)
	var eff_def: float = _get_effective_enemy_defense(false) * (1.0 - ignore_pct)
	var final_damage: float = maxf(1.0, raw_damage - eff_def)

	enemy_hp = maxf(0.0, enemy_hp - final_damage)
	enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
	overcharge_tick_fired.emit(next_tick, hp_burn, mana_burn, final_damage)
	_apply_vampirism(final_damage)

	if enemy_hp <= 0.0:
		_stop_overcharge(true)
		_handle_enemy_defeated()
	elif overcharge_tick_count >= OVERCHARGE_MAX_TICKS:
		_stop_overcharge(true)


func _stop_overcharge(trigger_cooldown: bool) -> void:
	var was_active: bool = overcharge_active
	var prev_slot: int = overcharge_slot_index
	var prev_ab: AbilityData = _overcharge_ability

	overcharge_active = false
	overcharge_slot_index = -1
	overcharge_tick_count = 0
	_overcharge_timer = 0.0
	_overcharge_ability = null

	if was_active:
		overcharge_state_changed.emit(false, -1, 0)
		if trigger_cooldown and prev_slot >= 0 and prev_ab != null:
			var reset_cd: bool = GameManager.has_dark_skill("spell_overload") and randf() < GameManager.get_dark_bonus("spell_overload")
			var cd_duration: float = GameManager.get_ability_cooldown_duration(prev_ab)
			GameManager.start_ability_cooldown(prev_slot, 0.0 if reset_cd else cd_duration)


func _apply_enemy_dot(ability: AbilityData, power_mult: float) -> void:
	var dot_entry: Dictionary = {
		"id": ability.id,
		"title": ability.title,
		"icon_emoji": ability.icon_emoji,
		"remaining": maxf(1.0, ability.duration * GameManager.get_effect_duration_multiplier()),
		"tick_timer": 0.0,
		"power_mult": power_mult,
		"armor_ignore_pct": clampf(ability.armor_ignore_pct, 0.0, 1.0),
		"lifesteal_ratio": ability.lifesteal_ratio,
	}
	for i: int in range(_enemy_dots.size()):
		if str(_enemy_dots[i]["id"]) == ability.id:
			_enemy_dots[i] = dot_entry
			return
	_enemy_dots.append(dot_entry)


func _has_enemy_dot(dot_id: String) -> bool:
	for d: Dictionary in _enemy_dots:
		if str(d["id"]) == dot_id and float(d["remaining"]) > 0.0:
			return true
	return false


func _process_enemy_dots(delta: float) -> void:
	if _enemy_dots.is_empty() or current_enemy == null:
		return
	for i: int in range(_enemy_dots.size() - 1, -1, -1):
		var d: Dictionary = _enemy_dots[i]
		d["remaining"] = float(d["remaining"]) - delta
		d["tick_timer"] = float(d["tick_timer"]) + delta
		while float(d["tick_timer"]) >= 1.0 and current_enemy != null and current_state == State.FIGHTING:
			d["tick_timer"] = float(d["tick_timer"]) - 1.0
			var raw_dmg: float = GameManager.get_player_damage() * float(d["power_mult"])
			if GameManager.has_dark_skill("dark_execution") and enemy_max_hp > 0.0 and (enemy_hp / enemy_max_hp) < 0.30:
				raw_dmg *= (1.0 + GameManager.get_dark_bonus("dark_execution"))
			var eff_def: float = _get_effective_enemy_defense(false) * (1.0 - float(d["armor_ignore_pct"]))
			var final_dmg: float = maxf(1.0, raw_dmg - eff_def)
			enemy_hp = maxf(0.0, enemy_hp - final_dmg)
			enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
			dot_tick_landed.emit(str(d["icon_emoji"]), str(d["title"]), final_dmg)
			_apply_vampirism(final_dmg)
			var ls: float = float(d["lifesteal_ratio"])
			if ls > 0.0:
				GameManager.heal(final_dmg * ls * maxf(0.25, 1.0 - GameManager.get_curse_value("blood_tax")))
			if enemy_hp <= 0.0:
				_handle_enemy_defeated()
				return
		if float(d["remaining"]) <= 0.0:
			_enemy_dots.remove_at(i)


func _clear_combat_effects() -> void:
	_enemy_dots.clear()
	_stop_overcharge(true)
	_enemy_stun_timer = 0.0
	_pet_pulse_timer = 0.0
	_pet_lightning_timer = 0.0
	_reflector_pulse_timer = 0.0
	enemy_stun_changed.emit(0.0)


func _get_effective_enemy_defense(ignore_flat_armor: bool = false) -> float:
	var def_val: float = 0.0 if ignore_flat_armor else enemy_defense
	if not ignore_flat_armor:
		if GameManager.has_dark_skill("armor_rend"):
			def_val *= maxf(0.0, 1.0 - GameManager.get_dark_bonus("armor_rend"))
		var pen: float = GameManager.get_player_armor_penetration()
		if pen > 0.0:
			def_val = maxf(0.0, def_val - pen)
	def_val -= float(enemy_troll_armor_shred)
	return def_val


func _apply_vampirism(damage_dealt: float) -> void:
	if damage_dealt <= 0.0:
		return
	var leach_pct: float = GameManager.get_dark_bonus("blood_vampirism") + GameManager.get_active_buff_sum("lifesteal_pct")
	if leach_pct <= 0.0:
		return
	var leach: float = damage_dealt * leach_pct
	if leach > 0.0:
		GameManager.heal(leach)


func _process_idle(delta: float) -> void:
	var max_hp: float = GameManager.get_max_hp()
	if GameManager.current_hp < max_hp:
		var regen_mult: float = 2.0 if GameManager.has_dark_skill("arcane_barrier") else 1.0
		GameManager.heal(max_hp * REGEN_RATE_PER_SEC * regen_mult * delta)
	_process_auto_potions(delta, false)
	attack_progress_updated.emit(0.0, 0.0)


func _process_auto_potions(delta: float, is_in_combat: bool) -> void:
	_auto_potion_timer += delta
	if _auto_potion_timer >= 0.25:
		_auto_potion_timer = 0.0
		GameManager.try_auto_use_all_potions(is_in_combat)


func _handle_player_death() -> void:
	_clear_combat_effects()
	_player_attack_timer = 0.0
	_enemy_attack_timer = 0.0
	_mine_ambient_timer = 0.0
	if GameManager.is_mine_location():
		is_seeking_battle = false
		_spawn_timer = 0.0
		current_enemy = null
		enemy_hp = 0.0
		enemy_max_hp = 0.0
		enemy_mana = 0.0
		enemy_troll_armor_shred = 0
		troll_shred_updated.emit(0)
		enemy_cleared.emit()
		battle_search_changed.emit(false)
		_set_state(State.RESTING)
		GameManager.fail_mine_run()
		return
	_set_state(State.RESTING)


func _process_fighting(delta: float) -> void:
	if not is_seeking_battle:
		_set_state(State.IDLE)
		return

	if current_enemy == null:
		_spawn_enemy()
		if current_enemy == null:
			return

	var combat_regen_pct: float = 0.0
	if GameManager.has_hero_class("troll"):
		combat_regen_pct += 0.025
	if GameManager.has_dark_skill("immortal_pact"):
		combat_regen_pct += 0.02
	if combat_regen_pct > 0.0 and GameManager.current_hp < GameManager.get_max_hp():
		GameManager.heal(GameManager.get_max_hp() * combat_regen_pct * delta)

	var rot_pct: float = GameManager.get_curse_value("rot")
	if rot_pct > 0.0:
		var rot_dmg: float = GameManager.get_max_hp() * rot_pct * delta
		GameManager.apply_rot_damage(rot_dmg)
		if GameManager.current_hp <= 0.0:
			_handle_player_death()
			return

	_process_auto_potions(delta, true)

	if GameManager.is_mine_location():
		_mine_ambient_timer += delta
		if _mine_ambient_timer >= 5.5:
			_mine_ambient_timer = 0.0
			var find_msg: String = GameManager.roll_mine_ambient_find()
			if not find_msg.is_empty():
				mine_find_triggered.emit(find_msg)

	if overcharge_active:
		_overcharge_timer += delta
		while _overcharge_timer >= OVERCHARGE_TICK_INTERVAL and overcharge_active and current_state == State.FIGHTING and current_enemy != null:
			_overcharge_timer -= OVERCHARGE_TICK_INTERVAL
			_execute_overcharge_tick()
			if current_state != State.FIGHTING or current_enemy == null:
				return

	_process_enemy_dots(delta)
	if current_state != State.FIGHTING or current_enemy == null:
		return

	if GameManager.has_hero_class("reflector"):
		_process_reflector_aura(delta)
		if current_state != State.FIGHTING or current_enemy == null:
			return

	_process_pet_combat(delta)
	if current_state != State.FIGHTING or current_enemy == null:
		return

	_process_auto_abilities()
	if current_state != State.FIGHTING or current_enemy == null:
		return

	if GameManager.has_hero_class("spirit"):
		_process_spirit_companions(delta)
		if current_state != State.FIGHTING or current_enemy == null:
			return

	if current_enemy.max_mana > 0.0 and enemy_mana < current_enemy.max_mana:
		enemy_mana = minf(current_enemy.max_mana, enemy_mana + ENEMY_MANA_REGEN_PER_SEC * delta)
		enemy_mana_changed.emit(enemy_mana, current_enemy.max_mana)

	var player_interval: float = GameManager.get_player_attack_interval()
	var frenzy: float = GameManager.get_curse_value("abyss_frenzy")
	var enemy_interval: float = maxf(0.35, current_enemy.get_attack_interval() / (1.0 + frenzy))
	var pet_slow: float = GameManager.get_pet_secondary_value("crit_lightning")
	if pet_slow > 0.0:
		enemy_interval *= (1.0 + pet_slow)

	var is_reflector: bool = GameManager.has_hero_class("reflector")
	if is_reflector:
		_player_attack_timer = 0.0
	else:
		_player_attack_timer += delta

	if _enemy_stun_timer > 0.0:
		_enemy_stun_timer = maxf(0.0, _enemy_stun_timer - delta)
		enemy_stun_changed.emit(_enemy_stun_timer)
	else:
		_enemy_attack_timer += delta

	attack_progress_updated.emit(
		0.0 if is_reflector else clampf(_player_attack_timer / player_interval, 0.0, 1.0),
		clampf(_enemy_attack_timer / enemy_interval, 0.0, 1.0)
	)

	if not is_reflector:
		var player_hits: int = 0
		while _player_attack_timer >= player_interval and player_hits < 4:
			_player_attack_timer -= player_interval
			player_hits += 1
			_perform_player_attack()
			if current_state != State.FIGHTING:
				return

	if _enemy_stun_timer <= 0.0:
		var enemy_hits: int = 0
		while _enemy_attack_timer >= enemy_interval and enemy_hits < 4:
			_enemy_attack_timer -= enemy_interval
			enemy_hits += 1
			_perform_enemy_attack()
			if current_state != State.FIGHTING:
				return


func _process_reflector_aura(delta: float) -> void:
	_reflector_pulse_timer += delta
	while _reflector_pulse_timer >= 1.0 and current_enemy != null and current_state == State.FIGHTING:
		_reflector_pulse_timer -= 1.0
		var hp_aura_dmg: float = maxf(1.0, GameManager.get_max_hp() * 0.05)
		var rot_dmg: float = enemy_max_hp * 0.001
		var total_dmg: float = hp_aura_dmg + rot_dmg
		enemy_hp = maxf(0.0, enemy_hp - total_dmg)
		enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
		dot_tick_landed.emit("🪞", "Аура 5% HP + Гниение 0.1%", total_dmg)
		if enemy_hp <= 0.0:
			_handle_enemy_defeated()
			return


func _process_pet_combat(delta: float) -> void:
	var pet: PetData = GameManager.get_equipped_pet()
	if pet == null or current_enemy == null:
		return

	match pet.effect_type:
		"aura_regen":
			var heal_amt: float = GameManager.get_max_hp() * GameManager.get_pet_effect_value("aura_regen") * delta
			if GameManager.current_hp < GameManager.get_max_hp():
				GameManager.heal(heal_amt)
		"enemy_burn":
			_pet_pulse_timer += delta
			while _pet_pulse_timer >= 1.0 and current_enemy != null and current_state == State.FIGHTING:
				_pet_pulse_timer -= 1.0
				var burn_dmg: float = maxf(1.0, enemy_max_hp * GameManager.get_pet_effect_value("enemy_burn"))
				enemy_hp = maxf(0.0, enemy_hp - burn_dmg)
				enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
				dot_tick_landed.emit(pet.icon_emoji, pet.pet_name, burn_dmg)
				if enemy_hp <= 0.0:
					_handle_enemy_defeated()
					return
		"crit_lightning":
			_pet_lightning_timer += delta
			while _pet_lightning_timer >= 4.0 and current_enemy != null and current_state == State.FIGHTING:
				_pet_lightning_timer -= 4.0
				var bolt_mult: float = GameManager.get_pet_training_multiplier(pet.id)
				var bolt_dmg: float = maxf(1.0, (GameManager.get_max_hp() * 0.08 + GameManager.get_player_damage() * 1.6) * bolt_mult)
				enemy_hp = maxf(0.0, enemy_hp - bolt_dmg)
				enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
				dot_tick_landed.emit(pet.icon_emoji, "Молния", bolt_dmg)
				if enemy_hp <= 0.0:
					_handle_enemy_defeated()
					return


func _process_spirit_companions(delta: float) -> void:
	var communion_bonus: float = GameManager.get_dark_bonus("spirit_communion")
	var base_power_mult: float = 1.0 + communion_bonus
	var base_tick_delta: float = delta * (1.0 + communion_bonus * 0.5)

	_spirit_fire_timer += base_tick_delta * GameManager.get_spirit_speed_multiplier("fire")
	_spirit_wind_timer += base_tick_delta * GameManager.get_spirit_speed_multiplier("wind")
	_spirit_forest_timer += base_tick_delta * GameManager.get_spirit_speed_multiplier("forest")
	_spirit_earth_timer += base_tick_delta * GameManager.get_spirit_speed_multiplier("earth")

	if _spirit_fire_timer >= SPIRIT_FIRE_INTERVAL:
		_spirit_fire_timer -= SPIRIT_FIRE_INTERVAL
		var fire_pow: float = base_power_mult * GameManager.get_spirit_power_multiplier("fire")
		var fire_raw: float = (14.0 + float(GameManager.get_total_strength()) * 1.4) * GameManager.get_mastery_bonus_multiplier("magic") * fire_pow
		_deal_spirit_damage("Дух Огня", "🔥", fire_raw, 0.5, "magic")
		if current_state != State.FIGHTING or current_enemy == null:
			return

	if _spirit_wind_timer >= SPIRIT_WIND_INTERVAL:
		_spirit_wind_timer -= SPIRIT_WIND_INTERVAL
		var wind_pow: float = base_power_mult * GameManager.get_spirit_power_multiplier("wind")
		var wind_raw: float = (10.0 + float(GameManager.get_total_agility()) * 1.3) * GameManager.get_mastery_bonus_multiplier("ranged") * wind_pow
		_deal_spirit_damage("Дух Ветра", "🌪️", wind_raw, 0.65, "ranged")
		if current_state != State.FIGHTING or current_enemy == null:
			return

	if _spirit_forest_timer >= SPIRIT_FOREST_INTERVAL:
		_spirit_forest_timer -= SPIRIT_FOREST_INTERVAL
		var forest_pow: float = base_power_mult * GameManager.get_spirit_power_multiplier("forest")
		var blood_tax_mult: float = maxf(0.25, 1.0 - GameManager.get_curse_value("blood_tax"))
		var heal_amt: float = (GameManager.get_max_hp() * 0.04 + float(GameManager.get_total_endurance()) * 0.8) * forest_pow * blood_tax_mult
		var actual_heal: float = GameManager.heal(heal_amt)
		GameManager.restore_mana(6.0 * forest_pow)
		spirit_action_performed.emit("Дух Леса", "🌿", actual_heal if actual_heal > 0.0 else heal_amt, true)

	if _spirit_earth_timer >= SPIRIT_EARTH_INTERVAL:
		_spirit_earth_timer -= SPIRIT_EARTH_INTERVAL
		var earth_pow: float = base_power_mult * GameManager.get_spirit_power_multiplier("earth")
		var earth_raw: float = (12.0 + float(GameManager.get_total_endurance()) * 1.5) * GameManager.get_mastery_bonus_multiplier("melee") * earth_pow
		_deal_spirit_damage("Дух Земли", "🪨", earth_raw, 1.0, "melee")


func _deal_spirit_damage(spirit_name: String, emoji: String, raw_base: float, def_factor: float, mastery_id: String) -> void:
	if current_enemy == null:
		return
	var raw_damage: float = raw_base
	var is_crit: bool = randf() < GameManager.get_crit_chance()
	if is_crit:
		raw_damage *= GameManager.get_crit_multiplier()
	if GameManager.has_dark_skill("dark_execution") and enemy_max_hp > 0.0 and (enemy_hp / enemy_max_hp) < 0.30:
		raw_damage *= (1.0 + GameManager.get_dark_bonus("dark_execution"))

	var eff_def: float = _get_effective_enemy_defense(false) * def_factor
	var final_damage: float = maxf(1.0, raw_damage - eff_def)
	enemy_hp = maxf(0.0, enemy_hp - final_damage)
	enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
	spirit_action_performed.emit(spirit_name, emoji, final_damage, false)
	GameManager.add_mastery_xp(mastery_id, 1.0)
	_apply_vampirism(final_damage)

	if enemy_hp <= 0.0:
		_handle_enemy_defeated()


func _process_auto_abilities() -> void:
	for i: int in range(GameManager.abilities.size()):
		if GameManager.is_ability_auto_cast(i):
			try_cast_ability(i, true)
			if current_state != State.FIGHTING or current_enemy == null:
				return


func _process_resting(delta: float) -> void:
	var max_hp: float = GameManager.get_max_hp()
	var regen_mult: float = 2.0 if GameManager.has_dark_skill("arcane_barrier") else 1.0
	var regen_amount: float = max_hp * REGEN_RATE_PER_SEC * regen_mult * delta
	GameManager.heal(regen_amount)
	_process_auto_potions(delta, false)
	attack_progress_updated.emit(0.0, 0.0)

	if GameManager.current_hp >= max_hp:
		if is_seeking_battle:
			if current_enemy == null or enemy_hp <= 0.0:
				_spawn_enemy()
			_player_attack_timer = 0.0
			_enemy_attack_timer = 0.0
			_set_state(State.FIGHTING)
		else:
			_set_state(State.IDLE)


func _process_spawning(delta: float) -> void:
	if not is_seeking_battle:
		_set_state(State.IDLE)
		return
	_spawn_timer -= delta
	attack_progress_updated.emit(0.0, 0.0)
	if _spawn_timer <= 0.0:
		_spawn_enemy()
		_set_state(State.FIGHTING)


func _perform_player_attack(power_scale: float = 1.0, allow_echo: bool = true) -> void:
	if current_enemy == null:
		return

	var is_ranged: bool = GameManager.is_using_ranged_weapon()
	var is_staff: bool = GameManager.is_using_mage_staff()
	var raw_damage: float = 0.0

	if is_ranged:
		var ammo_emoji: String = GameManager.equipped_ammo.icon_emoji if GameManager.equipped_ammo != null else "🏹"
		var has_ammo: bool = GameManager.consume_one_ammo()
		ranged_shot_fired.emit(ammo_emoji, has_ammo)
		raw_damage = GameManager.get_player_damage(has_ammo) * power_scale
		if has_ammo:
			GameManager.add_mastery_xp("ranged", 1.0)
	elif is_staff:
		var tome_emoji: String = GameManager.equipped_ammo.icon_emoji if GameManager.equipped_ammo != null else "✨"
		var has_tome: bool = GameManager.consume_one_ammo()
		ranged_shot_fired.emit(tome_emoji, has_tome)
		raw_damage = GameManager.get_player_damage(has_tome) * power_scale
		if has_tome:
			GameManager.add_mastery_xp("magic", 1.0)
	else:
		raw_damage = GameManager.get_player_damage(true) * power_scale
		GameManager.add_mastery_xp("melee", 1.0)

	if GameManager.has_hero_class("troll"):
		enemy_troll_armor_shred += 1
		troll_shred_updated.emit(enemy_troll_armor_shred)

	var is_crit: bool = randf() < GameManager.get_crit_chance()
	if is_crit:
		raw_damage *= GameManager.get_crit_multiplier()
	if GameManager.has_dark_skill("dark_execution") and enemy_max_hp > 0.0 and (enemy_hp / enemy_max_hp) < 0.30:
		raw_damage *= (1.0 + GameManager.get_dark_bonus("dark_execution"))

	var ignore_armor: bool = is_crit and (GameManager.has_hero_class("abyss_ranger") or (is_ranged and GameManager.has_dark_skill("piercing_volley")))
	var final_damage: float = maxf(1.0, raw_damage - _get_effective_enemy_defense(ignore_armor))
	enemy_hp = maxf(0.0, enemy_hp - final_damage)
	enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
	player_attack_landed.emit(final_damage, is_crit)
	_apply_vampirism(final_damage)

	if GameManager.has_hero_class("blood_archmage"):
		GameManager.reduce_all_ability_cooldowns(0.5)

	if enemy_hp <= 0.0:
		_handle_enemy_defeated()
		return

	if allow_echo:
		if GameManager.has_dark_skill("echo_strike") and randf() < GameManager.get_dark_bonus("echo_strike"):
			_perform_player_attack(0.75, false)
			return
		if is_ranged:
			var double_shot_chance: float = GameManager.get_dark_bonus("phantom_arrows")
			if GameManager.has_hero_class("abyss_ranger"):
				double_shot_chance += 0.30
			if double_shot_chance > 0.0 and randf() < clampf(double_shot_chance, 0.0, 0.75):
				_perform_player_attack(0.80, false)


func _perform_enemy_attack() -> void:
	if current_enemy == null:
		return

	if randf() < GameManager.get_dodge_chance():
		enemy_attack_landed.emit(0.0, true)
		return

	var raw_damage: float = enemy_attack_damage
	if current_enemy.max_mana > 0.0 and enemy_mana >= ENEMY_SPELL_MANA_COST:
		enemy_mana = maxf(0.0, enemy_mana - ENEMY_SPELL_MANA_COST)
		enemy_mana_changed.emit(enemy_mana, current_enemy.max_mana)
		raw_damage *= 1.35

	var taken: float = GameManager.apply_damage(raw_damage)
	enemy_attack_landed.emit(taken, false)

	var reflector_dmg: float = raw_damage * 0.20 if GameManager.has_hero_class("reflector") else 0.0
	var thorns_pct: float = GameManager.get_active_buff_sum("thorns_pct")
	var thorns_dmg: float = taken * thorns_pct if (thorns_pct > 0.0 and taken > 0.0) else 0.0
	var total_reflected: float = reflector_dmg + thorns_dmg

	if total_reflected > 0.0 and current_enemy != null and GameManager.current_hp > 0.0:
		var reflected_final: float = maxf(1.0, total_reflected)
		enemy_hp = maxf(0.0, enemy_hp - reflected_final)
		enemy_hp_changed.emit(enemy_hp, enemy_max_hp)
		var ref_emoji: String = "🪞" if reflector_dmg > 0.0 else "🧣"
		dot_tick_landed.emit(ref_emoji, "Отражение", reflected_final)
		if enemy_hp <= 0.0:
			_handle_enemy_defeated()
			return

	if GameManager.current_hp <= 0.0:
		_handle_player_death()
	else:
		GameManager.try_auto_use_all_potions(true)


func _handle_enemy_defeated() -> void:
	var defeated: EnemyData = current_enemy
	var xp_earned: float = round(float(defeated.xp_reward) * GameManager.get_xp_multiplier())
	var gold_earned: float = round(float(defeated.gold_reward) * GameManager.get_gold_multiplier())

	var mimic_double_chance: float = GameManager.get_pet_secondary_value("gold_echo")
	if mimic_double_chance > 0.0 and randf() < mimic_double_chance:
		gold_earned *= 2.0
		pet_action_performed.emit("🪙", "x2 Золото!", Color(0.98, 0.85, 0.28, 1.0))

	_clear_combat_effects()
	GameManager.record_kill()
	if GameManager.is_mine_location():
		GameManager.record_mine_kill()
	GameManager.add_gold(gold_earned)
	GameManager.add_xp(xp_earned)
	GameManager.record_afk_rewards(xp_earned, gold_earned)
	enemy_defeated_reward.emit(xp_earned, gold_earned)
	_roll_drops(defeated)

	if defeated.id == GameManager.FINAL_BOSS_ID:
		GameManager.on_final_boss_defeated()
		GameManager.on_final_boss_killed_for_garden()
	elif defeated.id == GameManager.CURSE_WARDEN_ID:
		GameManager.on_curse_warden_defeated()

	_player_attack_timer = 0.0
	_enemy_attack_timer = 0.0
	_spawn_timer = SPAWN_DELAY
	_set_state(State.SPAWNING)


func _roll_drops(enemy: EnemyData) -> void:
	var drop_count: int = mini(enemy.drop_items.size(), enemy.drop_chances.size())
	for i: int in range(drop_count):
		var item: ItemData = enemy.drop_items[i]
		var chance: float = enemy.drop_chances[i]
		if item != null and randf() <= chance:
			var amount: int = maxi(1, floori(float(item.shop_pack_amount) / 2.0)) if item.item_type == ItemData.ItemType.AMMO else 1
			GameManager.add_item(item, amount, true)
	GameManager.roll_rare_seed_drops(enemy)


func _spawn_enemy() -> void:
	var location: LocationData = GameManager.current_location
	if location == null:
		return
	var next_enemy: EnemyData = location.pick_random_enemy()
	if next_enemy == null:
		return

	_enemy_dots.clear()
	current_enemy = next_enemy
	enemy_troll_armor_shred = 0
	troll_shred_updated.emit(0)

	enemy_max_hp = round(current_enemy.max_hp * GameManager.get_difficulty_enemy_hp_mult())
	enemy_hp = enemy_max_hp
	enemy_mana = current_enemy.max_mana

	var blood_tax_mult: float = 1.0 + GameManager.get_curse_value("blood_tax")
	enemy_attack_damage = current_enemy.attack_damage * GameManager.get_difficulty_enemy_dmg_mult() * blood_tax_mult

	var base_scaled_def: float = current_enemy.defense * GameManager.get_difficulty_enemy_armor_mult() + GameManager.get_difficulty_enemy_flat_armor()
	enemy_defense = base_scaled_def * (1.0 + GameManager.get_curse_value("stone_skin"))

	if current_enemy.id == GameManager.CURSE_WARDEN_ID and GameManager.reroll_boss_kills_in_run > 0:
		var kills_f: float = float(GameManager.reroll_boss_kills_in_run)
		enemy_max_hp = round(enemy_max_hp * pow(1.85, kills_f))
		enemy_hp = enemy_max_hp
		enemy_attack_damage *= pow(1.55, kills_f)
		enemy_defense *= (1.0 + kills_f * 0.45)
	elif GameManager.is_mine_location() and GameManager.mine_depth > 0:
		var depth_scale: float = 1.0 + float(GameManager.mine_depth) * 0.08
		enemy_max_hp = round(enemy_max_hp * depth_scale)
		enemy_hp = enemy_max_hp
		enemy_attack_damage *= depth_scale
		enemy_defense *= depth_scale

	_player_attack_timer = 0.0
	_enemy_attack_timer = 0.0
	_enemy_stun_timer = 0.0
	_pet_stun_used_this_fight = false
	_pet_pulse_timer = 0.0
	_pet_lightning_timer = 0.0
	_reflector_pulse_timer = 0.0
	_reset_spirit_timers()

	enemy_spawned.emit(current_enemy, enemy_hp, enemy_max_hp, enemy_mana, current_enemy.max_mana)

	var pet: PetData = GameManager.get_equipped_pet()
	if pet != null and pet.effect_type == "start_stun" and not _pet_stun_used_this_fight:
		_pet_stun_used_this_fight = true
		_enemy_stun_timer = maxf(0.5, GameManager.get_pet_effect_value("start_stun"))
		enemy_stun_changed.emit(_enemy_stun_timer)
		pet_action_performed.emit(pet.icon_emoji, "🎆 Оглушён на %.1fс!" % _enemy_stun_timer, Color(1.0, 0.78, 0.25, 1.0))
	else:
		enemy_stun_changed.emit(0.0)


func _reset_spirit_timers() -> void:
	_spirit_fire_timer = 0.0
	_spirit_wind_timer = 0.0
	_spirit_forest_timer = 0.0
	_spirit_earth_timer = 0.0


func _set_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(int(current_state))


func _on_location_changed(_location: LocationData) -> void:
	_clear_combat_effects()
	_player_attack_timer = 0.0
	_enemy_attack_timer = 0.0
	_mine_ambient_timer = 0.0
	enemy_troll_armor_shred = 0
	troll_shred_updated.emit(0)
	if not is_seeking_battle:
		current_enemy = null
		enemy_cleared.emit()
		return
	_spawn_enemy()
	if current_state != State.RESTING:
		_set_state(State.FIGHTING)


func _on_game_reset() -> void:
	is_seeking_battle = false
	_clear_combat_effects()
	_player_attack_timer = 0.0
	_enemy_attack_timer = 0.0
	_spawn_timer = 0.0
	_mine_ambient_timer = 0.0
	_auto_potion_timer = 0.0
	_reset_spirit_timers()
	current_enemy = null
	enemy_hp = 0.0
	enemy_max_hp = 0.0
	enemy_mana = 0.0
	enemy_attack_damage = 0.0
	enemy_defense = 0.0
	enemy_troll_armor_shred = 0
	troll_shred_updated.emit(0)
	battle_search_changed.emit(false)
	enemy_cleared.emit()
	_set_state(State.IDLE)
