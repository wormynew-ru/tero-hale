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
@onready var dark_mastery_rows_vbox: VBoxContainer = %DarkMasteryRowsVBox

@onready var str_value_label: Label = %StrValueLabel
@onready var str_sp_button: Button = %StrSPButton
@onready var str_sp_10_button: Button = %StrSP10Button
@onready var str_sp_25_button: Button = %StrSP25Button
@onready var str_sp_50_button: Button = %StrSP50Button
@onready var str_sp_max_button: Button = %StrSPMaxButton
@onready var str_gold_button: Button = %StrGoldButton
@onready var str_gold_10_button: Button = %StrGold10Button
@onready var str_gold_25_button: Button = %StrGold25Button
@onready var str_gold_50_button: Button = %StrGold50Button
@onready var str_gold_max_button: Button = %StrGoldMaxButton

@onready var agi_value_label: Label = %AgiValueLabel
@onready var agi_sp_button: Button = %AgiSPButton
@onready var agi_sp_10_button: Button = %AgiSP10Button
@onready var agi_sp_25_button: Button = %AgiSP25Button
@onready var agi_sp_50_button: Button = %AgiSP50Button
@onready var agi_sp_max_button: Button = %AgiSPMaxButton
@onready var agi_gold_button: Button = %AgiGoldButton
@onready var agi_gold_10_button: Button = %AgiGold10Button
@onready var agi_gold_25_button: Button = %AgiGold25Button
@onready var agi_gold_50_button: Button = %AgiGold50Button
@onready var agi_gold_max_button: Button = %AgiGoldMaxButton

@onready var end_value_label: Label = %EndValueLabel
@onready var end_sp_button: Button = %EndSPButton
@onready var end_sp_10_button: Button = %EndSP10Button
@onready var end_sp_25_button: Button = %EndSP25Button
@onready var end_sp_50_button: Button = %EndSP50Button
@onready var end_sp_max_button: Button = %EndSPMaxButton
@onready var end_gold_button: Button = %EndGoldButton
@onready var end_gold_10_button: Button = %EndGold10Button
@onready var end_gold_25_button: Button = %EndGold25Button
@onready var end_gold_50_button: Button = %EndGold50Button
@onready var end_gold_max_button: Button = %EndGoldMaxButton

@onready var int_value_label: Label = %IntValueLabel
@onready var int_sp_button: Button = %IntSPButton
@onready var int_sp_10_button: Button = %IntSP10Button
@onready var int_sp_25_button: Button = %IntSP25Button
@onready var int_sp_50_button: Button = %IntSP50Button
@onready var int_sp_max_button: Button = %IntSPMaxButton
@onready var int_gold_button: Button = %IntGoldButton
@onready var int_gold_10_button: Button = %IntGold10Button
@onready var int_gold_25_button: Button = %IntGold25Button
@onready var int_gold_50_button: Button = %IntGold50Button
@onready var int_gold_max_button: Button = %IntGoldMaxButton

@onready var export_txt_button: Button = %ExportTxtButton
@onready var import_txt_button: Button = %ImportTxtButton
@onready var copy_txt_button: Button = %CopyTxtButton
@onready var paste_txt_button: Button = %PasteTxtButton
@onready var save_transfer_status_label: Label = %SaveTransferStatusLabel
@onready var export_txt_dialog: FileDialog = %ExportTxtDialog
@onready var import_txt_dialog: FileDialog = %ImportTxtDialog
@onready var reset_button: Button = %ResetButton

var _reset_confirm_deadline_ms: int = 0
var _paste_confirm_deadline_ms: int = 0
var _dirty: bool = true
var _refresh_queued: bool = false
var _dark_mastery_rows: Array[Dictionary] = []


func _ready() -> void:
	set_process(false)
	GameManager.stats_changed.connect(_on_state_updated)
	GameManager.skills_changed.connect(_on_state_updated)
	GameManager.dark_skills_changed.connect(_on_state_updated)
	GameManager.difficulty_changed.connect(_on_state_updated)
	GameManager.parallel_battle_changed.connect(func(_c: int) -> void: _on_state_updated())
	GameManager.mastery_changed.connect(func(_s: String, _l: int, _up: bool) -> void:
		if is_visible_in_tree():
			_refresh_masteries()
		else:
			_dirty = true
	)
	GameManager.dark_mastery_changed.connect(func(_m: String, _l: int, _up: bool) -> void:
		if is_visible_in_tree():
			_refresh_dark_masteries()
		else:
			_dirty = true
	)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _on_state_updated())
	GameManager.pets_changed.connect(_on_state_updated)
	GameManager.dark_forge_changed.connect(_on_state_updated)
	GameManager.barrier_changed.connect(func(_cur: float, _mx: float) -> void: _on_state_updated())
	GameManager.challenge_changed.connect(_on_state_updated)
	GameManager.wave_dungeon_changed.connect(_on_state_updated)

	_connect_stat_buttons("strength", [str_sp_button, str_sp_10_button, str_sp_25_button, str_sp_50_button, str_sp_max_button], [str_gold_button, str_gold_10_button, str_gold_25_button, str_gold_50_button, str_gold_max_button])
	_connect_stat_buttons("agility", [agi_sp_button, agi_sp_10_button, agi_sp_25_button, agi_sp_50_button, agi_sp_max_button], [agi_gold_button, agi_gold_10_button, agi_gold_25_button, agi_gold_50_button, agi_gold_max_button])
	_connect_stat_buttons("endurance", [end_sp_button, end_sp_10_button, end_sp_25_button, end_sp_50_button, end_sp_max_button], [end_gold_button, end_gold_10_button, end_gold_25_button, end_gold_50_button, end_gold_max_button])
	_connect_stat_buttons("intellect", [int_sp_button, int_sp_10_button, int_sp_25_button, int_sp_50_button, int_sp_max_button], [int_gold_button, int_gold_10_button, int_gold_25_button, int_gold_50_button, int_gold_max_button])

	HoldAutoClicker.attach(str_sp_button, 50.0)
	HoldAutoClicker.attach(agi_sp_button, 50.0)
	HoldAutoClicker.attach(end_sp_button, 50.0)
	HoldAutoClicker.attach(int_sp_button, 50.0)
	HoldAutoClicker.attach(str_gold_button, 50.0)
	HoldAutoClicker.attach(agi_gold_button, 50.0)
	HoldAutoClicker.attach(end_gold_button, 50.0)
	HoldAutoClicker.attach(int_gold_button, 50.0)

	export_txt_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_txt_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_txt_dialog.filters = PackedStringArray(["*.txt ; Текстовое сохранение (.txt)"])
	export_txt_dialog.use_native_dialog = true
	export_txt_dialog.file_selected.connect(_on_export_file_selected)

	import_txt_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	import_txt_dialog.access = FileDialog.ACCESS_FILESYSTEM
	import_txt_dialog.filters = PackedStringArray(["*.txt ; Текстовое сохранение (.txt)"])
	import_txt_dialog.use_native_dialog = true
	import_txt_dialog.file_selected.connect(_on_import_file_selected)

	export_txt_button.pressed.connect(_on_export_txt_pressed)
	import_txt_button.pressed.connect(_on_import_txt_pressed)
	copy_txt_button.pressed.connect(_on_copy_txt_pressed)
	paste_txt_button.pressed.connect(_on_paste_txt_pressed)

	reset_button.pressed.connect(_on_reset_button_pressed)
	_build_dark_mastery_rows_once()
	_refresh()


func _connect_stat_buttons(stat_key: String, sp_buttons: Array[Button], gold_buttons: Array[Button]) -> void:
	var amounts: Array[int] = [1, 10, 25, 50, 0]
	for idx: int in range(amounts.size()):
		var amt: int = amounts[idx]
		sp_buttons[idx].pressed.connect(func() -> void: GameManager.upgrade_stat_with_skill_points_bulk(stat_key, amt))
		gold_buttons[idx].pressed.connect(func() -> void: GameManager.train_stat_with_gold_bulk(stat_key, amt))


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and _dirty:
		_refresh()


func _on_state_updated() -> void:
	if not is_visible_in_tree():
		_dirty = true
		return
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_flush_deferred_refresh")


func _flush_deferred_refresh() -> void:
	_refresh_queued = false
	if not is_visible_in_tree():
		_dirty = true
		return
	_refresh()


func _process(_delta: float) -> void:
	var now_ms: int = Time.get_ticks_msec()
	if _reset_confirm_deadline_ms > 0 and now_ms > _reset_confirm_deadline_ms:
		_reset_confirm_deadline_ms = 0
		reset_button.text = "🔄 Сброс"
	if _paste_confirm_deadline_ms > 0 and now_ms > _paste_confirm_deadline_ms:
		_paste_confirm_deadline_ms = 0
		paste_txt_button.text = "📋 Вставить из буфера"
	if _reset_confirm_deadline_ms == 0 and _paste_confirm_deadline_ms == 0:
		set_process(false)


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
	var dmg: float = GameManager.get_basic_attack_damage()
	var dps: float = GameManager.get_player_dps()
	var atk_interval: float = GameManager.get_player_attack_interval()
	var armor: float = GameManager.get_armor_reduction()

	var style_info: String = "Ближний бой"
	if GameManager.has_hero_class("reflector"):
		var ref_pct: float = GameManager.get_damage_reflection_pct() * 100.0
		var mit_pct: float = GameManager.get_reflector_mitigation_pct() * 100.0
		style_info = "🪞 Отражение %.0f%% (поглощ. %.0f%% до брони) + 5%% HP/с + 0.1%% гниение (стак +%s, x20 HP)" % [
			ref_pct,
			mit_pct,
			NumberFormatter.format_number(float(GameManager.reflector_kill_hp_stacks)),
		]
	elif GameManager.has_hero_class("blood_archmage"):
		style_info = "🩸 10% шанс каста случайных чар вместо тычки (2x Инта, 3x MP/Инта)"
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

	var max_bar: float = GameManager.get_max_barrier()
	var barrier_str: String = "%s/%s" % [NumberFormatter.format_number(GameManager.current_barrier), NumberFormatter.format_number(max_bar)]
	if GameManager.has_hero_class("reflector"):
		barrier_str = "→ x20 Max HP (+%s)" % NumberFormatter.format_number(GameManager.get_raw_max_barrier() * 20.0 * 1.3)
	var ch_def: Dictionary = GameManager.get_challenge_def(GameManager.active_challenge_id)
	var extra_tags: Array[String] = []
	if not ch_def.is_empty():
		var r_min: int = floori(GameManager.run_elapsed_seconds / 60.0)
		var r_sec: int = floori(fmod(GameManager.run_elapsed_seconds, 60.0))
		extra_tags.append("🔥 %s (%d:%02d)" % [str(ch_def.get("title", "")), r_min, r_sec])
	if not GameManager.well_run_blessing.is_empty():
		extra_tags.append("⛲ %s" % GameManager.get_well_blessing_label())
	if GameManager.has_hero_class("alchemist"):
		extra_tags.append("⚗️ Золотая реакция: +%s к ручной атаке" % NumberFormatter.format_number(GameManager.get_alchemist_gold_reaction_bonus()))
	if GameManager.wave_dungeon_clears > 0:
		extra_tags.append("🏰 Данжей: %d" % GameManager.wave_dungeon_clears)
	var reflect_total_pct: float = GameManager.get_damage_reflection_pct() * 100.0
	if reflect_total_pct > 0.0:
		extra_tags.append("🪞 Отражение: %.0f%%" % reflect_total_pct)
	if GameManager.parallel_battle_count > 1:
		extra_tags.append("⚔️ Бои: x%d" % GameManager.parallel_battle_count)
	var extra_suffix: String = ("  |  " + "  |  ".join(extra_tags)) if not extra_tags.is_empty() else ""

	computed_stats_label.text = (
		"⚔️ Урон: %s (DPS: %s, %s)  |  ⚡ Атака: %.2fс  |  🎯 Крит: %.0f%% (x%.2f)  |  💨 Уклон: %.1f%%  |  🛡️ Броня: %s  |  🛡️ Барьер: %s  |  🧠 Инта: %d (✨+%d%%, -%d%% МП, +%d%% длит.)  |  💧 Мана: %s (+%.1f/с)  |  💰 Золото x%.2f  |  ✨ XP x%.2f  |  💀 Сл.%d  |  Побед: %d%s"
		% [
			NumberFormatter.format_number(dmg),
			NumberFormatter.format_number(dps),
			style_info,
			atk_interval,
			GameManager.get_crit_chance() * 100.0,
			GameManager.get_crit_multiplier(),
			GameManager.get_dodge_chance() * 100.0,
			NumberFormatter.format_number(armor),
			barrier_str,
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
			extra_suffix,
		]
	)

	_refresh_masteries()
	_refresh_dark_masteries()

	var bonus_str: int = total_str - GameManager.base_strength
	var bonus_agi: int = total_agi - GameManager.base_agility
	var bonus_end: int = total_end - GameManager.base_endurance
	var bonus_int: int = total_int - GameManager.base_intellect

	str_value_label.text = "💪 Сила: %d (%d + %d)" % [total_str, GameManager.base_strength, bonus_str]
	agi_value_label.text = "⚡ Ловкость: %d (%d + %d)" % [total_agi, GameManager.base_agility, bonus_agi]
	end_value_label.text = "🛡️ Выносливость: %d (%d + %d)" % [total_end, GameManager.base_endurance, bonus_end]
	int_value_label.text = "🧠 Инта: %d (%d + %d)" % [total_int, GameManager.base_intellect, bonus_int]

	_refresh_stat_bulk_row("strength", [str_sp_button, str_sp_10_button, str_sp_25_button, str_sp_50_button, str_sp_max_button], [str_gold_button, str_gold_10_button, str_gold_25_button, str_gold_50_button, str_gold_max_button])
	_refresh_stat_bulk_row("agility", [agi_sp_button, agi_sp_10_button, agi_sp_25_button, agi_sp_50_button, agi_sp_max_button], [agi_gold_button, agi_gold_10_button, agi_gold_25_button, agi_gold_50_button, agi_gold_max_button])
	_refresh_stat_bulk_row("endurance", [end_sp_button, end_sp_10_button, end_sp_25_button, end_sp_50_button, end_sp_max_button], [end_gold_button, end_gold_10_button, end_gold_25_button, end_gold_50_button, end_gold_max_button])
	_refresh_stat_bulk_row("intellect", [int_sp_button, int_sp_10_button, int_sp_25_button, int_sp_50_button, int_sp_max_button], [int_gold_button, int_gold_10_button, int_gold_25_button, int_gold_50_button, int_gold_max_button])


func _refresh_stat_bulk_row(stat_key: String, sp_buttons: Array[Button], gold_buttons: Array[Button]) -> void:
	var sp_avail: int = GameManager.skill_points
	sp_buttons[0].disabled = sp_avail < 1
	sp_buttons[1].disabled = sp_avail < 10
	sp_buttons[2].disabled = sp_avail < 25
	sp_buttons[3].disabled = sp_avail < 50
	sp_buttons[4].disabled = sp_avail <= 0
	sp_buttons[4].text = "Макс (+%d)" % sp_avail if sp_avail > 0 else "Макс"

	var fixed_steps: Array[int] = [1, 10, 25, 50]
	for idx: int in range(fixed_steps.size()):
		var step_cnt: int = fixed_steps[idx]
		var bulk_res: Dictionary = GameManager.get_train_bulk_cost(stat_key, step_cnt)
		var step_cost: float = float(bulk_res.get("cost", 0.0))
		gold_buttons[idx].text = "+%d (%s з.)" % [step_cnt, NumberFormatter.format_number(step_cost)]
		gold_buttons[idx].disabled = GameManager.gold < step_cost

	var max_res: Dictionary = GameManager.get_train_bulk_cost(stat_key, 0)
	var max_cnt: int = int(max_res.get("count", 0))
	var max_cost: float = float(max_res.get("cost", 0.0))
	gold_buttons[4].disabled = max_cnt <= 0
	if max_cnt > 0:
		gold_buttons[4].text = "Макс +%d (%s)" % [max_cnt, NumberFormatter.format_number(max_cost)]
	else:
		gold_buttons[4].text = "Макс (0)"


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


func _build_dark_mastery_rows_once() -> void:
	if dark_mastery_rows_vbox == null or not _dark_mastery_rows.is_empty():
		return
	for entry: Dictionary in GameManager.DARK_MASTERY_CATALOG:
		var mid: String = str(entry.get("id", ""))
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var lbl: Label = Label.new()
		lbl.custom_minimum_size = Vector2(240.0, 0.0)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(lbl)

		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(120.0, 22.0)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false

		var xp_lbl: Label = Label.new()
		xp_lbl.layout_mode = 1
		xp_lbl.anchors_preset = Control.PRESET_FULL_RECT
		xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		xp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		xp_lbl.add_theme_font_size_override("font_size", 11)
		xp_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		xp_lbl.add_theme_constant_override("outline_size", 2)
		bar.add_child(xp_lbl)
		row.add_child(bar)

		var sel_btn: Button = Button.new()
		sel_btn.custom_minimum_size = Vector2(118.0, 44.0)
		sel_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var target_mid: String = mid
		sel_btn.pressed.connect(func() -> void: GameManager.set_active_dark_mastery(target_mid))
		row.add_child(sel_btn)

		dark_mastery_rows_vbox.add_child(row)
		_dark_mastery_rows.append({
			"id": mid,
			"title": str(entry.get("title", mid)),
			"desc": str(entry.get("desc", "")),
			"lbl": lbl,
			"bar": bar,
			"xp_lbl": xp_lbl,
			"btn": sel_btn,
		})


func _refresh_dark_masteries() -> void:
	if _dark_mastery_rows.is_empty():
		_build_dark_mastery_rows_once()
	for row_item: Dictionary in _dark_mastery_rows:
		var mid: String = str(row_item["id"])
		var lvl: int = GameManager.get_dark_mastery_level(mid)
		var xp_val: float = GameManager.get_dark_mastery_xp(mid)
		var xp_req: float = GameManager.get_dark_mastery_xp_required(lvl)
		var bonus_pct: int = roundi(GameManager.get_dark_mastery_bonus(mid) * 100.0)
		var is_active: bool = GameManager.active_dark_mastery_id == mid

		var lbl: Label = row_item["lbl"] as Label
		var bar: ProgressBar = row_item["bar"] as ProgressBar
		var xp_lbl: Label = row_item["xp_lbl"] as Label
		var btn: Button = row_item["btn"] as Button

		lbl.text = "%s Ур.%d (+%d%% | %s)" % [str(row_item["title"]), lvl, bonus_pct, str(row_item["desc"])]
		lbl.modulate = Color(0.88, 0.72, 1.0, 1.0) if is_active else Color.WHITE
		bar.max_value = xp_req
		bar.value = xp_val
		xp_lbl.text = "%.0f / %.0f XP" % [xp_val, xp_req]
		btn.text = "✅ Активно" if is_active else "Тренировать"
		btn.modulate = Color(0.55, 0.96, 0.72, 1.0) if is_active else Color.WHITE
		btn.disabled = is_active


func _set_transfer_status(message: String, is_success: bool) -> void:
	save_transfer_status_label.visible = not message.is_empty()
	save_transfer_status_label.text = message
	save_transfer_status_label.add_theme_color_override(
		"font_color",
		Color(0.54, 0.92, 0.66, 1) if is_success else Color(0.96, 0.45, 0.45, 1)
	)


func _on_export_txt_pressed() -> void:
	var stamp: String = Time.get_date_string_from_system()
	export_txt_dialog.current_file = "hero_tale_save_%s.txt" % stamp
	export_txt_dialog.popup_centered_ratio(0.75)


func _on_import_txt_pressed() -> void:
	import_txt_dialog.popup_centered_ratio(0.75)


func _on_export_file_selected(file_path: String) -> void:
	var res: Dictionary = GameManager.export_save_to_txt_file(file_path)
	_set_transfer_status(str(res.get("message", "")), bool(res.get("success", false)))


func _on_import_file_selected(file_path: String) -> void:
	var res: Dictionary = GameManager.import_save_from_txt_file(file_path)
	_set_transfer_status(str(res.get("message", "")), bool(res.get("success", false)))


func _on_copy_txt_pressed() -> void:
	var txt: String = GameManager.export_save_to_text()
	DisplayServer.clipboard_set(txt)
	_set_transfer_status("✅ Текст сохранения скопирован в буфер обмена (%d симв.)." % txt.length(), true)


func _on_paste_txt_pressed() -> void:
	var now_ms: int = Time.get_ticks_msec()
	if _paste_confirm_deadline_ms == 0 or now_ms > _paste_confirm_deadline_ms:
		_paste_confirm_deadline_ms = now_ms + 3000
		paste_txt_button.text = "⚠️ Заменить текущий?"
		set_process(true)
		return
	_paste_confirm_deadline_ms = 0
	paste_txt_button.text = "📋 Вставить из буфера"
	var clip: String = DisplayServer.clipboard_get()
	var res: Dictionary = GameManager.import_save_from_text(clip)
	_set_transfer_status(str(res.get("message", "")), bool(res.get("success", false)))


func _on_reset_button_pressed() -> void:
	var now_ms: int = Time.get_ticks_msec()
	if _reset_confirm_deadline_ms == 0 or now_ms > _reset_confirm_deadline_ms:
		_reset_confirm_deadline_ms = now_ms + 3000
		reset_button.text = "⚠️ Стереть ВСЁ?"
		set_process(true)
		return
	_reset_confirm_deadline_ms = 0
	reset_button.text = "🔄 Сброс"
	reset_triggered.emit()
	GameManager.reset_progress()
