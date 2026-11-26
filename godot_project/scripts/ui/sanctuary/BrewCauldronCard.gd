class_name BrewCauldronCard
extends PanelContainer

signal feedback_emitted(msg: String)

@onready var status_label: Label = %StatusLabel
@onready var water_button: Button = %WaterButton
@onready var collect_button: Button = %CollectButton
@onready var dump_button: Button = %DumpButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var ingredients_title_label: Label = %IngredientsTitleLabel
@onready var ingredients_flow: HFlowContainer = %IngredientsFlow

var _slot_index: int = 0
var _ing_buttons: Array[Button] = []
var _bound_harvests: Array[ItemData] = []


func _ready() -> void:
	water_button.pressed.connect(_on_water_pressed)
	collect_button.pressed.connect(_on_collect_pressed)
	dump_button.pressed.connect(_on_dump_pressed)


func configure(slot_index: int, unlocked: bool, accessible: bool, cauldron: Dictionary, harvests_owned: Array[Dictionary]) -> void:
	_slot_index = slot_index
	var state: String = str(cauldron.get("state", "empty"))

	water_button.visible = false
	collect_button.visible = false
	dump_button.visible = false
	progress_bar.visible = false
	ingredients_title_label.visible = false
	ingredients_flow.visible = false

	if not accessible and (state == "empty" or state == "exploded"):
		status_label.text = "🔒 Котёл #%d — требуется талант «Мастер котла» или Сл.%d" % [slot_index + 1, GameManager.ALCHEMY_UNLOCK_DIFFICULTY]
		status_label.modulate = Color(0.65, 0.70, 0.78, 1.0)
		return

	if state == "empty" or state == "exploded":
		if state == "exploded":
			status_label.text = "💥 Котёл #%d: Взорвался из-за ошибки! Налейте свежую воду для нового зелья." % (slot_index + 1)
			status_label.modulate = Color(0.98, 0.45, 0.42, 1.0)
		else:
			status_label.text = "⚗️ Котёл #%d: Пуст — начните варку с колбы воды." % (slot_index + 1)
			status_label.modulate = Color.WHITE
		water_button.visible = true
		water_button.disabled = not unlocked
	elif state == "brewing":
		progress_bar.visible = true
		update_timer(cauldron)
	elif state == "ready":
		var stage: int = int(cauldron.get("stage", 0))
		var can_collect: bool = bool(cauldron.get("can_collect", false))
		status_label.text = "%s Котёл #%d [Этап %d/3]: %s" % [
			str(cauldron.get("brew_emoji", "⚗️")), slot_index + 1, stage, str(cauldron.get("brew_title", ""))
		]
		status_label.modulate = Color.WHITE
		if can_collect:
			collect_button.visible = true
			collect_button.text = "🧪 Забрать (x%d)" % maxi(1, int(cauldron.get("result_count", 1)))
		dump_button.visible = true

		if stage < 3:
			ingredients_title_label.visible = true
			if harvests_owned.is_empty():
				ingredients_title_label.text = "Добавить тёмную траву на Шаг %d — нет трав Тёмного сада (соберите урожай с тёмных грядок)." % (stage + 1)
			else:
				ingredients_title_label.text = "Добавить тёмную траву на Шаг %d (⚠️ неверный ингредиент взрывает котёл с шансом 100%%):" % (stage + 1)
				_configure_ingredients(harvests_owned)


func update_timer(cauldron: Dictionary) -> void:
	if str(cauldron.get("state", "empty")) != "brewing":
		return
	var elapsed: float = float(cauldron.get("elapsed", 0.0))
	var dur: float = maxf(0.1, float(cauldron.get("duration", 10.0)))
	var rem_sec: float = maxf(0.0, (dur - elapsed) / maxf(0.1, GameManager.get_brewing_speed_mult()))
	status_label.text = "🔥 Котёл #%d [Шаг %d]: Варится %s %s — %.1fс" % [
		_slot_index + 1, int(cauldron.get("pending_stage", 1)),
		str(cauldron.get("pending_emoji", "⚗️")), str(cauldron.get("pending_title", "")), rem_sec
	]
	status_label.modulate = Color(0.98, 0.82, 0.38, 1.0)
	progress_bar.max_value = dur
	progress_bar.value = minf(elapsed, dur)


func _configure_ingredients(harvests_owned: Array[Dictionary]) -> void:
	ingredients_flow.visible = true
	while _ing_buttons.size() < harvests_owned.size():
		var btn_idx: int = _ing_buttons.size()
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(180.0, 44.0)
		btn.pressed.connect(func() -> void: _on_ingredient_chosen(btn_idx))
		ingredients_flow.add_child(btn)
		_ing_buttons.append(btn)
		_bound_harvests.append(null)
	for i: int in range(_ing_buttons.size()):
		var btn: Button = _ing_buttons[i]
		if i < harvests_owned.size():
			var h_entry: Dictionary = harvests_owned[i]
			var harv: ItemData = h_entry["item"] as ItemData
			var cnt: int = int(h_entry["count"])
			_bound_harvests[i] = harv
			btn.visible = true
			btn.text = "➕ %s %s (x%d)" % [harv.icon_emoji, harv.item_name, cnt]
		else:
			_bound_harvests[i] = null
			btn.visible = false


func _on_ingredient_chosen(btn_idx: int) -> void:
	if btn_idx < 0 or btn_idx >= _bound_harvests.size() or _bound_harvests[btn_idx] == null:
		return
	var res: Dictionary = GameManager.add_brewing_ingredient(_slot_index, _bound_harvests[btn_idx])
	feedback_emitted.emit(str(res.get("message", "")))


func _on_water_pressed() -> void:
	var res: Dictionary = GameManager.start_brewing_water(_slot_index)
	feedback_emitted.emit(str(res.get("message", "")))


func _on_collect_pressed() -> void:
	var res: Dictionary = GameManager.collect_brewed_potion(_slot_index)
	feedback_emitted.emit(str(res.get("message", "")))


func _on_dump_pressed() -> void:
	GameManager.clear_brewing_slot(_slot_index)
	feedback_emitted.emit("Котёл #%d очищен." % (_slot_index + 1))
