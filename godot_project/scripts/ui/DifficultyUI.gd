extends ScrollContainer

signal new_run_started

@onready var current_run_label: Label = %CurrentRunLabel
@onready var boss_status_label: Label = %BossStatusLabel
@onready var crucible_status_label: Label = %CrucibleStatusLabel
@onready var diff_minus_button: Button = %DiffMinusButton
@onready var selected_diff_label: Label = %SelectedDiffLabel
@onready var diff_plus_button: Button = %DiffPlusButton
@onready var diff_max_button: Button = %DiffMaxButton
@onready var multipliers_preview_label: Label = %MultipliersPreviewLabel
@onready var start_new_run_button: Button = %StartNewRunButton
@onready var reroll_tokens_label: Label = %RerollTokensLabel
@onready var curses_feedback_label: Label = %CursesFeedbackLabel
@onready var curses_rows_vbox: VBoxContainer = %CursesRowsVBox

var _selected_difficulty: int = 1
var _confirm_deadline_ms: int = 0


func _ready() -> void:
	_selected_difficulty = GameManager.difficulty_level
	GameManager.difficulty_changed.connect(_on_manager_updated)
	GameManager.dark_skills_changed.connect(_refresh)
	GameManager.game_reset.connect(_on_reset)

	diff_minus_button.pressed.connect(func() -> void: _set_selected_difficulty(_selected_difficulty - 1))
	diff_plus_button.pressed.connect(func() -> void: _set_selected_difficulty(_selected_difficulty + 1))
	diff_max_button.pressed.connect(func() -> void: _set_selected_difficulty(GameManager.max_unlocked_difficulty))
	start_new_run_button.pressed.connect(_on_start_new_run_pressed)
	_refresh()


func _process(_delta: float) -> void:
	if _confirm_deadline_ms > 0 and Time.get_ticks_msec() > _confirm_deadline_ms:
		_confirm_deadline_ms = 0
		_refresh_start_button_text()


func _on_reset() -> void:
	curses_feedback_label.text = ""
	_on_manager_updated()


func _on_manager_updated() -> void:
	_selected_difficulty = clampi(
		maxi(_selected_difficulty, GameManager.difficulty_level),
		1,
		GameManager.max_unlocked_difficulty
	)
	_confirm_deadline_ms = 0
	_refresh()


func _set_selected_difficulty(target: int) -> void:
	_selected_difficulty = clampi(target, 1, GameManager.max_unlocked_difficulty)
	_confirm_deadline_ms = 0
	_refresh()


func _on_start_new_run_pressed() -> void:
	var now_ms: int = Time.get_ticks_msec()
	if _confirm_deadline_ms == 0 or now_ms > _confirm_deadline_ms:
		_confirm_deadline_ms = now_ms + 3000
		start_new_run_button.text = "⚠️ Точно начать (Сл. %d)?" % _selected_difficulty
		return
	_confirm_deadline_ms = 0
	GameManager.start_new_run(_selected_difficulty)
	new_run_started.emit()


func _refresh_start_button_text() -> void:
	start_new_run_button.text = "🔥 Начать ран (Сл. %d)" % _selected_difficulty


func _refresh() -> void:
	_selected_difficulty = clampi(_selected_difficulty, 1, GameManager.max_unlocked_difficulty)
	current_run_label.text = "💀 Текущий ран: Сложность %d (Открыто до %d  |  Пройдено ранов: %d)" % [
		GameManager.difficulty_level,
		GameManager.max_unlocked_difficulty,
		GameManager.total_runs_completed,
	]

	var already_claimed_diff: bool = GameManager.is_dark_points_claimed_for_difficulty(GameManager.difficulty_level)
	if GameManager.boss_defeated_this_run:
		boss_status_label.text = "✅ Вечный титан повержен на Сл.%d! Награда 🌑 за эту сложность учтена (макс. 1 раз на сложность), открыта Сложность %d." % [
			GameManager.difficulty_level,
			GameManager.max_unlocked_difficulty,
		]
		boss_status_label.modulate = Color(0.45, 0.96, 0.62, 1.0)
	elif already_claimed_diff:
		boss_status_label.text = "⏳ Вечный титан (Сл.%d): +2 🌑 за эту сложность уже были получены ранее — повторная победа 🌑 не даст (макс. 1 раз на Сл.)." % GameManager.difficulty_level
		boss_status_label.modulate = Color(0.95, 0.78, 0.42, 1.0)
	else:
		boss_status_label.text = "⏳ Победите Вечного титана (Небесный престол, Lv. 50+) — получите +2 🌑 (1 раз за Сл.%d) и откроете следующую сложность." % GameManager.difficulty_level
		boss_status_label.modulate = Color(0.84, 0.88, 0.96, 1.0)

	if GameManager.max_unlocked_difficulty >= GameManager.CRUCIBLE_UNLOCK_DIFFICULTY:
		crucible_status_label.text = "🌀 Горнило Проклятий ОТКРЫТО (всегда доступно справа в карте)! Убийств Хранителя Проклятий в этом ране: %d (следующий босс усилен: HP x%s, урон x%s)." % [
			GameManager.reroll_boss_kills_in_run,
			_fmt_mult(pow(1.85, float(GameManager.reroll_boss_kills_in_run))),
			_fmt_mult(pow(1.55, float(GameManager.reroll_boss_kills_in_run))),
		]
		crucible_status_label.modulate = Color(0.84, 0.65, 1.0, 1.0)
	else:
		crucible_status_label.text = "🔒 На Сл.%d откроется «Горнило Проклятий» (всегда открытая локация с Хранителем Проклятий — бесконечный фарм 🎲 рероллов проклятий за 1 ран!)." % GameManager.CRUCIBLE_UNLOCK_DIFFICULTY
		crucible_status_label.modulate = Color(0.72, 0.76, 0.86, 1.0)

	reroll_tokens_label.text = "🎲 Жетоны реролла: %d" % GameManager.curse_reroll_tokens

	selected_diff_label.text = "Выбранная сложность: %d" % _selected_difficulty
	diff_minus_button.disabled = _selected_difficulty <= 1
	diff_plus_button.disabled = _selected_difficulty >= GameManager.max_unlocked_difficulty
	diff_max_button.disabled = _selected_difficulty >= GameManager.max_unlocked_difficulty

	var d: float = float(_selected_difficulty - 1)
	var hp_m: float = pow(1.65, d)
	var dmg_m: float = pow(1.42, d)
	var arm_m: float = pow(1.38, d)
	var flat_arm: float = d * 4.0
	var price_m: float = pow(1.45, d)
	var gold_m: float = pow(1.50, d)
	var xp_m: float = pow(1.25, d)

	multipliers_preview_label.text = (
		"Монстры: HP x%s  |  Урон x%s  |  Плоская броня x%s (+%s)\n"
		+ "Экономика: Цены x%s  |  Золото x%s  |  Опыт x%s"
	) % [
		_fmt_mult(hp_m),
		_fmt_mult(dmg_m),
		_fmt_mult(arm_m),
		NumberFormatter.format_number(flat_arm),
		_fmt_mult(price_m),
		_fmt_mult(gold_m),
		_fmt_mult(xp_m),
	]

	if _confirm_deadline_ms == 0:
		_refresh_start_button_text()

	_refresh_curses_preview()


func _refresh_curses_preview() -> void:
	for child: Node in curses_rows_vbox.get_children():
		child.queue_free()

	GameManager.ensure_curses_for_difficulty(_selected_difficulty)
	var max_tier: int = floori(float(_selected_difficulty) / 10.0) * 10
	if max_tier < 10:
		var none_lbl: Label = Label.new()
		none_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none_lbl.modulate = Color(0.84, 0.86, 0.92, 1.0)
		none_lbl.text = "На сложности %d проклятий нет. Первое случайное проклятие появится на 10-й сложности, следующее — на 20-й и так каждые +10." % _selected_difficulty
		curses_rows_vbox.add_child(none_lbl)
		return

	var atten: float = GameManager.get_curse_attenuation()
	for tier: int in range(10, max_tier + 1, 10):
		var cid: String = str(GameManager.difficulty_curses.get(tier, ""))
		var found_def: Dictionary = {}
		for entry: Dictionary in GameManager.CURSE_CATALOG:
			if str(entry["id"]) == cid:
				found_def = entry
				break
		if found_def.is_empty():
			continue
		var eff_val: float = float(found_def["base_value"]) * atten
		var desc: String = GameManager.format_curse_description(found_def, eff_val)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.text = "• Сл. %d — %s: %s" % [tier, str(found_def["title"]), desc]
		row.add_child(lbl)

		var reroll_btn: Button = Button.new()
		reroll_btn.custom_minimum_size = Vector2(124.0, 38.0)
		reroll_btn.text = "🎲 Реролл"
		reroll_btn.disabled = GameManager.curse_reroll_tokens <= 0
		var target_tier: int = tier
		reroll_btn.pressed.connect(func() -> void:
			var res: Dictionary = GameManager.reroll_curse_at_tier(target_tier)
			curses_feedback_label.text = str(res.get("message", ""))
		)
		row.add_child(reroll_btn)

		curses_rows_vbox.add_child(row)

	if GameManager.has_dark_skill("curse_ward"):
		var ward_lbl: Label = Label.new()
		ward_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ward_lbl.modulate = Color(0.75, 0.85, 1.0, 1.0)
		ward_lbl.add_theme_font_size_override("font_size", 12)
		ward_lbl.text = "🕯️ Активно «Очищение скверны»: все проклятия ослаблены на 40%."
		curses_rows_vbox.add_child(ward_lbl)


func _fmt_mult(val: float) -> String:
	if val >= 1000.0:
		return NumberFormatter.format_number(val)
	if val >= 10.0:
		return "%.1f" % val
	return "%.2f" % val
