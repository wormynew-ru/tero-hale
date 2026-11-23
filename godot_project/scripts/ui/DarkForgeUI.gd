extends ScrollContainer

@onready var header_label: Label = %DarkForgeHeaderLabel
@onready var resources_label: Label = %DarkForgeResourcesLabel
@onready var feedback_label: Label = %DarkForgeFeedbackLabel

@onready var dark_weapon_header_label: Label = %DarkWeaponHeaderLabel
@onready var dark_weapon_stats_label: Label = %DarkWeaponStatsLabel
@onready var dark_weapon_next_label: Label = %DarkWeaponNextLabel
@onready var dark_weapon_enchant_button: Button = %DarkWeaponEnchantButton

@onready var dark_armor_header_label: Label = %DarkArmorHeaderLabel
@onready var dark_armor_stats_label: Label = %DarkArmorStatsLabel
@onready var dark_armor_next_label: Label = %DarkArmorNextLabel
@onready var dark_armor_enchant_button: Button = %DarkArmorEnchantButton

@onready var dark_offhand_header_label: Label = %DarkOffhandHeaderLabel
@onready var dark_offhand_stats_label: Label = %DarkOffhandStatsLabel
@onready var dark_offhand_next_label: Label = %DarkOffhandNextLabel
@onready var dark_offhand_enchant_button: Button = %DarkOffhandEnchantButton

@onready var recipe_list_container: VBoxContainer = %RecipeListContainer

var _recipe_rows: Array[Dictionary] = []
var _dirty: bool = true
var _refresh_queued: bool = false


func _ready() -> void:
	GameManager.dark_forge_changed.connect(_on_state_updated)
	GameManager.dark_skills_changed.connect(_on_state_updated)
	GameManager.inventory_changed.connect(_on_state_updated)
	GameManager.stats_changed.connect(_on_state_updated)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _on_state_updated())
	GameManager.game_reset.connect(_on_reset)

	dark_weapon_enchant_button.pressed.connect(func() -> void: _on_dark_enchant_pressed(ItemData.ItemType.WEAPON))
	dark_armor_enchant_button.pressed.connect(func() -> void: _on_dark_enchant_pressed(ItemData.ItemType.ARMOR))
	dark_offhand_enchant_button.pressed.connect(func() -> void: _on_dark_enchant_pressed(ItemData.ItemType.OFFHAND))
	HoldAutoClicker.attach(dark_weapon_enchant_button, 50.0)
	HoldAutoClicker.attach(dark_armor_enchant_button, 50.0)
	HoldAutoClicker.attach(dark_offhand_enchant_button, 50.0)

	_build_recipe_cards_once()
	_refresh()


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
	call_deferred("_flush_refresh")


func _flush_refresh() -> void:
	_refresh_queued = false
	if is_visible_in_tree():
		_refresh()
	else:
		_dirty = true


func _on_reset() -> void:
	feedback_label.text = ""
	_dirty = true
	_refresh_queued = false
	if is_visible_in_tree():
		_refresh()


func _on_dark_enchant_pressed(slot_type: ItemData.ItemType) -> void:
	var result: Dictionary = GameManager.try_dark_forge_enchant(slot_type)
	feedback_label.text = str(result.get("message", ""))
	if bool(result.get("success", false)):
		feedback_label.modulate = Color(0.45, 0.96, 0.65, 1.0)
	else:
		feedback_label.modulate = Color(0.98, 0.62, 0.42, 1.0)


func _on_craft_pressed(recipe_id: String) -> void:
	var result: Dictionary = GameManager.craft_dark_forge_item(recipe_id)
	feedback_label.text = str(result.get("message", ""))
	if bool(result.get("success", false)):
		feedback_label.modulate = Color(0.45, 0.96, 0.65, 1.0)
	else:
		feedback_label.modulate = Color(0.98, 0.62, 0.42, 1.0)


func _build_recipe_cards_once() -> void:
	if not _recipe_rows.is_empty():
		return

	for recipe: Dictionary in GameManager.DARK_FORGE_RECIPES:
		var recipe_id: String = str(recipe.get("id", ""))
		var is_eternal: bool = bool(recipe.get("eternal", false))
		var is_ult: bool = recipe.has("required_items")

		var card: PanelContainer = PanelContainer.new()
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.content_margin_left = 14.0
		sb.content_margin_top = 10.0
		sb.content_margin_right = 14.0
		sb.content_margin_bottom = 10.0
		sb.bg_color = Color(0.15, 0.10, 0.18, 1.0) if is_ult else (Color(0.12, 0.10, 0.17, 1.0) if is_eternal else Color(0.10, 0.12, 0.18, 1.0))
		sb.border_width_left = 2 if is_ult else 1
		sb.border_width_top = 2 if is_ult else 1
		sb.border_width_right = 2 if is_ult else 1
		sb.border_width_bottom = 2 if is_ult else 1
		sb.border_color = Color(0.96, 0.68, 0.34, 0.9) if is_ult else (Color(0.75, 0.48, 0.95, 0.85) if is_eternal else Color(0.42, 0.62, 0.88, 0.85))
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_right = 8
		sb.corner_radius_bottom_left = 8
		card.add_theme_stylebox_override("panel", sb)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		card.add_child(hbox)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		hbox.add_child(info_vbox)

		var title_lbl: Label = Label.new()
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.text = str(recipe.get("title", recipe_id))
		info_vbox.add_child(title_lbl)

		var desc_lbl: Label = Label.new()
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.modulate = Color(0.78, 0.85, 0.96, 1.0)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.text = str(recipe.get("desc", ""))
		info_vbox.add_child(desc_lbl)

		var cost_lbl: Label = Label.new()
		cost_lbl.add_theme_font_size_override("font_size", 13)
		cost_lbl.modulate = Color(0.98, 0.82, 0.42, 1.0)
		cost_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(cost_lbl)

		var craft_btn: Button = Button.new()
		craft_btn.custom_minimum_size = Vector2(154.0, 44.0)
		craft_btn.text = "🔥 Выковать" if is_eternal else "📜 Сшить"
		craft_btn.pressed.connect(func() -> void: _on_craft_pressed(recipe_id))
		if not is_eternal:
			HoldAutoClicker.attach(craft_btn, 50.0)
		hbox.add_child(craft_btn)

		recipe_list_container.add_child(card)
		_recipe_rows.append({
			"recipe": recipe,
			"cost_lbl": cost_lbl,
			"craft_btn": craft_btn,
		})


func _refresh() -> void:
	_dirty = false
	var ore_cnt: int = GameManager.get_dark_forge_material_count("abyss_ore")
	var page_cnt: int = GameManager.get_dark_forge_material_count("ancient_page")
	resources_label.text = "🌑 Очки Тьмы: %d   |   ⛏️ Руда Бездны: %d (Осколки: %d/10)   |   📜 Древние листы: %d" % [
		GameManager.dark_points,
		ore_cnt,
		GameManager.abyss_ore_shards,
		page_cnt,
	]

	if GameManager.is_equipment_disabled():
		header_label.text = "🌿 Класс Спирит не носит оружие и броню — но вы можете ковать вечные предметы впрок для смены класса!"
		header_label.modulate = Color(0.55, 0.96, 0.78, 1.0)
	else:
		header_label.text = "🔥 Тёмная кузня: вечная ковка за 🌑 Очки Тьмы и материалы Шахты. Выкованные вечные вещи и Тёмная заточка (🌑+0→+1: 25%, +1→+2: 20%, минимум 15%) НИКОГДА не сбрасываются между ранами!"
		header_label.modulate = Color(0.86, 0.78, 0.98, 1.0)

	_refresh_dark_enchant_slot(
		ItemData.ItemType.WEAPON,
		"⚔️ Оружие",
		GameManager.equipped_weapon,
		dark_weapon_header_label,
		dark_weapon_stats_label,
		dark_weapon_next_label,
		dark_weapon_enchant_button
	)
	_refresh_dark_enchant_slot(
		ItemData.ItemType.ARMOR,
		"🛡️ Броня",
		GameManager.equipped_armor,
		dark_armor_header_label,
		dark_armor_stats_label,
		dark_armor_next_label,
		dark_armor_enchant_button
	)
	_refresh_dark_enchant_slot(
		ItemData.ItemType.OFFHAND,
		"🔰 Оффхенд",
		GameManager.equipped_offhand,
		dark_offhand_header_label,
		dark_offhand_stats_label,
		dark_offhand_next_label,
		dark_offhand_enchant_button
	)

	for row: Dictionary in _recipe_rows:
		var recipe: Dictionary = row["recipe"] as Dictionary
		var recipe_id: String = str(recipe.get("id", ""))
		var cost_lbl: Label = row["cost_lbl"] as Label
		var craft_btn: Button = row["craft_btn"] as Button
		var need_dp: int = int(recipe.get("dark_points", 0))
		var need_ore: int = int(recipe.get("abyss_ore", 0))
		var need_page: int = int(recipe.get("ancient_page", 0))

		var cost_parts: Array[String] = []
		if need_dp > 0:
			cost_parts.append("🌑 %d/%d" % [GameManager.dark_points, need_dp])
		if need_ore > 0:
			cost_parts.append("⛏️ %d/%d" % [ore_cnt, need_ore])
		if need_page > 0:
			cost_parts.append("📜 %d/%d" % [page_cnt, need_page])
		var req_items_var: Variant = recipe.get("required_items", {})
		if req_items_var is Dictionary:
			var req_dict: Dictionary = req_items_var as Dictionary
			for req_id_var: Variant in req_dict.keys():
				var req_id: String = str(req_id_var)
				var req_need: int = int(req_dict[req_id_var])
				var req_have: int = GameManager.get_dark_forge_material_count(req_id)
				var req_item: ItemData = GameManager.get_cached_item("res://resources/items/%s.tres" % req_id)
				var req_title: String = req_item.get_display_name() if req_item != null else req_id
				cost_parts.append("%s %d/%d" % [req_title, req_have, req_need])
		cost_lbl.text = "Цена: " + "  |  ".join(cost_parts)
		craft_btn.disabled = not GameManager.can_craft_dark_forge_recipe(recipe_id)


func _refresh_dark_enchant_slot(
	slot_type: ItemData.ItemType,
	slot_title: String,
	item: ItemData,
	header_lbl: Label,
	stats_lbl: Label,
	next_lbl: Label,
	btn: Button
) -> void:
	var dark_lvl: int = GameManager.get_dark_enchant_level(slot_type)
	var run_lvl: int = GameManager.get_enchant_level(slot_type)
	if GameManager.is_equipment_disabled():
		header_lbl.text = "%s [🌑+%d]: Заблокировано классом Спирит" % [slot_title, dark_lvl]
		stats_lbl.text = "Тёмная заточка сохранена, сменится при смене класса."
		next_lbl.text = "Недоступно для класса Спирит"
		btn.text = "Недоступно"
		btn.disabled = true
		return

	if item == null:
		header_lbl.text = "%s [🌑+%d | Обыч.+%d]: [Не экипировано]" % [slot_title, dark_lvl, run_lvl]
		stats_lbl.text = "Наденьте предмет в инвентаре, чтобы закалить слот навсегда."
		next_lbl.text = "Шанс сл. уровня: %.0f%% | Цена: %d 🌑" % [
			GameManager.get_dark_forge_enchant_chance(dark_lvl),
			GameManager.get_dark_forge_enchant_cost(dark_lvl),
		]
		btn.text = "Нет предмета"
		btn.disabled = true
		return

	var total_lvl: int = GameManager.get_total_slot_enchant_level(slot_type)
	var mult: float = GameManager.get_enchant_power_multiplier(total_lvl)
	var bonuses: Dictionary = GameManager.get_equipped_stat_bonuses(slot_type)
	header_lbl.text = "%s [🌑+%d | Всего +%d]: %s" % [slot_title, dark_lvl, total_lvl, item.get_display_name()]
	var extra_bar: String = " | +%s Барьер" % NumberFormatter.format_number(GameManager.get_raw_max_barrier()) if slot_type == ItemData.ItemType.OFFHAND else ""
	stats_lbl.text = "Итоговые бонусы слота (x%.2f): +%d Сил, +%d Лов, +%d Вын, +%d Инт%s" % [
		mult,
		int(bonuses["strength"]),
		int(bonuses["agility"]),
		int(bonuses["endurance"]),
		int(bonuses["intellect"]),
		extra_bar,
	]

	var chance: float = GameManager.get_dark_forge_enchant_chance(dark_lvl)
	var cost: int = GameManager.get_dark_forge_enchant_cost(dark_lvl)
	next_lbl.text = "🌑+%d → 🌑+%d  |  Шанс: %.0f%%  |  Цена: %d 🌑" % [
		dark_lvl,
		dark_lvl + 1,
		chance,
		cost,
	]
	btn.text = "🔥 Закалить (%d 🌑)" % cost
	btn.disabled = GameManager.dark_points < cost
