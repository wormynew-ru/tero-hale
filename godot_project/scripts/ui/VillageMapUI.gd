extends Control

signal navigate_to_page(page_id: String)
signal return_to_battle_requested

@onready var house_hotspot: Button = %HouseHotspot
@onready var shop_building_hotspot: Button = %ShopBuildingHotspot
@onready var dog_hotspot: Button = %DogHotspot
@onready var mountains_hotspot: Button = %MountainsHotspot
@onready var well_hotspot: Button = %WellHotspot
@onready var map_hint_label: Label = %MapHintLabel

@onready var shop_choice_overlay: ColorRect = %ShopChoiceOverlay
@onready var go_shop_button: Button = %GoShopButton
@onready var go_enchant_button: Button = %GoEnchantButton
@onready var go_dark_forge_button: Button = %GoDarkForgeButton
@onready var go_dark_shop_button: Button = %GoDarkShopButton
@onready var cancel_choice_button: Button = %CancelChoiceButton

@onready var well_overlay: ColorRect = %WellOverlay
@onready var well_blessing_label: Label = %WellBlessingLabel
@onready var well_status_label: Label = %WellStatusLabel
@onready var well_feedback_label: Label = %WellFeedbackLabel
@onready var well_sacrifice_button: Button = %WellSacrificeButton
@onready var close_well_button: Button = %CloseWellButton


func _ready() -> void:
	shop_choice_overlay.visible = false
	well_overlay.visible = false
	GameManager.difficulty_changed.connect(_refresh_hint)
	GameManager.stats_changed.connect(_refresh_well_if_open)
	GameManager.game_reset.connect(_on_game_reset)

	house_hotspot.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		well_overlay.visible = false
		navigate_to_page.emit("sanctuary")
	)
	shop_building_hotspot.pressed.connect(func() -> void:
		well_overlay.visible = false
		shop_choice_overlay.visible = true
	)
	dog_hotspot.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		well_overlay.visible = false
		navigate_to_page.emit("pets")
	)
	mountains_hotspot.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		well_overlay.visible = false
		return_to_battle_requested.emit()
	)
	well_hotspot.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		well_feedback_label.text = ""
		well_overlay.visible = true
		_refresh_well_overlay()
	)

	go_shop_button.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		navigate_to_page.emit("shop")
	)
	go_enchant_button.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		navigate_to_page.emit("enchant")
	)
	go_dark_forge_button.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		navigate_to_page.emit("dark_forge")
	)
	go_dark_shop_button.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		navigate_to_page.emit("dark_shop")
	)
	cancel_choice_button.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
	)

	well_sacrifice_button.pressed.connect(func() -> void:
		var res: Dictionary = GameManager.sacrifice_all_gold_to_well()
		well_feedback_label.text = str(res.get("message", ""))
		_refresh_well_overlay()
	)
	close_well_button.pressed.connect(func() -> void:
		well_overlay.visible = false
	)

	_refresh_hint()


func _on_game_reset() -> void:
	well_feedback_label.text = ""
	reset_overlay()


func reset_overlay() -> void:
	if shop_choice_overlay != null:
		shop_choice_overlay.visible = false
	if well_overlay != null:
		well_overlay.visible = false
	_refresh_hint()


func _refresh_well_if_open() -> void:
	if well_overlay != null and well_overlay.visible:
		_refresh_well_overlay()


func _refresh_well_overlay() -> void:
	if well_blessing_label == null or well_status_label == null or well_sacrifice_button == null:
		return
	var check: Dictionary = GameManager.can_sacrifice_to_well()
	var ok: bool = bool(check.get("ok", false))
	well_blessing_label.text = GameManager.get_well_blessing_label()
	well_status_label.text = str(check.get("reason", ""))
	well_status_label.modulate = Color(0.56, 0.96, 0.72, 1.0) if ok else Color(0.95, 0.74, 0.45, 1.0)
	well_sacrifice_button.disabled = not ok
	well_sacrifice_button.text = "🪙 Пожертвовать всё (%s з.)" % NumberFormatter.format_number(GameManager.gold) if ok else "⏳ Жертва недоступна"


func _refresh_hint() -> void:
	if GameManager.is_alchemy_unlocked():
		house_hotspot.tooltip_text = "🏡 Убежище: Светлый и Тёмный сады, Зелья, Экспедиции и Духи (Открыто!)"
		map_hint_label.text = "🗺️ Объекты карты: Домик (🏡 Убежище), «МАГАЗИН» (🏪 Лавка / ⚒️ Кузня / 🔥 Тёмная кузня / 🦇 Тёмный магазин), Колодец (⛲ Колодец Жадности), Щенок (🐾 Путники), Горы (⚔️ Бой)."
	else:
		house_hotspot.tooltip_text = "☀️ Светлый сад и Экспедиции открыты! (🌑 Тёмный сад с Сл. %d)" % GameManager.ALCHEMY_UNLOCK_DIFFICULTY
		map_hint_label.text = "🗺️ Объекты карты: Домик (☀️ Светлый сад и Экспедиции; 🌑 Тёмный сад с Сл.%d), «МАГАЗИН» (🏪/⚒️/🔥/🦇), Колодец (⛲ Жертва золота), Щенок (🐾 Путники), Горы (⚔️ Бой)." % GameManager.ALCHEMY_UNLOCK_DIFFICULTY
