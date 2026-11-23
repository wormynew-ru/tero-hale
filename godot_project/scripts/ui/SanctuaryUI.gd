extends ScrollContainer

@onready var sanctuary_status_label: Label = %SanctuaryStatusLabel
@onready var alchemist_flag_label: Label = %AlchemistFlagLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var light_garden_plots_box: VBoxContainer = %LightGardenPlotsBox
@onready var lure_preview_label: Label = %LurePreviewLabel
@onready var lure_pet_button: Button = %LurePetButton
@onready var spirit_training_status_label: Label = %SpiritTrainingStatusLabel
@onready var spirit_training_box: VBoxContainer = %SpiritTrainingBox
@onready var expeditions_box: VBoxContainer = %ExpeditionsBox
@onready var garden_plots_box: VBoxContainer = %GardenPlotsBox
@onready var brew_cauldrons_box: VBoxContainer = %BrewCauldronsBox
@onready var recipe_guide_label: RichTextLabel = %RecipeGuideLabel

var _last_light_sig: String = ""
var _last_dark_sig: String = ""
var _last_spirit_sig: String = ""
var _last_brew_sig: String = ""
var _last_exp_sig: String = ""

var _light_plot_widgets: Array[Dictionary] = []
var _dark_plot_widgets: Array[Dictionary] = []
var _brew_widgets: Array[Dictionary] = []
var _spirit_widgets: Array[Dictionary] = []
var _pet_exp_widgets: Array[Dictionary] = []
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

	lure_pet_button.pressed.connect(func() -> void:
		var res: Dictionary = GameManager.lure_pet_from_light_garden()
		feedback_label.text = str(res.get("message", ""))
	)

	set_process(false)
	_build_pet_expeditions()
	_rebuild_sanctuary(true)


func _on_reset() -> void:
	feedback_label.text = ""
	_last_exp_sig = ""
	_rebuild_queued = false
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
	_update_light_garden_timers()
	_update_dark_garden_timers()
	_update_brew_timers()
	_update_expedition_timers()


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

	_sync_light_garden_plots(force)
	_refresh_lure_bar()
	_sync_pet_expeditions(force)
	_sync_spirit_training(force)
	_sync_dark_garden_plots(unlocked, force)
	_sync_brew_cauldrons(unlocked, force)
	if force or recipe_guide_label.text.is_empty():
		_refresh_recipe_guide()


func _collect_seeds(is_light: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in GameManager.inventory:
		var item: ItemData = entry["item"] as ItemData
		var cnt: int = int(entry["count"])
		if item == null or cnt <= 0 or item.item_type != ItemData.ItemType.SEED:
			continue
		var crop: CropData = GameManager.get_crop_by_id(item.seed_crop_id)
		var crop_is_light: bool = crop != null and crop.is_light_crop()
		if crop_is_light == is_light:
			result.append({"item": item, "count": cnt})
	return result


func _collect_dark_brewing_harvests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in GameManager.inventory:
		var item: ItemData = entry["item"] as ItemData
		var cnt: int = int(entry["count"])
		if item == null or cnt <= 0 or item.item_type != ItemData.ItemType.HARVEST:
			continue
		if item.garden_category == "light" or item.id == "spirit_primordial_harvest":
			continue
		result.append({"item": item, "count": cnt})
	return result


func _compute_light_sig(seeds_owned: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for i: int in range(GameManager.get_light_garden_plot_count()):
		var plot: Dictionary = GameManager.light_garden_plots[i] if i < GameManager.light_garden_plots.size() else {}
		parts.append("%d:%s:%s" % [i, str(plot.get("status", "empty")), str(plot.get("crop_id", ""))])
	for s_entry: Dictionary in seeds_owned:
		var it: ItemData = s_entry["item"] as ItemData
		parts.append("%s=%d" % [it.id, int(s_entry["count"])])
	return "|".join(parts)


func _sync_light_garden_plots(force: bool) -> void:
	var light_seeds: Array[Dictionary] = _collect_seeds(true)
	var sig: String = _compute_light_sig(light_seeds)
	if not force and sig == _last_light_sig:
		_update_light_garden_timers()
		return
	_last_light_sig = sig

	for child: Node in light_garden_plots_box.get_children():
		child.queue_free()
	_light_plot_widgets.clear()

	var total_plots: int = GameManager.get_light_garden_plot_count()
	for i: int in range(total_plots):
		var plot_idx: int = i
		var plot: Dictionary = GameManager.light_garden_plots[i] if i < GameManager.light_garden_plots.size() else {}
		var status: String = str(plot.get("status", "empty"))

		var card: PanelContainer = PanelContainer.new()
		var card_box: VBoxContainer = VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card.add_child(card_box)

		var widget_entry: Dictionary = {"status": status, "index": i}

		if status == "empty":
			var title_lbl: Label = Label.new()
			title_lbl.text = "🌼 Светлая грядка #%d — Свободна" % (i + 1)
			card_box.add_child(title_lbl)

			if light_seeds.is_empty():
				var hint_lbl: Label = Label.new()
				hint_lbl.text = "Нет семян Светлого сада. Они падают с любых врагов (2.5%–4.5% шанс)."
				hint_lbl.modulate = Color(0.72, 0.78, 0.86, 1.0)
				hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				card_box.add_child(hint_lbl)
			else:
				var btn_flow: HFlowContainer = HFlowContainer.new()
				btn_flow.add_theme_constant_override("h_separation", 8)
				btn_flow.add_theme_constant_override("v_separation", 8)
				for s_entry: Dictionary in light_seeds:
					var seed_item: ItemData = s_entry["item"] as ItemData
					var cnt: int = int(s_entry["count"])
					var plant_btn: Button = Button.new()
					plant_btn.custom_minimum_size = Vector2(180.0, 44.0)
					plant_btn.text = "🌱 %s %s (x%d)" % [seed_item.icon_emoji, seed_item.item_name, cnt]
					plant_btn.pressed.connect(func() -> void:
						var res: Dictionary = GameManager.plant_light_seed_on_plot(plot_idx, seed_item)
						feedback_label.text = str(res.get("message", ""))
					)
					btn_flow.add_child(plant_btn)
				card_box.add_child(btn_flow)

		elif status == "growing":
			var header_lbl: Label = Label.new()
			var bar: ProgressBar = ProgressBar.new()
			bar.custom_minimum_size = Vector2(0.0, 18.0)
			bar.show_percentage = true
			card_box.add_child(header_lbl)
			card_box.add_child(bar)
			widget_entry["label"] = header_lbl
			widget_entry["bar"] = bar

		elif status == "ready":
			var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
			var ready_row: HBoxContainer = HBoxContainer.new()
			ready_row.add_theme_constant_override("separation", 10)
			var ready_lbl: Label = Label.new()
			ready_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ready_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ready_lbl.text = "✨ %s Светлая грядка #%d: %s готова! (для приманки или собрать %d–%d шт.)" % [
				crop.icon_emoji if crop != null else "🌼",
				i + 1,
				crop.crop_name if crop != null else "Растение",
				crop.harvest_min if crop != null else 1,
				crop.harvest_max if crop != null else 2,
			]
			ready_lbl.modulate = Color(0.98, 0.90, 0.45, 1.0)
			ready_row.add_child(ready_lbl)

			var harvest_btn: Button = Button.new()
			harvest_btn.custom_minimum_size = Vector2(170.0, 44.0)
			harvest_btn.text = "🧺 Собрать"
			harvest_btn.pressed.connect(func() -> void:
				var res: Dictionary = GameManager.harvest_light_garden_plot(plot_idx)
				feedback_label.text = str(res.get("message", ""))
			)
			ready_row.add_child(harvest_btn)
			card_box.add_child(ready_row)

		_light_plot_widgets.append(widget_entry)
		light_garden_plots_box.add_child(card)

	_update_light_garden_timers()


func _update_light_garden_timers() -> void:
	for entry: Dictionary in _light_plot_widgets:
		if str(entry.get("status", "")) != "growing":
			continue
		var idx: int = int(entry["index"])
		if idx >= GameManager.light_garden_plots.size():
			continue
		var plot: Dictionary = GameManager.light_garden_plots[idx]
		var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
		var lbl: Label = entry.get("label") as Label
		var bar: ProgressBar = entry.get("bar") as ProgressBar
		if lbl == null or bar == null:
			continue
		if crop != null:
			var elapsed: float = float(plot.get("elapsed", 0.0))
			var total_sec: float = maxf(1.0, crop.grow_seconds)
			var rem_sec: float = maxf(0.0, (total_sec - elapsed) / maxf(0.1, GameManager.get_garden_growth_speed_mult()))
			lbl.text = "%s Светлая грядка #%d: %s — Осталось %.0fс" % [crop.icon_emoji, idx + 1, crop.crop_name, ceil(rem_sec)]
			bar.max_value = total_sec
			bar.value = minf(elapsed, total_sec)
		else:
			lbl.text = "🌱 Светлая грядка #%d: Растёт..." % (idx + 1)


func _refresh_lure_bar() -> void:
	var slot_tokens: Array[String] = []
	for i: int in range(GameManager.BASE_LIGHT_GARDEN_PLOTS):
		var plot: Dictionary = GameManager.light_garden_plots[i] if i < GameManager.light_garden_plots.size() else {}
		var st: String = str(plot.get("status", "empty"))
		var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
		if st == "empty" or crop == null:
			slot_tokens.append("[Пусто]")
		elif st == "growing":
			slot_tokens.append("[%s⏳]" % crop.icon_emoji)
		else:
			slot_tokens.append("[%s %s]" % [crop.icon_emoji, crop.crop_name])

	var can_lure: bool = GameManager.can_lure_pet_from_light_garden()
	lure_pet_button.disabled = not can_lure
	lure_preview_label.text = "Высадка приманки: %s\n%s" % [
		" + ".join(slot_tokens),
		"✅ Все 3 грядки готовы — можно приманивать путника!" if can_lure else "Дождитесь созревания всех 3 грядок для приманки (при ошибке или повторке растения завянут).",
	]


func _build_pet_expeditions() -> void:
	if expeditions_box == null:
		return
	for child: Node in expeditions_box.get_children():
		child.queue_free()
	_pet_exp_widgets.clear()

	for p: PetData in GameManager.all_pets:
		if p == null:
			continue
		var pid: String = p.id
		var card: PanelContainer = PanelContainer.new()
		var card_box: VBoxContainer = VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card.add_child(card_box)

		var top_row: HBoxContainer = HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 8)

		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 13)
		top_row.add_child(lbl)

		var short_btn: Button = Button.new()
		short_btn.custom_minimum_size = Vector2(118.0, 40.0)
		short_btn.focus_mode = Control.FOCUS_NONE
		short_btn.text = "🌿 15м"
		short_btn.pressed.connect(func() -> void:
			var res: Dictionary = GameManager.start_pet_expedition(pid, "short")
			feedback_label.text = str(res.get("message", ""))
		)
		top_row.add_child(short_btn)

		var long_btn: Button = Button.new()
		long_btn.custom_minimum_size = Vector2(118.0, 40.0)
		long_btn.focus_mode = Control.FOCUS_NONE
		long_btn.text = "🗺️ 1ч"
		long_btn.pressed.connect(func() -> void:
			var res: Dictionary = GameManager.start_pet_expedition(pid, "long")
			feedback_label.text = str(res.get("message", ""))
		)
		top_row.add_child(long_btn)

		var claim_btn: Button = Button.new()
		claim_btn.custom_minimum_size = Vector2(150.0, 40.0)
		claim_btn.focus_mode = Control.FOCUS_NONE
		claim_btn.text = "🎁 Забрать"
		claim_btn.pressed.connect(func() -> void:
			var res: Dictionary = GameManager.claim_pet_expedition(pid)
			feedback_label.text = str(res.get("message", ""))
		)
		top_row.add_child(claim_btn)

		card_box.add_child(top_row)

		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(0.0, 14.0)
		bar.show_percentage = true
		card_box.add_child(bar)

		expeditions_box.add_child(card)
		_pet_exp_widgets.append({
			"pet": p,
			"card": card,
			"lbl": lbl,
			"short_btn": short_btn,
			"long_btn": long_btn,
			"claim_btn": claim_btn,
			"bar": bar,
		})


func _sync_pet_expeditions(force: bool) -> void:
	if expeditions_box == null:
		return
	if _pet_exp_widgets.size() != GameManager.all_pets.size():
		_build_pet_expeditions()
		force = true

	var sig_parts: Array[String] = []
	sig_parts.append(GameManager.equipped_pet_id)
	for p: PetData in GameManager.all_pets:
		if p == null:
			continue
		var owned: int = 1 if GameManager.has_pet_owned(p.id) else 0
		var exp: Dictionary = GameManager.get_pet_expedition(p.id)
		var state_tag: String = "idle"
		if not exp.is_empty():
			state_tag = "done" if bool(exp.get("completed", false)) else "run:%s" % str(exp.get("plan_id", ""))
		sig_parts.append("%s:%d:%s" % [p.id, owned, state_tag])
	var sig: String = "|".join(sig_parts)

	if not force and sig == _last_exp_sig:
		_update_expedition_timers()
		return
	_last_exp_sig = sig

	for w: Dictionary in _pet_exp_widgets:
		var p: PetData = w["pet"] as PetData
		var card: PanelContainer = w["card"] as PanelContainer
		var lbl: Label = w["lbl"] as Label
		var short_btn: Button = w["short_btn"] as Button
		var long_btn: Button = w["long_btn"] as Button
		var claim_btn: Button = w["claim_btn"] as Button
		var bar: ProgressBar = w["bar"] as ProgressBar

		var owned: bool = GameManager.has_pet_owned(p.id)
		card.visible = owned
		if not owned:
			continue

		var exp: Dictionary = GameManager.get_pet_expedition(p.id)
		var is_eq: bool = GameManager.equipped_pet_id == p.id
		if exp.is_empty():
			bar.visible = false
			claim_btn.visible = false
			short_btn.visible = true
			long_btn.visible = true
			short_btn.disabled = is_eq
			long_btn.disabled = is_eq
			if is_eq:
				lbl.text = "%s %s — В бою с героем (снимите для отправки)" % [p.icon_emoji, p.pet_name]
				lbl.modulate = Color(0.84, 0.88, 0.96, 1.0)
			else:
				lbl.text = "%s %s — Свободен для вылазки (15м / 1ч)" % [p.icon_emoji, p.pet_name]
				lbl.modulate = Color.WHITE
		elif bool(exp.get("completed", false)):
			bar.visible = true
			bar.max_value = 100.0
			bar.value = 100.0
			short_btn.visible = false
			long_btn.visible = false
			claim_btn.visible = true
			claim_btn.disabled = false
			claim_btn.modulate = Color(0.45, 0.98, 0.72, 1.0)
			lbl.text = "🎁 %s %s вернулся из экспедиции! Заберите награду." % [p.icon_emoji, p.pet_name]
			lbl.modulate = Color(0.45, 0.98, 0.72, 1.0)
		else:
			bar.visible = true
			short_btn.visible = false
			long_btn.visible = false
			claim_btn.visible = false
	_update_expedition_timers()


func _update_expedition_timers() -> void:
	for w: Dictionary in _pet_exp_widgets:
		var p: PetData = w["pet"] as PetData
		if not GameManager.has_pet_owned(p.id):
			continue
		var exp: Dictionary = GameManager.get_pet_expedition(p.id)
		if exp.is_empty() or bool(exp.get("completed", false)):
			continue
		var lbl: Label = w["lbl"] as Label
		var bar: ProgressBar = w["bar"] as ProgressBar
		var elapsed: float = float(exp.get("elapsed", 0.0))
		var dur: float = maxf(1.0, float(exp.get("duration", 900.0)))
		var rem: float = maxf(0.0, dur - elapsed)
		var rem_min: int = floori(rem / 60.0)
		var rem_sec: int = floori(fmod(rem, 60.0))
		lbl.text = "🧭 %s %s в экспедиции — осталось %d:%02d" % [p.icon_emoji, p.pet_name, rem_min, rem_sec]
		lbl.modulate = Color(0.45, 0.92, 1.0, 1.0)
		bar.max_value = dur
		bar.value = minf(elapsed, dur)


func _build_spirit_training() -> void:
	for child: Node in spirit_training_box.get_children():
		child.queue_free()
	_spirit_widgets.clear()

	var defs: Array[Dictionary] = [
		{"key": "fire", "title": "🔥 Дух Огня", "desc": "Магический удар каждые 1.4с"},
		{"key": "wind", "title": "🌪️ Дух Ветра", "desc": "Быстрый вихрь каждые 0.95с"},
		{"key": "forest", "title": "🌿 Дух Леса", "desc": "Лечение HP и мана каждые 2.5с"},
		{"key": "earth", "title": "🪨 Дух Земли", "desc": "Тяжёлый удар каждые 2.0с"},
	]

	for d: Dictionary in defs:
		var skey: String = str(d["key"])
		var card: PanelContainer = PanelContainer.new()
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(lbl)

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(190.0, 44.0)
		btn.pressed.connect(func() -> void:
			var res: Dictionary = GameManager.train_spirit(skey)
			feedback_label.text = str(res.get("message", ""))
		)
		HoldAutoClicker.attach(btn, 50.0)
		row.add_child(btn)
		card.add_child(row)
		spirit_training_box.add_child(card)
		_spirit_widgets.append({
			"key": skey,
			"title": str(d["title"]),
			"desc": str(d["desc"]),
			"lbl": lbl,
			"btn": btn,
		})


func _sync_spirit_training(force: bool) -> void:
	var fruit_item: ItemData = GameManager.get_cached_item("res://resources/items/spirit_primordial_harvest.tres")
	var fruit_cnt: int = GameManager.get_item_count_in_inventory(fruit_item) if fruit_item != null else 0
	var is_spirit: bool = GameManager.has_hero_class("spirit")
	var lvls: Array[String] = []
	for sk: String in GameManager.SPIRIT_KEYS:
		lvls.append("%s=%d" % [sk, GameManager.get_spirit_training_level(sk)])
	var sig: String = "%s|%d|%s" % ["1" if is_spirit else "0", fruit_cnt, ",".join(lvls)]
	if not force and sig == _last_spirit_sig and _spirit_widgets.size() == 4:
		return
	_last_spirit_sig = sig

	if _spirit_widgets.size() != 4:
		_build_spirit_training()

	if not is_spirit:
		spirit_training_status_label.text = "🔒 Дрессировка духов открыта только при активном классе 🌿 Спирит (Сл.50+). Плодов первоцвета в рюкзаке: %d." % fruit_cnt
		spirit_training_status_label.modulate = Color(0.84, 0.78, 0.52, 1.0)
	else:
		spirit_training_status_label.text = "🌟 Класс 🌿 Спирит активен! Плодов первоцвета духов в рюкзаке: %d (стоимость дрессировки: 1 плод → +15%% силы и +3%% скорости духа)." % fruit_cnt
		spirit_training_status_label.modulate = Color(0.45, 0.98, 0.85, 1.0)

	for w: Dictionary in _spirit_widgets:
		var skey: String = str(w["key"])
		var lvl: int = GameManager.get_spirit_training_level(skey)
		var lbl: Label = w["lbl"] as Label
		var btn: Button = w["btn"] as Button
		lbl.text = "%s [Ур.%d] — %s (+%d%% сила, +%d%% скорость)" % [
			str(w["title"]),
			lvl,
			str(w["desc"]),
			lvl * 15,
			lvl * 3,
		]
		btn.disabled = (not is_spirit) or (fruit_cnt <= 0)
		btn.text = "🌟 Дрессировать (1 плод)" if is_spirit else "🔒 Нужен Спирит"


func _compute_dark_sig(unlocked: bool, seeds_owned: Array[Dictionary]) -> String:
	var parts: Array[String] = ["U:%s" % ("1" if unlocked else "0")]
	for i: int in range(GameManager.get_garden_plot_count()):
		var plot: Dictionary = GameManager.garden_plots[i] if i < GameManager.garden_plots.size() else {}
		var acc: bool = unlocked and GameManager.is_garden_plot_accessible(i)
		var can_feed: bool = GameManager.can_instant_grow_plot(i)
		parts.append("%d:%s:%s:%s:%d:%s" % [
			i,
			"1" if acc else "0",
			str(plot.get("status", "empty")),
			str(plot.get("crop_id", "")),
			int(plot.get("boss_kills", 0)),
			"1" if can_feed else "0",
		])
	for s_entry: Dictionary in seeds_owned:
		var it: ItemData = s_entry["item"] as ItemData
		parts.append("%s=%d" % [it.id, int(s_entry["count"])])
	return "|".join(parts)


func _sync_dark_garden_plots(unlocked: bool, force: bool) -> void:
	var dark_seeds: Array[Dictionary] = _collect_seeds(false)
	var sig: String = _compute_dark_sig(unlocked, dark_seeds)
	if not force and sig == _last_dark_sig:
		_update_dark_garden_timers()
		return
	_last_dark_sig = sig

	for child: Node in garden_plots_box.get_children():
		child.queue_free()
	_dark_plot_widgets.clear()

	var total_plots: int = GameManager.get_garden_plot_count()
	for i: int in range(total_plots):
		var plot_idx: int = i
		var plot: Dictionary = GameManager.garden_plots[i] if i < GameManager.garden_plots.size() else {}
		var accessible: bool = unlocked and GameManager.is_garden_plot_accessible(i)
		var status: String = str(plot.get("status", "empty"))

		var card: PanelContainer = PanelContainer.new()
		var card_box: VBoxContainer = VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card.add_child(card_box)

		if not accessible and status == "empty":
			var lock_lbl: Label = Label.new()
			lock_lbl.text = "🔒 Тёмная грядка #%d — требуется талант «Зелёные грядки» или Сл.%d" % [i + 1, GameManager.ALCHEMY_UNLOCK_DIFFICULTY]
			lock_lbl.modulate = Color(0.65, 0.70, 0.78, 1.0)
			lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card_box.add_child(lock_lbl)
			garden_plots_box.add_child(card)
			continue

		var widget_entry: Dictionary = {"status": status, "index": i}

		if status == "empty":
			var title_lbl: Label = Label.new()
			title_lbl.text = "🌑 Тёмная грядка #%d — Свободна (выберите редкое семя)" % (i + 1)
			card_box.add_child(title_lbl)

			if dark_seeds.is_empty():
				var hint_lbl: Label = Label.new()
				hint_lbl.text = "В рюкзаке нет семян Тёмного сада. Травы для зелий падают редко (0.005%–0.05%), а 🌟 Первоцвет духов — с 0.03% с Вечного титана."
				hint_lbl.modulate = Color(0.68, 0.74, 0.82, 1.0)
				hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				card_box.add_child(hint_lbl)
			else:
				var btn_flow: HFlowContainer = HFlowContainer.new()
				btn_flow.add_theme_constant_override("h_separation", 8)
				btn_flow.add_theme_constant_override("v_separation", 8)
				for s_entry: Dictionary in dark_seeds:
					var seed_item: ItemData = s_entry["item"] as ItemData
					var cnt: int = int(s_entry["count"])
					var plant_btn: Button = Button.new()
					plant_btn.custom_minimum_size = Vector2(185.0, 44.0)
					plant_btn.disabled = not unlocked
					plant_btn.text = "🌑 %s %s (x%d)" % [seed_item.icon_emoji, seed_item.item_name, cnt]
					plant_btn.pressed.connect(func() -> void:
						var res: Dictionary = GameManager.plant_seed_on_plot(plot_idx, seed_item)
						feedback_label.text = str(res.get("message", ""))
					)
					btn_flow.add_child(plant_btn)
				card_box.add_child(btn_flow)

		elif status == "growing":
			var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
			var header_lbl: Label = Label.new()
			var bar: ProgressBar = ProgressBar.new()
			bar.custom_minimum_size = Vector2(0.0, 18.0)
			bar.show_percentage = true
			card_box.add_child(header_lbl)
			card_box.add_child(bar)
			widget_entry["label"] = header_lbl
			widget_entry["bar"] = bar

			if crop != null and crop.has_instant_grow_feed():
				var feed_row: HBoxContainer = HBoxContainer.new()
				feed_row.add_theme_constant_override("separation", 10)
				var req_lbl: Label = Label.new()
				req_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				req_lbl.add_theme_font_size_override("font_size", 12)
				req_lbl.text = "Для моментального созревания скормите духам базовые растения Светлого сада: 🍀 Клевер x2, 🍓 Ягода x2, 🌼 Ромашка x2, 🌶️ Перчик x2"
				feed_row.add_child(req_lbl)

				var feed_btn: Button = Button.new()
				feed_btn.custom_minimum_size = Vector2(220.0, 44.0)
				feed_btn.disabled = not GameManager.can_instant_grow_plot(plot_idx)
				feed_btn.text = "🌿 Скормить духам (Момент. рост!)"
				feed_btn.pressed.connect(func() -> void:
					var res: Dictionary = GameManager.feed_growing_crop_for_instant_growth(plot_idx)
					feedback_label.text = str(res.get("message", ""))
				)
				feed_row.add_child(feed_btn)
				card_box.add_child(feed_row)

		elif status == "ready":
			var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
			var ready_row: HBoxContainer = HBoxContainer.new()
			ready_row.add_theme_constant_override("separation", 10)
			var ready_lbl: Label = Label.new()
			ready_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ready_lbl.text = "✨ %s Тёмная грядка #%d: %s созрел! (%d–%d шт.)" % [
				crop.icon_emoji if crop != null else "🌿",
				i + 1,
				crop.crop_name if crop != null else "Урожай",
				crop.harvest_min if crop != null else 1,
				crop.harvest_max if crop != null else 1,
			]
			ready_lbl.modulate = Color(0.42, 0.98, 0.62, 1.0)
			ready_row.add_child(ready_lbl)

			var harvest_btn: Button = Button.new()
			harvest_btn.custom_minimum_size = Vector2(170.0, 44.0)
			harvest_btn.disabled = not unlocked
			harvest_btn.text = "🧺 Собрать"
			harvest_btn.pressed.connect(func() -> void:
				var res: Dictionary = GameManager.harvest_garden_plot(plot_idx)
				feedback_label.text = str(res.get("message", ""))
			)
			ready_row.add_child(harvest_btn)
			card_box.add_child(ready_row)

		_dark_plot_widgets.append(widget_entry)
		garden_plots_box.add_child(card)

	_update_dark_garden_timers()


func _update_dark_garden_timers() -> void:
	for entry: Dictionary in _dark_plot_widgets:
		if str(entry.get("status", "")) != "growing":
			continue
		var idx: int = int(entry["index"])
		if idx >= GameManager.garden_plots.size():
			continue
		var plot: Dictionary = GameManager.garden_plots[idx]
		var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
		var lbl: Label = entry.get("label") as Label
		var bar: ProgressBar = entry.get("bar") as ProgressBar
		if lbl == null or bar == null:
			continue
		if crop != null and crop.is_boss_kill_crop():
			var boss_kills: int = int(plot.get("boss_kills", 0))
			var req_kills: int = maxi(1, crop.required_final_boss_kills)
			lbl.text = "%s Тёмная грядка #%d: %s — Убито Вечных титанов: %d / %d" % [
				crop.icon_emoji,
				idx + 1,
				crop.crop_name,
				boss_kills,
				req_kills,
			]
			lbl.modulate = Color(1.0, 0.45, 0.56, 1.0)
			bar.max_value = float(req_kills)
			bar.value = float(mini(boss_kills, req_kills))
		elif crop != null:
			var elapsed: float = float(plot.get("elapsed", 0.0))
			var total_sec: float = maxf(1.0, crop.grow_seconds)
			var rem_sec: float = maxf(0.0, (total_sec - elapsed) / maxf(0.1, GameManager.get_garden_growth_speed_mult()))
			lbl.text = "%s Тёмная грядка #%d: %s — Осталось %.0fс" % [crop.icon_emoji, idx + 1, crop.crop_name, ceil(rem_sec)]
			bar.max_value = total_sec
			bar.value = minf(elapsed, total_sec)
		else:
			lbl.text = "🌑 Тёмная грядка #%d: Растёт..." % (idx + 1)


func _compute_brew_sig(unlocked: bool, harvests_owned: Array[Dictionary]) -> String:
	var parts: Array[String] = ["U:%s" % ("1" if unlocked else "0")]
	for i: int in range(GameManager.get_brewing_slot_count()):
		var cauldron: Dictionary = GameManager.brewing_slots[i] if i < GameManager.brewing_slots.size() else {}
		var acc: bool = unlocked and GameManager.is_brewing_slot_accessible(i)
		parts.append("%d:%s:%s:%s:%d:%s" % [
			i,
			"1" if acc else "0",
			str(cauldron.get("state", "empty")),
			str(cauldron.get("brew_id", "")),
			int(cauldron.get("stage", 0)),
			"1" if bool(cauldron.get("can_collect", false)) else "0",
		])
	for h_entry: Dictionary in harvests_owned:
		var it: ItemData = h_entry["item"] as ItemData
		parts.append("%s=%d" % [it.id, int(h_entry["count"])])
	return "|".join(parts)


func _sync_brew_cauldrons(unlocked: bool, force: bool) -> void:
	var harvests_owned: Array[Dictionary] = _collect_dark_brewing_harvests()
	var sig: String = _compute_brew_sig(unlocked, harvests_owned)
	if not force and sig == _last_brew_sig:
		_update_brew_timers()
		return
	_last_brew_sig = sig

	for child: Node in brew_cauldrons_box.get_children():
		child.queue_free()
	_brew_widgets.clear()

	var total_cauldrons: int = GameManager.get_brewing_slot_count()
	for i: int in range(total_cauldrons):
		var slot_idx: int = i
		var cauldron: Dictionary = GameManager.brewing_slots[i] if i < GameManager.brewing_slots.size() else {}
		var accessible: bool = unlocked and GameManager.is_brewing_slot_accessible(i)
		var state: String = str(cauldron.get("state", "empty"))

		var card: PanelContainer = PanelContainer.new()
		var card_box: VBoxContainer = VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 8)
		card.add_child(card_box)

		if not accessible and (state == "empty" or state == "exploded"):
			var lock_lbl: Label = Label.new()
			lock_lbl.text = "🔒 Котёл #%d — требуется талант «Мастер котла» или Сл.%d" % [i + 1, GameManager.ALCHEMY_UNLOCK_DIFFICULTY]
			lock_lbl.modulate = Color(0.65, 0.70, 0.78, 1.0)
			lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card_box.add_child(lock_lbl)
			brew_cauldrons_box.add_child(card)
			continue

		var widget_entry: Dictionary = {"state": state, "index": i}

		if state == "empty" or state == "exploded":
			var top_row: HBoxContainer = HBoxContainer.new()
			top_row.add_theme_constant_override("separation", 10)
			var status_lbl: Label = Label.new()
			status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if state == "exploded":
				status_lbl.text = "💥 Котёл #%d: Взорвался из-за ошибки! Налейте свежую воду для нового зелья." % (i + 1)
				status_lbl.modulate = Color(0.98, 0.45, 0.42, 1.0)
			else:
				status_lbl.text = "⚗️ Котёл #%d: Пуст — начните варку с колбы воды." % (i + 1)
			status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			top_row.add_child(status_lbl)

			var water_btn: Button = Button.new()
			water_btn.custom_minimum_size = Vector2(180.0, 44.0)
			water_btn.disabled = not unlocked
			water_btn.text = "💧 Налить воду"
			water_btn.pressed.connect(func() -> void:
				var res: Dictionary = GameManager.start_brewing_water(slot_idx)
				feedback_label.text = str(res.get("message", ""))
			)
			top_row.add_child(water_btn)
			card_box.add_child(top_row)

		elif state == "brewing":
			var brew_lbl: Label = Label.new()
			brew_lbl.modulate = Color(0.98, 0.82, 0.38, 1.0)
			card_box.add_child(brew_lbl)

			var bar: ProgressBar = ProgressBar.new()
			bar.custom_minimum_size = Vector2(0.0, 18.0)
			bar.show_percentage = true
			card_box.add_child(bar)
			widget_entry["label"] = brew_lbl
			widget_entry["bar"] = bar

		elif state == "ready":
			var stage: int = int(cauldron.get("stage", 0))
			var can_collect: bool = bool(cauldron.get("can_collect", false))
			var header_row: HBoxContainer = HBoxContainer.new()
			header_row.add_theme_constant_override("separation", 10)

			var cur_lbl: Label = Label.new()
			cur_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cur_lbl.text = "%s Котёл #%d [Этап %d/3]: %s" % [
				str(cauldron.get("brew_emoji", "⚗️")),
				i + 1,
				stage,
				str(cauldron.get("brew_title", "")),
			]
			cur_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			header_row.add_child(cur_lbl)

			if can_collect:
				var collect_btn: Button = Button.new()
				collect_btn.custom_minimum_size = Vector2(180.0, 44.0)
				collect_btn.text = "🧪 Забрать (x%d)" % maxi(1, int(cauldron.get("result_count", 1)))
				collect_btn.modulate = Color(0.55, 0.98, 0.72, 1.0)
				collect_btn.pressed.connect(func() -> void:
					var res: Dictionary = GameManager.collect_brewed_potion(slot_idx)
					feedback_label.text = str(res.get("message", ""))
				)
				header_row.add_child(collect_btn)

			var dump_btn: Button = Button.new()
			dump_btn.custom_minimum_size = Vector2(96.0, 44.0)
			dump_btn.text = "🗑️ Слить"
			dump_btn.pressed.connect(func() -> void:
				GameManager.clear_brewing_slot(slot_idx)
				feedback_label.text = "Котёл #%d очищен." % (slot_idx + 1)
			)
			header_row.add_child(dump_btn)
			card_box.add_child(header_row)

			if stage < 3:
				var ing_title: Label = Label.new()
				ing_title.text = "Добавить тёмную траву на Шаг %d (⚠️ неверный ингредиент взрывает котёл с шансом 100%%):" % (stage + 1)
				ing_title.add_theme_font_size_override("font_size", 12)
				ing_title.modulate = Color(0.84, 0.88, 0.94, 1.0)
				ing_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				card_box.add_child(ing_title)

				if harvests_owned.is_empty():
					var no_ing: Label = Label.new()
					no_ing.text = "Нет трав Тёмного сада — соберите урожай с тёмных грядок."
					no_ing.modulate = Color(0.68, 0.74, 0.82, 1.0)
					card_box.add_child(no_ing)
				else:
					var ing_flow: HFlowContainer = HFlowContainer.new()
					ing_flow.add_theme_constant_override("h_separation", 8)
					ing_flow.add_theme_constant_override("v_separation", 8)
					for h_entry: Dictionary in harvests_owned:
						var harv: ItemData = h_entry["item"] as ItemData
						var cnt: int = int(h_entry["count"])
						var add_btn: Button = Button.new()
						add_btn.custom_minimum_size = Vector2(180.0, 44.0)
						add_btn.text = "➕ %s %s (x%d)" % [harv.icon_emoji, harv.item_name, cnt]
						add_btn.pressed.connect(func() -> void:
							var res: Dictionary = GameManager.add_brewing_ingredient(slot_idx, harv)
							feedback_label.text = str(res.get("message", ""))
						)
						ing_flow.add_child(add_btn)
					card_box.add_child(ing_flow)

		_brew_widgets.append(widget_entry)
		brew_cauldrons_box.add_child(card)

	_update_brew_timers()


func _update_brew_timers() -> void:
	for entry: Dictionary in _brew_widgets:
		if str(entry.get("state", "")) != "brewing":
			continue
		var idx: int = int(entry["index"])
		if idx >= GameManager.brewing_slots.size():
			continue
		var cauldron: Dictionary = GameManager.brewing_slots[idx]
		var lbl: Label = entry.get("label") as Label
		var bar: ProgressBar = entry.get("bar") as ProgressBar
		if lbl == null or bar == null:
			continue
		var elapsed: float = float(cauldron.get("elapsed", 0.0))
		var dur: float = maxf(0.1, float(cauldron.get("duration", 10.0)))
		var rem_sec: float = maxf(0.0, (dur - elapsed) / maxf(0.1, GameManager.get_brewing_speed_mult()))
		lbl.text = "🔥 Котёл #%d [Шаг %d]: Варится %s %s — %.1fс" % [
			idx + 1,
			int(cauldron.get("pending_stage", 1)),
			str(cauldron.get("pending_emoji", "⚗️")),
			str(cauldron.get("pending_title", "")),
			rem_sec,
		]
		bar.max_value = dur
		bar.value = minf(elapsed, dur)


func _refresh_recipe_guide() -> void:
	recipe_guide_label.text = (
		"[b][color=#facc15]☀️ Светлый сад (Сл.1+) — Приманка и Дрессировка путников:[/color][/b]\n"
		+ "• Простые семена падают с любых врагов: 🍀 [b]Солнечный клевер[/b] (4.5%, 20с), 🍓 [b]Медовая ягода[/b] (3.5%, 30с), 🌼 [b]Небесная ромашка[/b] (3.0%, 35с), 🌶️ [b]Искристый перчик[/b] (2.5%, 40с).\n"
		+ "• Путников [b]нельзя купить за золото[/b] — только выманить высадкой на 3 грядки Светлого сада! Если узор ведёт к уже приручённому путнику (повторке) или никому не подходит — [color=#fb7185]ничего не происходит, а растения завянут[/color]:\n"
		+ "   — 🎆 [b]Фейерверк[/b]: 🌶️ Перчик + 🌼 Ромашка + 🌶️ Перчик\n"
		+ "   — 🧚 [b]Лесной светлячок[/b]: 🍀 Клевер + 🌼 Ромашка + 🍀 Клевер\n"
		+ "   — 🪙 [b]Мимик-копилка[/b]: 🍓 Ягода + 🍀 Клевер + 🍓 Ягода\n"
		+ "   — 🦊 [b]Огненный лисёнок[/b]: 🌶️ Перчик + 🍓 Ягода + 🌶️ Перчик\n"
		+ "   — 🦉 [b]Хроно-сова[/b]: 🌼 Ромашка + 🌼 Ромашка + 🍀 Клевер\n"
		+ "   — 🦅 [b]Грозовой сокол[/b]: 🌼 Ромашка + 🌶️ Перчик + 🍓 Ягода\n"
		+ "• Собранный урожай Светлого сада идёт на [b]🍪 пряники[/b] для дрессировки путников в разделе «Путники» (у каждого свой любимый пряник с повышенным % успеха).\n\n"
		+ "[b][color=#c084fc]🌑 Тёмный сад (Сл.10+) — Супер-зелья и 🌟 Духи:[/color][/b]\n"
		+ "• 🌿 [b]Лунная мята[/b] (0.05%, 45с), 🥕 [b]Солнечный корень[/b] (0.03%, 90с), 🪷 [b]Лазурный лотос[/b] (0.02%, 150с), 🍄 [b]Звёздный трюфель[/b] (0.012%, 240с), 🌺 [b]Алый лепесток[/b] (0.005%/0.025%, растёт за 2000 побед над Вечным титаном).\n"
		+ "• 🌟 [b]Первоцвет духов[/b] — ультра-редкое семя с шансом [color=#22d3ee]0.03% ТОЛЬКО с Вечного титана[/color]. Растёт целый час ([b]3600с[/b]), [color=#34d399]НО если скормить духам 🍀x2 + 🍓x2 + 🌼x2 + 🌶️x2 — созревает МОМЕНТАЛЬНО![/color] Плод дрессирует духов Спирита.\n\n"
		+ "[b][color=#38bdf8]⚗️ Многоступенчатые рецепты котла:[/color][/b]\n"
		+ "• [b]Ветка Восстановления[/b]: Вода → [i]🌿 Мята[/i] → (+ [i]🌿 Мята[/i] = 🌙 [b]Лунный эликсир[/b] → + [i]🍄 Трюфель[/i] = 🥛 [b]Роса бессмертия[/b]) / (+ [i]🪷 Лотос[/i] = 🔮 [b]Нектар арканы x2[/b] → + [i]🍄 Трюфель[/i] = 📜 [b]Мудрость арканы x2[/b])\n"
		+ "• [b]Ветка Ярости[/b]: Вода → [i]🥕 Корень[/i] → (+ [i]🥕 Корень[/i] = 🩸 [b]Зелье ярости x2[/b] → + [i]🍄 Трюфель[/i] = 🔥 [b]Отвар крови титана[/b]) / (+ [i]🪷 Лотос[/i] = 🌪️ [b]Зелье вихря x2[/b] → + [i]🍄 Трюфель[/i] = 🛡️ [b]Железная кожа x3[/b])\n"
		+ "• [b]🌺 Вершина алхимии[/b]: [i]🌙 Лунный эликсир[/i] ИЛИ [i]🩸 Зелье ярости[/i] + [i]🌺 Алый лепесток[/i] = 🌺 [b]Эликсир Алого Лепестка[/b]."
	)
