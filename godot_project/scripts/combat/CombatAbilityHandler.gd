class_name CombatAbilityHandler
extends Node

const OVERCHARGE_TICKS_PER_SECOND: float = 12.0
const OVERCHARGE_TICK_INTERVAL: float = 1.0 / OVERCHARGE_TICKS_PER_SECOND
const OVERCHARGE_MAX_TICKS: int = 12

var _cs: CombatSystem = null
var overcharge_active: bool = false
var overcharge_slot_index: int = -1
var overcharge_tick_count: int = 0
var _overcharge_timer: float = 0.0
var _overcharge_ability: AbilityData = null
var _overcharge_trigger_cooldown: bool = true
var _enemy_dots: Array[Dictionary] = []
var _quick_cast_slots: Array[int] = []


func setup(host: CombatSystem) -> void:
	_cs = host


func clear_effects() -> void:
	_enemy_dots.clear()
	stop_overcharge(true)


func clear_dots() -> void:
	_enemy_dots.clear()


func on_abilities_changed() -> void:
	if overcharge_active and overcharge_slot_index >= 0:
		var slot_ab: AbilityData = GameManager.get_ability(overcharge_slot_index)
		if slot_ab == null or slot_ab != _overcharge_ability:
			stop_overcharge(true)


func process_auto_abilities() -> void:
	for i: int in range(GameManager.abilities.size()):
		if GameManager.is_ability_auto_cast(i):
			try_cast_ability(i, true)
			if _cs.current_state != CombatSystem.State.FIGHTING or _cs.current_enemy == null:
				return


func process_overcharge(delta: float) -> void:
	if not overcharge_active:
		return
	_overcharge_timer += delta
	while _overcharge_timer >= OVERCHARGE_TICK_INTERVAL and overcharge_active and _cs.current_state == CombatSystem.State.FIGHTING and _cs.current_enemy != null:
		_overcharge_timer -= OVERCHARGE_TICK_INTERVAL
		execute_overcharge_tick()
		if _cs.current_state != CombatSystem.State.FIGHTING or _cs.current_enemy == null:
			return


func try_cast_random_quick_ability(power_scale: float = 1.0) -> bool:
	_quick_cast_slots.clear()
	for i: int in range(GameManager.abilities.size()):
		var ab: AbilityData = GameManager.get_ability(i)
		if ab != null and GameManager.is_ability_unlocked(ab):
			_quick_cast_slots.append(i)
	if _quick_cast_slots.is_empty():
		return false
	if _quick_cast_slots.size() > 1:
		_quick_cast_slots.shuffle()
	for slot_idx: int in _quick_cast_slots:
		if try_cast_ability(slot_idx, true, true, false, power_scale):
			return true
	return false


func try_cast_ability(slot_index: int, is_auto: bool = false, ignore_cooldown: bool = false, trigger_cooldown: bool = true, power_scale: float = 1.0) -> bool:
	var ability: AbilityData = GameManager.get_ability(slot_index)
	if ability == null or not GameManager.is_ability_unlocked(ability):
		return false
	if overcharge_active and ability.effect_type == "overcharge_burn" and overcharge_slot_index == slot_index:
		if not is_auto:
			stop_overcharge(true)
			return true
		return false
	if not ignore_cooldown and GameManager.get_ability_cooldown(slot_index) > 0.0:
		return false

	var mana_cost: float = GameManager.get_ability_mana_cost(ability)
	var use_blood_cast: bool = false
	var blood_hp_cost: float = 0.0
	if GameManager.current_mana < mana_cost:
		if GameManager.has_hero_class("blood_archmage"):
			blood_hp_cost = maxf(1.0, GameManager.current_hp * 0.08)
			if GameManager.current_hp <= blood_hp_cost + 1.0:
				return false
			use_blood_cast = true
		else:
			return false

	var cd_duration: float = GameManager.get_ability_cooldown_duration(ability)
	var power_mult: float = GameManager.get_ability_power_multiplier(ability) * power_scale
	var rune_data: Dictionary = GameManager.get_ability_rune_data(ability.id)
	var rune_barrier_pct: float = float(rune_data.get("shield_barrier_pct", 0.0))

	if ability.effect_type == "heal":
		return _cast_heal_ability(slot_index, ability, is_auto, trigger_cooldown, mana_cost, use_blood_cast, blood_hp_cost, cd_duration, power_mult, rune_barrier_pct)

	if ability.effect_type == "buff":
		return _cast_buff_ability(slot_index, ability, is_auto, trigger_cooldown, mana_cost, use_blood_cast, blood_hp_cost, cd_duration, rune_barrier_pct)

	if GameManager.has_hero_class("reflector"):
		return false

	if _cs.current_state != CombatSystem.State.FIGHTING or _cs.current_enemy == null:
		return false

	if ability.effect_type == "overcharge_burn":
		if overcharge_active or not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
			return false
		_record_cast_progress(ability.id, mana_cost, 0.0)
		overcharge_active = true
		overcharge_slot_index = slot_index
		overcharge_tick_count = 0
		_overcharge_timer = 0.0
		_overcharge_ability = ability
		_overcharge_trigger_cooldown = trigger_cooldown
		_cs.ability_casted.emit(slot_index, ability)
		execute_overcharge_tick()
		return true

	if ability.effect_type == "dot":
		if (is_auto and _has_enemy_dot(ability.id)) or not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
			return false
		_record_cast_progress(ability.id, mana_cost, 0.0)
		if trigger_cooldown:
			GameManager.start_ability_cooldown(slot_index, 0.0 if _should_reset_ability_cooldown() else cd_duration)
		_apply_enemy_dot(ability, power_mult)
		_cs.ability_casted.emit(slot_index, ability)
		return true

	return _cast_offensive_ability(slot_index, ability, trigger_cooldown, mana_cost, use_blood_cast, blood_hp_cost, cd_duration, power_mult, rune_data)


func _cast_heal_ability(slot_index: int, ability: AbilityData, is_auto: bool, trigger_cooldown: bool, mana_cost: float, use_blood_cast: bool, blood_hp_cost: float, cd_duration: float, power_mult: float, rune_barrier_pct: float) -> bool:
	var max_hp: float = GameManager.get_max_hp()
	if GameManager.current_hp >= max_hp or (is_auto and (GameManager.current_hp / max_hp) > 0.85):
		return false
	if not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
		return false
	_record_cast_progress(ability.id, mana_cost, 2.5)
	if trigger_cooldown:
		GameManager.start_ability_cooldown(slot_index, cd_duration)
	var healed: float = GameManager.heal(max_hp * power_mult)
	GameManager.player_healed.emit(healed)
	if rune_barrier_pct > 0.0:
		GameManager.add_barrier(max_hp * rune_barrier_pct)
	_cs.ability_casted.emit(slot_index, ability)
	return true

func _cast_buff_ability(slot_index: int, ability: AbilityData, is_auto: bool, trigger_cooldown: bool, mana_cost: float, use_blood_cast: bool, blood_hp_cost: float, cd_duration: float, rune_barrier_pct: float) -> bool:
	if is_auto and (_cs.current_state != CombatSystem.State.FIGHTING or GameManager.has_active_buff(ability.id)):
		return false
	if not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
		return false
	_record_cast_progress(ability.id, mana_cost, 2.5)
	if trigger_cooldown:
		GameManager.start_ability_cooldown(slot_index, 0.0 if _should_reset_ability_cooldown() else cd_duration)
	GameManager.apply_ability_buff(ability, 1.0 + float(maxi(0, GameManager.magic_level - 1)) * 0.012)
	if rune_barrier_pct > 0.0:
		GameManager.add_barrier(GameManager.get_max_hp() * rune_barrier_pct)
	_cs.ability_casted.emit(slot_index, ability)
	return true

func _cast_offensive_ability(slot_index: int, ability: AbilityData, trigger_cooldown: bool, mana_cost: float, use_blood_cast: bool, blood_hp_cost: float, cd_duration: float, power_mult: float, rune_data: Dictionary) -> bool:
	var extra_hp_sac: float = 0.0
	if ability.hp_sacrifice_pct > 0.0:
		extra_hp_sac = maxf(1.0, GameManager.current_hp * ability.hp_sacrifice_pct)
		if GameManager.current_hp <= extra_hp_sac + blood_hp_cost + 1.0:
			return false
	if not _consume_spell_cost(mana_cost, use_blood_cast, blood_hp_cost):
		return false
	if extra_hp_sac > 0.0:
		GameManager.apply_rot_damage(extra_hp_sac)
	_record_cast_progress(ability.id, mana_cost, 2.5)
	if trigger_cooldown:
		GameManager.start_ability_cooldown(slot_index, 0.0 if _should_reset_ability_cooldown() else cd_duration)

	var rune_double_chance: float = float(rune_data.get("double_cast_chance", 0.0))
	var cast_mult_count: int = 2 if (rune_double_chance > 0.0 and randf() < rune_double_chance) else 1
	var rune_crit_bonus: float = float(rune_data.get("crit_bonus", 0.0))
	var rune_lifesteal_bonus: float = float(rune_data.get("lifesteal_bonus", 0.0))
	var bestiary_mult: float = 1.0 + GameManager.get_bestiary_damage_bonus(_cs.current_enemy.id)
	var pack_boss_mult: float = GameManager.get_pack_or_boss_damage_mult(_cs.current_enemy.id, _cs.pack_total_count)

	var hits: int = maxi(1, ability.hit_count) * cast_mult_count
	var total_dealt: float = 0.0
	for _h: int in range(hits):
		if _cs.current_enemy == null or _cs.current_state != CombatSystem.State.FIGHTING or _cs.get_alive_pack_count() <= 0:
			break
		var target_ratio: float = _cs.get_active_target_hp_ratio()
		var effective_power: float = power_mult
		var ignore_pct: float = clampf(ability.armor_ignore_pct, 0.0, 1.0)
		if ability.effect_type == "execute_damage" and target_ratio < 0.40:
			effective_power *= 2.0
			ignore_pct = 1.0

		var raw_damage: float = GameManager.get_player_damage() * effective_power * bestiary_mult * pack_boss_mult
		if extra_hp_sac > 0.0:
			raw_damage += extra_hp_sac * 2.5
		if GameManager.has_dark_skill("arcane_echo"):
			raw_damage += GameManager.current_mana * GameManager.get_dark_bonus("arcane_echo")

		var is_crit: bool = randf() < (GameManager.get_crit_chance() + rune_crit_bonus)
		if is_crit:
			raw_damage *= GameManager.get_crit_multiplier()
		if GameManager.has_dark_skill("dark_execution") and target_ratio < 0.30:
			raw_damage *= (1.0 + GameManager.get_dark_bonus("dark_execution"))

		var full_def_bypass: bool = ignore_pct >= 0.999 or (is_crit and GameManager.has_hero_class("abyss_ranger"))
		var eff_def: float = _cs.get_effective_enemy_defense(full_def_bypass) * (1.0 - ignore_pct)
		var final_damage: float = maxf(1.0, raw_damage - eff_def)
		total_dealt += final_damage
		_cs.player_attack_landed.emit(final_damage, is_crit)
		_cs.class_pet_handler.apply_vampirism(final_damage)
		_cs.apply_damage_to_pack_rollover(final_damage)

	var effective_lifesteal: float = ability.lifesteal_ratio + rune_lifesteal_bonus
	if effective_lifesteal > 0.0 and total_dealt > 0.0:
		var spell_heal: float = total_dealt * effective_lifesteal * maxf(0.25, 1.0 - GameManager.get_curse_value("blood_tax"))
		var actual_healed: float = GameManager.heal(spell_heal)
		if actual_healed > 0.0:
			GameManager.player_healed.emit(actual_healed)

	if ability.mana_restore_flat > 0.0:
		GameManager.restore_mana(ability.mana_restore_flat)

	_cs.ability_casted.emit(slot_index, ability)
	return true


func _should_reset_ability_cooldown() -> bool:
	var reset_chance: float = 0.0
	if GameManager.has_dark_skill("spell_overload"):
		reset_chance += GameManager.get_dark_bonus("spell_overload")
	var owl_reset: float = GameManager.get_pet_secondary_value("cooldown_haste")
	if owl_reset > 0.0:
		reset_chance += owl_reset
	return reset_chance > 0.0 and randf() < clampf(reset_chance, 0.0, 0.85)


func _record_cast_progress(ability_id: String, mana_cost: float, dark_mastery_xp: float) -> void:
	GameManager.add_mastery_xp("magic", mana_cost)
	if dark_mastery_xp > 0.0 and GameManager.is_training_grounds_location():
		GameManager.add_dark_mastery_xp(GameManager.active_dark_mastery_id, dark_mastery_xp)
	if not ability_id.is_empty():
		GameManager.record_ability_cast(ability_id)

func _consume_spell_cost(mana_cost: float, use_blood_cast: bool, blood_hp_cost: float) -> bool:
	if use_blood_cast:
		GameManager.apply_rot_damage(blood_hp_cost)
		return true
	return GameManager.spend_mana(mana_cost)


func execute_overcharge_tick() -> void:
	if not overcharge_active or _overcharge_ability == null or _cs.current_enemy == null or _cs.current_state != CombatSystem.State.FIGHTING:
		stop_overcharge(true)
		return
	var next_tick: int = overcharge_tick_count + 1
	if next_tick > OVERCHARGE_MAX_TICKS:
		stop_overcharge(true)
		return

	var hp_burn: float = pow(2.0, float(next_tick - 1))
	var extra_mana: float = float(maxi(0, next_tick - 2))
	var mana_burn: float = hp_burn + extra_mana
	if GameManager.current_hp <= hp_burn + 1.0 or GameManager.current_mana < mana_burn:
		stop_overcharge(true)
		return

	GameManager.apply_rot_damage(hp_burn)
	if not GameManager.spend_mana(mana_burn):
		stop_overcharge(true)
		return

	_record_cast_progress("", mana_burn, 1.5)
	overcharge_tick_count = next_tick
	_cs.overcharge_state_changed.emit(true, overcharge_slot_index, overcharge_tick_count)

	var power_mult: float = GameManager.get_ability_power_multiplier(_overcharge_ability)
	var rune_oc: Dictionary = GameManager.get_ability_rune_data(_overcharge_ability.id)
	var oc_crit_bonus: float = float(rune_oc.get("crit_bonus", 0.0))
	var burst_scale: float = pow(1.75, float(next_tick - 1))
	var raw_damage: float = (GameManager.get_player_damage() * power_mult + (hp_burn + mana_burn) * 4.0) * burst_scale
	raw_damage *= (1.0 + GameManager.get_bestiary_damage_bonus(_cs.current_enemy.id))
	raw_damage *= GameManager.get_pack_or_boss_damage_mult(_cs.current_enemy.id, _cs.pack_total_count)
	if GameManager.has_dark_skill("arcane_echo"):
		raw_damage += GameManager.current_mana * GameManager.get_dark_bonus("arcane_echo")

	var is_crit: bool = randf() < (GameManager.get_crit_chance() + oc_crit_bonus)
	if is_crit:
		raw_damage *= GameManager.get_crit_multiplier()
	if GameManager.has_dark_skill("dark_execution") and _cs.get_active_target_hp_ratio() < 0.30:
		raw_damage *= (1.0 + GameManager.get_dark_bonus("dark_execution"))

	var ignore_pct: float = clampf(_overcharge_ability.armor_ignore_pct, 0.0, 1.0)
	var eff_def: float = _cs.get_effective_enemy_defense(false) * (1.0 - ignore_pct)
	var final_damage: float = maxf(1.0, raw_damage - eff_def)

	_cs.overcharge_tick_fired.emit(next_tick, hp_burn, mana_burn, final_damage)
	_cs.class_pet_handler.apply_vampirism(final_damage)
	_cs.apply_damage_to_pack_rollover(final_damage)

	if _cs.current_state != CombatSystem.State.FIGHTING or _cs.current_enemy == null or _cs.get_alive_pack_count() <= 0:
		stop_overcharge(true)
	elif overcharge_tick_count >= OVERCHARGE_MAX_TICKS:
		stop_overcharge(true)


func stop_overcharge(trigger_cooldown: bool) -> void:
	var was_active: bool = overcharge_active
	var prev_slot: int = overcharge_slot_index
	var prev_ab: AbilityData = _overcharge_ability
	var should_cd: bool = trigger_cooldown and _overcharge_trigger_cooldown

	overcharge_active = false
	overcharge_slot_index = -1
	overcharge_tick_count = 0
	_overcharge_timer = 0.0
	_overcharge_ability = null
	_overcharge_trigger_cooldown = true

	if was_active:
		_cs.overcharge_state_changed.emit(false, -1, 0)
		if should_cd and prev_slot >= 0 and prev_ab != null:
			var reset_cd: bool = GameManager.has_dark_skill("spell_overload") and randf() < GameManager.get_dark_bonus("spell_overload")
			var cd_duration: float = GameManager.get_ability_cooldown_duration(prev_ab)
			GameManager.start_ability_cooldown(prev_slot, 0.0 if reset_cd else cd_duration)


func _apply_enemy_dot(ability: AbilityData, power_mult: float) -> void:
	var rune_dot: Dictionary = GameManager.get_ability_rune_data(ability.id)
	var rune_dur_mult: float = float(rune_dot.get("duration_mult", 1.0))
	var dot_entry: Dictionary = {
		"id": ability.id,
		"title": ability.title,
		"icon_emoji": ability.icon_emoji,
		"remaining": maxf(1.0, ability.duration * GameManager.get_effect_duration_multiplier() * rune_dur_mult),
		"tick_timer": 0.0,
		"power_mult": power_mult,
		"armor_ignore_pct": clampf(ability.armor_ignore_pct, 0.0, 1.0),
		"lifesteal_ratio": ability.lifesteal_ratio + float(rune_dot.get("lifesteal_bonus", 0.0)),
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


func process_enemy_dots(delta: float) -> void:
	if _enemy_dots.is_empty() or _cs.current_enemy == null:
		return
	for i: int in range(_enemy_dots.size() - 1, -1, -1):
		var d: Dictionary = _enemy_dots[i]
		d["remaining"] = float(d["remaining"]) - delta
		d["tick_timer"] = float(d["tick_timer"]) + delta
		while float(d["tick_timer"]) >= 1.0 and _cs.current_enemy != null and _cs.current_state == CombatSystem.State.FIGHTING:
			d["tick_timer"] = float(d["tick_timer"]) - 1.0
			var alive_before: int = maxi(1, _cs.get_alive_pack_count())
			var raw_dmg: float = GameManager.get_player_damage() * float(d["power_mult"]) * (1.0 + GameManager.get_bestiary_damage_bonus(_cs.current_enemy.id)) * GameManager.get_pack_or_boss_damage_mult(_cs.current_enemy.id, _cs.pack_total_count)
			if GameManager.has_dark_skill("dark_execution") and _cs.get_active_target_hp_ratio() < 0.30:
				raw_dmg *= (1.0 + GameManager.get_dark_bonus("dark_execution"))
			var eff_def: float = _cs.get_effective_enemy_defense(false) * (1.0 - float(d["armor_ignore_pct"]))
			var final_dmg: float = maxf(1.0, raw_dmg - eff_def)
			_cs.dot_tick_landed.emit(str(d["icon_emoji"]), str(d["title"]), final_dmg)
			var total_dot_dealt: float = final_dmg * float(alive_before)
			_cs.class_pet_handler.apply_vampirism(total_dot_dealt)
			var ls: float = float(d["lifesteal_ratio"])
			if ls > 0.0:
				GameManager.heal(total_dot_dealt * ls * maxf(0.25, 1.0 - GameManager.get_curse_value("blood_tax")))
			if _cs.apply_damage_to_all_alive_in_pack(final_dmg):
				return
		if float(d["remaining"]) <= 0.0:
			_enemy_dots.remove_at(i)
