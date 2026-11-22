extends ScrollContainer

@onready var status_label: Label = %SpellbookStatusLabel
@onready var feedback_label: Label = %SpellbookFeedbackLabel
@onready var active_slots_hbox: HBoxContainer = %ActiveSlotsHBox
@onready var spell_list_vbox: VBoxContainer = %SpellListVBox


func _ready() -> void:
	GameManager.abilities_changed.connect(_refresh)
	GameManager.class_changed.connect(_on_class_changed)
	GameManager.dark_skills_changed.connect(_refresh)
	GameManager.skills_changed.connect(_refresh)
	GameManager.game_reset.connect(_on_reset)
	_refresh()


func _on_reset() -> void:
	feedback_label.text = ""
	_refresh()


func _on_class_changed(_c: HeroClassData) -> void:
	_refresh()


func _refresh() -> void:
	if active_slots_hbox == null or spell_list_vbox == null:
		return

	var total_spells: int = GameManager.all_abilities.size()
	var unlocked_count: int = 0
	for ab: AbilityData in GameManager.all_abilities:
		if GameManager.is_ability_unlocked(ab):
			unlocked_count += 1

	var blood_open: bool = GameManager.has_hero_class("blood_archmage")
	var is_reflector: bool = GameManager.has_hero_class("reflector")
	var class_note: String = "🩸 Класс Архимаг Крови активен — все 6 запретных чар доступны!" if blood_open else "🔒 Ещё 6 запретных заклинаний открывает класс «🩸 Архимаг Крови» (Сл.50+)."
	if is_reflector:
		class_note = "🪞 Отражатель: боевые заклинания урона заблокированы — доступны только лечение и баффы."
	status_label.text = (
		"✨ Открыто заклинаний: %d / %d. В бою можно использовать максимум %d слота. %s"
		% [
			unlocked_count,
			total_spells,
			GameManager.MAX_ACTIVE_ABILITY_SLOTS,
			class_note,
		]
	)
	status_label.modulate = Color(0.86, 0.72, 1.0, 1.0) if blood_open else Color(0.84, 0.88, 0.96, 1.0)

	_rebuild_active_slots()
	_rebuild_spell_list()


func _rebuild_active_slots() -> void:
	for child: Node in active_slots_hbox.get_children():
		child.queue_free()

	for slot_idx: int in range(GameManager.MAX_ACTIVE_ABILITY_SLOTS):
		var ab: AbilityData = GameManager.get_ability(slot_idx)
		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.content_margin_left = 10.0
		style.content_margin_top = 8.0
		style.content_margin_right = 10.0
		style.content_margin_bottom = 8.0
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.bg_color = Color(0.14, 0.17, 0.23, 1.0) if ab != null else Color(0.10, 0.11, 0.15, 0.85)
		style.border_color = Color(0.45, 0.72, 0.98, 0.9) if ab != null else Color(0.30, 0.34, 0.42, 0.7)
		card.add_theme_stylebox_override("panel", style)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 13)
		if ab != null:
			lbl.text = "Слот %d: %s %s (💧%.0f)" % [
				slot_idx + 1,
				ab.icon_emoji,
				ab.title,
				GameManager.get_ability_mana_cost(ab),
			]
		else:
			lbl.text = "Слот %d: [Пусто]" % (slot_idx + 1)
			lbl.modulate = Color(0.62, 0.66, 0.74, 1.0)
		hbox.add_child(lbl)

		if ab != null:
			var clear_btn: Button = Button.new()
			clear_btn.custom_minimum_size = Vector2(44.0, 44.0)
			clear_btn.text = "✕"
			var target_slot: int = slot_idx
			clear_btn.pressed.connect(func() -> void:
				GameManager.clear_ability_slot(target_slot)
				feedback_label.text = "Слот %d очищен." % (target_slot + 1)
			)
			hbox.add_child(clear_btn)

		card.add_child(hbox)
		active_slots_hbox.add_child(card)


func _rebuild_spell_list() -> void:
	for child: Node in spell_list_vbox.get_children():
		child.queue_free()

	for ab: AbilityData in GameManager.all_abilities:
		if ab == null:
			continue

		var unlocked: bool = GameManager.is_ability_unlocked(ab)
		var equipped_slot: int = GameManager.get_equipped_slot_for_ability(ab.id)
		var is_blood: bool = ab.required_class_id == "blood_archmage"

		var card: PanelContainer = PanelContainer.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.content_margin_left = 12.0
		style.content_margin_top = 10.0
		style.content_margin_right = 12.0
		style.content_margin_bottom = 10.0
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		style.border_width_left = 2 if equipped_slot != -1 else 1
		style.border_width_top = 2 if equipped_slot != -1 else 1
		style.border_width_right = 2 if equipped_slot != -1 else 1
		style.border_width_bottom = 2 if equipped_slot != -1 else 1

		if equipped_slot != -1:
			style.bg_color = Color(0.13, 0.21, 0.28, 1.0)
			style.border_color = Color(0.42, 0.85, 0.98, 1.0)
		elif is_blood:
			style.bg_color = Color(0.17, 0.10, 0.16, 0.95) if unlocked else Color(0.11, 0.08, 0.11, 0.78)
			style.border_color = Color(0.84, 0.36, 0.62, 0.85) if unlocked else Color(0.45, 0.24, 0.36, 0.65)
		else:
			style.bg_color = Color(0.11, 0.13, 0.17, 1.0)
			style.border_color = Color(0.32, 0.36, 0.44, 1.0)
		card.add_theme_stylebox_override("panel", style)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)

		var mana_eff: float = GameManager.get_ability_mana_cost(ab)
		var cd_eff: float = GameManager.get_ability_cooldown_duration(ab)
		var type_tag: String = _get_type_tag(ab)
		var blood_tag: String = "  |  🩸 Архимаг Крови" if is_blood else ""

		var title_lbl: Label = Label.new()
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.text = "%s %s  [%s]  •  💧%.0f  ⏱️%.1fс%s" % [
			ab.icon_emoji,
			ab.title,
			type_tag,
			mana_eff,
			cd_eff,
			blood_tag,
		]
		if not unlocked:
			title_lbl.modulate = Color(0.68, 0.56, 0.66, 1.0)
		elif is_blood:
			title_lbl.modulate = Color(0.98, 0.62, 0.84, 1.0)
		else:
			title_lbl.modulate = Color(0.92, 0.95, 1.0, 1.0)
		info_vbox.add_child(title_lbl)

		var is_reflector_locked: bool = GameManager.has_hero_class("reflector") and ab.effect_type != "heal" and ab.effect_type != "buff"
		var desc_lbl: Label = Label.new()
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.modulate = Color(0.76, 0.82, 0.90, 1.0) if unlocked else Color(0.58, 0.56, 0.62, 1.0)
		desc_lbl.text = ab.description + ("  [🛡️ Заблокировано Отражателем: только хил/баффы]" if is_reflector_locked else "")
		info_vbox.add_child(desc_lbl)

		row.add_child(info_vbox)

		var actions_hbox: HBoxContainer = HBoxContainer.new()
		actions_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		actions_hbox.add_theme_constant_override("separation", 6)

		if not unlocked:
			var lock_btn: Button = Button.new()
			lock_btn.custom_minimum_size = Vector2(156.0, 44.0)
			lock_btn.disabled = true
			lock_btn.text = "🔒 Нужен Архимаг"
			actions_hbox.add_child(lock_btn)
		else:
			for slot_i: int in range(GameManager.MAX_ACTIVE_ABILITY_SLOTS):
				var btn: Button = Button.new()
				btn.custom_minimum_size = Vector2(68.0, 44.0)
				if equipped_slot == slot_i:
					btn.text = "✅ %d" % (slot_i + 1)
					btn.disabled = true
				else:
					btn.text = "Слот %d" % (slot_i + 1)
					var target_ab_id: String = ab.id
					var target_ab_title: String = "%s %s" % [ab.icon_emoji, ab.title]
					var target_slot: int = slot_i
					btn.pressed.connect(func() -> void:
						if GameManager.equip_ability_to_slot(target_ab_id, target_slot):
							feedback_label.text = "Заклинание «%s» назначено в Слот %d!" % [target_ab_title, target_slot + 1]
					)
				actions_hbox.add_child(btn)

		row.add_child(actions_hbox)
		card.add_child(row)
		spell_list_vbox.add_child(card)


func _get_type_tag(ab: AbilityData) -> String:
	match ab.effect_type:
		"buff":
			return "Бафф %.0fс" % ab.duration
		"dot":
			return "Период. %.0fс" % ab.duration
		"overcharge_burn":
			return "Бёрст-перегрузка"
		"heal":
			return "Лечение"
		"pierce_damage":
			return "Пробитие"
		"multi_hit":
			return "%d удара" % maxi(1, ab.hit_count)
		"execute_damage":
			return "Казнь"
		"lifesteal_damage":
			return "Вампиризм"
		"blood_damage", "blood_nova":
			return "Магия крови"
		_:
			return "Урон"
