extends ScrollContainer

@onready var coins_label: Label = %DarkShopCoinsLabel
@onready var feedback_label: Label = %DarkShopFeedbackLabel
@onready var dark_shop_list: VBoxContainer = %DarkShopList

var _shop_rows: Array[Dictionary] = []
var _dirty: bool = true
var _refresh_queued: bool = false


func _ready() -> void:
	GameManager.dark_shop_changed.connect(_on_state_updated)
	GameManager.inventory_changed.connect(_on_state_updated)
	GameManager.difficulty_changed.connect(_on_state_updated)
	GameManager.game_reset.connect(_on_reset)
	_build_shop()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and _dirty:
		_refresh()


func _on_reset() -> void:
	feedback_label.text = ""
	_dirty = true
	_refresh_queued = false
	if is_visible_in_tree():
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


func _make_card_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.content_margin_left = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 14.0
	sb.content_margin_bottom = 10.0
	sb.bg_color = Color(0.13, 0.08, 0.14, 1.0)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.72, 0.34, 0.58, 0.88)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	return sb


func _build_shop() -> void:
	if dark_shop_list == null:
		return
	for child: Node in dark_shop_list.get_children():
		child.queue_free()
	_shop_rows.clear()

	var shared_card_style: StyleBoxFlat = _make_card_style()
	for item: ItemData in GameManager.dark_shop_items:
		if item == null:
			continue

		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", shared_card_style)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)

		var icon_label: Label = Label.new()
		icon_label.custom_minimum_size = Vector2(40.0, 40.0)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 26)
		icon_label.text = item.icon_emoji
		row.add_child(icon_label)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 3)
		row.add_child(info_vbox)

		var title_label: Label = Label.new()
		title_label.add_theme_font_size_override("font_size", 15)
		title_label.add_theme_color_override("font_color", item.icon_color.lightened(0.2))
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(title_label)

		var summary_label: Label = Label.new()
		summary_label.add_theme_font_size_override("font_size", 13)
		summary_label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.96, 1.0))
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_label.text = "%s\n%s" % [item.get_summary_text(), item.description]
		info_vbox.add_child(summary_label)

		var buy_btn: Button = Button.new()
		buy_btn.custom_minimum_size = Vector2(156.0, 46.0)
		buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var target_item: ItemData = item
		buy_btn.pressed.connect(func() -> void:
			var res: Dictionary = GameManager.buy_dark_shop_item(target_item)
			feedback_label.text = str(res.get("message", ""))
			if bool(res.get("success", false)):
				feedback_label.modulate = Color(0.45, 0.96, 0.68, 1.0)
			else:
				feedback_label.modulate = Color(0.98, 0.56, 0.44, 1.0)
		)
		HoldAutoClicker.attach(buy_btn, 50.0)
		row.add_child(buy_btn)

		dark_shop_list.add_child(card)
		_shop_rows.append({
			"item": item,
			"title_label": title_label,
			"buy_btn": buy_btn,
		})


func _refresh() -> void:
	_dirty = false
	if coins_label != null:
		coins_label.text = "🪙 Монеты Тёмного магазина: %d  (за Сл.%d при победе над Титаном даётся +%d 🪙, повторно!)" % [
			GameManager.dark_shop_coins,
			GameManager.difficulty_level,
			maxi(1, GameManager.difficulty_level),
		]
	if _shop_rows.size() != GameManager.dark_shop_items.size():
		_build_shop()

	for entry: Dictionary in _shop_rows:
		var item: ItemData = entry["item"] as ItemData
		var title_label: Label = entry["title_label"] as Label
		var buy_btn: Button = entry["buy_btn"] as Button
		if item == null or title_label == null or buy_btn == null:
			continue
		var owned_cnt: int = GameManager.get_item_count_in_inventory(item)
		var cnt_suffix: String = "  (В сумке: %d)" % owned_cnt if owned_cnt > 0 else ""
		title_label.text = "%s%s" % [item.item_name, cnt_suffix]
		var price: int = GameManager.get_dark_shop_item_price(item)
		buy_btn.text = "Купить (%d 🪙)" % price
		buy_btn.disabled = GameManager.dark_shop_coins < price
