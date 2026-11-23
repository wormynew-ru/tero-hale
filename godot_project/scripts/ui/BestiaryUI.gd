extends ScrollContainer

@onready var bestiary_summary_label: Label = %BestiarySummaryLabel
@onready var bestiary_grid: VBoxContainer = %BestiaryGrid

var _enemy_rows: Array[Dictionary] = []
var _dirty: bool = true
var _refresh_queued: bool = false


func _ready() -> void:
	GameManager.bestiary_changed.connect(_on_state_updated)
	GameManager.game_reset.connect(_on_reset)
	_build_pool_once()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and _dirty:
		_refresh()


func _on_reset() -> void:
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


func _build_pool_once() -> void:
	if bestiary_grid == null:
		return
	_enemy_rows.clear()
	for enemy: EnemyData in GameManager.all_enemies:
		if enemy == null:
			continue
		var card: PanelContainer = PanelContainer.new()
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.content_margin_left = 12.0
		sb.content_margin_top = 10.0
		sb.content_margin_right = 12.0
		sb.content_margin_bottom = 10.0
		sb.bg_color = Color(0.11, 0.13, 0.18, 1.0)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.32, 0.36, 0.46, 0.9)
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_right = 8
		sb.corner_radius_bottom_left = 8
		card.add_theme_stylebox_override("panel", sb)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		card.add_child(hbox)

		var icon_lbl: Label = Label.new()
		icon_lbl.custom_minimum_size = Vector2(44.0, 44.0)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 26)
		icon_lbl.text = enemy.icon_emoji
		hbox.add_child(icon_lbl)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 3)
		hbox.add_child(info_vbox)

		var title_lbl: Label = Label.new()
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.text = "%s%s" % [enemy.display_name, " [БОСС]" if enemy.is_boss else ""]
		info_vbox.add_child(title_lbl)

		var bonus_lbl: Label = Label.new()
		bonus_lbl.add_theme_font_size_override("font_size", 12)
		bonus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(bonus_lbl)

		var kills_lbl: Label = Label.new()
		kills_lbl.custom_minimum_size = Vector2(160.0, 0.0)
		kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		kills_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		kills_lbl.add_theme_font_size_override("font_size", 14)
		hbox.add_child(kills_lbl)

		bestiary_grid.add_child(card)
		_enemy_rows.append({
			"enemy": enemy,
			"style": sb,
			"title_lbl": title_lbl,
			"bonus_lbl": bonus_lbl,
			"kills_lbl": kills_lbl,
		})


func _refresh() -> void:
	_dirty = false
	var total_kills: int = 0
	var mastered_tiers: int = 0
	var max_tiers: int = _enemy_rows.size() * GameManager.BESTIARY_MILESTONES.size()

	for row: Dictionary in _enemy_rows:
		var enemy: EnemyData = row["enemy"] as EnemyData
		var sb: StyleBoxFlat = row["style"] as StyleBoxFlat
		var bonus_lbl: Label = row["bonus_lbl"] as Label
		var kills_lbl: Label = row["kills_lbl"] as Label
		if enemy == null:
			continue

		var eid: String = enemy.id
		var kills: int = GameManager.get_bestiary_kills(eid)
		total_kills += kills

		var dmg_pct: int = roundi((GameManager.get_bestiary_damage_bonus(eid) - 1.0) * 100.0)
		var gold_pct: int = roundi((GameManager.get_bestiary_gold_bonus(eid) - 1.0) * 100.0)
		var drop_pct: int = roundi((GameManager.get_bestiary_drop_bonus(eid) - 1.0) * 100.0)

		var tier_count: int = 0
		var next_milestone: int = -1
		for m: Dictionary in GameManager.BESTIARY_MILESTONES:
			var req_kills: int = int(m.get("kills", 100))
			if kills >= req_kills:
				tier_count += 1
				mastered_tiers += 1
			elif next_milestone < 0:
				next_milestone = req_kills

		if tier_count >= 3:
			sb.border_color = Color(0.98, 0.82, 0.34, 0.95)
			sb.bg_color = Color(0.14, 0.14, 0.10, 1.0)
		elif tier_count > 0:
			sb.border_color = Color(0.45, 0.86, 0.68, 0.9)
			sb.bg_color = Color(0.11, 0.14, 0.15, 1.0)
		else:
			sb.border_color = Color(0.32, 0.36, 0.46, 0.85)
			sb.bg_color = Color(0.11, 0.13, 0.18, 1.0)

		var bonus_parts: Array[String] = []
		if dmg_pct > 0:
			bonus_parts.append("+%d%% урона" % dmg_pct)
		if gold_pct > 0:
			bonus_parts.append("+%d%% золота" % gold_pct)
		if drop_pct > 0:
			bonus_parts.append("+%d%% дропа" % drop_pct)

		if bonus_parts.is_empty():
			bonus_lbl.text = "Вехи: 100 (+2% урона) • 1 000 (+6% ур., +3% золота) • 10 000 (+11% ур., +10% дропа)"
			bonus_lbl.modulate = Color(0.66, 0.72, 0.82, 1.0)
		else:
			bonus_lbl.text = "Активные вехи (%d/3): %s" % [tier_count, ", ".join(bonus_parts)]
			bonus_lbl.modulate = Color(0.55, 0.96, 0.72, 1.0)

		if next_milestone > 0:
			kills_lbl.text = "💀 %s / %s" % [
				NumberFormatter.format_number(float(kills)),
				NumberFormatter.format_number(float(next_milestone)),
			]
			kills_lbl.modulate = Color(0.86, 0.9, 0.98, 1.0)
		else:
			kills_lbl.text = "🏆 %s (МАКС)" % NumberFormatter.format_number(float(kills))
			kills_lbl.modulate = Color(0.98, 0.85, 0.36, 1.0)

	bestiary_summary_label.text = (
		"📖 Вечный бестиарий (%d видов  |  Открыто вех: %d/%d  |  Всего убийств в базе: %s)\n"
		+ "Награды сохраняются НАВСЕГДА между ранами: 100 уб. (+2%% ур.), 1 000 (+4%% ур. и +3%% золота), 10 000 (+5%% ур. и +10%% шанса дропа)."
	) % [
		_enemy_rows.size(),
		mastered_tiers,
		max_tiers,
		NumberFormatter.format_number(float(total_kills)),
	]
