extends ScrollContainer

@onready var pet_status_label: Label = %PetStatusLabel
@onready var pet_feedback_label: Label = %PetFeedbackLabel
@onready var active_pet_label: Label = %ActivePetLabel
@onready var unequip_pet_button: Button = %UnequipPetButton
@onready var pet_list_vbox: VBoxContainer = %PetListVBox


const TREAT_ITEM_PATHS: Array[String] = [
	"res://resources/items/light_clover_harvest.tres",
	"res://resources/items/honey_berry_harvest.tres",
	"res://resources/items/sky_chamomile_harvest.tres",
	"res://resources/items/spark_chili_harvest.tres",
]

var _treat_items: Array[ItemData] = []
var _pet_views: Array[Dictionary] = []
var _dirty: bool = true


func _ready() -> void:
	for p: String in TREAT_ITEM_PATHS:
		var it: ItemData = load(p) as ItemData
		if it != null:
			_treat_items.append(it)

	GameManager.pets_changed.connect(_on_state_updated)
	GameManager.stats_changed.connect(_on_state_updated)
	GameManager.inventory_changed.connect(_on_state_updated)
	GameManager.difficulty_changed.connect(_on_state_updated)
	GameManager.game_reset.connect(_on_reset)
	unequip_pet_button.pressed.connect(func() -> void:
		GameManager.unequip_pet()
		pet_feedback_label.text = "Слот Путника освобождён."
	)
	_build_pet_cards()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and _dirty:
		_refresh()


func _on_reset() -> void:
	pet_feedback_label.text = ""
	_dirty = true
	if is_visible_in_tree():
		_refresh()


func _on_state_updated() -> void:
	if not is_visible_in_tree():
		_dirty = true
		return
	_refresh()


func _get_item_display(item_id: String) -> String:
	if item_id.is_empty():
		return "—"
	var item: ItemData = load("res://resources/items/%s.tres" % item_id) as ItemData
	if item != null:
		return "%s %s" % [item.icon_emoji, item.item_name]
	return item_id


func _build_pet_cards() -> void:
	if pet_list_vbox == null:
		return
	for child: Node in pet_list_vbox.get_children():
		child.queue_free()
	_pet_views.clear()

	for pet: PetData in GameManager.all_pets:
		if pet == null:
			continue

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
		info_vbox.add_child(pref_lbl)

		row.add_child(info_vbox)

		var action_btn: Button = Button.new()
		action_btn.custom_minimum_size = Vector2(168.0, 46.0)
		action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var target_id: String = pet.id
		var target_name: String = "%s %s" % [pet.icon_emoji, pet.pet_name]
		action_btn.pressed.connect(func() -> void:
			if GameManager.equip_pet(target_id):
				pet_feedback_label.text = "Путник «%s» теперь сопровождает героя!" % target_name
		)
		row.add_child(action_btn)
		card_vbox.add_child(row)

		var status_note_lbl: Label = Label.new()
		status_note_lbl.add_theme_font_size_override("font_size", 12)
		card_vbox.add_child(status_note_lbl)

		var treat_flow: HFlowContainer = HFlowContainer.new()
		treat_flow.add_theme_constant_override("h_separation", 8)
		treat_flow.add_theme_constant_override("v_separation", 8)
		var treat_buttons: Array[Dictionary] = []
		for treat_item: ItemData in _treat_items:
			var feed_btn: Button = Button.new()
			feed_btn.custom_minimum_size = Vector2(210.0, 44.0)
			var t_item: ItemData = treat_item
			var pid: String = pet.id
			feed_btn.pressed.connect(func() -> void:
				var res: Dictionary = GameManager.train_pet_with_treat(pid, t_item)
				pet_feedback_label.text = str(res.get("message", ""))
			)
			HoldAutoClicker.attach(feed_btn, 50.0)
			treat_flow.add_child(feed_btn)
			treat_buttons.append({"item": treat_item, "btn": feed_btn})
		card_vbox.add_child(treat_flow)

		card.add_child(card_vbox)
		pet_list_vbox.add_child(card)

		_pet_views.append({
			"pet": pet,
			"style": style,
			"title_lbl": title_lbl,
			"pref_lbl": pref_lbl,
			"action_btn": action_btn,
			"status_note_lbl": status_note_lbl,
			"treat_flow": treat_flow,
			"treat_buttons": treat_buttons,
		})


func _refresh() -> void:
	_dirty = false
	if pet_list_vbox == null:
		return
	if _pet_views.size() != GameManager.all_pets.size():
		_build_pet_cards()

	var active_pet: PetData = GameManager.get_equipped_pet()
	pet_status_label.text = "🐾 Приручено путников: %d / %d. Путников нельзя купить за золото — только приманить высадкой в ☀️ Светлом саду (повторки вянут) и дрессировать пряниками (удержание кнопки — автокормление 50/с)!" % [
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

	var any_treat: bool = false
	for treat_item: ItemData in _treat_items:
		if GameManager.get_item_count_in_inventory(treat_item) > 0:
			any_treat = true
			break

	for view: Dictionary in _pet_views:
		var pet: PetData = view["pet"] as PetData
		var style: StyleBoxFlat = view["style"] as StyleBoxFlat
		var title_lbl: Label = view["title_lbl"] as Label
		var pref_lbl: Label = view["pref_lbl"] as Label
		var action_btn: Button = view["action_btn"] as Button
		var status_note_lbl: Label = view["status_note_lbl"] as Label
		var treat_flow: HFlowContainer = view["treat_flow"] as HFlowContainer
		var treat_buttons: Array[Dictionary] = view["treat_buttons"] as Array[Dictionary]

		var owned: bool = GameManager.has_pet_owned(pet.id)
		var equipped: bool = GameManager.equipped_pet_id == pet.id
		var train_lvl: int = GameManager.get_pet_training_level(pet.id)

		var bw: int = 2 if equipped else 1
		style.border_width_left = bw
		style.border_width_top = bw
		style.border_width_right = bw
		style.border_width_bottom = bw
		if equipped:
			style.bg_color = pet.accent_color.darkened(0.74)
			style.border_color = pet.accent_color
		elif owned:
			style.bg_color = Color(0.12, 0.16, 0.21, 1.0)
			style.border_color = Color(0.42, 0.56, 0.72, 0.9)
		else:
			style.bg_color = Color(0.11, 0.13, 0.17, 1.0)
			style.border_color = Color(0.32, 0.36, 0.44, 1.0)

		var lvl_badge: String = " • Дресс. Ур.%d/%d (+%d%%)" % [train_lvl, GameManager.MAX_PET_TRAINING_LEVEL, train_lvl * 12] if owned else " • Не приручён"
		title_lbl.text = "%s %s (%s)%s" % [pet.icon_emoji, pet.pet_name, pet.subtitle, lvl_badge]

		if owned:
			pref_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.45, 1.0))
			pref_lbl.text = "🍪 Пряники: ★ Любимый — %s  |  👍 Хороший — %s" % [
				_get_item_display(pet.favorite_treat_id),
				_get_item_display(pet.secondary_treat_id),
			]
		else:
			pref_lbl.add_theme_color_override("font_color", Color(0.68, 0.92, 0.72, 1.0))
			pref_lbl.text = "☀️ Приманка в Светлом саду (грядки 1 + 2 + 3): %s" % pet.lure_hint

		if equipped:
			action_btn.text = "✅ В слоте"
			action_btn.disabled = true
		elif owned:
			action_btn.text = "Взять с собой"
			action_btn.disabled = false
		else:
			action_btn.text = "☀️ Приманить в Саду"
			action_btn.disabled = true

		if not owned:
			status_note_lbl.visible = false
			treat_flow.visible = false
		elif train_lvl >= GameManager.MAX_PET_TRAINING_LEVEL:
			status_note_lbl.visible = true
			status_note_lbl.add_theme_color_override("font_color", Color(0.45, 0.96, 0.72, 1.0))
			status_note_lbl.text = "🏆 Достигнут максимальный уровень дрессировки (%d/%d)!" % [train_lvl, GameManager.MAX_PET_TRAINING_LEVEL]
			treat_flow.visible = false
		elif not any_treat:
			status_note_lbl.visible = true
			status_note_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.80, 1.0))
			status_note_lbl.text = "Нет пряников в рюкзаке — вырастите и соберите растения в ☀️ Светлом саду."
			treat_flow.visible = false
		else:
			status_note_lbl.visible = false
			treat_flow.visible = true
			for tb: Dictionary in treat_buttons:
				var treat_item: ItemData = tb["item"] as ItemData
				var feed_btn: Button = tb["btn"] as Button
				var cnt: int = GameManager.get_item_count_in_inventory(treat_item)
				if cnt <= 0:
					feed_btn.visible = false
					feed_btn.disabled = true
				else:
					var chance_pct: int = roundi(GameManager.get_pet_treat_success_chance(pet.id, treat_item) * 100.0)
					var tag: String = "★" if treat_item.id == pet.favorite_treat_id else ("👍" if treat_item.id == pet.secondary_treat_id else "🍪")
					feed_btn.visible = true
					feed_btn.disabled = false
					feed_btn.text = "%s %s %s (x%d · %d%%)" % [tag, treat_item.icon_emoji, treat_item.item_name, cnt, chance_pct]

