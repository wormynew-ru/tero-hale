extends ScrollContainer

@onready var class_status_label: Label = %ClassStatusLabel
@onready var class_feedback_label: Label = %ClassFeedbackLabel
@onready var class_list_vbox: VBoxContainer = %ClassListVBox


var _class_cards: Array[Dictionary] = []
var _dirty: bool = true
var _refresh_queued: bool = false


func _ready() -> void:
	GameManager.class_changed.connect(_on_class_changed)
	GameManager.difficulty_changed.connect(_on_state_updated)
	GameManager.stats_changed.connect(_on_state_updated)
	GameManager.challenge_changed.connect(_on_state_updated)
	GameManager.game_reset.connect(_on_reset)
	_build_cards_once()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and _dirty:
		_refresh()


func _on_reset() -> void:
	class_feedback_label.text = ""
	_dirty = true
	_refresh_queued = false
	if is_visible_in_tree():
		_refresh()


func _on_class_changed(_class_data: HeroClassData) -> void:
	_on_state_updated()


func _on_state_updated() -> void:
	if not is_visible_in_tree():
		_dirty = true
		return
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_flush_refresh")


func _flush_refresh() -> void:
	_refresh_queued = false
	if is_visible_in_tree():
		_refresh()
	else:
		_dirty = true


func _make_card_style(bg_col: Color, border_col: Color, border_w: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 12.0
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = border_w
	style.border_width_top = border_w
	style.border_width_right = border_w
	style.border_width_bottom = border_w
	style.bg_color = bg_col
	style.border_color = border_col
	return style


func _build_cards_once() -> void:
	if class_list_vbox == null or not _class_cards.is_empty():
		return

	for hc: HeroClassData in GameManager.hero_classes:
		if hc == null:
			continue

		var active_style: StyleBoxFlat = _make_card_style(hc.accent_color.darkened(0.76), hc.accent_color, 2)
		var inactive_style: StyleBoxFlat = _make_card_style(Color(0.11, 0.13, 0.17, 1.0), Color(0.32, 0.36, 0.44, 1.0), 1)

		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", inactive_style)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)

		var title_lbl: Label = Label.new()
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.text = "%s %s (%s)" % [hc.icon_emoji, hc.title, hc.subtitle]
		title_lbl.add_theme_color_override("font_color", hc.accent_color.lightened(0.25))
		info_vbox.add_child(title_lbl)

		var desc_lbl: Label = Label.new()
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.84, 0.92, 1.0))
		desc_lbl.text = hc.description
		info_vbox.add_child(desc_lbl)

		var passive_lbl: Label = Label.new()
		passive_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		passive_lbl.add_theme_font_size_override("font_size", 12)
		passive_lbl.add_theme_color_override("font_color", Color(0.95, 0.84, 0.42, 1.0))
		passive_lbl.text = hc.passive_summary
		info_vbox.add_child(passive_lbl)

		row.add_child(info_vbox)

		var select_btn: Button = Button.new()
		select_btn.custom_minimum_size = Vector2(148.0, 46.0)
		select_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var cid: String = hc.id
		var c_emoji: String = hc.icon_emoji
		var c_title: String = hc.title
		select_btn.pressed.connect(func() -> void:
			if GameManager.select_hero_class(cid):
				class_feedback_label.text = "Выбран класс: %s %s!" % [c_emoji, c_title]
		)
		row.add_child(select_btn)

		card.add_child(row)
		class_list_vbox.add_child(card)
		_class_cards.append({
			"id": hc.id,
			"req_diff": hc.required_difficulty,
			"card": card,
			"btn": select_btn,
			"passive_lbl": passive_lbl,
			"base_passive": hc.passive_summary,
			"active_style": active_style,
			"inactive_style": inactive_style,
			"last_state": "",
		})


func _refresh() -> void:
	if class_list_vbox == null:
		return
	_dirty = false

	var unlocked: bool = GameManager.is_classes_unlocked()
	var current_class: HeroClassData = GameManager.get_current_class()
	var current_name: String = "%s %s" % [current_class.icon_emoji, current_class.title] if current_class != null else "Странник"
	var trials_note: String = " | 🏆 Пройдено испытаний Бездны: %d/%d" % [
		GameManager.completed_challenges.size(),
		GameManager.CHALLENGE_CATALOG.size(),
	]

	if unlocked:
		class_status_label.text = "✅ Классы открыты (%d/%d). Текущий класс: %s%s. Личные бонусы (стаки HP 🪞 Отражателя и уровни духов 🌿 Спирита) сохраняются строго за своим классом." % [
			GameManager.max_unlocked_difficulty,
			GameManager.CLASSES_UNLOCK_DIFFICULTY,
			current_name,
			trials_note,
		]
		class_status_label.modulate = Color(0.55, 0.95, 0.72, 1.0)
	else:
		class_status_label.text = "🔒 Классы открываются после достижения %d-й сложности (сейчас открыто до Сл.%d)%s. После открытия классы можно свободно переключать." % [
			GameManager.CLASSES_UNLOCK_DIFFICULTY,
			GameManager.max_unlocked_difficulty,
			trials_note,
		]
		class_status_label.modulate = Color(0.95, 0.78, 0.42, 1.0)

	for entry: Dictionary in _class_cards:
		var cid: String = str(entry["id"])
		var req_diff: int = int(entry["req_diff"])
		var is_active: bool = GameManager.has_hero_class(cid)
		var req_met: bool = req_diff <= 1 or unlocked

		var passive_lbl: Label = entry["passive_lbl"] as Label
		if passive_lbl != null:
			var base_passive: String = str(entry["base_passive"])
			if cid == "reflector":
				var barrier_hp_conv: float = GameManager.get_raw_max_barrier()
				passive_lbl.text = "%s\n📊 Стаки убийств: +%s (x20 → +%s Max HP) | 🛡️ Конвертация Барьера 1:1 (x20) → +%s Max HP (действует только на Отражателе)" % [
					base_passive,
					NumberFormatter.format_number(float(GameManager.reflector_kill_hp_stacks)),
					NumberFormatter.format_number(float(GameManager.reflector_kill_hp_stacks) * 20.0 * 1.3),
					NumberFormatter.format_number(barrier_hp_conv * 20.0 * 1.3),
				]
			elif cid == "spirit":
				passive_lbl.text = "%s\n📊 Уровни духов Спирита: 🔥%d / 🌪️%d / 🌿%d / 🪨%d (действуют только на Спирите)" % [
					base_passive,
					GameManager.get_spirit_training_level("fire"),
					GameManager.get_spirit_training_level("wind"),
					GameManager.get_spirit_training_level("forest"),
					GameManager.get_spirit_training_level("earth"),
				]

		var state_key: String = "active" if is_active else ("locked_%d" % req_diff if not req_met else "ready")
		if str(entry["last_state"]) == state_key:
			continue
		entry["last_state"] = state_key

		var card: PanelContainer = entry["card"] as PanelContainer
		var select_btn: Button = entry["btn"] as Button
		if card != null:
			card.add_theme_stylebox_override("panel", (entry["active_style"] if is_active else entry["inactive_style"]) as StyleBoxFlat)
		if select_btn != null:
			if is_active:
				select_btn.text = "✅ Активен"
				select_btn.disabled = true
			elif not req_met:
				select_btn.text = "🔒 Сл. %d" % req_diff
				select_btn.disabled = true
			else:
				select_btn.text = "Выбрать"
				select_btn.disabled = false
