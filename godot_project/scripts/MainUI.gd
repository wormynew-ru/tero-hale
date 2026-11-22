extends Control

const BattleArenaUIScript = preload("res://scripts/ui/BattleArenaUI.gd")
const HeroMenuUIScript = preload("res://scripts/ui/HeroMenuUI.gd")

@onready var combat_system: CombatSystem = %CombatSystem
@onready var root_hbox: HBoxContainer = %RootHBox
@onready var battle_arena_ui: BattleArenaUIScript = %BattleArenaUI
@onready var hero_menu_ui: HeroMenuUIScript = %HeroMenuUI


func _ready() -> void:
	battle_arena_ui.bind_combat_system(combat_system)
	battle_arena_ui.open_menu_requested.connect(hero_menu_ui.open_hub)
	battle_arena_ui.open_inventory_requested.connect(func() -> void: hero_menu_ui.open_page("inventory"))
	battle_arena_ui.open_difficulty_requested.connect(func() -> void: hero_menu_ui.open_page("difficulty"))
	battle_arena_ui.open_pets_requested.connect(func() -> void: hero_menu_ui.open_page("pets"))
	battle_arena_ui.open_village_requested.connect(func() -> void: hero_menu_ui.open_page("village"))
	GameManager.afk_mode_changed.connect(_on_afk_mode_changed)
	_on_afk_mode_changed(GameManager.is_afk_mode)


func _on_afk_mode_changed(is_afk: bool) -> void:
	root_hbox.visible = not is_afk
	if is_afk:
		hero_menu_ui.close_menu()
