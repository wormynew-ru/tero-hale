extends Control

signal open_menu_requested
signal open_inventory_requested
signal open_difficulty_requested
signal open_pets_requested
signal open_village_requested

const AVATAR_BASE_POS: Vector2 = Vector2(2.0, 2.0)
const AVATAR_TWEEN_MIN_INTERVAL_MS: int = 90
const AttackDiamondScript = preload("res://scripts/ui/AttackDiamond.gd")
const AbilitySlotButtonScript = preload("res://scripts/ui/AbilitySlotButton.gd")

@onready var backdrop_tint: ColorRect = %BackdropTint

@onready var hero_crest_button: Button = %HeroCrestButton
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var xp_label: Label = %XPLabel
@onready var hero_crest_hp_bar: ProgressBar = %HeroCrestHPBar
@onready var hero_crest_hp_label: Label = %HeroCrestHPLabel

@onready var str_badge_label: Label = %StrBadgeLabel
@onready var agi_badge_label: Label = %AgiBadgeLabel
@onready var end_badge_label: Label = %EndBadgeLabel
@onready var int_badge_label: Label = %IntBadgeLabel
@onready var crest_red_label: Label = %CrestRedLabel
@onready var crest_blue_label: Label = %CrestBlueLabel

@onready var village_chip_button: Button = %VillageChipButton
@onready var difficulty_chip_button: Button = %DifficultyChipButton
@onready var wave_dungeon_label: Label = %WaveDungeonLabel
@onready var state_label: Label = %StateLabel
@onready var afk_toggle_button: Button = %AfkToggleButton
@onready var save_button: Button = %SaveButton

@onready var player_attack_diamond: AttackDiamondScript = %PlayerAttackDiamond
@onready var player_avatar_stage: Control = %PlayerAvatarStage
@onready var player_avatar_panel: PanelContainer = %PlayerAvatarPanel
@onready var player_emoji_label: Label = %PlayerEmojiLabel
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_barrier_bar: ProgressBar = %PlayerBarrierBar
@onready var player_hp_bar_label: Label = %PlayerHPBarLabel
@onready var player_mana_bar: ProgressBar = %PlayerManaBar
@onready var player_mana_bar_label: Label = %PlayerManaBarLabel
@onready var companion_slot_button: Button = %CompanionSlotButton

@onready var enemy_fighter: VBoxContainer = %EnemyFighter
@onready var enemy_attack_diamond: AttackDiamondScript = %EnemyAttackDiamond
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_avatar_stage: Control = %EnemyAvatarStage
@onready var enemy_avatar_panel: PanelContainer = %EnemyAvatarPanel
@onready var enemy_emoji_label: Label = %EnemyEmojiLabel
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_hp_bar_label: Label = %EnemyHPBarLabel
@onready var enemy_mana_bar: ProgressBar = %EnemyManaBar
@onready var enemy_mana_bar_label: Label = %EnemyManaBarLabel

@onready var magic_status_label: Label = %MagicStatusLabel
@onready var active_buffs_label: Label = %ActiveBuffsLabel
@onready var ability_slot_0: AbilitySlotButtonScript = %AbilitySlot0
@onready var ability_slot_1: AbilitySlotButtonScript = %AbilitySlot1
@onready var ability_slot_2: AbilitySlotButtonScript = %AbilitySlot2

@onready var battle_search_button: Button = %BattleSearchButton
@onready var battle_search_caption: Label = %BattleSearchCaption
@onready var backpack_button: Button = %BackpackButton

var _combat_system: CombatSystem = null
var _player_tween: Tween = null
var _enemy_tween: Tween = null
var _search_btn_tween: Tween = null
var _base_enemy_name: String = ""
var _enemy_shred_stacks: int = 0
var _enemy_stun_remaining: float = 0.0
var _enemy_avatar_style: StyleBoxFlat = null
var _hud_refresh_queued: bool = false
var _last_hp_bar_str: String = ""
var _last_mp_bar_str: String = ""
var _last_enemy_hp_str: String = ""
var _last_enemy_mp_str: String = ""

var _player_popup_pool: Array[Dictionary] = []
var _enemy_popup_pool: Array[Dictionary] = []
var _proj_pool: Array[Dictionary] = []
var _player_popup_cursor: int = 0
var _enemy_popup_cursor: int = 0
var _proj_cursor: int = 0
var _last_player_anim_ms: int = 0
var _last_enemy_anim_ms: int = 0


func _ready() -> void:
	_init_visual_pools()
	var base_style: StyleBoxFlat = enemy_avatar_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if base_style != null:
		_enemy_avatar_style = base_style.duplicate() as StyleBoxFlat
		enemy_avatar_panel.add_theme_stylebox_override("panel", _enemy_avatar_style)

	GameManager.stats_changed.connect(_request_hud_refresh)
	GameManager.hp_changed.connect(_on_player_hp_changed)
	GameManager.mana_changed.connect(_on_player_mana_changed)
	GameManager.barrier_changed.connect(_on_player_barrier_changed)
	GameManager.player_healed.connect(_on_player_healed)
	GameManager.abilities_changed.connect(_refresh_magic_summary)
	GameManager.buffs_changed.connect(_refresh_active_buffs)
	GameManager.difficulty_changed.connect(_refresh_difficulty_chip)
	GameManager.final_boss_cleared.connect(_on_final_boss_cleared)
	GameManager.curse_warden_defeated.connect(_on_curse_warden_defeated)
	GameManager.mastery_changed.connect(_on_mastery_changed)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _request_hud_refresh())
	GameManager.pets_changed.connect(_refresh_companion_slot)
	GameManager.location_changed.connect(_on_location_changed)
	GameManager.mine_run_failed.connect(_on_mine_run_failed)
	GameManager.wave_dungeon_changed.connect(_refresh_wave_dungeon_banner)
	GameManager.afk_mode_changed.connect(_on_afk_mode_changed)
	GameManager.game_reset.connect(_refresh_all)

	hero_crest_button.pressed.connect(func() -> void: open_menu_requested.emit())
	village_chip_button.pressed.connect(func() -> void: open_village_requested.emit())
	difficulty_chip_button.pressed.connect(func() -> void: open_difficulty_requested.emit())
	companion_slot_button.pressed.connect(func() -> void: open_pets_requested.emit())
	save_button.pressed.connect(func() -> void: GameManager.save_game())
	afk_toggle_button.pressed.connect(func() -> void: GameManager.set_afk_mode(not GameManager.is_afk_mode))
	battle_search_button.pressed.connect(_on_battle_search_pressed)
	backpack_button.pressed.connect(func() -> void: open_inventory_requested.emit())

	for slot_btn: AbilitySlotButtonScript in [ability_slot_0, ability_slot_1, ability_slot_2]:
		slot_btn.manual_cast_requested.connect(_on_ability_manual_cast)
		slot_btn.auto_cast_toggled.connect(_on_ability_auto_toggled)

	_refresh_all()


func _init_visual_pools() -> void:
	for _i: int in range(10):
		_player_popup_pool.append(_create_popup_slot(player_avatar_stage))
		_enemy_popup_pool.append(_create_popup_slot(enemy_avatar_stage))
	for _i: int in range(6):
		var proj: Label = Label.new()
		proj.mouse_filter = Control.MOUSE_FILTER_IGNORE
		proj.z_index = 12
		proj.visible = false
		proj.add_theme_font_size_override("font_size", 26)
		add_child(proj)
		_proj_pool.append({"label": proj, "tween": null})


func _create_popup_slot(stage: Control) -> Dictionary:
	var popup: Label = Label.new()
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 10
	popup.visible = false
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.custom_minimum_size = Vector2(180.0, 24.0)
	popup.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.08, 0.95))
	popup.add_theme_constant_override("outline_size", 4)
	if stage != null:
		stage.add_child(popup)
	return {"label": popup, "tween": null, "last_size": -1, "last_color": Color(-1.0, -1.0, -1.0, -1.0)}


func _request_hud_refresh() -> void:
	if GameManager.is_afk_mode or _hud_refresh_queued:
		return
	_hud_refresh_queued = true
	call_deferred("_refresh_hud")


func bind_combat_system(combat: CombatSystem) -> void:
	if combat == null or _combat_system == combat:
		return
	_combat_system = combat
	_combat_system.state_changed.connect(_on_combat_state_changed)
	_combat_system.battle_search_changed.connect(_on_battle_search_changed)
	_combat_system.enemy_spawned.connect(_on_enemy_spawned)
	_combat_system.enemy_cleared.connect(_on_enemy_cleared)
	_combat_system.enemy_hp_changed.connect(_on_enemy_hp_changed)
	_combat_system.enemy_mana_changed.connect(_on_enemy_mana_changed)
	_combat_system.attack_progress_updated.connect(_on_attack_progress_updated)
	_combat_system.player_attack_landed.connect(_on_player_attack_landed)
	_combat_system.ranged_shot_fired.connect(_on_ranged_shot_fired)
	_combat_system.spirit_action_performed.connect(_on_spirit_action_performed)
	_combat_system.troll_shred_updated.connect(_on_troll_shred_updated)
	_combat_system.enemy_attack_landed.connect(_on_enemy_attack_landed)
	_combat_system.enemy_defeated_reward.connect(_on_enemy_defeated_reward)
	_combat_system.ability_casted.connect(_on_ability_casted)
	_combat_system.overcharge_tick_fired.connect(_on_overcharge_tick_fired)
	_combat_system.overcharge_state_changed.connect(_on_overcharge_state_changed)
	_combat_system.dot_tick_landed.connect(_on_dot_tick_landed)
	_combat_system.enemy_stun_changed.connect(_on_enemy_stun_changed)
	_combat_system.pet_action_performed.connect(_on_pet_action_performed)
	_combat_system.mine_find_triggered.connect(_on_mine_find_triggered)
	_combat_system.route_event_triggered.connect(_on_route_event_triggered)

	_on_battle_search_changed(_combat_system.is_seeking_battle)
	_on_combat_state_changed(int(_combat_system.current_state))
	if _combat_system.current_enemy != null:
		_on_enemy_spawned(
			_combat_system.current_enemy,
			_combat_system.enemy_hp,
			_combat_system.enemy_max_hp,
			_combat_system.enemy_mana,
			_combat_system.current_enemy.max_mana
		)
	else:
		_on_enemy_cleared()


func _refresh_all() -> void:
	if GameManager.is_afk_mode:
		afk_toggle_button.text = "🌙 AFK (вкл)"
		return
	_last_hp_bar_str = ""
	_last_mp_bar_str = ""
	_last_enemy_hp_str = ""
	_last_enemy_mp_str = ""
	_refresh_hud()
	_refresh_companion_slot()
	_refresh_difficulty_chip()
	_refresh_magic_summary()
	_refresh_active_buffs()
	_refresh_wave_dungeon_banner()
	_on_player_hp_changed(GameManager.current_hp, GameManager.get_max_hp())
	_on_player_mana_changed(GameManager.current_mana, GameManager.get_max_mana())
	_on_player_barrier_changed(GameManager.current_barrier, GameManager.get_max_barrier())
	afk_toggle_button.text = "🌙 AFK"
	if GameManager.current_location != null:
		_on_location_changed(GameManager.current_location)
	if _combat_system != null:
		_on_battle_search_changed(_combat_system.is_seeking_battle)
		_on_combat_state_changed(int(_combat_system.current_state))
		if _combat_system.current_enemy != null:
			_on_enemy_spawned(
				_combat_system.current_enemy,
				_combat_system.enemy_hp,
				_combat_system.enemy_max_hp,
				_combat_system.enemy_mana,
				_combat_system.current_enemy.max_mana
			)
		else:
			_on_enemy_cleared()
	else:
		_on_battle_search_changed(false)
		_on_enemy_cleared()


func _refresh_hud() -> void:
	_hud_refresh_queued = false
	if GameManager.is_afk_mode:
		return
	level_label.text = "Lv. %d" % GameManager.level
	var xp_req: float = GameManager.get_xp_to_next_level()
	xp_bar.max_value = xp_req
	xp_bar.value = GameManager.current_xp
	xp_label.text = "%s / %s" % [
		NumberFormatter.format_number(GameManager.current_xp),
		NumberFormatter.format_number(xp_req),
	]

	var total_str: int = GameManager.get_total_strength()
	var total_agi: int = GameManager.get_total_agility()
	var total_end: int = GameManager.get_total_endurance()
	var total_int: int = GameManager.get_total_intellect()

	str_badge_label.text = "⚔️\n%d" % total_str
	agi_badge_label.text = "⚡\n%d" % total_agi
	end_badge_label.text = "🛡️\n%d" % total_end
	int_badge_label.text = "🧠\n%d" % total_int

	if GameManager.is_equipment_disabled():
		var hc: HeroClassData = GameManager.get_current_class()
		player_emoji_label.text = hc.icon_emoji if hc != null else "🌿"
	elif GameManager.has_hero_class("reflector"):
		player_emoji_label.text = "🪞"
	elif GameManager.equipped_weapon != null:
		player_emoji_label.text = GameManager.equipped_weapon.icon_emoji
	else:
		var hc: HeroClassData = GameManager.get_current_class()
		player_emoji_label.text = hc.icon_emoji if (hc != null and hc.id != "wanderer") else "🧙"

	player_attack_diamond.modulate = Color(0.55, 0.72, 0.85, 0.25) if GameManager.has_hero_class("reflector") else Color.WHITE

	if GameManager.is_using_ranged_weapon():
		backpack_button.text = "🏹 %d  🎒" % GameManager.equipped_ammo_count
	elif GameManager.is_using_mage_staff():
		var tome_cnt: String = "♾️" if (GameManager.equipped_ammo != null and GameManager.equipped_ammo.is_dark_forged) else str(GameManager.equipped_ammo_count)
		backpack_button.text = "📚 %s  🎒" % tome_cnt
	else:
		backpack_button.text = "РЮКЗАК  🎒"


func _refresh_companion_slot() -> void:
	if companion_slot_button == null:
		return
	var pet: PetData = GameManager.get_equipped_pet()
	if pet != null:
		companion_slot_button.text = "%s %s" % [pet.icon_emoji, pet.pet_name]
		companion_slot_button.tooltip_text = "%s %s (без HP): %s" % [pet.icon_emoji, pet.pet_name, pet.description]
		companion_slot_button.modulate = Color.WHITE
	else:
		companion_slot_button.text = "🐾 Путник: [Пусто]"
		companion_slot_button.tooltip_text = "Слот Путника (бессмертный питомец без HP). Нажмите, чтобы выбрать."
		companion_slot_button.modulate = Color(0.82, 0.86, 0.92, 0.88)


func _refresh_difficulty_chip() -> void:
	var curses: Array[Dictionary] = GameManager.get_active_curses()
	if curses.is_empty():
		difficulty_chip_button.text = "💀 Сл.%d" % GameManager.difficulty_level
	else:
		difficulty_chip_button.text = "💀 Сл.%d (☠️%d)" % [GameManager.difficulty_level, curses.size()]


func _refresh_magic_summary() -> void:
	var auto_count: int = 0
	var equipped_count: int = 0
	for i: int in range(GameManager.abilities.size()):
		if GameManager.abilities[i] != null:
			equipped_count += 1
			if GameManager.is_ability_auto_cast(i):
				auto_count += 1
	magic_status_label.text = "✨\n%d/%d" % [auto_count, equipped_count]


func _refresh_active_buffs() -> void:
	if GameManager.is_afk_mode or active_buffs_label == null:
		return
	if GameManager.active_buffs.is_empty():
		active_buffs_label.text = ""
		return
	var parts: Array[String] = []
	for b: Dictionary in GameManager.active_buffs:
		var rem: float = maxf(0.0, float(b.get("remaining", 0.0)))
		if rem > 0.0:
			parts.append("%s%.0fс" % [str(b.get("icon_emoji", "✨")), ceil(rem)])
	active_buffs_label.text = " ".join(parts)


func _refresh_wave_dungeon_banner() -> void:
	if wave_dungeon_label == null:
		return
	wave_dungeon_label.visible = GameManager.wave_dungeon_active
	if GameManager.wave_dungeon_active:
		wave_dungeon_label.text = "🏰 Данж волн: %d / %d" % [GameManager.wave_dungeon_wave, GameManager.WAVE_DUNGEON_TOTAL_WAVES]


func _on_battle_search_pressed() -> void:
	if _combat_system != null:
		_combat_system.toggle_battle_search()
	if _search_btn_tween != null and _search_btn_tween.is_valid():
		_search_btn_tween.kill()
	battle_search_button.scale = Vector2(0.9, 0.9)
	var tween: Tween = create_tween()
	tween.tween_property(battle_search_button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_search_btn_tween = tween


func _on_battle_search_changed(is_seeking: bool) -> void:
	if is_seeking:
		battle_search_button.text = "🏳️"
		battle_search_caption.text = "ОТСТУПИТЬ"
	else:
		battle_search_button.text = "⚔️"
		battle_search_caption.text = "ПОИСК БОЯ"


func _on_ability_manual_cast(slot_index: int) -> void:
	if _combat_system != null:
		_combat_system.try_cast_ability(slot_index, false)


func _on_ability_auto_toggled(slot_index: int) -> void:
	GameManager.toggle_ability_auto_cast(slot_index)


func _on_ability_casted(_slot_index: int, ability: AbilityData) -> void:
	if ability == null or GameManager.is_afk_mode:
		return
	if ability.effect_type == "heal":
		_spawn_floating_text(player_avatar_stage, "%s %s!" % [ability.icon_emoji, ability.title], Color(0.45, 0.96, 0.65, 1.0))
	elif ability.effect_type == "buff":
		_spawn_floating_text(player_avatar_stage, "%s %s!" % [ability.icon_emoji, ability.title], Color(0.96, 0.86, 0.36, 1.0), true)
	elif ability.effect_type == "dot":
		_spawn_floating_text(enemy_avatar_stage, "%s %s!" % [ability.icon_emoji, ability.title], Color(0.75, 0.92, 0.36, 1.0))
	elif ability.effect_type == "overcharge_burn":
		_spawn_floating_text(player_avatar_stage, "%s ПЕРЕГРУЗКА!" % ability.icon_emoji, Color(1.0, 0.52, 0.25, 1.0), true)
	else:
		_play_attack_animation(true, 18.0)
		_spawn_floating_text(player_avatar_stage, "%s %s!" % [ability.icon_emoji, ability.title], Color(0.55, 0.85, 1.0, 1.0))


func _on_overcharge_state_changed(is_active: bool, slot_idx: int, tick_num: int) -> void:
	var slots: Array[AbilitySlotButtonScript] = [ability_slot_0, ability_slot_1, ability_slot_2]
	for i: int in range(slots.size()):
		if is_active and i == slot_idx:
			slots[i].set_overcharge_tick(tick_num)
		else:
			slots[i].set_overcharge_tick(0)


func _on_overcharge_tick_fired(tick_num: int, hp_burn: float, mana_burn: float, damage: float) -> void:
	if GameManager.is_afk_mode:
		return
	_play_attack_animation(true, 16.0)
	_play_hit_reaction(false)
	_spawn_floating_text(
		player_avatar_stage,
		"🌋 Т%d: -%.0fHP / -%.0fMP" % [tick_num, hp_burn, mana_burn],
		Color(1.0, 0.56, 0.26, 1.0)
	)
	_spawn_floating_text(
		enemy_avatar_stage,
		"🌋 -%s!" % NumberFormatter.format_number(damage),
		Color(1.0, 0.68, 0.22, 1.0),
		true
	)


func _on_dot_tick_landed(emoji: String, _title: String, damage: float) -> void:
	if GameManager.is_afk_mode:
		return
	_spawn_floating_text(
		enemy_avatar_stage,
		"%s -%s" % [emoji, NumberFormatter.format_number(damage)],
		Color(0.72, 0.94, 0.42, 1.0)
	)


func _on_final_boss_cleared(dark_points_gained: int, unlocked_difficulty: int) -> void:
	if GameManager.is_afk_mode:
		return
	var coins_gained: int = maxi(1, GameManager.difficulty_level)
	var msg: String = ""
	if dark_points_gained > 0:
		msg = "🌑 +%d 🌑  |  🪙 +%d Тёмного магазина! Сл.%d открыта!" % [dark_points_gained, coins_gained, unlocked_difficulty]
	else:
		msg = "👑 Титан повержен! 🪙 +%d Тёмного магазина (🌑 за Сл.%d уже получены)" % [coins_gained, GameManager.difficulty_level]
	_spawn_floating_text(
		player_avatar_stage,
		msg,
		Color(0.84, 0.56, 1.0, 1.0),
		true
	)


func _on_curse_warden_defeated(tokens_total: int, kills_in_run: int) -> void:
	if GameManager.is_afk_mode:
		return
	_spawn_floating_text(
		player_avatar_stage,
		"🎲 +1 Реролл (Всего: %d, Убийств: %d)" % [tokens_total, kills_in_run],
		Color(0.42, 0.94, 0.98, 1.0),
		true
	)


func _on_mastery_changed(skill_id: String, new_level: int, leveled_up: bool) -> void:
	if not leveled_up or GameManager.is_afk_mode:
		return
	var label_name: String = "⚔️ Ближний бой"
	if skill_id == "ranged":
		label_name = "🏹 Дальний бой"
	elif skill_id == "magic":
		label_name = "✨ Магия"
	_spawn_floating_text(
		player_avatar_stage,
		"📘 %s Ур.%d!" % [label_name, new_level],
		Color(0.62, 0.88, 1.0, 1.0),
		true
	)


func _on_player_hp_changed(current_hp: float, max_hp: float) -> void:
	if GameManager.is_afk_mode:
		return
	var pct: int = clampi(roundi((current_hp / maxf(1.0, max_hp)) * 100.0), 0, 100)
	var cur_str: String = NumberFormatter.format_number(ceil(current_hp))
	var max_str: String = NumberFormatter.format_number(maxf(1.0, max_hp))
	var barrier_note: String = " [🛡️%s]" % NumberFormatter.format_number(ceil(GameManager.current_barrier)) if GameManager.current_barrier > 0.5 else ""
	var full_str: String = "%s / %s (%d%%)%s" % [cur_str, max_str, pct, barrier_note]

	player_hp_bar.max_value = max_hp
	player_hp_bar.value = current_hp
	hero_crest_hp_bar.max_value = max_hp
	hero_crest_hp_bar.value = current_hp

	if full_str != _last_hp_bar_str:
		_last_hp_bar_str = full_str
		player_hp_bar_label.text = full_str
		hero_crest_hp_label.text = "%s/%s" % [cur_str, max_str]
		crest_red_label.text = "❤️ %s" % cur_str


func _on_player_barrier_changed(current_barrier: float, max_barrier: float) -> void:
	if GameManager.is_afk_mode:
		return
	if player_barrier_bar != null:
		var bar_cap: float = maxf(max_barrier, GameManager.get_max_hp())
		player_barrier_bar.visible = current_barrier > 0.5
		player_barrier_bar.max_value = maxf(1.0, bar_cap)
		player_barrier_bar.value = clampf(current_barrier, 0.0, bar_cap)
	_on_player_hp_changed(GameManager.current_hp, GameManager.get_max_hp())


func _on_player_mana_changed(current_mana: float, max_mana: float) -> void:
	if GameManager.is_afk_mode:
		return
	var has_mana: bool = max_mana > 0.0
	player_mana_bar.visible = has_mana
	if not has_mana:
		if _last_mp_bar_str != "0":
			_last_mp_bar_str = "0"
			crest_blue_label.text = "💧 0"
		return
	var pct: int = clampi(roundi((current_mana / maxf(1.0, max_mana)) * 100.0), 0, 100)
	var cur_str: String = NumberFormatter.format_number(floor(current_mana))
	var max_str: String = NumberFormatter.format_number(maxf(1.0, max_mana))
	var full_str: String = "%s / %s (%d%%)" % [cur_str, max_str, pct]

	player_mana_bar.max_value = max_mana
	player_mana_bar.value = current_mana
	if full_str != _last_mp_bar_str:
		_last_mp_bar_str = full_str
		player_mana_bar_label.text = full_str
		crest_blue_label.text = "💧 %s" % cur_str


func _on_player_healed(amount: float) -> void:
	if amount <= 0.0 or GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	_spawn_floating_text(player_avatar_stage, "+%s HP" % NumberFormatter.format_number(amount), Color(0.32, 0.92, 0.56, 1.0))


func _on_enemy_spawned(enemy: EnemyData, current_hp: float, max_hp: float, current_mana: float, max_mana: float) -> void:
	enemy_fighter.visible = true
	_enemy_shred_stacks = 0
	_enemy_stun_remaining = 0.0
	_base_enemy_name = enemy.enemy_name
	if enemy.id == GameManager.CURSE_WARDEN_ID and GameManager.reroll_boss_kills_in_run > 0:
		_base_enemy_name = "%s [Ур.+%d]" % [enemy.enemy_name, GameManager.reroll_boss_kills_in_run]
	_update_enemy_name_label()
	enemy_emoji_label.text = enemy.icon_emoji
	_last_enemy_hp_str = ""
	_last_enemy_mp_str = ""

	if _enemy_avatar_style != null:
		_enemy_avatar_style.border_color = enemy.sprite_color
		var bg: Color = enemy.sprite_color.darkened(0.68)
		bg.a = 0.72
		_enemy_avatar_style.bg_color = bg

	_on_enemy_hp_changed(current_hp, max_hp)
	_on_enemy_mana_changed(current_mana, max_mana)

	_last_enemy_anim_ms = 0
	if not GameManager.is_afk_mode:
		_play_enemy_spawn_pop()


func _on_enemy_cleared() -> void:
	enemy_fighter.visible = false
	_base_enemy_name = ""
	_enemy_shred_stacks = 0
	_enemy_stun_remaining = 0.0
	enemy_attack_diamond.set_progress(0.0)


func _on_troll_shred_updated(stacks: int) -> void:
	_enemy_shred_stacks = stacks
	_update_enemy_name_label()


func _on_enemy_stun_changed(remaining_seconds: float) -> void:
	_enemy_stun_remaining = remaining_seconds
	_update_enemy_name_label()


func _on_pet_action_performed(pet_emoji: String, text_value: String, color: Color) -> void:
	if GameManager.is_afk_mode:
		return
	var target_stage: Control = enemy_avatar_stage if pet_emoji == "🎆" else player_avatar_stage
	_spawn_floating_text(target_stage, text_value, color, true)


func _update_enemy_name_label() -> void:
	if _base_enemy_name.is_empty():
		return
	var label_txt: String = _base_enemy_name
	if _enemy_shred_stacks > 0:
		label_txt += " [🦴-%d]" % _enemy_shred_stacks
	if _enemy_stun_remaining > 0.05:
		label_txt += " [💫%.1fс]" % _enemy_stun_remaining
	enemy_name_label.text = label_txt


func _on_enemy_hp_changed(current_hp: float, max_hp: float) -> void:
	if GameManager.is_afk_mode:
		return
	var pct: int = clampi(roundi((current_hp / maxf(1.0, max_hp)) * 100.0), 0, 100)
	var hp_str: String = "%s / %s (%d%%)" % [
		NumberFormatter.format_number(ceil(current_hp)),
		NumberFormatter.format_number(maxf(1.0, max_hp)),
		pct,
	]
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = current_hp
	if hp_str != _last_enemy_hp_str:
		_last_enemy_hp_str = hp_str
		enemy_hp_bar_label.text = hp_str


func _on_enemy_mana_changed(current_mana: float, max_mana: float) -> void:
	if GameManager.is_afk_mode:
		return
	var has_mana: bool = max_mana > 0.0
	enemy_mana_bar.visible = has_mana
	if not has_mana:
		return
	var pct: int = clampi(roundi((current_mana / maxf(1.0, max_mana)) * 100.0), 0, 100)
	var mp_str: String = "%s / %s (%d%%)" % [
		NumberFormatter.format_number(floor(current_mana)),
		NumberFormatter.format_number(maxf(1.0, max_mana)),
		pct,
	]
	enemy_mana_bar.max_value = max_mana
	enemy_mana_bar.value = current_mana
	if mp_str != _last_enemy_mp_str:
		_last_enemy_mp_str = mp_str
		enemy_mana_bar_label.text = mp_str


func _on_attack_progress_updated(player_progress: float, enemy_progress: float) -> void:
	if GameManager.is_afk_mode:
		return
	player_attack_diamond.set_progress(player_progress)
	enemy_attack_diamond.set_progress(enemy_progress)


func _on_ranged_shot_fired(ammo_emoji: String, has_ammo: bool) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	if has_ammo:
		_spawn_ranged_projectile(ammo_emoji)
	else:
		_spawn_floating_text(player_avatar_stage, "⚠️ Нет снарядов!", Color(0.98, 0.62, 0.32, 1.0))


func _on_spirit_action_performed(spirit_name: String, emoji: String, value: float, is_heal: bool) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	if is_heal:
		_spawn_floating_text(player_avatar_stage, "%s +%s HP" % [emoji, NumberFormatter.format_number(value)], Color(0.45, 0.96, 0.68, 1.0))
	else:
		_play_hit_reaction(false)
		_spawn_floating_text(enemy_avatar_stage, "%s %s -%s" % [emoji, spirit_name, NumberFormatter.format_number(value)], Color(0.55, 0.92, 1.0, 1.0))


func _on_player_attack_landed(damage: float, is_crit: bool) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	_play_attack_animation(true, 22.0)
	_play_hit_reaction(false)
	var dmg_txt: String = NumberFormatter.format_number(damage)
	if is_crit:
		_spawn_floating_text(enemy_avatar_stage, "💥 -%s!" % dmg_txt, Color(1.0, 0.82, 0.22, 1.0), true)
	else:
		_spawn_floating_text(enemy_avatar_stage, "-%s" % dmg_txt, Color(0.98, 0.45, 0.45, 1.0))


func _on_enemy_attack_landed(damage: float, dodged: bool) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	_play_attack_animation(false, -22.0)
	if dodged:
		_spawn_floating_text(player_avatar_stage, "💨 Уклон!", Color(0.98, 0.9, 0.35, 1.0))
		return
	_play_hit_reaction(true)
	_spawn_floating_text(player_avatar_stage, "-%s" % NumberFormatter.format_number(damage), Color(0.98, 0.38, 0.38, 1.0))


func _on_enemy_defeated_reward(xp_earned: float, gold_earned: float) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	_spawn_floating_text(
		enemy_avatar_stage,
		"✨ +%s XP  💰 +%s" % [NumberFormatter.format_number(xp_earned), NumberFormatter.format_number(gold_earned)],
		Color(0.45, 0.95, 0.62, 1.0)
	)


func _spawn_ranged_projectile(emoji: String) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open or player_avatar_stage == null or enemy_avatar_stage == null or _proj_pool.is_empty():
		return
	var slot: Dictionary = _proj_pool[_proj_cursor]
	_proj_cursor = (_proj_cursor + 1) % _proj_pool.size()
	var prev_tween: Tween = slot.get("tween") as Tween
	if prev_tween != null and prev_tween.is_valid():
		prev_tween.kill()
	var proj: Label = slot["label"] as Label
	proj.text = emoji
	var start_pos: Vector2 = player_avatar_stage.global_position + player_avatar_stage.size * 0.45
	var end_pos: Vector2 = enemy_avatar_stage.global_position + enemy_avatar_stage.size * 0.45
	proj.global_position = start_pos
	proj.visible = true

	var tween: Tween = create_tween()
	tween.tween_property(proj, "global_position", end_pos, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: proj.visible = false)
	slot["tween"] = tween


func _play_attack_animation(is_player: bool, offset_x: float) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = _last_player_anim_ms if is_player else _last_enemy_anim_ms
	if last_ms > 0 and (now_ms - last_ms) < AVATAR_TWEEN_MIN_INTERVAL_MS:
		return
	if is_player:
		_last_player_anim_ms = now_ms
	else:
		_last_enemy_anim_ms = now_ms

	var panel: PanelContainer = player_avatar_panel if is_player else enemy_avatar_panel
	var active_tween: Tween = _player_tween if is_player else _enemy_tween
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	panel.position = AVATAR_BASE_POS
	panel.scale = Vector2.ONE
	panel.modulate = Color.WHITE

	var tween: Tween = create_tween()
	tween.tween_property(panel, "position:x", AVATAR_BASE_POS.x + offset_x, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(panel, "position:x", AVATAR_BASE_POS.x, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.14)

	if is_player:
		_player_tween = tween
	else:
		_enemy_tween = tween


func _play_hit_reaction(is_player: bool) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = _last_player_anim_ms if is_player else _last_enemy_anim_ms
	if last_ms > 0 and (now_ms - last_ms) < AVATAR_TWEEN_MIN_INTERVAL_MS:
		return
	if is_player:
		_last_player_anim_ms = now_ms
	else:
		_last_enemy_anim_ms = now_ms

	var panel: PanelContainer = player_avatar_panel if is_player else enemy_avatar_panel
	var active_tween: Tween = _player_tween if is_player else _enemy_tween
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	panel.position = AVATAR_BASE_POS
	panel.scale = Vector2.ONE
	panel.modulate = Color(1.0, 0.48, 0.48, 1.0)

	var tween: Tween = create_tween()
	tween.tween_property(panel, "position:x", AVATAR_BASE_POS.x - 6.0, 0.04)
	tween.tween_property(panel, "position:x", AVATAR_BASE_POS.x + 6.0, 0.05)
	tween.tween_property(panel, "position:x", AVATAR_BASE_POS.x, 0.05)
	tween.parallel().tween_property(panel, "modulate", Color.WHITE, 0.16)

	if is_player:
		_player_tween = tween
	else:
		_enemy_tween = tween


func _play_enemy_spawn_pop() -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	if _enemy_tween != null and _enemy_tween.is_valid():
		_enemy_tween.kill()

	enemy_avatar_panel.position = AVATAR_BASE_POS
	enemy_avatar_panel.modulate = Color(1.0, 1.0, 1.0, 0.2)
	enemy_avatar_panel.scale = Vector2(0.72, 0.72)

	var tween: Tween = create_tween()
	tween.tween_property(enemy_avatar_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(enemy_avatar_panel, "modulate", Color.WHITE, 0.2)
	_enemy_tween = tween


func _spawn_floating_text(stage: Control, text_value: String, color: Color, is_big: bool = false) -> void:
	if stage == null or GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	var is_player_stage: bool = (stage == player_avatar_stage)
	var pool: Array[Dictionary] = _player_popup_pool if is_player_stage else _enemy_popup_pool
	if pool.is_empty():
		return
	var idx: int = _player_popup_cursor if is_player_stage else _enemy_popup_cursor
	if is_player_stage:
		_player_popup_cursor = (_player_popup_cursor + 1) % pool.size()
	else:
		_enemy_popup_cursor = (_enemy_popup_cursor + 1) % pool.size()

	var slot: Dictionary = pool[idx]
	var prev_tween: Tween = slot.get("tween") as Tween
	if prev_tween != null and prev_tween.is_valid():
		prev_tween.kill()

	var popup: Label = slot["label"] as Label
	popup.text = text_value
	popup.position = Vector2(-30.0 + randf_range(-8.0, 8.0), -10.0)
	popup.modulate = Color.WHITE
	var target_size: int = 19 if is_big else 15
	if int(slot.get("last_size", -1)) != target_size:
		slot["last_size"] = target_size
		popup.add_theme_font_size_override("font_size", target_size)
	var prev_color: Color = slot.get("last_color", Color(-1.0, -1.0, -1.0, -1.0)) as Color
	if not prev_color.is_equal_approx(color):
		slot["last_color"] = color
		popup.add_theme_color_override("font_color", color)
	popup.visible = true

	var tween: Tween = create_tween()
	tween.tween_property(popup, "position:y", popup.position.y - 40.0, 0.74).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.74).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: popup.visible = false)
	slot["tween"] = tween


func _on_combat_state_changed(new_state: int) -> void:
	match new_state:
		CombatSystem.State.IDLE:
			state_label.text = "🏕️ ЛАГЕРЬ"
			state_label.modulate = Color(0.78, 0.86, 0.96, 1.0)
		CombatSystem.State.FIGHTING:
			state_label.text = "⚔️ В БОЮ"
			state_label.modulate = Color(0.95, 0.45, 0.45, 1.0)
		CombatSystem.State.RESTING:
			state_label.text = "🏕️ ОТДЫХ (+15%)"
			state_label.modulate = Color(0.35, 0.9, 0.55, 1.0)
		CombatSystem.State.SPAWNING:
			state_label.text = "🔍 ПОИСК..."
			state_label.modulate = Color(0.95, 0.78, 0.35, 1.0)


func _on_location_changed(location: LocationData) -> void:
	match location.id:
		"quiet_glade":
			backdrop_tint.color = Color(0.0, 0.0, 0.0, 0.0)
		"dark_forest":
			backdrop_tint.color = Color(0.03, 0.12, 0.08, 0.36)
		"abandoned_mine":
			backdrop_tint.color = Color(0.08, 0.14, 0.22, 0.56)
		"ancient_ruins":
			backdrop_tint.color = Color(0.12, 0.07, 0.16, 0.44)
		"swamp_marshes":
			backdrop_tint.color = Color(0.04, 0.16, 0.10, 0.46)
		"frost_peaks":
			backdrop_tint.color = Color(0.12, 0.24, 0.38, 0.44)
		"obsidian_citadel":
			backdrop_tint.color = Color(0.16, 0.05, 0.20, 0.54)
		"dragon_lair":
			backdrop_tint.color = Color(0.28, 0.05, 0.03, 0.56)
		"sunken_temple":
			backdrop_tint.color = Color(0.03, 0.16, 0.28, 0.50)
		"astral_spire":
			backdrop_tint.color = Color(0.11, 0.06, 0.28, 0.56)
		"celestial_throne":
			backdrop_tint.color = Color(0.26, 0.20, 0.04, 0.42)
		"abyss_crucible":
			backdrop_tint.color = Color(0.24, 0.04, 0.28, 0.58)
		_:
			backdrop_tint.color = Color(location.background_color.r, location.background_color.g, location.background_color.b, 0.35)


func _on_mine_find_triggered(msg: String) -> void:
	if msg.is_empty() or GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	_spawn_floating_text(player_avatar_stage, msg, Color(0.55, 0.92, 1.0, 1.0), true)


func _on_route_event_triggered(msg: String) -> void:
	if msg.is_empty() or GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	_spawn_floating_text(player_avatar_stage, msg, Color(0.96, 0.86, 0.36, 1.0), true)


func _on_mine_run_failed(depth_reached: int) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	_spawn_floating_text(
		player_avatar_stage,
		"💀 Шахта обрушилась на гл.%d! Новый заход — в новом ране." % depth_reached,
		Color(1.0, 0.42, 0.46, 1.0),
		true
	)


func _on_afk_mode_changed(is_afk: bool) -> void:
	afk_toggle_button.text = "🌙 AFK (вкл)" if is_afk else "🌙 AFK"
	if not is_afk:
		_refresh_all()
