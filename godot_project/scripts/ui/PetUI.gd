extends ScrollContainer

@onready var pet_status_label: Label = %PetStatusLabel
@onready var pet_feedback_label: Label = %PetFeedbackLabel
@onready var active_pet_label: Label = %ActivePetLabel
@onready var unequip_pet_button: Button = %UnequipPetButton
@onready var pet_list_vbox: VBoxContainer = %PetListVBox


func _ready() -> void:
	GameManager.pets_changed.connect(_refresh)
	GameManager.stats_changed.connect(_refresh)
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


func _refresh() -> void:
	if pet_list_vbox == null:
		return

	var active_pet: PetData = GameManager.get_equipped_pet()
	pet_status_label.text = "🐾 Приручено путников: %d / %d. Путник не имеет HP и не может погибнуть — он помогает в бою в отдельном слоте." % [
		GameManager.owned_pet_ids.size(),
		GameManager.all_pets.size(),
	]

	if active_pet != null:
		active_pet_label.text = "🌟 Активный слот Путника: %s %s (%s) — %s" % [
			active_pet.icon_emoji,
			active_pet.pet_name,
			active_pet.subtitle,
			active_pet.description,
		]
		unequip_pet_button.disabled = false
	else:
		active_pet_label.text = "🐾 Активный слот Путника: [Пусто — выберите спутника ниже]"
		unequip_pet_button.disabled = true

	for child: Node in pet_list_vbox.get_children():
		child.queue_free()

	for pet: PetData in GameManager.all_pets:
		if pet == null:
			continue

		var owned: bool = GameManager.has_pet_owned(pet.id)
		var equipped: bool = GameManager.equipped_pet_id == pet.id
		var diff_ok: bool = GameManager.max_unlocked_difficulty >= pet.required_difficulty

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

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)

		var title_lbl: Label = Label.new()
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.text = "%s %s (%s) • Бессмертный путник" % [pet.icon_emoji, pet.pet_name, pet.subtitle]
		title_lbl.add_theme_color_override("font_color", pet.accent_color.lightened(0.25))
		info_vbox.add_child(title_lbl)

		var desc_lbl: Label = Label.new()
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.86, 0.94, 1.0))
		desc_lbl.text = pet.description
		info_vbox.add_child(desc_lbl)

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
		elif not diff_ok:
			action_btn.text = "🔒 Сл. %d" % pet.required_difficulty
			action_btn.disabled = true
		else:
			var price: float = GameManager.get_pet_buy_price(pet)
			action_btn.text = "Приручить (%s з.)" % NumberFormatter.format_number(price)
			action_btn.disabled = GameManager.gold < price
			var target_id: String = pet.id
			action_btn.pressed.connect(func() -> void:
				var res: Dictionary = GameManager.buy_pet(target_id)
				pet_feedback_label.text = str(res.get("message", ""))
			)

		row.add_child(action_btn)
		card.add_child(row)
		pet_list_vbox.add_child(card)
