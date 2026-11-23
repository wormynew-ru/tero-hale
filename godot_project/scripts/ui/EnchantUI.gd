extends ScrollContainer

@onready var header_hint_label: Label = %HeaderHintLabel
@onready var feedback_label: Label = %EnchantFeedbackLabel

@onready var weapon_header_label: Label = %WeaponHeaderLabel
@onready var weapon_stats_label: Label = %WeaponStatsLabel
@onready var weapon_next_label: Label = %WeaponNextLabel
@onready var weapon_enchant_button: Button = %WeaponEnchantButton

@onready var armor_header_label: Label = %ArmorHeaderLabel
@onready var armor_stats_label: Label = %ArmorStatsLabel
@onready var armor_next_label: Label = %ArmorNextLabel
@onready var armor_enchant_button: Button = %ArmorEnchantButton

@onready var offhand_header_label: Label = %OffhandHeaderLabel
@onready var offhand_stats_label: Label = %OffhandStatsLabel
@onready var offhand_next_label: Label = %OffhandNextLabel
@onready var offhand_enchant_button: Button = %OffhandEnchantButton

@onready var merge_list_vbox: VBoxContainer = %MergeListVBox


var _merge_rows: Array[Dictionary] = []
var _empty_merge_label: Label = null
var _dirty: bool = true
var _refresh_queued: bool = false


func _ready() -> void:
	GameManager.stats_changed.connect(_on_state_updated)
	GameManager.inventory_changed.connect(_on_state_updated)
	GameManager.enchant_changed.connect(_on_state_updated)
	GameManager.difficulty_changed.connect(_on_state_updated)
	GameManager.dark_skills_changed.connect(_on_state_updated)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _on_state_updated())
	GameManager.game_reset.connect(_on_reset)

	weapon_enchant_button.pressed.connect(func() -> void: _on_enchant_pressed(ItemData.ItemType.WEAPON))
	armor_enchant_button.pressed.connect(func() -> void: _on_enchant_pressed(ItemData.ItemType.ARMOR))
	offhand_enchant_button.pressed.connect(func() -> void: _on_enchant_pressed(ItemData.ItemType.OFFHAND))
	HoldAutoClicker.attach(weapon_enchant_button, 50.0)
	HoldAutoClicker.attach(armor_enchant_button, 50.0)
	HoldAutoClicker.attach(offhand_enchant_button, 50.0)
	_ensure_empty_merge_label()
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


func _on_enchant_pressed(slot_type: ItemData.ItemType) -> void:
	var result: Dictionary = GameManager.try_enchant_slot(slot_type)
	feedback_label.text = str(result.get("message", ""))
	if bool(result.get("success", false)):
		feedback_label.modulate = Color(0.42, 0.96, 0.62, 1.0)
	else:
		feedback_label.modulate = Color(0.98, 0.62, 0.42, 1.0)


func _ensure_empty_merge_label() -> void:
	if _empty_merge_label != null:
		return
	_empty_merge_label = Label.new()
	_empty_merge_label.text = "Нет подходящих пар дубликатов (★1–★4) в рюкзаке."
	_empty_merge_label.modulate = Color(0.66, 0.72, 0.82, 1.0)
	_empty_merge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_merge_label.visible = false
	merge_list_vbox.add_child(_empty_merge_label)


func _get_or_create_merge_row(idx: int) -> Dictionary:
	while _merge_rows.size() <= idx:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(lbl)

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(180.0, 42.0)
		var entry_ref: Dictionary = {
			"row": row,
			"lbl": lbl,
			"btn": btn,
			"item_id": "",
			"star_level": 1,
		}
		btn.pressed.connect(func() -> void:
			var iid: String = str(entry_ref["item_id"])
			var st: int = int(entry_ref["star_level"])
			if not iid.is_empty():
				var res: Dictionary = GameManager.merge_duplicate_item(iid, st)
				feedback_label.text = str(res.get("message", ""))
				feedback_label.modulate = Color(0.45, 0.96, 0.65, 1.0) if bool(res.get("success", false)) else Color(0.98, 0.62, 0.42, 1.0)
		)
		row.add_child(btn)
		merge_list_vbox.add_child(row)
		_merge_rows.append(entry_ref)
	return _merge_rows[idx]


func _refresh_merge_list() -> void:
	_ensure_empty_merge_label()
	var candidates: Array[Dictionary] = GameManager.get_merge_candidates()
	for i: int in range(candidates.size()):
		var c: Dictionary = candidates[i]
		var it: ItemData = c["item"] as ItemData
		var st: int = int(c["star_level"])
		var total: int = int(c["total"])
		var max_q: int = int(c["max_quality"])
		var r: Dictionary = _get_or_create_merge_row(i)
		var row: HBoxContainer = r["row"] as HBoxContainer
		var lbl: Label = r["lbl"] as Label
		var btn: Button = r["btn"] as Button
		row.visible = true
		r["item_id"] = it.id
		r["star_level"] = st
		lbl.text = "%s [★%d → ★%d | x%d в сумке, макс. %d%% кач.]" % [it.get_display_name(), st, st + 1, total, max_q]
		btn.text = "⭐ Слить (2 → ★%d)" % (st + 1)
		btn.disabled = total < 2

	for j: int in range(candidates.size(), _merge_rows.size()):
		(_merge_rows[j]["row"] as HBoxContainer).visible = false
		_merge_rows[j]["item_id"] = ""

	_empty_merge_label.visible = candidates.is_empty()


func _refresh() -> void:
	_dirty = false
	var max_lvl: int = GameManager.get_max_enchant_level()
	if GameManager.is_equipment_disabled():
		header_hint_label.text = "🌿 Класс Спирит не использует экипировку и ковку — вместо вещей сражаются 4 природных духа."
		header_hint_label.modulate = Color(0.55, 0.96, 0.78, 1.0)
	elif GameManager.has_hero_class("alchemist"):
		header_hint_label.text = "⚗️ Бонус Алхимика: лимит заточки расширен до +%d, стоимость -40%%, шанс успеха x1.60 (мин. 1.50%%) и иммунитет к дебафу цен!" % max_lvl
		header_hint_label.modulate = Color(0.45, 0.95, 0.72, 1.0)
	else:
		header_hint_label.text = "⚒️ Кузня зачарования: усиливает Оружие, Броню и Оффхенд от +0 до +%d. При неудаче уровень не теряется, но шанс падает до 0.50%% на +99 → +100." % max_lvl
		header_hint_label.modulate = Color(0.78, 0.84, 0.94, 1.0)

	_refresh_slot(
		ItemData.ItemType.WEAPON,
		"⚔️ Оружие",
		GameManager.equipped_weapon,
		GameManager.equipped_weapon_quality,
		GameManager.equipped_weapon_stars,
		weapon_header_label,
		weapon_stats_label,
		weapon_next_label,
		weapon_enchant_button
	)
	_refresh_slot(
		ItemData.ItemType.ARMOR,
		"🛡️ Броня",
		GameManager.equipped_armor,
		GameManager.equipped_armor_quality,
		GameManager.equipped_armor_stars,
		armor_header_label,
		armor_stats_label,
		armor_next_label,
		armor_enchant_button
	)
	_refresh_slot(
		ItemData.ItemType.OFFHAND,
		"🔰 Оффхенд",
		GameManager.equipped_offhand,
		GameManager.equipped_offhand_quality,
		GameManager.equipped_offhand_stars,
		offhand_header_label,
		offhand_stats_label,
		offhand_next_label,
		offhand_enchant_button
	)
	_refresh_merge_list()


func _refresh_slot(
	slot_type: ItemData.ItemType,
	slot_title: String,
	item: ItemData,
	item_q: int,
	item_stars: int,
	header_lbl: Label,
	stats_lbl: Label,
	next_lbl: Label,
	btn: Button
) -> void:
	if GameManager.is_equipment_disabled():
		header_lbl.text = "%s: [Заблокировано классом Спирит]" % slot_title
		stats_lbl.text = "Смените класс в меню «🎭 Класс героя», чтобы снова ковать экипировку."
		next_lbl.text = "Недоступно для класса Спирит"
		btn.text = "Недоступно"
		btn.disabled = true
		return

	var elvl: int = GameManager.get_enchant_level(slot_type)

	if item == null:
		header_lbl.text = "%s [+%d]: [Не экипировано]" % [slot_title, elvl]
		stats_lbl.text = "Наденьте предмет из рюкзака или купите в лавке, чтобы ковать этот слот."
		next_lbl.text = "Недоступно без предмета"
		btn.text = "Нет предмета"
		btn.disabled = true
		return

	var dark_lvl: int = GameManager.get_dark_enchant_level(slot_type)
	var total_mult: float = GameManager.get_enchant_power_multiplier(elvl + dark_lvl)
	var dark_tag: String = " | 🌑+%d" % dark_lvl if dark_lvl > 0 else ""
	header_lbl.text = "%s [+%d%s | %d%% ★%d]: %s" % [slot_title, elvl, dark_tag, item_q, item_stars, item.get_display_name()]
	var bonuses: Dictionary = GameManager.get_equipped_stat_bonuses(slot_type)
	var extra_bar: String = " | +%s Барьер" % NumberFormatter.format_number(GameManager.get_raw_max_barrier()) if slot_type == ItemData.ItemType.OFFHAND else ""
	stats_lbl.text = "Итоговые бонусы (x%.2f): +%d Сила, +%d Ловкость, +%d Выносливость, +%d Инта%s" % [
		total_mult,
		int(bonuses["strength"]),
		int(bonuses["agility"]),
		int(bonuses["endurance"]),
		int(bonuses["intellect"]),
		extra_bar,
	]

	var max_lvl: int = GameManager.get_max_enchant_level()
	if elvl >= max_lvl:
		next_lbl.text = "Максимум (+%d достигнут)" % max_lvl
		btn.text = "Максимум"
		btn.disabled = true
		return

	var chance: float = GameManager.get_enchant_success_chance(elvl)
	var cost: float = GameManager.get_enchant_cost(elvl)
	next_lbl.text = "+%d → +%d  |  Шанс: %.2f%%  |  Цена: %s з." % [
		elvl,
		elvl + 1,
		chance,
		NumberFormatter.format_number(cost),
	]
	btn.text = "⚒️ Зачаровать (+%d)" % (elvl + 1)
	btn.disabled = GameManager.gold < cost
