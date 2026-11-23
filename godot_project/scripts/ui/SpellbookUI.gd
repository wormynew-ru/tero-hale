extends ScrollContainer

@onready var status_label: Label = %SpellbookStatusLabel
@onready var feedback_label: Label = %SpellbookFeedbackLabel
@onready var active_slots_hbox: HBoxContainer = %ActiveSlotsHBox
@onready var spell_list_vbox: VBoxContainer = %SpellListVBox

var _active_slot_views: Array[Dictionary] = []
var _spell_row_views: Array[Dictionary] = []
var _last_signature: String = ""
var _dirty: bool = true


func _ready() -> void:
	GameManager.abilities_changed.connect(_on_state_changed)
	GameManager.inventory_changed.connect(_on_state_changed)
	GameManager.class_changed.connect(_on_class_changed)
	GameManager.dark_skills_changed.connect(_on_state_changed)
	GameManager.skills_changed.connect(_on_state_changed)
	GameManager.game_reset.connect(_on_reset)
	_build_active_slots()
	_build_spell_list()
	_refresh(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		if _dirty:
			_refresh(true)


func _on_reset() -> void:
	feedback_label.text = ""
	_dirty = true
	_refresh(true)


func _on_class_changed(_c: HeroClassData) -> void:
	_on_state_changed()


func _on_state_changed() -> void:
	if not is_visible_in_tree():
		_dirty = true
		return
	_refresh(false)


func _on_clear_slot_pressed(slot_index: int) -> void:
	GameManager.clear_ability_slot(slot_index)
	feedback_label.text = "Слот %d очищен." % (slot_index + 1)
	_refresh(true)


func _on_equip_slot_pressed(ability_id: String, slot_index: int) -> void:
	var ab: AbilityData = GameManager.get_ability_by_id(ability_id)
	if GameManager.equip_ability_to_slot(ability_id, slot_index):
		var ab_title: String = "%s %s" % [ab.icon_emoji, ab.title] if ab != null else ability_id
		feedback_label.text = "Заклинание «%s» назначено в Слот %d!" % [ab_title, slot_index + 1]
		_refresh(true)


func _on_upgrade_spell_pressed(ability_id: String) -> void:
	var res: Dictionary = GameManager.upgrade_ability_with_page(ability_id)
	feedback_label.text = str(res.get("message", ""))
	_refresh(true)


func _on_toggle_rune_pressed(ability_id: String, rune_key: String) -> void:
	var cur: String = GameManager.get_ability_rune(ability_id)
	var next_key: String = "" if cur == rune_key else rune_key
	GameManager.set_ability_rune(ability_id, next_key)
	var ab: AbilityData = GameManager.get_ability_by_id(ability_id)
	var ab_name: String = ab.title if ab != null else ability_id
	if next_key.is_empty():
		feedback_label.text = "Руна для «%s» снята." % ab_name
	else:
		var r_dict: Dictionary = GameManager.SPELL_RUNES_CATALOG.get(ability_id, {}) as Dictionary
		var r_info: Dictionary = r_dict.get(next_key, {}) as Dictionary
		feedback_label.text = "Активирована руна %s для «%s»: %s" % [str(r_info.get("title", next_key.to_upper())), ab_name, str(r_info.get("desc", ""))]
	_refresh(true)


func _compute_state_signature() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append(GameManager.selected_class_id)
	parts.append("P:%d" % GameManager.get_dark_forge_material_count("ancient_page"))
	parts.append(",".join(PackedStringArray(GameManager.equipped_ability_ids)))
	for ab: AbilityData in GameManager.all_abilities:
		if ab == null:
			continue
		var unlocked_flag: int = 1 if GameManager.is_ability_unlocked(ab) else 0
		var mana_key: int = roundi(GameManager.get_ability_mana_cost(ab) * 10.0)
		var cd_key: int = roundi(GameManager.get_ability_cooldown_duration(ab) * 10.0)
		var lvl: int = GameManager.get_ability_level(ab.id)
		var casts: int = GameManager.get_ability_casts(ab.id)
		var rune_key: String = GameManager.get_ability_rune(ab.id)
		parts.append("%s:%d:%d:%d:%d:%d:%s" % [ab.id, unlocked_flag, mana_key, cd_key, lvl, casts, rune_key])
	return "|".join(parts)


func _refresh(force: bool = false) -> void:
	if active_slots_hbox == null or spell_list_vbox == null:
		return

	if _active_slot_views.size() != GameManager.MAX_ACTIVE_ABILITY_SLOTS:
		_build_active_slots()
		force = true
	if _spell_row_views.size() != GameManager.all_abilities.size():
		_build_spell_list()
		force = true

	var sig: String = _compute_state_signature()
	if not force and sig == _last_signature:
		_dirty = false
		return
	_last_signature = sig
	_dirty = false

	var total_spells: int = GameManager.all_abilities.size()
	var unlocked_count: int = 0
	for ab: AbilityData in GameManager.all_abilities:
		if GameManager.is_ability_unlocked(ab):
			unlocked_count += 1

	var blood_open: bool = GameManager.has_hero_class("blood_archmage")
	var is_reflector: bool = GameManager.has_hero_class("reflector")
	var page_cnt: int = GameManager.get_dark_forge_material_count("ancient_page")
	var class_note: String = "🩸 Класс Архимаг Крови активен — все 7 запретных чар доступны!" if blood_open else "🔒 Ещё 7 запретных заклинаний открывает класс «🩸 Архимаг Крови» (Сл.50+)."
	if is_reflector:
		class_note = "🪞 Отражатель: боевые заклинания урона заблокированы — доступны только лечение и баффы."
	status_label.text = (
		"✨ Открыто заклинаний: %d / %d (слотов: %d)  |  📜 Древних листов: %d  •  %s"
		% [
			unlocked_count,
			total_spells,
			GameManager.MAX_ACTIVE_ABILITY_SLOTS,
			page_cnt,
			class_note,
		]
	)
	status_label.modulate = Color(0.86, 0.72, 1.0, 1.0) if blood_open else Color(0.84, 0.88, 0.96, 1.0)

	_update_active_slots()
	_update_spell_list()


func _build_active_slots() -> void:
	for child: Node in active_slots_hbox.get_children():
		child.queue_free()
	_active_slot_views.clear()

	for slot_idx: int in range(GameManager.MAX_ACTIVE_ABILITY_SLOTS):
		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_PASS

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
		card.add_theme_stylebox_override("panel", style)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 13)
		hbox.add_child(lbl)

		var clear_btn: Button = Button.new()
		clear_btn.custom_minimum_size = Vector2(44.0, 44.0)
		clear_btn.focus_mode = Control.FOCUS_NONE
		clear_btn.text = "✕"
		var target_slot: int = slot_idx
		clear_btn.pressed.connect(func() -> void: _on_clear_slot_pressed(target_slot))
		hbox.add_child(clear_btn)

		card.add_child(hbox)
		active_slots_hbox.add_child(card)

		_active_slot_views.append({
			"style": style,
			"label": lbl,
			"clear_btn": clear_btn,
		})


func _update_active_slots() -> void:
	for slot_idx: int in range(_active_slot_views.size()):
		var view: Dictionary = _active_slot_views[slot_idx]
		var style: StyleBoxFlat = view["style"] as StyleBoxFlat
		var lbl: Label = view["label"] as Label
		var clear_btn: Button = view["clear_btn"] as Button
		var ab: AbilityData = GameManager.get_ability(slot_idx)

		style.bg_color = Color(0.14, 0.17, 0.23, 1.0) if ab != null else Color(0.10, 0.11, 0.15, 0.85)
		style.border_color = Color(0.45, 0.72, 0.98, 0.9) if ab != null else Color(0.30, 0.34, 0.42, 0.7)

		if ab != null:
			var lvl: int = GameManager.get_ability_level(ab.id)
			var r_key: String = GameManager.get_ability_rune(ab.id)
			var r_tag: String = " [Руна %s]" % r_key.to_upper() if not r_key.is_empty() else ""
			lbl.text = "Слот %d: %s %s Ур.%d%s (💧%.0f)" % [
				slot_idx + 1,
				ab.icon_emoji,
				ab.title,
				lvl,
				r_tag,
				GameManager.get_ability_mana_cost(ab),
			]
			lbl.modulate = Color.WHITE
			clear_btn.visible = true
			clear_btn.disabled = false
		else:
			lbl.text = "Слот %d: [Пусто]" % (slot_idx + 1)
			lbl.modulate = Color(0.62, 0.66, 0.74, 1.0)
			clear_btn.visible = false


func _build_spell_list() -> void:
	for child: Node in spell_list_vbox.get_children():
		child.queue_free()
	_spell_row_views.clear()

	for ab: AbilityData in GameManager.all_abilities:
		if ab == null:
			continue

		var card: PanelContainer = PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.content_margin_left = 12.0
		style.content_margin_top = 10.0
		style.content_margin_right = 12.0
		style.content_margin_bottom = 10.0
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		card.add_theme_stylebox_override("panel", style)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)

		var title_lbl: Label = Label.new()
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(title_lbl)

		var desc_lbl: Label = Label.new()
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		info_vbox.add_child(desc_lbl)

		var prog_row: HFlowContainer = HFlowContainer.new()
		prog_row.add_theme_constant_override("h_separation", 8)
		prog_row.add_theme_constant_override("v_separation", 6)

		var target_ab_id: String = ab.id

		var lvl_lbl: Label = Label.new()
		lvl_lbl.add_theme_font_size_override("font_size", 12)
		lvl_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		prog_row.add_child(lvl_lbl)

		var upgrade_btn: Button = Button.new()
		upgrade_btn.custom_minimum_size = Vector2(138.0, 34.0)
		upgrade_btn.focus_mode = Control.FOCUS_NONE
		upgrade_btn.add_theme_font_size_override("font_size", 12)
		upgrade_btn.pressed.connect(func() -> void: _on_upgrade_spell_pressed(target_ab_id))
		prog_row.add_child(upgrade_btn)

		var rune_a_btn: Button = Button.new()
		rune_a_btn.custom_minimum_size = Vector2(130.0, 34.0)
		rune_a_btn.focus_mode = Control.FOCUS_NONE
		rune_a_btn.add_theme_font_size_override("font_size", 12)
		rune_a_btn.pressed.connect(func() -> void: _on_toggle_rune_pressed(target_ab_id, "a"))
		prog_row.add_child(rune_a_btn)

		var rune_b_btn: Button = Button.new()
		rune_b_btn.custom_minimum_size = Vector2(130.0, 34.0)
		rune_b_btn.focus_mode = Control.FOCUS_NONE
		rune_b_btn.add_theme_font_size_override("font_size", 12)
		rune_b_btn.pressed.connect(func() -> void: _on_toggle_rune_pressed(target_ab_id, "b"))
		prog_row.add_child(rune_b_btn)

		info_vbox.add_child(prog_row)

		var rune_desc_lbl: Label = Label.new()
		rune_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rune_desc_lbl.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(rune_desc_lbl)

		row.add_child(info_vbox)

		var actions_hbox: HBoxContainer = HBoxContainer.new()
		actions_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		actions_hbox.add_theme_constant_override("separation", 6)

		var lock_btn: Button = Button.new()
		lock_btn.custom_minimum_size = Vector2(156.0, 44.0)
		lock_btn.focus_mode = Control.FOCUS_NONE
		lock_btn.disabled = true
		lock_btn.text = "🔒 Нужен Архимаг"
		actions_hbox.add_child(lock_btn)

		var slot_buttons: Array[Button] = []
		for slot_i: int in range(GameManager.MAX_ACTIVE_ABILITY_SLOTS):
			var btn: Button = Button.new()
			btn.custom_minimum_size = Vector2(68.0, 44.0)
			btn.focus_mode = Control.FOCUS_NONE
			var target_slot: int = slot_i
			btn.pressed.connect(func() -> void: _on_equip_slot_pressed(target_ab_id, target_slot))
			actions_hbox.add_child(btn)
			slot_buttons.append(btn)

		row.add_child(actions_hbox)
		card.add_child(row)
		spell_list_vbox.add_child(card)

		_spell_row_views.append({
			"ability": ab,
			"style": style,
			"title_lbl": title_lbl,
			"desc_lbl": desc_lbl,
			"lvl_lbl": lvl_lbl,
			"upgrade_btn": upgrade_btn,
			"rune_a_btn": rune_a_btn,
			"rune_b_btn": rune_b_btn,
			"rune_desc_lbl": rune_desc_lbl,
			"lock_btn": lock_btn,
			"slot_buttons": slot_buttons,
		})


func _update_spell_list() -> void:
	var is_reflector: bool = GameManager.has_hero_class("reflector")
	var page_cnt: int = GameManager.get_dark_forge_material_count("ancient_page")
	for view: Dictionary in _spell_row_views:
		var ab: AbilityData = view["ability"] as AbilityData
		if ab == null:
			continue
		var style: StyleBoxFlat = view["style"] as StyleBoxFlat
		var title_lbl: Label = view["title_lbl"] as Label
		var desc_lbl: Label = view["desc_lbl"] as Label
		var lvl_lbl: Label = view["lvl_lbl"] as Label
		var upgrade_btn: Button = view["upgrade_btn"] as Button
		var rune_a_btn: Button = view["rune_a_btn"] as Button
		var rune_b_btn: Button = view["rune_b_btn"] as Button
		var rune_desc_lbl: Label = view["rune_desc_lbl"] as Label
		var lock_btn: Button = view["lock_btn"] as Button
		var slot_buttons: Array[Button] = view["slot_buttons"] as Array[Button]

		var unlocked: bool = GameManager.is_ability_unlocked(ab)
		var equipped_slot: int = GameManager.get_equipped_slot_for_ability(ab.id)
		var is_blood: bool = ab.required_class_id == "blood_archmage"

		var border_w: int = 2 if equipped_slot != -1 else 1
		style.border_width_left = border_w
		style.border_width_top = border_w
		style.border_width_right = border_w
		style.border_width_bottom = border_w

		if equipped_slot != -1:
			style.bg_color = Color(0.13, 0.21, 0.28, 1.0)
			style.border_color = Color(0.42, 0.85, 0.98, 1.0)
		elif is_blood:
			style.bg_color = Color(0.17, 0.10, 0.16, 0.95) if unlocked else Color(0.11, 0.08, 0.11, 0.78)
			style.border_color = Color(0.84, 0.36, 0.62, 0.85) if unlocked else Color(0.45, 0.24, 0.36, 0.65)
		else:
			style.bg_color = Color(0.11, 0.13, 0.17, 1.0)
			style.border_color = Color(0.32, 0.36, 0.44, 1.0)

		var lvl: int = GameManager.get_ability_level(ab.id)
		var casts: int = GameManager.get_ability_casts(ab.id)
		var next_casts: int = GameManager.get_next_spell_level_casts(ab.id)
		var mana_eff: float = GameManager.get_ability_mana_cost(ab)
		var cd_eff: float = GameManager.get_ability_cooldown_duration(ab)
		var type_tag: String = _get_type_tag(ab)
		var blood_tag: String = "  |  🩸 Архимаг Крови" if is_blood else ""

		title_lbl.text = "%s %s [Ур.%d/%d]  [%s]  •  💧%.0f  ⏱️%.1fс%s" % [
			ab.icon_emoji,
			ab.title,
			lvl,
			AbilityData.MAX_SPELL_LEVEL,
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

		var is_reflector_locked: bool = is_reflector and ab.effect_type != "heal" and ab.effect_type != "buff"
		desc_lbl.modulate = Color(0.76, 0.82, 0.90, 1.0) if unlocked else Color(0.58, 0.56, 0.62, 1.0)
		desc_lbl.text = ab.description + ("  [🛡️ Заблокировано Отражателем: только хил/баффы]" if is_reflector_locked else "")

		var lvl_mult: float = AbilityData.get_level_multiplier(lvl)
		if next_casts > 0:
			lvl_lbl.text = "📖 Сила x%.2f • Касты: %d/%d" % [lvl_mult, casts, next_casts]
		else:
			lvl_lbl.text = "📖 МАКС. Ур.%d (x%.2f) • Кастов: %d" % [lvl, lvl_mult, casts]
		lvl_lbl.modulate = Color(0.56, 0.96, 0.72, 1.0) if lvl >= AbilityData.MAX_SPELL_LEVEL else Color(0.78, 0.86, 0.96, 1.0)

		var page_cost: int = GameManager.get_ability_upgrade_page_cost(ab.id)
		if page_cost <= 0:
			upgrade_btn.text = "✅ Макс. Ур."
			upgrade_btn.disabled = true
		else:
			upgrade_btn.text = "📜 +1 Ур. (%d)" % page_cost
			upgrade_btn.disabled = (not unlocked) or (page_cnt < page_cost)

		var active_rune: String = GameManager.get_ability_rune(ab.id)
		var rune_pair: Dictionary = GameManager.SPELL_RUNES_CATALOG.get(ab.id, {}) as Dictionary
		var rune_a: Dictionary = rune_pair.get("a", {}) as Dictionary
		var rune_b: Dictionary = rune_pair.get("b", {}) as Dictionary

		rune_a_btn.visible = not rune_a.is_empty()
		rune_b_btn.visible = not rune_b.is_empty()
		if not rune_a.is_empty():
			var a_active: bool = active_rune == "a"
			rune_a_btn.text = ("%s " % ("✅" if a_active else "🔸")) + "Руна A"
			rune_a_btn.modulate = Color(0.55, 0.98, 0.74, 1.0) if a_active else Color.WHITE
			rune_a_btn.disabled = not unlocked
		if not rune_b.is_empty():
			var b_active: bool = active_rune == "b"
			rune_b_btn.text = ("%s " % ("✅" if b_active else "🔹")) + "Руна B"
			rune_b_btn.modulate = Color(0.45, 0.90, 1.0, 1.0) if b_active else Color.WHITE
			rune_b_btn.disabled = not unlocked

		if active_rune == "a" and not rune_a.is_empty():
			rune_desc_lbl.text = "✅ Активна Руна A — %s: %s" % [str(rune_a.get("title", "")), str(rune_a.get("desc", ""))]
			rune_desc_lbl.modulate = Color(0.55, 0.98, 0.74, 1.0)
		elif active_rune == "b" and not rune_b.is_empty():
			rune_desc_lbl.text = "✅ Активна Руна B — %s: %s" % [str(rune_b.get("title", "")), str(rune_b.get("desc", ""))]
			rune_desc_lbl.modulate = Color(0.45, 0.90, 1.0, 1.0)
		else:
			rune_desc_lbl.text = "Руны: [A] %s (%s)  |  [B] %s (%s)" % [
				str(rune_a.get("title", "-")),
				str(rune_a.get("desc", "")),
				str(rune_b.get("title", "-")),
				str(rune_b.get("desc", "")),
			]
			rune_desc_lbl.modulate = Color(0.70, 0.74, 0.82, 1.0)

		if not unlocked:
			lock_btn.visible = true
			for btn: Button in slot_buttons:
				btn.visible = false
		else:
			lock_btn.visible = false
			for slot_i: int in range(slot_buttons.size()):
				var btn: Button = slot_buttons[slot_i]
				btn.visible = true
				if equipped_slot == slot_i:
					btn.text = "✅ %d" % (slot_i + 1)
					btn.disabled = true
				else:
					btn.text = "Слот %d" % (slot_i + 1)
					btn.disabled = false


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
