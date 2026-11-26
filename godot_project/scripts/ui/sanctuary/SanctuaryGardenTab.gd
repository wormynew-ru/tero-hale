class_name SanctuaryGardenTab
extends VBoxContainer

signal feedback_emitted(msg: String)

const GardenPlotCardScene := preload("res://scenes/sanctuary/GardenPlotCard.tscn")

@onready var light_garden_plots_box: VBoxContainer = %LightGardenPlotsBox
@onready var lure_preview_label: Label = %LurePreviewLabel
@onready var lure_pet_button: Button = %LurePetButton
@onready var garden_plots_box: VBoxContainer = %GardenPlotsBox

var _light_cards: Array[GardenPlotCard] = []
var _dark_cards: Array[GardenPlotCard] = []
var _last_light_sig: String = ""
var _last_dark_sig: String = ""


func _ready() -> void:
	lure_pet_button.pressed.connect(_on_lure_pet_pressed)


func reset_cache() -> void:
	_last_light_sig = ""
	_last_dark_sig = ""


func sync_state(unlocked: bool, force: bool = false) -> void:
	if not is_visible_in_tree() and not force:
		return
	_sync_light_garden_plots(force)
	_refresh_lure_bar()
	_sync_dark_garden_plots(unlocked, force)


func update_timers() -> void:
	if not is_visible_in_tree():
		return
	var light_count: int = GameManager.get_light_garden_plot_count()
	for i: int in range(mini(light_count, _light_cards.size())):
		if i < GameManager.light_garden_plots.size():
			_light_cards[i].update_timer(GameManager.light_garden_plots[i])
	var dark_count: int = GameManager.get_garden_plot_count()
	for i: int in range(mini(dark_count, _dark_cards.size())):
		if i < GameManager.garden_plots.size():
			_dark_cards[i].update_timer(GameManager.garden_plots[i])


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


func _compute_light_sig(seeds_owned: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for i: int in range(GameManager.get_light_garden_plot_count()):
		var plot: Dictionary = GameManager.light_garden_plots[i] if i < GameManager.light_garden_plots.size() else {}
		parts.append("%d:%s:%s" % [i, str(plot.get("status", "empty")), str(plot.get("crop_id", ""))])
	for s_entry: Dictionary in seeds_owned:
		var it: ItemData = s_entry["item"] as ItemData
		parts.append("%s=%d" % [it.id, int(s_entry["count"])])
	return "|".join(parts)


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


func _ensure_card_pool(pool: Array[GardenPlotCard], box: VBoxContainer, target_count: int) -> void:
	while pool.size() < target_count:
		var card: GardenPlotCard = GardenPlotCardScene.instantiate() as GardenPlotCard
		card.feedback_emitted.connect(func(msg: String) -> void: feedback_emitted.emit(msg))
		box.add_child(card)
		pool.append(card)


func _sync_light_garden_plots(force: bool) -> void:
	var light_seeds: Array[Dictionary] = _collect_seeds(true)
	var sig: String = _compute_light_sig(light_seeds)
	if not force and sig == _last_light_sig:
		return
	_last_light_sig = sig

	var total_plots: int = GameManager.get_light_garden_plot_count()
	_ensure_card_pool(_light_cards, light_garden_plots_box, total_plots)
	for i: int in range(_light_cards.size()):
		var card: GardenPlotCard = _light_cards[i]
		if i < total_plots:
			card.visible = true
			var plot: Dictionary = GameManager.light_garden_plots[i] if i < GameManager.light_garden_plots.size() else {}
			card.configure(true, i, true, true, plot, light_seeds)
		else:
			card.visible = false


func _sync_dark_garden_plots(unlocked: bool, force: bool) -> void:
	var dark_seeds: Array[Dictionary] = _collect_seeds(false)
	var sig: String = _compute_dark_sig(unlocked, dark_seeds)
	if not force and sig == _last_dark_sig:
		return
	_last_dark_sig = sig

	var total_plots: int = GameManager.get_garden_plot_count()
	_ensure_card_pool(_dark_cards, garden_plots_box, total_plots)
	for i: int in range(_dark_cards.size()):
		var card: GardenPlotCard = _dark_cards[i]
		if i < total_plots:
			card.visible = true
			var plot: Dictionary = GameManager.garden_plots[i] if i < GameManager.garden_plots.size() else {}
			var accessible: bool = unlocked and GameManager.is_garden_plot_accessible(i)
			card.configure(false, i, unlocked, accessible, plot, dark_seeds)
		else:
			card.visible = false


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


func _on_lure_pet_pressed() -> void:
	var res: Dictionary = GameManager.lure_pet_from_light_garden()
	feedback_emitted.emit(str(res.get("message", "")))
