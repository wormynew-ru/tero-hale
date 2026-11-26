extends Control

signal open_menu_requested
signal open_inventory_requested
signal open_difficulty_requested
signal open_pets_requested
signal open_village_requested

const AttackDiamondScript = preload("res://scripts/ui/AttackDiamond.gd")
const ArenaHeroHudScript = preload("res://scripts/ui/arena/ArenaHeroHud.gd")
const ArenaBuffsPanelScript = preload("res://scripts/ui/arena/ArenaBuffsPanel.gd")
const ArenaDamagePopupsScript = preload("res://scripts/ui/arena/ArenaDamagePopups.gd")

@onready var backdrop_tint: ColorRect = %BackdropTint
@onready var hero_hud: ArenaHeroHudScript = %ArenaHeroHud
@onready var buffs_panel: ArenaBuffsPanelScript = %ArenaBuffsPanel
@onready var damage_popups: ArenaDamagePopupsScript = %ArenaDamagePopups

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

@onready var battle_search_button: Button = %BattleSearchButton
@onready var battle_search_caption: Label = %BattleSearchCaption
@onready var backpack_button: Button = %BackpackButton

var _combat_system: CombatSystem = null
var _search_btn_tween: Tween = null
var _base_enemy_name: String = ""
var _enemy_shred_stacks: int = 0
var _enemy_stun_remaining: float = 0.0
var _enemy_pack_alive: int = 1
var _enemy_pack_total: int = 1
var _enemy_avatar_style: StyleBoxFlat = null
var _hud_refresh_queued: bool = false
var _last_hp_bar_str: String = ""
var _last_mp_bar_str: String = ""
var _last_enemy_hp_str: String = ""
var _last_enemy_mp_str: String = ""


func _ready() -> void:
	damage_popups.setup(player_avatar_stage, enemy_avatar_stage, player_avatar_panel, enemy_avatar_panel)
	var base_style: StyleBoxFlat = enemy_avatar_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if base_style != null:
		_enemy_avatar_style = base_style.duplicate() as StyleBoxFlat
		enemy_avatar_panel.add_theme_stylebox_override("panel", _enemy_avatar_style)

	GameManager.stats_changed.connect(_request_hud_refresh)
	GameManager.hp_changed.connect(_on_player_hp_changed)
	GameManager.mana_changed.connect(_on_player_mana_changed)
	GameManager.barrier_changed.connect(_on_player_barrier_changed)
	GameManager.abilities_changed.connect(func() -> void: buffs_panel.refresh_magic_summary())
	GameManager.buffs_changed.connect(func() -> void: buffs_panel.refresh_active_buffs())
	GameManager.difficulty_changed.connect(_refresh_difficulty_chip)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _request_hud_refresh())
	GameManager.pets_changed.connect(_refresh_companion_slot)
	GameManager.location_changed.connect(_on_location_changed)
	GameManager.wave_dungeon_changed.connect(_refresh_wave_dungeon_banner)
	GameManager.afk_mode_changed.connect(_on_afk_mode_changed)
	GameManager.game_reset.connect(_refresh_all)

	hero_hud.open_menu_requested.connect(func() -> void: open_menu_requested.emit())
	buffs_panel.manual_cast_requested.connect(_on_ability_manual_cast)
	buffs_panel.auto_cast_toggled.connect(_on_ability_auto_toggled)
	village_chip_button.pressed.connect(func() -> void: open_village_requested.emit())
	difficulty_chip_button.pressed.connect(func() -> void: open_difficulty_requested.emit())
	companion_slot_button.pressed.connect(func() -> void: open_pets_requested.emit())
	save_button.pressed.connect(func() -> void: GameManager.save_game())
	afk_toggle_button.pressed.connect(func() -> void: GameManager.set_afk_mode(not GameManager.is_afk_mode))
	battle_search_button.pressed.connect(_on_battle_search_pressed)
	backpack_button.pressed.connect(func() -> void: open_inventory_requested.emit())

	_refresh_all()


func _request_hud_refresh() -> void:
	if GameManager.is_afk_mode or _hud_refresh_queued:
		return
	_hud_refresh_queued = true
	call_deferred("_refresh_hud")


func bind_combat_system(combat: CombatSystem) -> void:
	if combat == null or _combat_system == combat:
		return
	_combat_system = combat
	damage_popups.bind_combat_events(combat)
	_combat_system.state_changed.connect(_on_combat_state_changed)
	_combat_system.battle_search_changed.connect(_on_battle_search_changed)
	_combat_system.enemy_spawned.connect(_on_enemy_spawned)
	_combat_system.enemy_pack_changed.connect(_on_enemy_pack_changed)
	_combat_system.enemy_cleared.connect(_on_enemy_cleared)
	_combat_system.enemy_hp_changed.connect(_on_enemy_hp_changed)
	_combat_system.enemy_mana_changed.connect(_on_enemy_mana_changed)
	_combat_system.attack_progress_updated.connect(_on_attack_progress_updated)
	_combat_system.troll_shred_updated.connect(_on_troll_shred_updated)
	_combat_system.enemy_stun_changed.connect(_on_enemy_stun_changed)
	_combat_system.overcharge_state_changed.connect(func(is_act: bool, s_idx: int, t_num: int) -> void: buffs_panel.set_overcharge_state(is_act, s_idx, t_num))

	_on_battle_search_changed(_combat_system.is_seeking_battle)
	_on_combat_state_changed(int(_combat_system.current_state))
	if _combat_system.current_enemy != null and _combat_system.current_state != CombatSystem.State.SPAWNING and _combat_system.enemy_max_hp > 0.0 and _combat_system.get_alive_pack_count() > 0:
		_on_enemy_pack_changed(_combat_system.get_alive_pack_count(), _combat_system.pack_total_count)
		_on_enemy_spawned(_combat_system.current_enemy, _combat_system.enemy_hp, _combat_system.enemy_max_hp, _combat_system.enemy_mana, _combat_system.current_enemy.max_mana)
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
	buffs_panel.refresh_magic_summary()
	buffs_panel.refresh_active_buffs()
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
		if _combat_system.current_enemy != null and _combat_system.current_state != CombatSystem.State.SPAWNING and _combat_system.enemy_max_hp > 0.0 and _combat_system.get_alive_pack_count() > 0:
			_on_enemy_pack_changed(_combat_system.get_alive_pack_count(), _combat_system.pack_total_count)
			_on_enemy_spawned(_combat_system.current_enemy, _combat_system.enemy_hp, _combat_system.enemy_max_hp, _combat_system.enemy_mana, _combat_system.current_enemy.max_mana)
		else:
			_on_enemy_cleared()
	else:
		_on_battle_search_changed(false)
		_on_enemy_cleared()


func _refresh_hud() -> void:
	_hud_refresh_queued = false
	if GameManager.is_afk_mode:
		return
	hero_hud.refresh_stats()
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
	companion_slot_button.text = "%s %s" % [pet.icon_emoji, pet.pet_name] if pet != null else "🐾 Путник: [Пусто]"
	companion_slot_button.tooltip_text = ("%s %s (без HP): %s" % [pet.icon_emoji, pet.pet_name, pet.description]) if pet != null else "Слот Путника (бессмертный питомец без HP). Нажмите, чтобы выбрать."
	companion_slot_button.modulate = Color.WHITE if pet != null else Color(0.82, 0.86, 0.92, 0.88)

func _refresh_difficulty_chip() -> void:
	var curses: Array[Dictionary] = GameManager.get_active_curses()
	difficulty_chip_button.text = ("💀 Сл.%d" % GameManager.difficulty_level) if curses.is_empty() else ("💀 Сл.%d (☠️%d)" % [GameManager.difficulty_level, curses.size()])

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
	_search_btn_tween = create_tween()
	_search_btn_tween.tween_property(battle_search_button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_battle_search_changed(is_seeking: bool) -> void:
	battle_search_button.text = "🏳️" if is_seeking else "⚔️"
	battle_search_caption.text = "ОТСТУПИТЬ" if is_seeking else "ПОИСК БОЯ"

func _on_ability_manual_cast(slot_index: int) -> void:
	if _combat_system != null:
		_combat_system.try_cast_ability(slot_index, false)

func _on_ability_auto_toggled(slot_index: int) -> void:
	GameManager.toggle_ability_auto_cast(slot_index)


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
	var changed: bool = full_str != _last_hp_bar_str
	if changed:
		_last_hp_bar_str = full_str
		player_hp_bar_label.text = full_str
	hero_hud.update_hp(current_hp, max_hp, cur_str, max_str, changed)


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
			hero_hud.update_mana_label(false, "0")
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
		hero_hud.update_mana_label(true, cur_str)


func _on_enemy_spawned(enemy: EnemyData, current_hp: float, max_hp: float, current_mana: float, max_mana: float) -> void:
	enemy_fighter.visible = true
	_enemy_shred_stacks = 0
	_enemy_stun_remaining = 0.0
	_base_enemy_name = "%s [Ур.+%d]" % [enemy.enemy_name, GameManager.reroll_boss_kills_in_run] if (enemy.id == GameManager.CURSE_WARDEN_ID and GameManager.reroll_boss_kills_in_run > 0) else enemy.enemy_name
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
	damage_popups.reset_enemy_anim_timer()
	if not GameManager.is_afk_mode and not GameManager.is_menu_open:
		damage_popups.play_enemy_spawn_pop()


func _on_enemy_cleared() -> void:
	enemy_fighter.visible = false
	_base_enemy_name = ""
	_enemy_shred_stacks = 0
	_enemy_stun_remaining = 0.0
	_enemy_pack_alive = 1
	_enemy_pack_total = 1
	enemy_attack_diamond.set_progress(0.0)


func _on_enemy_pack_changed(alive_count: int, total_count: int) -> void:
	_enemy_pack_alive = alive_count
	_enemy_pack_total = total_count
	_update_enemy_name_label()


func _on_troll_shred_updated(stacks: int) -> void:
	_enemy_shred_stacks = stacks
	_update_enemy_name_label()


func _on_enemy_stun_changed(remaining_seconds: float) -> void:
	_enemy_stun_remaining = remaining_seconds
	_update_enemy_name_label()


func _update_enemy_name_label() -> void:
	if _base_enemy_name.is_empty():
		return
	var label_txt: String = _base_enemy_name
	if _enemy_pack_total > 1:
		label_txt += " [x%d/%d]" % [_enemy_pack_alive, _enemy_pack_total]
	if _enemy_shred_stacks > 0:
		label_txt += " [🦴-%d]" % _enemy_shred_stacks
	if _enemy_stun_remaining > 0.05:
		label_txt += " [💫%.1fс]" % _enemy_stun_remaining
	enemy_name_label.text = label_txt


func _on_enemy_hp_changed(current_hp: float, max_hp: float) -> void:
	if GameManager.is_afk_mode:
		return
	if max_hp <= 0.0:
		enemy_hp_bar.max_value = 1.0
		enemy_hp_bar.value = 0.0
		return
	var pct: int = clampi(roundi((current_hp / max_hp) * 100.0), 0, 100)
	var hp_str: String = "%s / %s (%d%%)" % [NumberFormatter.format_number(ceil(current_hp)), NumberFormatter.format_number(max_hp), pct]
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = clampf(current_hp, 0.0, max_hp)
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
	var mp_str: String = "%s / %s (%d%%)" % [NumberFormatter.format_number(floor(current_mana)), NumberFormatter.format_number(maxf(1.0, max_mana)), pct]
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


func _on_combat_state_changed(new_state: int) -> void:
	var labels: Dictionary = {
		CombatSystem.State.IDLE: ["🏕️ ЛАГЕРЬ", Color(0.78, 0.86, 0.96, 1.0)],
		CombatSystem.State.FIGHTING: ["⚔️ В БОЮ", Color(0.95, 0.45, 0.45, 1.0)],
		CombatSystem.State.RESTING: ["🏕️ ОТДЫХ (+15%)", Color(0.35, 0.9, 0.55, 1.0)],
		CombatSystem.State.SPAWNING: ["🔍 ПОИСК...", Color(0.95, 0.78, 0.35, 1.0)],
	}
	var entry: Array = labels.get(new_state, ["🏕️ ЛАГЕРЬ", Color.WHITE])
	state_label.text = str(entry[0])
	state_label.modulate = entry[1] as Color

func _on_location_changed(location: LocationData) -> void:
	backdrop_tint.color = WorldAndAbilityCatalog.LOCATION_TINTS.get(location.id, Color(location.background_color.r, location.background_color.g, location.background_color.b, 0.35))

func _on_afk_mode_changed(is_afk: bool) -> void:
	afk_toggle_button.text = "🌙 AFK (вкл)" if is_afk else "🌙 AFK"
	if not is_afk:
		_refresh_all()
