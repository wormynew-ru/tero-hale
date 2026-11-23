extends ColorRect

@onready var afk_center: CenterContainer = %AfkCenter
@onready var afk_time_label: Label = %AfkTimeLabel
@onready var afk_kills_label: Label = %AfkKillsLabel
@onready var afk_gold_label: Label = %AfkGoldLabel
@onready var afk_xp_label: Label = %AfkXPLabel
@onready var exit_afk_button: Button = %ExitAfkButton
@onready var fps_15_button: Button = %Fps15Button
@onready var fps_20_button: Button = %Fps20Button
@onready var fps_30_button: Button = %Fps30Button
@onready var fps_60_button: Button = %Fps60Button


func _ready() -> void:
	GameManager.afk_mode_changed.connect(_on_afk_mode_changed)
	GameManager.afk_stats_updated.connect(_on_afk_stats_updated)
	exit_afk_button.pressed.connect(func() -> void: GameManager.set_afk_mode(false))
	fps_15_button.pressed.connect(func() -> void: _select_fps(15))
	fps_20_button.pressed.connect(func() -> void: _select_fps(20))
	fps_30_button.pressed.connect(func() -> void: _select_fps(30))
	fps_60_button.pressed.connect(func() -> void: _select_fps(60))

	_on_afk_mode_changed(GameManager.is_afk_mode)
	_refresh_fps_buttons()
	_on_afk_stats_updated(
		GameManager.afk_elapsed_seconds,
		GameManager.afk_kills,
		GameManager.afk_gold_earned,
		GameManager.afk_xp_earned
	)


func _select_fps(fps_val: int) -> void:
	GameManager.set_afk_fps_limit(fps_val)
	_refresh_fps_buttons()


func _refresh_fps_buttons() -> void:
	var cur: int = GameManager.afk_target_fps
	var pairs: Array[Array] = [
		[fps_15_button, 15],
		[fps_20_button, 20],
		[fps_30_button, 30],
		[fps_60_button, 60],
	]
	for pair: Array in pairs:
		var btn: Button = pair[0] as Button
		var val: int = int(pair[1])
		var active: bool = (cur == val)
		btn.text = "✅ %d FPS" % val if active else "%d FPS" % val
		btn.modulate = Color(0.55, 0.96, 0.72, 1.0) if active else Color(0.82, 0.86, 0.92, 0.85)


func _exit_tree() -> void:
	DisplayServer.screen_set_keep_on(false)


func _on_afk_mode_changed(is_afk: bool) -> void:
	visible = is_afk
	if is_afk:
		if afk_center != null:
			afk_center.visible = true
		_refresh_fps_buttons()


func _on_afk_stats_updated(elapsed_seconds: float, kills: int, gold_earned: float, xp_earned: float) -> void:
	var total_sec: int = int(elapsed_seconds)
	var hours: int = floori(float(total_sec) / 3600.0)
	var minutes: int = floori(float(total_sec % 3600) / 60.0)
	var seconds: int = total_sec % 60
	afk_time_label.text = "⏱️ Время в AFK: %02d:%02d:%02d" % [hours, minutes, seconds]
	afk_kills_label.text = "💀 Побеждено врагов: %d" % kills
	afk_gold_label.text = "💰 Заработано золота: %s" % NumberFormatter.format_number(gold_earned)
	afk_xp_label.text = "✨ Получено опыта: %s" % NumberFormatter.format_number(xp_earned)
