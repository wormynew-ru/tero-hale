class_name CombatClassAndPetHandler
extends Node

const SPIRIT_FIRE_INTERVAL: float = 1.4
const SPIRIT_WIND_INTERVAL: float = 0.95
const SPIRIT_FOREST_INTERVAL: float = 2.5
const SPIRIT_EARTH_INTERVAL: float = 2.0

var _cs: CombatSystem = null
var _spirit_fire_timer: float = 0.0
var _spirit_wind_timer: float = 0.0
var _spirit_forest_timer: float = 0.0
var _spirit_earth_timer: float = 0.0
var _pet_stun_used_this_fight: bool = false
var _pet_pulse_timer: float = 0.0
var _pet_lightning_timer: float = 0.0
var _reflector_pulse_timer: float = 0.0


func setup(host: CombatSystem) -> void:
	_cs = host


func reset_spirit_timers() -> void:
	_spirit_fire_timer = 0.0
	_spirit_wind_timer = 0.0
	_spirit_forest_timer = 0.0
	_spirit_earth_timer = 0.0


func reset_combat_timers() -> void:
	_pet_pulse_timer = 0.0
	_pet_lightning_timer = 0.0
	_reflector_pulse_timer = 0.0


func reset_for_spawn() -> void:
	_pet_stun_used_this_fight = false
	_pet_pulse_timer = 0.0
	_pet_lightning_timer = 0.0
	_reflector_pulse_timer = 0.0
	reset_spirit_timers()


func apply_start_of_battle_effects() -> void:
	var pet: PetData = GameManager.get_equipped_pet()
	if pet != null and pet.effect_type == "start_stun" and not _pet_stun_used_this_fight:
		_pet_stun_used_this_fight = true
		var stun_dur: float = maxf(0.5, GameManager.get_pet_effect_value("start_stun"))
		_cs.set_enemy_stun_timer(stun_dur)
		_cs.enemy_stun_changed.emit(stun_dur)
		_cs.pet_action_performed.emit(pet.icon_emoji, "🎆 Оглушён на %.1fс!" % stun_dur, Color(1.0, 0.78, 0.25, 1.0))
	else:
		_cs.enemy_stun_changed.emit(0.0)

	if GameManager.has_hero_class("reflector") and _cs.current_state == CombatSystem.State.FIGHTING:
		trigger_reflector_aura_pulse()


func trigger_reflector_aura_pulse() -> void:
	if _cs.current_enemy == null or _cs.get_alive_pack_count() <= 0:
		return
	var hp_aura_dmg: float = maxf(1.0, GameManager.get_max_hp() * 0.05)
	var rot_dmg: float = _cs.get_unit_max_hp() * 0.001
	var aura_mult: float = (1.0 + GameManager.get_dark_bonus("reflect_fortress")) * GameManager.get_pack_or_boss_damage_mult(_cs.current_enemy.id, _cs.pack_total_count)
	var total_dmg: float = (hp_aura_dmg + rot_dmg) * aura_mult
	if GameManager.is_training_grounds_location():
		GameManager.add_dark_mastery_xp(GameManager.active_dark_mastery_id, 2.5)
	_cs.dot_tick_landed.emit("🪞", "Аура 5% HP + Гниение 0.1%", total_dmg)
	_cs.apply_damage_to_all_alive_in_pack(total_dmg)


func process_reflector_aura(delta: float) -> void:
	_reflector_pulse_timer += delta
	while _reflector_pulse_timer >= 1.0 and _cs.current_enemy != null and _cs.current_state == CombatSystem.State.FIGHTING:
		_reflector_pulse_timer -= 1.0
		trigger_reflector_aura_pulse()
		if _cs.current_state != CombatSystem.State.FIGHTING or _cs.current_enemy == null:
			return


func process_pet_combat(delta: float) -> void:
	var pet: PetData = GameManager.get_equipped_pet()
	if pet == null or _cs.current_enemy == null:
		return
	match pet.effect_type:
		"aura_regen":
			var heal_amt: float = GameManager.get_max_hp() * GameManager.get_pet_effect_value("aura_regen") * delta
			if GameManager.current_hp < GameManager.get_max_hp():
				GameManager.heal(heal_amt, false)
		"enemy_burn":
			_pet_pulse_timer += delta
			while _pet_pulse_timer >= 1.0 and _cs.current_enemy != null and _cs.current_state == CombatSystem.State.FIGHTING:
				_pet_pulse_timer -= 1.0
				var burn_dmg: float = maxf(1.0, _cs.get_unit_max_hp() * GameManager.get_pet_effect_value("enemy_burn")) * GameManager.get_pack_or_boss_damage_mult(_cs.current_enemy.id, _cs.pack_total_count)
				_cs.dot_tick_landed.emit(pet.icon_emoji, pet.pet_name, burn_dmg)
				if _cs.apply_damage_to_all_alive_in_pack(burn_dmg):
					return
		"crit_lightning":
			_pet_lightning_timer += delta
			while _pet_lightning_timer >= 4.0 and _cs.current_enemy != null and _cs.current_state == CombatSystem.State.FIGHTING:
				_pet_lightning_timer -= 4.0
				var bolt_mult: float = GameManager.get_pet_training_multiplier(pet.id)
				var bolt_dmg: float = maxf(1.0, (GameManager.get_max_hp() * 0.08 + GameManager.get_player_damage() * 1.6) * bolt_mult) * GameManager.get_pack_or_boss_damage_mult(_cs.current_enemy.id, _cs.pack_total_count)
				_cs.dot_tick_landed.emit(pet.icon_emoji, "Молния", bolt_dmg)
				if _cs.apply_damage_to_all_alive_in_pack(bolt_dmg):
					return


func process_spirit_companions(delta: float) -> void:
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
		if _cs.current_state != CombatSystem.State.FIGHTING or _cs.current_enemy == null:
			return

	if _spirit_wind_timer >= SPIRIT_WIND_INTERVAL:
		_spirit_wind_timer -= SPIRIT_WIND_INTERVAL
		var wind_pow: float = base_power_mult * GameManager.get_spirit_power_multiplier("wind")
		var wind_raw: float = (10.0 + float(GameManager.get_total_agility()) * 1.3) * GameManager.get_mastery_bonus_multiplier("ranged") * wind_pow
		_deal_spirit_damage("Дух Ветра", "🌪️", wind_raw, 0.65, "ranged")
		if _cs.current_state != CombatSystem.State.FIGHTING or _cs.current_enemy == null:
			return

	if _spirit_forest_timer >= SPIRIT_FOREST_INTERVAL:
		_spirit_forest_timer -= SPIRIT_FOREST_INTERVAL
		var forest_pow: float = base_power_mult * GameManager.get_spirit_power_multiplier("forest")
		var blood_tax_mult: float = maxf(0.25, 1.0 - GameManager.get_curse_value("blood_tax"))
		var heal_amt: float = (GameManager.get_max_hp() * 0.04 + float(GameManager.get_total_endurance()) * 0.8) * forest_pow * blood_tax_mult
		var actual_heal: float = GameManager.heal(heal_amt)
		GameManager.restore_mana(6.0 * forest_pow)
		_cs.spirit_action_performed.emit("Дух Леса", "🌿", actual_heal if actual_heal > 0.0 else heal_amt, true)

	if _spirit_earth_timer >= SPIRIT_EARTH_INTERVAL:
		_spirit_earth_timer -= SPIRIT_EARTH_INTERVAL
		var earth_pow: float = base_power_mult * GameManager.get_spirit_power_multiplier("earth")
		var earth_raw: float = (12.0 + float(GameManager.get_total_endurance()) * 1.5) * GameManager.get_mastery_bonus_multiplier("melee") * earth_pow
		_deal_spirit_damage("Дух Земли", "🪨", earth_raw, 1.0, "melee")


func _deal_spirit_damage(spirit_name: String, emoji: String, raw_base: float, def_factor: float, mastery_id: String) -> void:
	if _cs.current_enemy == null or _cs.get_alive_pack_count() <= 0:
		return
	var raw_damage: float = raw_base * (1.0 + GameManager.get_bestiary_damage_bonus(_cs.current_enemy.id)) * GameManager.get_pack_or_boss_damage_mult(_cs.current_enemy.id, _cs.pack_total_count)
	var is_crit: bool = randf() < GameManager.get_crit_chance()
	if is_crit:
		raw_damage *= GameManager.get_crit_multiplier()
	if GameManager.has_dark_skill("dark_execution") and _cs.get_active_target_hp_ratio() < 0.30:
		raw_damage *= (1.0 + GameManager.get_dark_bonus("dark_execution"))

	var eff_def: float = _cs.get_effective_enemy_defense(false) * def_factor
	var final_damage: float = maxf(1.0, raw_damage - eff_def)
	_cs.spirit_action_performed.emit(spirit_name, emoji, final_damage, false)
	GameManager.add_mastery_xp(mastery_id, 1.0)
	if GameManager.is_training_grounds_location():
		GameManager.add_dark_mastery_xp(GameManager.active_dark_mastery_id, 2.0)
	apply_vampirism(final_damage)
	_cs.apply_damage_to_pack_rollover(final_damage)


func apply_vampirism(damage_dealt: float) -> void:
	if damage_dealt <= 0.0:
		return
	var leach_pct: float = GameManager.get_dark_bonus("blood_vampirism") + GameManager.get_active_buff_sum("lifesteal_pct")
	if leach_pct <= 0.0:
		return
	var leach: float = damage_dealt * leach_pct
	if leach > 0.0:
		GameManager.heal(leach)
