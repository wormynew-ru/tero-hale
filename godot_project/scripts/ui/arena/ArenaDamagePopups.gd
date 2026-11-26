class_name ArenaDamagePopups
extends Control

const AVATAR_BASE_POS: Vector2 = Vector2(2.0, 2.0)
const AVATAR_TWEEN_MIN_INTERVAL_MS: int = 90

var _player_stage: Control = null
var _enemy_stage: Control = null
var _player_panel: PanelContainer = null
var _enemy_panel: PanelContainer = null

var _player_tween: Tween = null
var _enemy_tween: Tween = null
var _player_popup_pool: Array[Dictionary] = []
var _enemy_popup_pool: Array[Dictionary] = []
var _proj_pool: Array[Dictionary] = []
var _player_popup_cursor: int = 0
var _enemy_popup_cursor: int = 0
var _proj_cursor: int = 0
var _last_player_anim_ms: int = 0
var _last_enemy_anim_ms: int = 0
var _pools_ready: bool = false
var _bound_combat: CombatSystem = null


func setup(p_stage: Control, e_stage: Control, p_panel: PanelContainer, e_panel: PanelContainer) -> void:
	_player_stage = p_stage
	_enemy_stage = e_stage
	_player_panel = p_panel
	_enemy_panel = e_panel
	if _pools_ready:
		return
	_pools_ready = true
	for _i: int in range(10):
		_player_popup_pool.append(_create_popup_slot(_player_stage))
		_enemy_popup_pool.append(_create_popup_slot(_enemy_stage))
	for _i: int in range(6):
		var proj: Label = Label.new()
		proj.mouse_filter = Control.MOUSE_FILTER_IGNORE
		proj.z_index = 12
		proj.visible = false
		proj.add_theme_font_size_override("font_size", 26)
		add_child(proj)
		_proj_pool.append({"label": proj, "tween": null})

	GameManager.player_healed.connect(_on_player_healed)
	GameManager.final_boss_cleared.connect(_on_final_boss_cleared)
	GameManager.curse_warden_defeated.connect(_on_curse_warden_defeated)
	GameManager.mastery_changed.connect(_on_mastery_changed)
	GameManager.mine_run_failed.connect(_on_mine_run_failed)


func bind_combat_events(combat: CombatSystem) -> void:
	if combat == null or _bound_combat == combat:
		return
	_bound_combat = combat
	combat.player_attack_landed.connect(_on_player_attack_landed)
	combat.ranged_shot_fired.connect(_on_ranged_shot_fired)
	combat.spirit_action_performed.connect(_on_spirit_action_performed)
	combat.enemy_attack_landed.connect(_on_enemy_attack_landed)
	combat.enemy_defeated_reward.connect(_on_enemy_defeated_reward)
	combat.ability_casted.connect(_on_ability_casted)
	combat.overcharge_tick_fired.connect(_on_overcharge_tick_fired)
	combat.dot_tick_landed.connect(_on_dot_tick_landed)
	combat.pet_action_performed.connect(_on_pet_action_performed)
	combat.mine_find_triggered.connect(_on_mine_find_triggered)
	combat.route_event_triggered.connect(_on_route_event_triggered)


func reset_enemy_anim_timer() -> void:
	_last_enemy_anim_ms = 0


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


func spawn_ranged_projectile(emoji: String) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open or _player_stage == null or _enemy_stage == null or _proj_pool.is_empty():
		return
	var slot: Dictionary = _proj_pool[_proj_cursor]
	_proj_cursor = (_proj_cursor + 1) % _proj_pool.size()
	var prev_tween: Tween = slot.get("tween") as Tween
	if prev_tween != null and prev_tween.is_valid():
		prev_tween.kill()
	var proj: Label = slot["label"] as Label
	proj.text = emoji
	var start_pos: Vector2 = _player_stage.global_position + _player_stage.size * 0.45
	var end_pos: Vector2 = _enemy_stage.global_position + _enemy_stage.size * 0.45
	proj.global_position = start_pos
	proj.visible = true

	var tween: Tween = create_tween()
	tween.tween_property(proj, "global_position", end_pos, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: proj.visible = false)
	slot["tween"] = tween


func play_attack_animation(is_player: bool, offset_x: float) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	var panel: PanelContainer = _player_panel if is_player else _enemy_panel
	if panel == null:
		return
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = _last_player_anim_ms if is_player else _last_enemy_anim_ms
	if last_ms > 0 and (now_ms - last_ms) < AVATAR_TWEEN_MIN_INTERVAL_MS:
		return
	if is_player:
		_last_player_anim_ms = now_ms
	else:
		_last_enemy_anim_ms = now_ms

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


func play_hit_reaction(is_player: bool) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	var panel: PanelContainer = _player_panel if is_player else _enemy_panel
	if panel == null:
		return
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = _last_player_anim_ms if is_player else _last_enemy_anim_ms
	if last_ms > 0 and (now_ms - last_ms) < AVATAR_TWEEN_MIN_INTERVAL_MS:
		return
	if is_player:
		_last_player_anim_ms = now_ms
	else:
		_last_enemy_anim_ms = now_ms

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


func play_enemy_spawn_pop() -> void:
	if _enemy_panel == null or GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	if _enemy_tween != null and _enemy_tween.is_valid():
		_enemy_tween.kill()

	_enemy_panel.position = AVATAR_BASE_POS
	_enemy_panel.modulate = Color(1.0, 1.0, 1.0, 0.2)
	_enemy_panel.scale = Vector2(0.72, 0.72)

	var tween: Tween = create_tween()
	tween.tween_property(_enemy_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_enemy_panel, "modulate", Color.WHITE, 0.2)
	_enemy_tween = tween


func spawn_floating_text(is_player_stage: bool, text_value: String, color: Color, is_big: bool = false) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	var stage: Control = _player_stage if is_player_stage else _enemy_stage
	if stage == null:
		return
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


func _on_ability_casted(_slot_index: int, ability: AbilityData) -> void:
	if ability == null or GameManager.is_afk_mode:
		return
	if ability.effect_type == "heal":
		spawn_floating_text(true, "%s %s!" % [ability.icon_emoji, ability.title], Color(0.45, 0.96, 0.65, 1.0))
	elif ability.effect_type == "buff":
		spawn_floating_text(true, "%s %s!" % [ability.icon_emoji, ability.title], Color(0.96, 0.86, 0.36, 1.0), true)
	elif ability.effect_type == "dot":
		spawn_floating_text(false, "%s %s!" % [ability.icon_emoji, ability.title], Color(0.75, 0.92, 0.36, 1.0))
	elif ability.effect_type == "overcharge_burn":
		spawn_floating_text(true, "%s ПЕРЕГРУЗКА!" % ability.icon_emoji, Color(1.0, 0.52, 0.25, 1.0), true)
	else:
		play_attack_animation(true, 18.0)
		spawn_floating_text(true, "%s %s!" % [ability.icon_emoji, ability.title], Color(0.55, 0.85, 1.0, 1.0))


func _on_overcharge_tick_fired(tick_num: int, hp_burn: float, mana_burn: float, damage: float) -> void:
	if GameManager.is_afk_mode:
		return
	play_attack_animation(true, 16.0)
	play_hit_reaction(false)
	spawn_floating_text(true, "🌋 Т%d: -%.0fHP / -%.0fMP" % [tick_num, hp_burn, mana_burn], Color(1.0, 0.56, 0.26, 1.0))
	spawn_floating_text(false, "🌋 -%s!" % NumberFormatter.format_number(damage), Color(1.0, 0.68, 0.22, 1.0), true)


func _on_dot_tick_landed(emoji: String, _title: String, damage: float) -> void:
	if not GameManager.is_afk_mode:
		spawn_floating_text(false, "%s -%s" % [emoji, NumberFormatter.format_number(damage)], Color(0.72, 0.94, 0.42, 1.0))


func _on_final_boss_cleared(dark_points_gained: int, unlocked_difficulty: int) -> void:
	if GameManager.is_afk_mode:
		return
	var coins_gained: int = maxi(1, GameManager.difficulty_level)
	var msg: String = (
		"🌑 +%d 🌑  |  🪙 +%d Тёмного магазина! Сл.%d открыта!" % [dark_points_gained, coins_gained, unlocked_difficulty]
		if dark_points_gained > 0
		else "👑 Титан повержен! 🪙 +%d Тёмного магазина (🌑 за Сл.%d уже получены)" % [coins_gained, GameManager.difficulty_level]
	)
	spawn_floating_text(true, msg, Color(0.84, 0.56, 1.0, 1.0), true)


func _on_curse_warden_defeated(tokens_total: int, kills_in_run: int) -> void:
	if not GameManager.is_afk_mode:
		spawn_floating_text(true, "🎲 +1 Реролл (Всего: %d, Убийств: %d)" % [tokens_total, kills_in_run], Color(0.42, 0.94, 0.98, 1.0), true)


func _on_mastery_changed(skill_id: String, new_level: int, leveled_up: bool) -> void:
	if not leveled_up or GameManager.is_afk_mode:
		return
	var label_name: String = "⚔️ Ближний бой"
	if skill_id == "ranged":
		label_name = "🏹 Дальний бой"
	elif skill_id == "magic":
		label_name = "✨ Магия"
	spawn_floating_text(true, "📘 %s Ур.%d!" % [label_name, new_level], Color(0.62, 0.88, 1.0, 1.0), true)


func _on_player_healed(amount: float) -> void:
	if amount > 0.0:
		spawn_floating_text(true, "+%s HP" % NumberFormatter.format_number(amount), Color(0.32, 0.92, 0.56, 1.0))


func _on_pet_action_performed(pet_emoji: String, text_value: String, color: Color) -> void:
	if not GameManager.is_afk_mode:
		spawn_floating_text(pet_emoji != "🎆", text_value, color, true)


func _on_ranged_shot_fired(ammo_emoji: String, has_ammo: bool) -> void:
	if has_ammo:
		spawn_ranged_projectile(ammo_emoji)
	else:
		spawn_floating_text(true, "⚠️ Нет снарядов!", Color(0.98, 0.62, 0.32, 1.0))


func _on_spirit_action_performed(spirit_name: String, emoji: String, value: float, is_heal: bool) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	if is_heal:
		spawn_floating_text(true, "%s +%s HP" % [emoji, NumberFormatter.format_number(value)], Color(0.45, 0.96, 0.68, 1.0))
	else:
		play_hit_reaction(false)
		spawn_floating_text(false, "%s %s -%s" % [emoji, spirit_name, NumberFormatter.format_number(value)], Color(0.55, 0.92, 1.0, 1.0))


func _on_player_attack_landed(damage: float, is_crit: bool) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	play_attack_animation(true, 22.0)
	play_hit_reaction(false)
	var dmg_txt: String = NumberFormatter.format_number(damage)
	if is_crit:
		spawn_floating_text(false, "💥 -%s!" % dmg_txt, Color(1.0, 0.82, 0.22, 1.0), true)
	else:
		spawn_floating_text(false, "-%s" % dmg_txt, Color(0.98, 0.45, 0.45, 1.0))


func _on_enemy_attack_landed(damage: float, dodged: bool) -> void:
	if GameManager.is_afk_mode or GameManager.is_menu_open:
		return
	play_attack_animation(false, -22.0)
	if dodged:
		spawn_floating_text(true, "💨 Уклон!", Color(0.98, 0.9, 0.35, 1.0))
		return
	play_hit_reaction(true)
	spawn_floating_text(true, "-%s" % NumberFormatter.format_number(damage), Color(0.98, 0.38, 0.38, 1.0))


func _on_enemy_defeated_reward(xp_earned: float, gold_earned: float) -> void:
	spawn_floating_text(false, "✨ +%s XP  💰 +%s" % [NumberFormatter.format_number(xp_earned), NumberFormatter.format_number(gold_earned)], Color(0.45, 0.95, 0.62, 1.0))


func _on_mine_find_triggered(msg: String) -> void:
	if not msg.is_empty():
		spawn_floating_text(true, msg, Color(0.55, 0.92, 1.0, 1.0), true)


func _on_route_event_triggered(msg: String) -> void:
	if not msg.is_empty():
		spawn_floating_text(true, msg, Color(0.96, 0.86, 0.36, 1.0), true)


func _on_mine_run_failed(depth_reached: int) -> void:
	spawn_floating_text(true, "💀 Шахта обрушилась на гл.%d! Новый заход — в новом ране." % depth_reached, Color(1.0, 0.42, 0.46, 1.0), true)
