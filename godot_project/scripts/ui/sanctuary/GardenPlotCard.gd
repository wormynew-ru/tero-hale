class_name GardenPlotCard
extends PanelContainer

signal feedback_emitted(msg: String)

const ChoiceBtnScene := false

@onready var title_label: Label = %TitleLabel
@onready var action_button: Button = %ActionButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var feed_row: HBoxContainer = %FeedRow
@onready var feed_hint_label: Label = %FeedHintLabel
@onready var feed_button: Button = %FeedButton
@onready var choices_flow: HFlowContainer = %ChoicesFlow

var _is_light: bool = true
var _plot_index: int = 0
var _choice_buttons: Array[Button] = []
var _bound_seeds: Array[ItemData] = []


func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)
	feed_button.pressed.connect(_on_feed_pressed)


func configure(is_light: bool, plot_index: int, unlocked: bool, accessible: bool, plot: Dictionary, owned_seeds: Array[Dictionary]) -> void:
	_is_light = is_light
	_plot_index = plot_index
	var plot_status: String = str(plot.get("status", "empty"))

	progress_bar.visible = false
	feed_row.visible = false
	action_button.visible = false
	choices_flow.visible = false

	if not is_light and not accessible and plot_status == "empty":
		title_label.text = "🔒 Тёмная грядка #%d — требуется талант «Зелёные грядки» или Сл.%d" % [plot_index + 1, GameManager.ALCHEMY_UNLOCK_DIFFICULTY]
		title_label.modulate = Color(0.65, 0.70, 0.78, 1.0)
		return

	if plot_status == "empty":
		title_label.modulate = Color.WHITE
		if is_light:
			title_label.text = "🌼 Светлая грядка #%d — Свободна" % (plot_index + 1)
		else:
			title_label.text = "🌑 Тёмная грядка #%d — Свободна (выберите редкое семя)" % (plot_index + 1)
		_configure_seed_choices(owned_seeds, unlocked)
	elif plot_status == "growing":
		title_label.modulate = Color.WHITE
		progress_bar.visible = true
		var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
		if not is_light and crop != null and crop.has_instant_grow_feed():
			feed_row.visible = true
			feed_hint_label.text = "Для моментального созревания скормите духам базовые растения Светлого сада: 🍀 Клевер x2, 🍓 Ягода x2, 🌼 Ромашка x2, 🌶️ Перчик x2"
			feed_button.disabled = not GameManager.can_instant_grow_plot(plot_index)
		update_timer(plot)
	elif plot_status == "ready":
		var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
		if is_light:
			title_label.text = "✨ %s Светлая грядка #%d: %s готова! (для приманки или собрать %d–%d шт.)" % [
				crop.icon_emoji if crop != null else "🌼",
				plot_index + 1,
				crop.crop_name if crop != null else "Растение",
				crop.harvest_min if crop != null else 1,
				crop.harvest_max if crop != null else 2,
			]
			title_label.modulate = Color(0.98, 0.90, 0.45, 1.0)
			action_button.disabled = false
		else:
			title_label.text = "✨ %s Тёмная грядка #%d: %s созрел! (%d–%d шт.)" % [
				crop.icon_emoji if crop != null else "🌿",
				plot_index + 1,
				crop.crop_name if crop != null else "Урожай",
				crop.harvest_min if crop != null else 1,
				crop.harvest_max if crop != null else 1,
			]
			title_label.modulate = Color(0.42, 0.98, 0.62, 1.0)
			action_button.disabled = not unlocked
		action_button.visible = true
		action_button.text = "🧺 Собрать"


func update_timer(plot: Dictionary) -> void:
	if str(plot.get("status", "empty")) != "growing":
		return
	var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
	if not _is_light and crop != null and crop.is_boss_kill_crop():
		var boss_kills: int = int(plot.get("boss_kills", 0))
		var req_kills: int = maxi(1, crop.required_final_boss_kills)
		title_label.text = "%s Тёмная грядка #%d: %s — Убито Вечных титанов: %d / %d" % [
			crop.icon_emoji, _plot_index + 1, crop.crop_name, boss_kills, req_kills
		]
		title_label.modulate = Color(1.0, 0.45, 0.56, 1.0)
		progress_bar.max_value = float(req_kills)
		progress_bar.value = float(mini(boss_kills, req_kills))
	elif crop != null:
		var elapsed: float = float(plot.get("elapsed", 0.0))
		var total_sec: float = maxf(1.0, crop.grow_seconds)
		var rem_sec: float = maxf(0.0, (total_sec - elapsed) / maxf(0.1, GameManager.get_garden_growth_speed_mult()))
		var prefix: String = "Светлая" if _is_light else "Тёмная"
		title_label.text = "%s %s грядка #%d: %s — Осталось %.0fс" % [crop.icon_emoji, prefix, _plot_index + 1, crop.crop_name, ceil(rem_sec)]
		title_label.modulate = Color.WHITE
		progress_bar.max_value = total_sec
		progress_bar.value = minf(elapsed, total_sec)
	else:
		title_label.text = "%s Грядка #%d: Растёт..." % ["🌱" if _is_light else "🌑", _plot_index + 1]


func _configure_seed_choices(owned_seeds: Array[Dictionary], unlocked: bool) -> void:
	if owned_seeds.is_empty():
		var empty_lbl: String = "Нет семян Светлого сада. Они падают с любых врагов (2.5%–4.5% шанс)." if _is_light else "В рюкзаке нет семян Тёмного сада. Травы для зелий падают редко (0.005%–0.05%), а 🌟 Первоцвет духов — с 0.03% с Вечного титана."
		title_label.text += "\n" + empty_lbl
		return
	choices_flow.visible = true
	while _choice_buttons.size() < owned_seeds.size():
		var btn_idx: int = _choice_buttons.size()
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(185.0, 44.0)
		btn.pressed.connect(func() -> void: _on_seed_chosen(btn_idx))
		choices_flow.add_child(btn)
		_choice_buttons.append(btn)
		_bound_seeds.append(null)
	for i: int in range(_choice_buttons.size()):
		var btn: Button = _choice_buttons[i]
		if i < owned_seeds.size():
			var s_entry: Dictionary = owned_seeds[i]
			var seed_item: ItemData = s_entry["item"] as ItemData
			var cnt: int = int(s_entry["count"])
			_bound_seeds[i] = seed_item
			btn.visible = true
			btn.disabled = (not _is_light) and (not unlocked)
			btn.text = "%s %s %s (x%d)" % ["🌱" if _is_light else "🌑", seed_item.icon_emoji, seed_item.item_name, cnt]
		else:
			_bound_seeds[i] = null
			btn.visible = false


func _on_seed_chosen(btn_idx: int) -> void:
	if btn_idx < 0 or btn_idx >= _bound_seeds.size() or _bound_seeds[btn_idx] == null:
		return
	var res: Dictionary = GameManager.plant_light_seed_on_plot(_plot_index, _bound_seeds[btn_idx]) if _is_light else GameManager.plant_seed_on_plot(_plot_index, _bound_seeds[btn_idx])
	feedback_emitted.emit(str(res.get("message", "")))


func _on_action_pressed() -> void:
	var res: Dictionary = GameManager.harvest_light_garden_plot(_plot_index) if _is_light else GameManager.harvest_garden_plot(_plot_index)
	feedback_emitted.emit(str(res.get("message", "")))


func _on_feed_pressed() -> void:
	var res: Dictionary = GameManager.feed_growing_crop_for_instant_growth(_plot_index)
	feedback_emitted.emit(str(res.get("message", "")))
