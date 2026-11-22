extends ColorRect

const StatsUIScript = preload("res://scripts/ui/StatsUI.gd")
const DifficultyUIScript = preload("res://scripts/ui/DifficultyUI.gd")
const VillageMapUIScript = preload("res://scripts/ui/VillageMapUI.gd")

@onready var back_button: Button = %BackButton
@onready var menu_title_label: Label = %MenuTitleLabel
@onready var resource_badge_label: Label = %ResourceBadgeLabel
@onready var close_button: Button = %CloseButton

@onready var menu_hub: VBoxContainer = %MenuHub
@onready var open_stats_button: Button = %OpenStatsButton
@onready var open_classes_button: Button = %OpenClassesButton
@onready var open_spells_button: Button = %OpenSpellsButton
@onready var open_pets_button: Button = %OpenPetsButton
@onready var open_skills_button: Button = %OpenSkillsButton
@onready var open_dark_skills_button: Button = %OpenDarkSkillsButton
@onready var open_inventory_button: Button = %OpenInventoryButton
@onready var open_enchant_button: Button = %OpenEnchantButton
@onready var open_shop_button: Button = %OpenShopButton
@onready var open_difficulty_button: Button = %OpenDifficultyButton
@onready var open_faq_button: Button = %OpenFaqButton
@onready var open_village_button: Button = %OpenVillageButton
@onready var open_sanctuary_button: Button = %OpenSanctuaryButton
@onready var open_afk_button: Button = %OpenAfkButton

@onready var stats_ui: StatsUIScript = %StatsUI
@onready var class_ui: ScrollContainer = %ClassUI
@onready var spellbook_ui: ScrollContainer = %SpellbookUI
@onready var pet_ui: ScrollContainer = %PetUI
@onready var skill_tree_ui: Control = %SkillTreeUI
@onready var dark_skill_tree_ui: Control = %DarkSkillTreeUI
@onready var inventory_ui: ScrollContainer = %InventoryUI
@onready var enchant_ui: ScrollContainer = %EnchantUI
@onready var shop_ui: ScrollContainer = %ShopUI
@onready var difficulty_ui: DifficultyUIScript = %DifficultyUI
@onready var faq_ui: ScrollContainer = %FaqUI
@onready var sanctuary_ui: ScrollContainer = %SanctuaryUI
@onready var village_map_ui: VillageMapUIScript = %VillageMapUI


func _ready() -> void:
	visible = false
	GameManager.stats_changed.connect(_refresh_resources)
	GameManager.skills_changed.connect(_refresh_resources)
	GameManager.dark_skills_changed.connect(_refresh_resources)
	GameManager.difficulty_changed.connect(_refresh_resources)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _refresh_resources())
	GameManager.pets_changed.connect(_refresh_resources)

	back_button.pressed.connect(open_hub)
	close_button.pressed.connect(close_menu)

	open_stats_button.pressed.connect(func() -> void: open_page("stats"))
	open_classes_button.pressed.connect(func() -> void: open_page("classes"))
	open_spells_button.pressed.connect(func() -> void: open_page("spells"))
	open_pets_button.pressed.connect(func() -> void: open_page("pets"))
	open_skills_button.pressed.connect(func() -> void: open_page("skills"))
	open_dark_skills_button.pressed.connect(func() -> void: open_page("dark_skills"))
	open_inventory_button.pressed.connect(func() -> void: open_page("inventory"))
	open_enchant_button.pressed.connect(func() -> void: open_page("enchant"))
	open_shop_button.pressed.connect(func() -> void: open_page("shop"))
	open_difficulty_button.pressed.connect(func() -> void: open_page("difficulty"))
	open_faq_button.pressed.connect(func() -> void: open_page("faq"))
	open_village_button.pressed.connect(func() -> void: open_page("village"))
	open_sanctuary_button.pressed.connect(func() -> void: open_page("sanctuary"))
	open_afk_button.pressed.connect(func() -> void:
		close_menu()
		GameManager.set_afk_mode(true)
	)

	stats_ui.reset_triggered.connect(close_menu)
	difficulty_ui.new_run_started.connect(close_menu)
	village_map_ui.navigate_to_page.connect(open_page)
	village_map_ui.return_to_battle_requested.connect(close_menu)
	_refresh_resources()


func _refresh_resources() -> void:
	resource_badge_label.text = "💰 %s   |   💎 %d ОН   |   🌑 %d   |   🎲 %d   |   💀 Сл.%d" % [
		NumberFormatter.format_number(GameManager.gold),
		GameManager.skill_points,
		GameManager.dark_points,
		GameManager.curse_reroll_tokens,
		GameManager.difficulty_level,
	]
	if GameManager.is_classes_unlocked():
		var hc: HeroClassData = GameManager.get_current_class()
		open_classes_button.text = "%s Класс: %s" % [hc.icon_emoji if hc != null else "🎭", hc.title if hc != null else "Странник"]
	else:
		open_classes_button.text = "🔒 Классы (Сл.%d)" % GameManager.CLASSES_UNLOCK_DIFFICULTY

	var active_pet: PetData = GameManager.get_equipped_pet()
	if active_pet != null:
		open_pets_button.text = "%s Путник: %s" % [active_pet.icon_emoji, active_pet.pet_name]
	else:
		open_pets_button.text = "🐾 Путники (%d)" % GameManager.all_pets.size()

	if GameManager.is_alchemy_unlocked():
		open_sanctuary_button.text = "🏡 Убежище (Сады и Зелья)"
	else:
		open_sanctuary_button.text = "☀️ Светлый сад (Тёмн.: Сл.%d)" % GameManager.ALCHEMY_UNLOCK_DIFFICULTY


func open_hub() -> void:
	_hide_all_pages()
	menu_hub.visible = true
	back_button.visible = false
	menu_title_label.text = "📜 Меню героя"
	_refresh_resources()
	visible = true


func open_page(page_id: String) -> void:
	_hide_all_pages()
	back_button.visible = true
	_refresh_resources()
	match page_id:
		"stats":
			menu_title_label.text = "📈 Статы и Мастерство"
			stats_ui.visible = true
		"classes":
			menu_title_label.text = "🎭 Класс героя"
			class_ui.visible = true
		"spells":
			menu_title_label.text = "✨ Книга заклинаний (20)"
			spellbook_ui.visible = true
		"pets":
			menu_title_label.text = "🐾 Путники (Слот без HP)"
			pet_ui.visible = true
		"skills":
			menu_title_label.text = "🌳 Древо талантов"
			skill_tree_ui.visible = true
		"dark_skills":
			menu_title_label.text = "🌑 Тёмные навыки"
			dark_skill_tree_ui.visible = true
		"inventory":
			menu_title_label.text = "🎒 Инвентарь"
			inventory_ui.visible = true
		"enchant":
			menu_title_label.text = "⚒️ Кузня (Зачарование)"
			enchant_ui.visible = true
		"shop":
			menu_title_label.text = "🏪 Лавка"
			shop_ui.visible = true
		"difficulty":
			menu_title_label.text = "💀 Сложность и Новый ран"
			difficulty_ui.visible = true
		"faq":
			menu_title_label.text = "❓ F.A.Q."
			faq_ui.visible = true
		"sanctuary":
			menu_title_label.text = "🏡 Убежище: Сад и Зельеварение"
			sanctuary_ui.visible = true
		"village":
			menu_title_label.text = "🗺️ Карта деревни"
			village_map_ui.reset_overlay()
			village_map_ui.visible = true
		_:
			open_hub()
			return
	visible = true


func close_menu() -> void:
	visible = false


func _hide_all_pages() -> void:
	menu_hub.visible = false
	stats_ui.visible = false
	class_ui.visible = false
	spellbook_ui.visible = false
	pet_ui.visible = false
	skill_tree_ui.visible = false
	dark_skill_tree_ui.visible = false
	inventory_ui.visible = false
	enchant_ui.visible = false
	shop_ui.visible = false
	difficulty_ui.visible = false
	faq_ui.visible = false
	sanctuary_ui.visible = false
	village_map_ui.visible = false
