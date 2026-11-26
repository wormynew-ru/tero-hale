extends ScrollContainer

const GardenTabScript = preload("res://scripts/ui/sanctuary/SanctuaryGardenTab.gd")
const BrewingTabScript = preload("res://scripts/ui/sanctuary/SanctuaryBrewingTab.gd")
const SpiritTabScript = preload("res://scripts/ui/sanctuary/SanctuarySpiritTab.gd")

@onready var sanctuary_status_label: Label = %SanctuaryStatusLabel
@onready var alchemist_flag_label: Label = %AlchemistFlagLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var tab_garden_button: Button = %TabGardenButton
@onready var tab_brew_button: Button = %TabBrewButton
@onready var tab_spirit_button: Button = %TabSpiritButton
@onready var garden_tab: GardenTabScript = %SanctuaryGardenTab
@onready var brewing_tab: BrewingTabScript = %SanctuaryBrewingTab
@onready var spirit_tab: SpiritTabScript = %SanctuarySpiritTab

var _active_tab_idx: int = 0
var _rebuild_queued: bool = false
var _timer_accum: float = 0.0


func _ready() -> void:
	GameManager.garden_changed.connect(_on_state_updated)
	GameManager.brewing_changed.connect(_on_state_updated)
	GameManager.inventory_changed.connect(_on_state_updated)
	GameManager.difficulty_changed.connect(_on_state_updated)
	GameManager.skills_changed.connect(_on_state_updated)
	GameManager.dark_skills_changed.connect(_on_state_updated)
	GameManager.pets_changed.connect(_on_state_updated)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _on_state_updated())
	GameManager.game_reset.connect(_on_reset)
	visibility_changed.connect(_on_visibility_changed)

	tab_garden_button.pressed.connect(func() -> void: _switch_tab(0))
	tab_brew_button.pressed.connect(func() -> void: _switch_tab(1))
	tab_spirit_button.pressed.connect(func() -> void: _switch_tab(2))

	garden_tab.feedback_emitted.connect(_on_feedback_emitted)
	brewing_tab.feedback_emitted.connect(_on_feedback_emitted)
	spirit_tab.feedback_emitted.connect(_on_feedback_emitted)

	set_process(false)
	_apply_tab_visibility()
	_rebuild_sanctuary(true)


func _switch_tab(tab_idx: int) -> void:
	_active_tab_idx = clampi(tab_idx, 0, 2)
	_apply_tab_visibility()
	_rebuild_sanctuary(true)


func _apply_tab_visibility() -> void:
	garden_tab.visible = _active_tab_idx == 0
	brewing_tab.visible = _active_tab_idx == 1
	spirit_tab.visible = _active_tab_idx == 2
	tab_garden_button.modulate = Color(0.55, 0.96, 0.72, 1.0) if _active_tab_idx == 0 else Color(0.76, 0.80, 0.88, 1.0)
	tab_brew_button.modulate = Color(0.55, 0.88, 0.98, 1.0) if _active_tab_idx == 1 else Color(0.76, 0.80, 0.88, 1.0)
	tab_spirit_button.modulate = Color(0.96, 0.86, 0.48, 1.0) if _active_tab_idx == 2 else Color(0.76, 0.80, 0.88, 1.0)


func _on_feedback_emitted(msg: String) -> void:
	feedback_label.text = msg


func _on_reset() -> void:
	feedback_label.text = ""
	_rebuild_queued = false
	garden_tab.reset_cache()
	brewing_tab.reset_cache()
	spirit_tab.reset_cache()
	_rebuild_sanctuary(true)


func _on_visibility_changed() -> void:
	var vis: bool = is_visible_in_tree()
	set_process(vis)
	if vis:
		_rebuild_sanctuary(false)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		set_process(false)
		return
	_timer_accum += delta
	if _timer_accum < 0.5:
		return
	_timer_accum = 0.0
	if _active_tab_idx == 0:
		garden_tab.update_timers()
	elif _active_tab_idx == 1:
		brewing_tab.update_timers()
	else:
		spirit_tab.update_timers()


func _on_state_updated() -> void:
	if not is_visible_in_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_flush_sanctuary_rebuild")


func _flush_sanctuary_rebuild() -> void:
	_rebuild_queued = false
	if is_visible_in_tree():
		_rebuild_sanctuary(false)


func _rebuild_sanctuary(force: bool = false) -> void:
	var unlocked: bool = GameManager.is_alchemy_unlocked()
	if unlocked:
		sanctuary_status_label.text = "🏡 Убежище открыто (☀️ Светлый сад: Сл.1+ • 🌑 Тёмный сад и Котлы: Сл.%d+) · Сад: x%.2f · Варка: x%.2f · Дроп семян: x%.2f" % [
			GameManager.ALCHEMY_UNLOCK_DIFFICULTY,
			GameManager.get_garden_growth_speed_mult(),
			GameManager.get_brewing_speed_mult(),
			GameManager.get_seed_drop_multiplier(),
		]
		sanctuary_status_label.modulate = Color(0.55, 0.96, 0.72, 1.0)
	else:
		sanctuary_status_label.text = "☀️ Светлый сад открыт! 🌑 Тёмный сад и ⚗️ Зельеварение откроются после %d-й сложности (сейчас макс. Сл.%d)." % [
			GameManager.ALCHEMY_UNLOCK_DIFFICULTY,
			GameManager.max_unlocked_difficulty,
		]
		sanctuary_status_label.modulate = Color(0.98, 0.78, 0.42, 1.0)

	if GameManager.has_hero_class("alchemist"):
		var flag_text: String = "✅ СЛЕДУЮЩАЯ ОШИБКА НЕ ВЗОРВЁТСЯ (флаг активен)" if GameManager.alchemist_next_mistake_safe else "⚡ Следующая ошибка взорвёт котёл (следующая за ней — спасётся)"
		alchemist_flag_label.text = "⚗️ Алхимик: семена x2, варка x2, каждое 2-е неверное зелье не взрывается → %s" % flag_text
		alchemist_flag_label.modulate = Color(0.45, 0.98, 0.78, 1.0) if GameManager.alchemist_next_mistake_safe else Color(0.95, 0.85, 0.45, 1.0)
	else:
		alchemist_flag_label.text = "ℹ️ Посадки обоих садов, варящиеся зелья, семена, приручённые путники и уровни духов НЕ пропадают при новом ране."
		alchemist_flag_label.modulate = Color(0.76, 0.86, 0.96, 1.0)

	if _active_tab_idx == 0 or force:
		garden_tab.sync_state(unlocked, force)
	if _active_tab_idx == 1 or force:
		brewing_tab.sync_state(unlocked, force)
	if _active_tab_idx == 2 or force:
		spirit_tab.sync_state(force)
