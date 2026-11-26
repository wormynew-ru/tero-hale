extends PanelContainer

@onready var location_title_label: Label = %LocationTitleLabel
@onready var locations_row: VBoxContainer = %LocationsRow
@onready var auto_route_toggle_button: Button = %AutoRouteToggleButton
@onready var auto_route_wins_button: Button = %AutoRouteWinsButton
@onready var auto_diff_button: Button = %AutoDiffButton
@onready var parallel_battle_button: Button = %ParallelBattleButton
@onready var wave_dungeon_button: Button = %WaveDungeonButton
@onready var mine_cp1_button: Button = %MineCp1Button
@onready var mine_cp10_button: Button = %MineCp10Button
@onready var mine_cp25_button: Button = %MineCp25Button
@onready var mine_cp50_button: Button = %MineCp50Button
@onready var sidebar_status_label: Label = %SidebarStatusLabel

@onready var _slot_buttons: Array[Button] = [
	%Slot1Button,
	%Slot2Button,
	%Slot3Button,
	%Slot4Button,
	%Slot5Button,
	%Slot6Button,
]
@onready var _slot_icons: Array[Label] = [
	%Slot1Icon,
	%Slot2Icon,
	%Slot3Icon,
	%Slot4Icon,
	%Slot5Icon,
	%Slot6Icon,
]
@onready var _slot_counts: Array[Label] = [
	%Slot1CountLabel,
	%Slot2CountLabel,
	%Slot3CountLabel,
	%Slot4CountLabel,
	%Slot5CountLabel,
	%Slot6CountLabel,
]
@onready var _slot_labels: Array[Label] = [
	%Slot1Label,
	%Slot2Label,
	%Slot3Label,
	%Slot4Label,
	%Slot5Label,
	%Slot6Label,
]

const AUTO_ROUTE_THRESHOLDS: Array[int] = [3, 5, 10, 20]

var _held_slot_item_ids: Array[String] = ["", "", "", "", "", ""]
var _last_locations_sig: String = ""
var _last_slot_sigs: Array[String] = ["", "", "", "", "", ""]
var _location_buttons: Array[Button] = []
var _location_targets: Array[LocationData] = []
var _refresh_queued: bool = false


func _ready() -> void:
	GameManager.stats_changed.connect(_request_refresh)
	GameManager.inventory_changed.connect(_request_refresh)
	GameManager.location_changed.connect(_on_location_changed)
	GameManager.difficulty_changed.connect(_request_refresh)
	GameManager.parallel_battle_changed.connect(func(_c: int) -> void: _request_refresh())
	GameManager.mine_state_changed.connect(_request_refresh)
	GameManager.wave_dungeon_changed.connect(_request_refresh)
	GameManager.challenge_changed.connect(_request_refresh)
	GameManager.game_reset.connect(_on_reset)

	auto_route_toggle_button.pressed.connect(_on_auto_route_toggle_pressed)
	auto_route_wins_button.pressed.connect(_on_auto_route_wins_pressed)
	auto_diff_button.pressed.connect(_on_auto_diff_pressed)
	parallel_battle_button.pressed.connect(_on_parallel_battle_pressed)
	wave_dungeon_button.pressed.connect(_on_wave_dungeon_pressed)
	mine_cp1_button.pressed.connect(func() -> void: _on_mine_checkpoint_pressed(1))
	mine_cp10_button.pressed.connect(func() -> void: _on_mine_checkpoint_pressed(10))
	mine_cp25_button.pressed.connect(func() -> void: _on_mine_checkpoint_pressed(25))
	mine_cp50_button.pressed.connect(func() -> void: _on_mine_checkpoint_pressed(50))

	for i: int in range(_slot_buttons.size()):
		var slot_idx: int = i
		var btn: Button = _slot_buttons[i]
		btn.button_down.connect(func() -> void: _snapshot_held_slot(slot_idx))
		btn.pressed.connect(func() -> void: _on_slot_pressed(slot_idx))
		HoldAutoClicker.attach(
			btn,
			50.0,
			0.25,
			func() -> bool: return _can_repeat_slot(slot_idx)
		)

	_refresh()
	if GameManager.current_location != null:
		_on_location_changed(GameManager.current_location)


func _on_reset() -> void:
	_last_locations_sig = ""
	_last_slot_sigs = ["", "", "", "", "", ""]
	sidebar_status_label.text = ""
	sidebar_status_label.visible = false
	_refresh_queued = false
	_refresh()


func _snapshot_held_slot(slot_index: int) -> void:
	var item_id: String = ""
	if slot_index >= 0 and slot_index < GameManager.inventory.size():
		var entry: Dictionary = GameManager.inventory[slot_index]
		var item: ItemData = entry["item"] as ItemData
		if item != null and item.item_type == ItemData.ItemType.CONSUMABLE:
			item_id = item.id
	_held_slot_item_ids[slot_index] = item_id


func _can_repeat_slot(slot_index: int) -> bool:
	var expected_id: String = _held_slot_item_ids[slot_index]
	if expected_id.is_empty():
		return false
	if slot_index < 0 or slot_index >= GameManager.inventory.size():
		return false
	var entry: Dictionary = GameManager.inventory[slot_index]
	var item: ItemData = entry["item"] as ItemData
	var cnt: int = int(entry["count"])
	return item != null and cnt > 0 and item.item_type == ItemData.ItemType.CONSUMABLE and item.id == expected_id


func _on_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= GameManager.inventory.size():
		return
	var entry: Dictionary = GameManager.inventory[slot_index]
	var item: ItemData = entry["item"] as ItemData
	if item != null:
		var msg: String = GameManager.use_or_equip_item(item, GameManager.get_entry_quality(entry), GameManager.get_entry_stars(entry))
		if not msg.is_empty():
			_set_sidebar_status(msg)


func _request_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_flush_refresh")


func _flush_refresh() -> void:
	_refresh_queued = false
	_refresh()


func _refresh() -> void:
	_refresh_inventory_slots()
	_rebuild_location_buttons()
	_refresh_expedition_and_route_controls()


func _refresh_inventory_slots() -> void:
	for i: int in range(_slot_buttons.size()):
		var btn: Button = _slot_buttons[i]
		var icon_lbl: Label = _slot_icons[i]
		var count_lbl: Label = _slot_counts[i]
		var name_lbl: Label = _slot_labels[i]

		if i < GameManager.inventory.size():
			var entry: Dictionary = GameManager.inventory[i]
			var item: ItemData = entry["item"] as ItemData
			var count: int = int(entry["count"])
			if item != null:
				var q_pct: int = GameManager.get_entry_quality(entry)
				var s_lvl: int = GameManager.get_entry_stars(entry)
				var slot_sig: String = "%s:%d:%d:%d:%s:%s" % [item.id, count, q_pct, s_lvl, item.icon_emoji, item.item_name]
				if _last_slot_sigs[i] == slot_sig:
					continue
				_last_slot_sigs[i] = slot_sig
				btn.disabled = false
				btn.modulate = Color.WHITE
				icon_lbl.text = item.icon_emoji
				count_lbl.text = "x%d" % count
				name_lbl.text = item.item_name
				continue

		var empty_sig: String = "EMPTY:%d" % i
		if _last_slot_sigs[i] == empty_sig:
			continue
		_last_slot_sigs[i] = empty_sig
		btn.disabled = true
		btn.modulate = Color(0.65, 0.68, 0.72, 0.75)
		icon_lbl.text = "▫️"
		count_lbl.text = ""
		name_lbl.text = "СЛОТ %d\nПусто" % (i + 1)


func _on_location_changed(location: LocationData) -> void:
	if GameManager.wave_dungeon_active:
		location_title_label.text = "🏰 Данж волн (%d/%d)" % [GameManager.wave_dungeon_wave, GameManager.WAVE_DUNGEON_TOTAL_WAVES]
	else:
		location_title_label.text = "%s %s" % [location.icon_emoji, location.location_name]
	_rebuild_location_buttons()
	_refresh_expedition_and_route_controls()


func _on_auto_route_toggle_pressed() -> void:
	GameManager.set_auto_route_settings(not GameManager.auto_route_enabled, GameManager.auto_route_wins_threshold)
	_set_sidebar_status("🧭 Авто-маршрут %s (порог: %d побед)" % ["ВКЛ" if GameManager.auto_route_enabled else "ВЫКЛ", GameManager.auto_route_wins_threshold])


func _on_auto_route_wins_pressed() -> void:
	var cur: int = GameManager.auto_route_wins_threshold
	var next_val: int = AUTO_ROUTE_THRESHOLDS[0]
	for i: int in range(AUTO_ROUTE_THRESHOLDS.size()):
		if AUTO_ROUTE_THRESHOLDS[i] == cur:
			next_val = AUTO_ROUTE_THRESHOLDS[(i + 1) % AUTO_ROUTE_THRESHOLDS.size()]
			break
	GameManager.set_auto_route_settings(GameManager.auto_route_enabled, next_val)
	_set_sidebar_status("🧭 Порог авто-маршрута: %d побед подряд" % next_val)


func _on_auto_diff_pressed() -> void:
	var next_val: bool = not GameManager.auto_advance_next_boss
	GameManager.set_auto_advance_next_boss(next_val)
	_set_sidebar_status("⏩ Авто-сложность после Титана: %s" % ("ВКЛ" if next_val else "ВЫКЛ"))


func _on_parallel_battle_pressed() -> void:
	var next_cnt: int = GameManager.cycle_parallel_battle_count()
	_set_sidebar_status("⚔️ Параллельные бои: x%d врагов в бою" % next_cnt)


func _on_wave_dungeon_pressed() -> void:
	if GameManager.wave_dungeon_active:
		GameManager.abort_wave_dungeon()
		_set_sidebar_status("🏰 Заход в Данж волн прерван.")
	else:
		var res: Dictionary = GameManager.start_wave_dungeon()
		_set_sidebar_status(str(res.get("message", "")))


func _on_mine_checkpoint_pressed(depth: int) -> void:
	if depth <= 1:
		GameManager.set_mine_start_depth(1)
		_set_sidebar_status("⛏️ Старт в Шахте: Глубина 1.")
		return
	if GameManager.is_mine_checkpoint_unlocked(depth):
		GameManager.set_mine_start_depth(depth)
		_set_sidebar_status("⛏️ Старт в Шахте: Глубина %d." % depth)
	else:
		var res: Dictionary = GameManager.buy_mine_checkpoint(depth)
		_set_sidebar_status(str(res.get("message", "")))


func _set_sidebar_status(msg: String) -> void:
	sidebar_status_label.text = msg
	sidebar_status_label.visible = not msg.is_empty()


func _refresh_expedition_and_route_controls() -> void:
	if auto_route_toggle_button == null:
		return
	var ar_on: bool = GameManager.auto_route_enabled
	auto_route_toggle_button.text = "🧭 Маршрут: ВКЛ (%d/%d)" % [GameManager.consecutive_location_wins, GameManager.auto_route_wins_threshold] if ar_on else "🧭 Маршрут: ВЫКЛ"
	auto_route_toggle_button.modulate = Color(0.56, 0.96, 0.72, 1.0) if ar_on else Color.WHITE
	auto_route_wins_button.text = "%d поб." % GameManager.auto_route_wins_threshold

	var ad_on: bool = GameManager.auto_advance_next_boss
	auto_diff_button.text = "⏩ Авто-Сл: ВКЛ" if ad_on else "⏩ Авто-Сл: ВЫКЛ"
	auto_diff_button.modulate = Color(0.56, 0.96, 0.72, 1.0) if ad_on else Color.WHITE

	var pb_cnt: int = GameManager.parallel_battle_count
	parallel_battle_button.text = "⚔️ Враги: x%d" % pb_cnt
	parallel_battle_button.modulate = Color(0.98, 0.82, 0.45, 1.0) if pb_cnt > 1 else Color.WHITE

	if GameManager.wave_dungeon_active:
		wave_dungeon_button.text = "🏳️ Выйти из Данжа (%d/%d)" % [GameManager.wave_dungeon_wave, GameManager.WAVE_DUNGEON_TOTAL_WAVES]
		wave_dungeon_button.modulate = Color(0.98, 0.65, 0.45, 1.0)
		location_title_label.text = "🏰 Данж волн (%d/%d)" % [GameManager.wave_dungeon_wave, GameManager.WAVE_DUNGEON_TOTAL_WAVES]
	else:
		wave_dungeon_button.text = "🏰 Данж 10 волн (Закр.: %d)" % GameManager.wave_dungeon_clears if GameManager.wave_dungeon_clears > 0 else "🏰 Данж 10 волн"
		wave_dungeon_button.modulate = Color(0.75, 0.90, 1.0, 1.0)
		if GameManager.current_location != null:
			location_title_label.text = "%s %s" % [GameManager.current_location.icon_emoji, GameManager.current_location.location_name]

	var ore_cnt: int = GameManager.get_dark_forge_material_count("abyss_ore")
	var cp_buttons: Array[Button] = [mine_cp1_button, mine_cp10_button, mine_cp25_button, mine_cp50_button]
	var cp_depths: Array[int] = [1, 10, 25, 50]
	for i: int in range(cp_buttons.size()):
		var b: Button = cp_buttons[i]
		var d: int = cp_depths[i]
		var unlocked_cp: bool = GameManager.is_mine_checkpoint_unlocked(d)
		var active_cp: bool = GameManager.mine_start_depth == d
		if unlocked_cp:
			b.text = ("✅%d" % d) if active_cp else ("⛏️%d" % d)
			b.modulate = Color(0.55, 0.98, 0.74, 1.0) if active_cp else Color(0.84, 0.92, 1.0, 1.0)
			b.disabled = false
			b.tooltip_text = "Стартовать в Древней Шахте с глубины %d" % d
		else:
			var cost: int = GameManager.get_mine_checkpoint_cost(d)
			b.text = "🔒%d(%d)" % [d, cost]
			b.modulate = Color(0.95, 0.78, 0.45, 1.0) if ore_cnt >= cost else Color(0.65, 0.68, 0.75, 0.8)
			b.disabled = ore_cnt < cost
			b.tooltip_text = "Открыть навсегда чекпоинт Глубины %d за %d ⛏️ Руды Бездны" % [d, cost]


func _compute_locations_sig() -> String:
	var parts: Array[String] = []
	parts.append("M:%s:%d:%d" % ["1" if GameManager.mine_locked_this_run else "0", GameManager.mine_depth, GameManager.mine_start_depth])
	for loc: LocationData in GameManager.locations:
		if loc.required_difficulty > 1 and GameManager.max_unlocked_difficulty < loc.required_difficulty:
			continue
		var unlocked: int = 1 if GameManager.is_location_unlocked(loc) else 0
		var is_cur: int = 1 if GameManager.current_location == loc else 0
		parts.append("%s:%d:%d" % [loc.id, unlocked, is_cur])
	return "|".join(parts)


func _on_location_btn_pressed(idx: int) -> void:
	if idx < 0 or idx >= _location_targets.size():
		return
	var loc: LocationData = _location_targets[idx]
	if loc != null:
		GameManager.select_location(loc)


func _rebuild_location_buttons() -> void:
	var sig: String = _compute_locations_sig()
	if sig == _last_locations_sig:
		return
	_last_locations_sig = sig

	var visible_locs: Array[LocationData] = []
	for loc: LocationData in GameManager.locations:
		if loc.required_difficulty > 1 and GameManager.max_unlocked_difficulty < loc.required_difficulty:
			continue
		visible_locs.append(loc)

	while _location_buttons.size() < visible_locs.size():
		var slot_idx: int = _location_buttons.size()
		var btn: Button = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 38.0)
		btn.clip_text = true
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(func() -> void: _on_location_btn_pressed(slot_idx))
		locations_row.add_child(btn)
		_location_buttons.append(btn)

	_location_targets.resize(visible_locs.size())
	for i: int in range(_location_buttons.size()):
		var btn: Button = _location_buttons[i]
		if i >= visible_locs.size():
			btn.visible = false
			continue
		var loc: LocationData = visible_locs[i]
		_location_targets[i] = loc
		btn.visible = true

		var unlocked: bool = GameManager.is_location_unlocked(loc)
		var is_current: bool = GameManager.current_location == loc

		if loc.is_one_attempt_mine and GameManager.mine_locked_this_run:
			btn.text = "💀 %s (Заход окончен)" % loc.location_name
			btn.modulate = Color(0.75, 0.52, 0.56, 0.85)
		elif unlocked:
			var prefix: String = "● " if is_current else ""
			if loc.is_one_attempt_mine:
				btn.text = "%s%s %s [Гл.%d] (1 заход)" % [prefix, loc.icon_emoji, loc.location_name, GameManager.mine_depth]
				btn.modulate = Color(0.68, 0.92, 1.0, 1.0)
			else:
				var suffix: String = " ★" if loc.always_open_once_unlocked else ""
				btn.text = "%s%s %s%s" % [prefix, loc.icon_emoji, loc.location_name, suffix]
				if loc.always_open_once_unlocked:
					btn.modulate = Color(0.92, 0.78, 1.0, 1.0)
				else:
					btn.modulate = Color.WHITE
		else:
			btn.text = "🔒 %s (Ур.%d)" % [loc.location_name, loc.required_level]
			btn.modulate = Color.WHITE

		btn.disabled = not unlocked

