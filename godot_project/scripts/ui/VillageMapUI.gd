extends Control

signal navigate_to_page(page_id: String)
signal return_to_battle_requested

@onready var house_hotspot: Button = %HouseHotspot
@onready var shop_building_hotspot: Button = %ShopBuildingHotspot
@onready var dog_hotspot: Button = %DogHotspot
@onready var mountains_hotspot: Button = %MountainsHotspot
@onready var map_hint_label: Label = %MapHintLabel

@onready var shop_choice_overlay: ColorRect = %ShopChoiceOverlay
@onready var go_shop_button: Button = %GoShopButton
@onready var go_enchant_button: Button = %GoEnchantButton
@onready var cancel_choice_button: Button = %CancelChoiceButton


func _ready() -> void:
	shop_choice_overlay.visible = false
	GameManager.difficulty_changed.connect(_refresh_hint)
	GameManager.game_reset.connect(_refresh_hint)

	house_hotspot.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		navigate_to_page.emit("sanctuary")
	)
	shop_building_hotspot.pressed.connect(func() -> void:
		shop_choice_overlay.visible = true
	)
	dog_hotspot.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		navigate_to_page.emit("pets")
	)
	mountains_hotspot.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		return_to_battle_requested.emit()
	)

	go_shop_button.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		navigate_to_page.emit("shop")
	)
	go_enchant_button.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
		navigate_to_page.emit("enchant")
	)
	cancel_choice_button.pressed.connect(func() -> void:
		shop_choice_overlay.visible = false
	)

	_refresh_hint()


func reset_overlay() -> void:
	if shop_choice_overlay != null:
		shop_choice_overlay.visible = false
	_refresh_hint()


func _refresh_hint() -> void:
	if GameManager.is_alchemy_unlocked():
		house_hotspot.tooltip_text = "🏡 Убежище: Светлый и Тёмный сады, Зелья и Духи (Открыто!)"
		map_hint_label.text = "🗺️ Нажмите на объекты на картине: Домик (🏡 Убежище — Сады, Зелья и Духи), «МАГАЗИН» (🏪 Лавка / ⚒️ Кузня), Щенок (🐾 Путники), Горы (⚔️ Бой)."
	else:
		house_hotspot.tooltip_text = "☀️ Светлый сад открыт! (🌑 Тёмный сад и котлы с Сл. %d)" % GameManager.ALCHEMY_UNLOCK_DIFFICULTY
		map_hint_label.text = "🗺️ Нажмите на объекты на картине: Домик (☀️ Светлый сад для приманки путников; 🌑 Тёмный сад с Сл.%d), «МАГАЗИН» (🏪 Лавка / ⚒️ Кузня), Щенок (🐾 Путники), Горы (⚔️ Бой)." % GameManager.ALCHEMY_UNLOCK_DIFFICULTY
