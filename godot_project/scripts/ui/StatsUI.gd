extends ScrollContainer

signal reset_triggered

@onready var class_summary_label: Label = %ClassSummaryLabel
@onready var computed_stats_label: Label = %ComputedStatsLabel

@onready var melee_mastery_label: Label = %MeleeMasteryLabel
@onready var melee_xp_bar: ProgressBar = %MeleeXPBar
@onready var melee_xp_label: Label = %MeleeXPLabel

@onready var ranged_mastery_label: Label = %RangedMasteryLabel
@onready var ranged_xp_bar: ProgressBar = %RangedXPBar
@onready var ranged_xp_label: Label = %RangedXPLabel

@onready var magic_mastery_label: Label = %MagicMasteryLabel
@onready var magic_xp_bar: ProgressBar = %MagicXPBar
@onready var magic_xp_label: Label = %MagicXPLabel

@onready var str_value_label: Label = %StrValueLabel
@onready var str_sp_button: Button = %StrSPButton
@onready var str_gold_button: Button = %StrGoldButton

@onready var agi_value_label: Label = %AgiValueLabel
@onready var agi_sp_button: Button = %AgiSPButton
@onready var agi_gold_button: Button = %AgiGoldButton

@onready var end_value_label: Label = %EndValueLabel
@onready var end_sp_button: Button = %EndSPButton
@onready var end_gold_button: Button = %EndGoldButton
@onready var reset_button: Button = %ResetButton

var _reset_confirm_deadline_ms: int = 0
var _dirty: bool = true


func _ready() -> void:
	GameManager.stats_changed.connect(_on_state_updated)
	GameManager.skills_changed.connect(_on_state_updated)
	GameManager.dark_skills_changed.connect(_on_state_updated)
	GameManager.difficulty_changed.connect(_on_state_updated)
	GameManager.mastery_changed.connect(func(_s: String, _l: int, _up: bool) -> void:
		if is_visible_in_tree():
			_refresh_masteries()
		else:
			_dirty = true
	)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _on_state_updated())
	GameManager.pets_changed.connect(_on_state_updated)
	GameManager.dark_forge_changed.connect(_on_state_updated)

	str_sp_button.pressed.connect(func() -> void: GameManager.upgrade_stat_with_skill_point("strength"))
	agi_sp_button.pressed.connect(func() -> void: GameManager.upgrade_stat_with_skill_point("agility"))
	end_sp_button.pressed.connect(func() -> void: GameManager.upgrade_stat_with_skill_point("endurance"))

	str_gold_button.pressed.connect(func() -> void: GameManager.train_stat_with_gold("strength"))
	agi_gold_button.pressed.connect(func() -> void: GameManager.train_stat_with_gold("agility"))
	end_gold_button.pressed.connect(func() -> void: GameManager.train_stat_with_gold("endurance"))

	HoldAutoClicker.attach(str_sp_button, 50.0)
	HoldAutoClicker.attach(agi_sp_button, 50.0)
	HoldAutoClicker.attach(end_sp_button, 50.0)
	HoldAutoClicker.attach(str_gold_button, 50.0)
	HoldAutoClicker.attach(agi_gold_button, 50.0)
	HoldAutoClicker.attach(end_gold_button, 50.0)

	reset_button.pressed.connect(_on_reset_button_pressed)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and _dirty:
		_refresh()


func _on_state_updated() -> void:
	if not is_visible_in_tree():
		_dirty = true
		return
	_refresh()


func _process(_delta: float) -> void:
	if _reset_confirm_deadline_ms > 0 and Time.get_ticks_msec() > _reset_confirm_deadline_ms:
		_reset_confirm_deadline_ms = 0
		reset_button.text = "🔄 Сброс"


func _refresh() -> void:
	_dirty = false
	var hc: HeroClassData = GameManager.get_current_class()
	var pet: PetData = GameManager.get_equipped_pet()
	var pet_text: String = "  |  🐾 Путник: %s %s (Ур.%d)" % [pet.icon_emoji, pet.pet_name, GameManager.get_pet_training_level(pet.id)] if pet != null else "  |  🐾 Путник: не выбран"
	if hc != null:
		class_summary_label.text = "%s Класс: %s — %s%s" % [hc.icon_emoji, hc.title, hc.passive_summary, pet_text]
	else:
		class_summary_label.text = "🎭 Класс: Странник%s" % pet_text

	var total_str: int = GameManager.get_total_strength()
	var total_agi: int = GameManager.get_total_agility()
	var total_end: int = GameManager.get_total_endurance()
	var dmg: float = GameManager.get_player_damage()
	var dps: float = GameManager.get_player_dps()
	var atk_interval: float = GameManager.get_player_attack_interval()
	var armor: float = GameManager.get_armor_reduction()

	var style_info: String = "Ближний бой"
	if GameManager.has_hero_class("reflector"):
		style_info = "🪞 Отражение 20% + 5% HP/с + 0.1% гниение"
	elif GameManager.is_equipment_disabled():
		style_info = "Духи (🔥%d/🌪️%d/🌿%d/🪨%d)" % [
			GameManager.get_spirit_training_level("fire"),
			GameManager.get_spirit_training_level("wind"),
			GameManager.get_spirit_training_level("forest"),
			GameManager.get_spirit_training_level("earth"),
		]
	elif GameManager.is_using_ranged_weapon():
		style_info = "Дальний бой (снарядов: %d)" % GameManager.equipped_ammo_count
	elif GameManager.is_using_mage_staff():
		var tome_str: String = "♾️" if (GameManager.equipped_ammo != null and GameManager.equipped_ammo.is_dark_forged) else str(GameManager.equipped_ammo_count)
		style_info = "Маг-посох (книг: %s)" % tome_str

	var total_int: int = GameManager.get_total_intellect()
	var spell_power_bonus: int = roundi(GameManager.get_equipped_spell_power_bonus() * 100.0 + float(total_int) * 1.5)
	var mana_red_pct: int = roundi(GameManager.get_equipped_mana_cost_reduction() * 100.0)
	var dur_bonus_pct: int = roundi((GameManager.get_effect_duration_multiplier() - 1.0) * 100.0)

	computed_stats_label.text = (
		"⚔️ Урон: %s (DPS: %s, %s)  |  ⚡ Атака: %.2fс  |  🎯 Крит: %.0f%% (x%.2f)  |  💨 Уклон: %.1f%%  |  🛡️ Броня: %s  |  🧠 Инта: %d (✨+%d%%, -%d%% МП, +%d%% длит.)  |  💧 Мана: %s (+%.1f/с)  |  💰 Золото x%.2f  |  ✨ XP x%.2f  |  💀 Сл.%d  |  Побед: %d"
		% [
			NumberFormatter.format_number(dmg),
			NumberFormatter.format_number(dps),
			style_info,
			atk_interval,
			GameManager.get_crit_chance() * 100.0,
			GameManager.get_crit_multiplier(),
			GameManager.get_dodge_chance() * 100.0,
			NumberFormatter.format_number(armor),
			total_int,
			spell_power_bonus,
			mana_red_pct,
			dur_bonus_pct,
			NumberFormatter.format_number(GameManager.get_max_mana()),
			GameManager.get_mana_regen_per_sec(),
			GameManager.get_gold_multiplier(),
			GameManager.get_xp_multiplier(),
			GameManager.difficulty_level,
			GameManager.enemies_defeated,
		]
	)

	_refresh_masteries()

	var bonus_str: int = total_str - GameManager.base_strength
	var bonus_agi: int = total_agi - GameManager.base_agility
	var bonus_end: int = total_end - GameManager.base_endurance

	str_value_label.text = "💪 Сила: %d (%d + %d)" % [total_str, GameManager.base_strength, bonus_str]
	agi_value_label.text = "⚡ Ловкость: %d (%d + %d)" % [total_agi, GameManager.base_agility, bonus_agi]
	end_value_label.text = "🛡️ Выносливость: %d (%d + %d)" % [total_end, GameManager.base_endurance, bonus_end]

	var has_sp: bool = GameManager.skill_points > 0
	str_sp_button.disabled = not has_sp
	agi_sp_button.disabled = not has_sp
	end_sp_button.disabled = not has_sp

	var str_cost: float = GameManager.get_train_cost("strength")
	var agi_cost: float = GameManager.get_train_cost("agility")
	var end_cost: float = GameManager.get_train_cost("endurance")

	str_gold_button.text = "Тренир. (%s з.)" % NumberFormatter.format_number(str_cost)
	agi_gold_button.text = "Тренир. (%s з.)" % NumberFormatter.format_number(agi_cost)
	end_gold_button.text = "Тренир. (%s з.)" % NumberFormatter.format_number(end_cost)

	str_gold_button.disabled = GameManager.gold < str_cost
	agi_gold_button.disabled = GameManager.gold < agi_cost
	end_gold_button.disabled = GameManager.gold < end_cost


func _refresh_masteries() -> void:
	var m_lvl: int = GameManager.get_mastery_level("melee")
	var m_xp: float = GameManager.get_mastery_xp("melee")
	var m_req: float = GameManager.get_mastery_xp_required("melee", m_lvl)
	var m_pct: int = roundi((GameManager.get_mastery_bonus_multiplier("melee") - 1.0) * 100.0)
	melee_mastery_label.text = "⚔️ Ближний бой Ур.%d (+%d%% урон)" % [m_lvl, m_pct]
	melee_xp_bar.max_value = m_req
	melee_xp_bar.value = m_xp
	melee_xp_label.text = "%.0f / %.0f XP" % [m_xp, m_req]

	var r_lvl: int = GameManager.get_mastery_level("ranged")
	var r_xp: float = GameManager.get_mastery_xp("ranged")
	var r_req: float = GameManager.get_mastery_xp_required("ranged", r_lvl)
	var r_pct: int = roundi((GameManager.get_mastery_bonus_multiplier("ranged") - 1.0) * 100.0)
	var r_crit: float = float(maxi(0, r_lvl - 1)) * 0.3
	ranged_mastery_label.text = "🏹 Дальний бой Ур.%d (+%d%%, +%.1f%% крит)" % [r_lvl, r_pct, r_crit]
	ranged_xp_bar.max_value = r_req
	ranged_xp_bar.value = r_xp
	ranged_xp_label.text = "%.0f / %.0f XP" % [r_xp, r_req]

	var g_lvl: int = GameManager.get_mastery_level("magic")
	var g_xp: float = GameManager.get_mastery_xp("magic")
	var g_req: float = GameManager.get_mastery_xp_required("magic", g_lvl)
	var g_pct: int = roundi((GameManager.get_mastery_bonus_multiplier("magic") - 1.0) * 100.0)
	var g_reg: int = maxi(0, g_lvl - 1) * 4
	magic_mastery_label.text = "✨ Магия Ур.%d (+%d%% сила, +%d%% реген)" % [g_lvl, g_pct, g_reg]
	magic_xp_bar.max_value = g_req
	magic_xp_bar.value = g_xp
	magic_xp_label.text = "%.0f / %.0f XP" % [g_xp, g_req]


func _on_reset_button_pressed() -> void:
	var now_ms: int = Time.get_ticks_msec()
	if _reset_confirm_deadline_ms == 0 or now_ms > _reset_confirm_deadline_ms:
		_reset_confirm_deadline_ms = now_ms + 3000
		reset_button.text = "⚠️ Стереть ВСЁ?"
		return
	_reset_confirm_deadline_ms = 0
	reset_button.text = "🔄 Сброс"
	reset_triggered.emit()
	GameManager.reset_progress()
