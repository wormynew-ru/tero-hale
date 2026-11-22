extends ScrollContainer

@onready var pet_status_label: Label = %PetStatusLabel
@onready var pet_feedback_label: Label = %PetFeedbackLabel
@onready var active_pet_label: Label = %ActivePetLabel
@onready var unequip_pet_button: Button = %UnequipPetButton
@onready var pet_list_vbox: VBoxContainer = %PetListVBox


func _ready() -> void:
	GameManager.pets_changed.connect(_refresh)
	GameManager.stats_changed.connect(_refresh)
	GameManager.inventory_changed.connect(_refresh)
	GameManager.difficulty_changed.connect(_refresh)
	GameManager.game_reset.connect(_on_reset)
	unequip_pet_button.pressed.connect(func() -> void:
		GameManager.unequip_pet()
		pet_feedback_label.text = "Слот Путника освобождён."
	)
	_refresh()


func _on_reset() -> void:
	pet_feedback_label.text = ""
	_refresh()


func _collect_light_treats() -> Array[Dictionary]:
	var treats: Array[Dictionary] = []
	for entry: Dictionary in GameManager.inventory:
		var item: ItemData = entry["item"] as ItemData
		var cnt: int = int(entry["count"])
		if item != null and cnt > 0 and item.item_type == ItemData.ItemType.HARVEST and item.garden_category == "light":
			treats.append({"item": item, "count": cnt})
	return treats


func _get_item_display(item_id: String) -> String:
	if item_id.is_empty():
		return "—"
	var item: ItemData = load("res://resources/items/%s.tres" % item_id) as ItemData
	if item != null:
		return "%s %s" % [item.icon_emoji, item.item_name]
	return item_id


func _refresh() -> void:
	if pet_list_vbox == null:
		return

	var active_pet: PetData = GameManager.get_equipped_pet()
	pet_status_label.text = "🐾 Приручено путников: %d / %d. Путников нельзя купить за золото — только приманить высадкой в ☀️ Светлом саду (повторки вянут) и дрессировать пряниками!" % [
		GameManager.owned_pet_ids.size(),
		GameManager.all_pets.size(),
	]

	if active_pet != null:
		var active_lvl: int = GameManager.get_pet_training_level(active_pet.id)
		active_pet_label.text = "🌟 Активный слот Путника: %s %s [Дресс. Ур.%d, +%d%%] (%s) — %s" % [
			active_pet.icon_emoji,
			active_pet.pet_name,
			active_lvl,
			active_lvl * 12,
			active_pet.subtitle,
			active_pet.description,
		]
		unequip_pet_button.disabled = false
	else:
		active_pet_label.text = "🐾 Активный слот Путника: [Пусто — приманите в Светлом саду и выберите ниже]"
		unequip_pet_button.disabled = true

	for child: Node in pet_list_vbox.get_children():
		child.queue_free()

	var light_treats: Array[Dictionary] = _collect_light_treats()

	for pet: PetData in GameManager.all_pets:
		if pet == null:
			continue

		var owned: bool = GameManager.has_pet_owned(pet.id)
		var equipped: bool = GameManager.equipped_pet_id == pet.id
		var train_lvl: int = GameManager.get_pet_training_level(pet.id)

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
		style.border_width_left = 2 if equipped else 1
		style.border_width_top = 2 if equipped else 1
		style.border_width_right = 2 if equipped else 1
		style.border_width_bottom = 2 if equipped else 1

		if equipped:
			style.bg_color = pet.accent_color.darkened(0.74)
			style.border_color = pet.accent_color
		elif owned:
			style.bg_color = Color(0.12, 0.16, 0.21, 1.0)
			style.border_color = Color(0.42, 0.56, 0.72, 0.9)
		else:
			style.bg_color = Color(0.11, 0.13, 0.17, 1.0)
			style.border_color = Color(0.32, 0.36, 0.44, 1.0)
		card.add_theme_stylebox_override("panel", style)

		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 8)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)

		var title_lbl: Label = Label.new()
		title_lbl.add_theme_font_size_override("font_size", 16)
		var lvl_badge: String = " • Дресс. Ур.%d/%d (+%d%%)" % [train_lvl, GameManager.MAX_PET_TRAINING_LEVEL, train_lvl * 12] if owned else " • Не приручён"
		title_lbl.text = "%s %s (%s)%s" % [pet.icon_emoji, pet.pet_name, pet.subtitle, lvl_badge]
		title_lbl.add_theme_color_override("font_color", pet.accent_color.lightened(0.25))
		info_vbox.add_child(title_lbl)

		var desc_lbl: Label = Label.new()
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.86, 0.94, 1.0))
		desc_lbl.text = pet.description
		info_vbox.add_child(desc_lbl)

		var pref_lbl: Label = Label.new()
		pref_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pref_lbl.add_theme_font_size_override("font_size", 12)
		if owned:
			pref_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.45, 1.0))
			pref_lbl.text = "🍪 Пряники: ★ Любимый — %s  |  👍 Хороший — %s" % [
				_get_item_display(pet.favorite_treat_id),
				_get_item_display(pet.secondary_treat_id),
			]
		else:
			pref_lbl.add_theme_color_override("font_color", Color(0.68, 0.92, 0.72, 1.0))
			pref_lbl.text = "☀️ Приманка в Светлом саду (грядки 1 + 2 + 3): %s" % pet.lure_hint
		info_vbox.add_child(pref_lbl)

		row.add_child(info_vbox)

		var action_btn: Button = Button.new()
		action_btn.custom_minimum_size = Vector2(168.0, 46.0)
		action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		if equipped:
			action_btn.text = "✅ В слоте"
			action_btn.disabled = true
		elif owned:
			action_btn.text = "Взять с собой"
			var target_id: String = pet.id
			var target_name: String = "%s %s" % [pet.icon_emoji, pet.pet_name]
			action_btn.pressed.connect(func() -> void:
				if GameManager.equip_pet(target_id):
					pet_feedback_label.text = "Путник «%s» теперь сопровождает героя!" % target_name
			)
		else:
			action_btn.text = "☀️ Приманить в Саду"
			action_btn.disabled = true

		row.add_child(action_btn)
		card_vbox.add_child(row)

		if owned and train_lvl < GameManager.MAX_PET_TRAINING_LEVEL:
			if light_treats.is_empty():
				var no_treat_lbl: Label = Label.new()
				no_treat_lbl.add_theme_font_size_override("font_size", 12)
				no_treat_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.80, 1.0))
				no_treat_lbl.text = "Нет пряников в рюкзаке — вырастите и соберите растения в ☀️ Светлом саду."
				card_vbox.add_child(no_treat_lbl)
			else:
				var treat_flow: HFlowContainer = HFlowContainer.new()
				treat_flow.add_theme_constant_override("h_separation", 8)
				treat_flow.add_theme_constant_override("v_separation", 8)
				for t_entry: Dictionary in light_treats:
					var treat_item: ItemData = t_entry["item"] as ItemData
					var cnt: int = int(t_entry["count"])
					var chance_pct: int = roundi(GameManager.get_pet_treat_success_chance(pet.id, treat_item) * 100.0)
					var tag: String = "★" if treat_item.id == pet.favorite_treat_id else ("👍" if treat_item.id == pet.secondary_treat_id else "🍪")
					var feed_btn: Button = Button.new()
					feed_btn.custom_minimum_size = Vector2(210.0, 44.0)
					feed_btn.text = "%s %s %s (x%d · %d%%)" % [tag, treat_item.icon_emoji, treat_item.item_name, cnt, chance_pct]
					var pid: String = pet.id
					feed_btn.pressed.connect(func() -> void:
						var res: Dictionary = GameManager.train_pet_with_treat(pid, treat_item)
						pet_feedback_label.text = str(res.get("message", ""))
					)
					treat_flow.add_child(feed_btn)
				card_vbox.add_child(treat_flow)
		elif owned and train_lvl >= GameManager.MAX_PET_TRAINING_LEVEL:
			var max_lbl: Label = Label.new()
			max_lbl.add_theme_font_size_override("font_size", 12)
			max_lbl.add_theme_color_override("font_color", Color(0.45, 0.96, 0.72, 1.0))
			max_lbl.text = "🏆 Достигнут максимальный уровень дрессировки (%d/%d)!" % [train_lvl, GameManager.MAX_PET_TRAINING_LEVEL]
			card_vbox.add_child(max_lbl)

		card.add_child(card_vbox)
		pet_list_vbox.add_child(card)
