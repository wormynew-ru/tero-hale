extends Button

signal manual_cast_requested(slot_index: int)
signal auto_cast_toggled(slot_index: int)

const HOLD_THRESHOLD_SEC: float = 1.0

@export var slot_index: int = 0

@onready var emoji_label: Label = %EmojiLabel
@onready var status_label: Label = %StatusLabel
@onready var auto_badge_label: Label = %AutoBadgeLabel
@onready var hold_progress_bar: ProgressBar = %HoldProgressBar

var _is_holding: bool = false
var _hold_elapsed: float = 0.0
var _hold_triggered: bool = false
var _overcharge_tick: int = 0
var _normal_style: StyleBoxFlat = null
var _auto_style: StyleBoxFlat = null


func _ready() -> void:
	_build_styles()
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

	GameManager.abilities_changed.connect(_refresh)
	GameManager.buffs_changed.connect(_refresh)
	GameManager.mana_changed.connect(_on_mana_changed)
	GameManager.difficulty_changed.connect(_refresh)
	GameManager.dark_skills_changed.connect(_refresh)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _refresh())
	GameManager.game_reset.connect(_refresh)
	_refresh()


func set_overcharge_tick(tick_num: int) -> void:
	_overcharge_tick = tick_num
	_refresh()


func _build_styles() -> void:
	var base: StyleBoxFlat = get_theme_stylebox("normal") as StyleBoxFlat
	if base != null:
		_normal_style = base.duplicate() as StyleBoxFlat
		_auto_style = base.duplicate() as StyleBoxFlat
		_auto_style.border_color = Color(0.98, 0.82, 0.28, 1.0)
		_auto_style.bg_color = Color(0.2, 0.25, 0.3, 0.96)


func _process(delta: float) -> void:
	if _is_holding and not _hold_triggered:
		_hold_elapsed += delta
		hold_progress_bar.visible = true
		hold_progress_bar.value = clampf((_hold_elapsed / HOLD_THRESHOLD_SEC) * 100.0, 0.0, 100.0)
		if _hold_elapsed >= HOLD_THRESHOLD_SEC:
			_hold_triggered = true
			hold_progress_bar.visible = false
			hold_progress_bar.value = 0.0
			auto_cast_toggled.emit(slot_index)


func _on_button_down() -> void:
	_is_holding = true
	_hold_elapsed = 0.0
	_hold_triggered = false


func _on_button_up() -> void:
	if _is_holding and not _hold_triggered:
		manual_cast_requested.emit(slot_index)
	_is_holding = false
	_hold_elapsed = 0.0
	_hold_triggered = false
	hold_progress_bar.visible = false
	hold_progress_bar.value = 0.0


func _on_mana_changed(_current_mana: float, _max_mana: float) -> void:
	_refresh()


func _refresh() -> void:
	var ability: AbilityData = GameManager.get_ability(slot_index)
	if ability == null:
		emoji_label.text = "✨"
		status_label.text = "Пусто"
		status_label.modulate = Color(0.55, 0.60, 0.68, 0.8)
		emoji_label.modulate = Color(0.45, 0.50, 0.58, 0.65)
		auto_badge_label.visible = false
		return

	emoji_label.text = ability.icon_emoji
	var cd: float = GameManager.get_ability_cooldown(slot_index)
	var is_auto: bool = GameManager.is_ability_auto_cast(slot_index)
	var mana_cost: float = GameManager.get_ability_mana_cost(ability)
	var has_mana: bool = GameManager.current_mana >= mana_cost
	var buff_rem: float = GameManager.get_active_buff_remaining(ability.id) if ability.effect_type == "buff" else 0.0
	var is_reflector_locked: bool = GameManager.has_hero_class("reflector") and ability.effect_type != "heal" and ability.effect_type != "buff"

	auto_badge_label.visible = is_auto
	if _auto_style != null and _normal_style != null:
		add_theme_stylebox_override("normal", _auto_style if is_auto else _normal_style)
		add_theme_stylebox_override("hover", _auto_style if is_auto else _normal_style)

	if _overcharge_tick > 0 and ability.effect_type == "overcharge_burn":
		status_label.text = "🔥Т%d" % _overcharge_tick
		status_label.modulate = Color(1.0, 0.45, 0.28, 1.0)
		emoji_label.modulate = Color(1.0, 0.85, 0.72, 1.0)
	elif buff_rem > 0.1:
		status_label.text = "✨%.0fс" % ceil(buff_rem)
		status_label.modulate = Color(0.48, 0.96, 0.68, 1.0)
		emoji_label.modulate = Color.WHITE
	elif is_reflector_locked:
		status_label.text = "🛡️ Блок"
		status_label.modulate = Color(0.72, 0.78, 0.88, 0.92)
		emoji_label.modulate = Color(0.55, 0.60, 0.68, 0.68)
	elif cd > 0.05:
		status_label.text = "%.1fс" % cd
		status_label.modulate = Color(0.95, 0.65, 0.35, 1.0)
		emoji_label.modulate = Color(0.6, 0.65, 0.72, 1.0)
	elif not has_mana:
		status_label.text = "💧%.0f" % mana_cost
		status_label.modulate = Color(0.45, 0.72, 0.98, 0.85)
		emoji_label.modulate = Color(0.7, 0.75, 0.85, 0.85)
	else:
		status_label.text = "💧%.0f" % mana_cost
		status_label.modulate = Color(0.55, 0.88, 1.0, 1.0)
		emoji_label.modulate = Color.WHITE
