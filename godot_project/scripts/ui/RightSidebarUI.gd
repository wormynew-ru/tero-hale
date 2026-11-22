extends PanelContainer

@onready var location_title_label: Label = %LocationTitleLabel
@onready var locations_row: VBoxContainer = %LocationsRow

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


var _held_slot_item_ids: Array[String] = ["", "", "", "", "", ""]
var _last_locations_sig: String = ""


func _ready() -> void:
	GameManager.stats_changed.connect(_refresh)
	GameManager.inventory_changed.connect(_refresh)
	GameManager.location_changed.connect(_on_location_changed)
	GameManager.difficulty_changed.connect(_refresh)
	GameManager.mine_state_changed.connect(_refresh)
	GameManager.game_reset.connect(_on_reset)

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
		GameManager.use_or_equip_item(item)


func _refresh() -> void:
	_refresh_inventory_slots()
	_rebuild_location_buttons()


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
				btn.disabled = false
				btn.modulate = Color.WHITE
				icon_lbl.text = item.icon_emoji
				count_lbl.text = "x%d" % count
				name_lbl.text = item.item_name
				continue

		btn.disabled = true
		btn.modulate = Color(0.65, 0.68, 0.72, 0.75)
		icon_lbl.text = "▫️"
		count_lbl.text = ""
		name_lbl.text = "СЛОТ %d\nПусто" % (i + 1)


func _on_location_changed(location: LocationData) -> void:
	location_title_label.text = "%s %s" % [location.icon_emoji, location.location_name]
	_rebuild_location_buttons()


func _compute_locations_sig() -> String:
	var parts: Array[String] = []
	parts.append("M:%s:%d" % ["1" if GameManager.mine_locked_this_run else "0", GameManager.mine_depth])
	for loc: LocationData in GameManager.locations:
		if loc.required_difficulty > 1 and GameManager.max_unlocked_difficulty < loc.required_difficulty:
			continue
		var unlocked: int = 1 if GameManager.is_location_unlocked(loc) else 0
		var is_cur: int = 1 if GameManager.current_location == loc else 0
		parts.append("%s:%d:%d" % [loc.id, unlocked, is_cur])
	return "|".join(parts)


func _rebuild_location_buttons() -> void:
	var sig: String = _compute_locations_sig()
	if sig == _last_locations_sig:
		return
	_last_locations_sig = sig

	for child: Node in locations_row.get_children():
		child.queue_free()

	for loc: LocationData in GameManager.locations:
		if loc.required_difficulty > 1 and GameManager.max_unlocked_difficulty < loc.required_difficulty:
			continue

		var btn: Button = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 38.0)
		btn.clip_text = true
		btn.add_theme_font_size_override("font_size", 13)
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
			btn.text = "🔒 %s (Ур.%d)" % [loc.location_name, loc.required_level]

		btn.disabled = not unlocked
		btn.pressed.connect(func() -> void: GameManager.select_location(loc))
		locations_row.add_child(btn)

