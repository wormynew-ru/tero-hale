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


var _dirty: bool = true


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
	HoldAutoClicker.attach(weapon_enchant_button, 50.0)
	HoldAutoClicker.attach(armor_enchant_button, 50.0)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and _dirty:
		_refresh()


func _on_state_updated() -> void:
	if not is_visible_in_tree():
		_dirty = true
		return
	_refresh()


func _on_reset() -> void:
	feedback_label.text = ""
	_dirty = true
	if is_visible_in_tree():
		_refresh()


func _on_enchant_pressed(slot_type: ItemData.ItemType) -> void:
	var result: Dictionary = GameManager.try_enchant_slot(slot_type)
	feedback_label.text = str(result.get("message", ""))
	if bool(result.get("success", false)):
		feedback_label.modulate = Color(0.42, 0.96, 0.62, 1.0)
	else:
		feedback_label.modulate = Color(0.98, 0.62, 0.42, 1.0)


func _refresh() -> void:
	_dirty = false
	var max_lvl: int = GameManager.get_max_enchant_level()
	if GameManager.is_equipment_disabled():
		header_hint_label.text = "🌿 Класс Спирит не использует экипировку и ковку — вместо вещей сражаются 4 природных духа."
		header_hint_label.modulate = Color(0.55, 0.96, 0.78, 1.0)
	elif GameManager.has_hero_class("alchemist"):
		header_hint_label.text = "⚗️ Бонус Алхимика: лимит заточки расширен до +%d, стоимость -40%%, шанс успеха x1.60 (мин. 1.50%%)!" % max_lvl
		header_hint_label.modulate = Color(0.45, 0.95, 0.72, 1.0)
	else:
		header_hint_label.text = "⚒️ Кузня зачарования: усиливает экипированные слоты Оружия и Брони от +0 до +%d. При неудаче уровень не теряется, но шанс падает до 0.50%% на +99 → +100." % max_lvl
		header_hint_label.modulate = Color(0.78, 0.84, 0.94, 1.0)

	_refresh_slot(
		ItemData.ItemType.WEAPON,
		"⚔️ Оружие",
		GameManager.equipped_weapon,
		weapon_header_label,
		weapon_stats_label,
		weapon_next_label,
		weapon_enchant_button
	)
	_refresh_slot(
		ItemData.ItemType.ARMOR,
		"🛡️ Броня",
		GameManager.equipped_armor,
		armor_header_label,
		armor_stats_label,
		armor_next_label,
		armor_enchant_button
	)


func _refresh_slot(
	slot_type: ItemData.ItemType,
	slot_title: String,
	item: ItemData,
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
	var mult: float = GameManager.get_enchant_power_multiplier(elvl)

	if item == null:
		header_lbl.text = "%s [+%d]: [Не экипировано]" % [slot_title, elvl]
		stats_lbl.text = "Наденьте предмет из рюкзака или купите в лавке, чтобы ковать этот слот."
		next_lbl.text = "Недоступно без предмета"
		btn.text = "Нет предмета"
		btn.disabled = true
		return

	header_lbl.text = "%s [+%d]: %s" % [slot_title, elvl, item.get_display_name()]
	var bonuses: Dictionary = GameManager.get_equipped_stat_bonuses(slot_type)
	stats_lbl.text = "Итоговые бонусы (x%.2f): +%d Сила, +%d Ловкость, +%d Выносливость" % [
		mult,
		int(bonuses["strength"]),
		int(bonuses["agility"]),
		int(bonuses["endurance"]),
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
