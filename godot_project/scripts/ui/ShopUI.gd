extends ScrollContainer

@onready var shop_feedback_label: Label = %ShopFeedbackLabel
@onready var shop_list: VBoxContainer = %ShopList


var _shop_rows: Array[Dictionary] = []
var _dirty: bool = true


func _ready() -> void:
	GameManager.stats_changed.connect(_on_state_updated)
	GameManager.difficulty_changed.connect(_on_state_updated)
	GameManager.game_reset.connect(_on_reset)
	_build_shop()
	_refresh_shop_prices()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and _dirty:
		_refresh_shop_prices()


func _on_reset() -> void:
	shop_feedback_label.text = ""
	_dirty = true
	if is_visible_in_tree():
		_refresh_shop_prices()


func _on_state_updated() -> void:
	if not is_visible_in_tree():
		_dirty = true
		return
	_refresh_shop_prices()


func _build_shop() -> void:
	if shop_list == null:
		return

	for child: Node in shop_list.get_children():
		child.queue_free()
	_shop_rows.clear()

	for item: ItemData in GameManager.shop_items:
		if item == null:
			continue

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var icon_label: Label = Label.new()
		icon_label.custom_minimum_size = Vector2(38.0, 38.0)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 24)
		icon_label.text = item.icon_emoji
		row.add_child(icon_label)

		var pack_suffix: String = " x%d" % item.shop_pack_amount if item.shop_pack_amount > 1 else ""
		var info_label: Label = Label.new()
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_label.text = "%s%s — %s" % [item.item_name, pack_suffix, item.get_summary_text()]
		row.add_child(info_label)

		var buy_btn: Button = Button.new()
		buy_btn.custom_minimum_size = Vector2(146.0, 44.0)
		var target_item: ItemData = item
		buy_btn.pressed.connect(func() -> void:
			var msg: String = GameManager.buy_item(target_item)
			if not msg.is_empty():
				shop_feedback_label.text = msg
		)
		HoldAutoClicker.attach(buy_btn, 50.0)
		row.add_child(buy_btn)

		shop_list.add_child(row)
		_shop_rows.append({"item": item, "btn": buy_btn})


func _refresh_shop_prices() -> void:
	_dirty = false
	if _shop_rows.size() != GameManager.shop_items.size():
		_build_shop()
	for entry: Dictionary in _shop_rows:
		var item: ItemData = entry["item"] as ItemData
		var buy_btn: Button = entry["btn"] as Button
		if item == null or buy_btn == null:
			continue
		var buy_price: float = GameManager.get_item_buy_price(item)
		buy_btn.text = "Купить (%s з.)" % NumberFormatter.format_number(buy_price)
		buy_btn.disabled = GameManager.gold < buy_price

