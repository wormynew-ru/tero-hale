extends ColorRect

@onready var afk_center: CenterContainer = %AfkCenter
@onready var afk_time_label: Label = %AfkTimeLabel
@onready var afk_kills_label: Label = %AfkKillsLabel
@onready var afk_gold_label: Label = %AfkGoldLabel
@onready var afk_xp_label: Label = %AfkXPLabel
@onready var blackout_button: Button = %BlackoutButton
@onready var exit_afk_button: Button = %ExitAfkButton
@onready var wake_hint_label: Label = %WakeHintLabel

var _is_blackout: bool = false


func _ready() -> void:
	GameManager.afk_mode_changed.connect(_on_afk_mode_changed)
	GameManager.afk_stats_updated.connect(_on_afk_stats_updated)
	blackout_button.pressed.connect(func() -> void: _set_blackout(true))
	exit_afk_button.pressed.connect(func() -> void: GameManager.set_afk_mode(false))

	_on_afk_mode_changed(GameManager.is_afk_mode)
	_on_afk_stats_updated(
		GameManager.afk_elapsed_seconds,
		GameManager.afk_kills,
		GameManager.afk_gold_earned,
		GameManager.afk_xp_earned
	)


func _gui_input(event: InputEvent) -> void:
	if not _is_blackout or not visible:
		return
	var is_tap: bool = (
		(event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	)
	if is_tap:
		_set_blackout(false)
		accept_event()


func _exit_tree() -> void:
	RenderingServer.render_loop_enabled = true
	DisplayServer.screen_set_keep_on(false)


func _on_afk_mode_changed(is_afk: bool) -> void:
	visible = is_afk
	if not is_afk:
		_set_blackout(false)
	else:
		afk_center.visible = true
		wake_hint_label.visible = false


func _set_blackout(enabled: bool) -> void:
	_is_blackout = enabled
	if enabled:
		afk_center.visible = false
		wake_hint_label.visible = true
		await RenderingServer.frame_post_draw
		if _is_blackout and GameManager.is_afk_mode:
			RenderingServer.render_loop_enabled = false
	else:
		RenderingServer.render_loop_enabled = true
		afk_center.visible = true
		wake_hint_label.visible = false


func _on_afk_stats_updated(elapsed_seconds: float, kills: int, gold_earned: float, xp_earned: float) -> void:
	var total_sec: int = int(elapsed_seconds)
	var hours: int = floori(float(total_sec) / 3600.0)
	var minutes: int = floori(float(total_sec % 3600) / 60.0)
	var seconds: int = total_sec % 60
	afk_time_label.text = "⏱️ Время в AFK: %02d:%02d:%02d" % [hours, minutes, seconds]
	afk_kills_label.text = "💀 Побеждено врагов: %d" % kills
	afk_gold_label.text = "💰 Заработано золота: %s" % NumberFormatter.format_number(gold_earned)
	afk_xp_label.text = "✨ Получено опыта: %s" % NumberFormatter.format_number(xp_earned)
