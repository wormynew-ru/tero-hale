extends ScrollContainer

@onready var class_status_label: Label = %ClassStatusLabel
@onready var class_feedback_label: Label = %ClassFeedbackLabel
@onready var class_list_vbox: VBoxContainer = %ClassListVBox


func _ready() -> void:
	GameManager.class_changed.connect(_on_class_changed)
	GameManager.difficulty_changed.connect(_refresh)
	GameManager.game_reset.connect(_on_reset)
	_refresh()


func _on_reset() -> void:
	class_feedback_label.text = ""
	_refresh()


func _on_class_changed(_class_data: HeroClassData) -> void:
	_refresh()


func _refresh() -> void:
	if class_list_vbox == null:
		return

	var unlocked: bool = GameManager.is_classes_unlocked()
	var current_class: HeroClassData = GameManager.get_current_class()
	var current_name: String = "%s %s" % [current_class.icon_emoji, current_class.title] if current_class != null else "Странник"

	if unlocked:
		class_status_label.text = "✅ Классы открыты (достигнута %d/%d сложность). Текущий класс: %s. Смена класса доступна в любой момент." % [
			GameManager.max_unlocked_difficulty,
			GameManager.CLASSES_UNLOCK_DIFFICULTY,
			current_name,
		]
		class_status_label.modulate = Color(0.55, 0.95, 0.72, 1.0)
	else:
		class_status_label.text = "🔒 Классы открываются после достижения %d-й сложности (сейчас открыто до Сл.%d). До 50-й сложности активен базовый класс %s." % [
			GameManager.CLASSES_UNLOCK_DIFFICULTY,
			GameManager.max_unlocked_difficulty,
			current_name,
		]
		class_status_label.modulate = Color(0.95, 0.78, 0.42, 1.0)

	for child: Node in class_list_vbox.get_children():
		child.queue_free()

	for hc: HeroClassData in GameManager.hero_classes:
		if hc == null:
			continue

		var is_active: bool = GameManager.has_hero_class(hc.id)
		var req_met: bool = hc.required_difficulty <= 1 or unlocked

		var card: PanelContainer = PanelContainer.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.content_margin_left = 14.0
		style.content_margin_top = 12.0
		style.content_margin_right = 14.0
		style.content_margin_bottom = 12.0
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		style.border_width_left = 2 if is_active else 1
		style.border_width_top = 2 if is_active else 1
		style.border_width_right = 2 if is_active else 1
		style.border_width_bottom = 2 if is_active else 1
		if is_active:
			style.bg_color = hc.accent_color.darkened(0.76)
			style.border_color = hc.accent_color
		else:
			style.bg_color = Color(0.11, 0.13, 0.17, 1.0)
			style.border_color = Color(0.32, 0.36, 0.44, 1.0)
		card.add_theme_stylebox_override("panel", style)

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
		if is_active:
			select_btn.text = "✅ Активен"
			select_btn.disabled = true
		elif not req_met:
			select_btn.text = "🔒 Сл. %d" % hc.required_difficulty
			select_btn.disabled = true
		else:
			select_btn.text = "Выбрать"
			select_btn.disabled = false
			select_btn.pressed.connect(func() -> void:
				if GameManager.select_hero_class(hc.id):
					class_feedback_label.text = "Выбран класс: %s %s!" % [hc.icon_emoji, hc.title]
			)
		row.add_child(select_btn)

		card.add_child(row)
		class_list_vbox.add_child(card)
