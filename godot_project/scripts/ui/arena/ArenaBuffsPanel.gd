class_name ArenaBuffsPanel
extends VBoxContainer

signal manual_cast_requested(slot_index: int)
signal auto_cast_toggled(slot_index: int)

const AbilitySlotButtonScript = preload("res://scripts/ui/AbilitySlotButton.gd")

@onready var magic_status_label: Label = %MagicStatusLabel
@onready var active_buffs_label: Label = %ActiveBuffsLabel
@onready var ability_slot_0: AbilitySlotButtonScript = %AbilitySlot0
@onready var ability_slot_1: AbilitySlotButtonScript = %AbilitySlot1
@onready var ability_slot_2: AbilitySlotButtonScript = %AbilitySlot2


func _ready() -> void:
	for slot_btn: AbilitySlotButtonScript in [ability_slot_0, ability_slot_1, ability_slot_2]:
		slot_btn.manual_cast_requested.connect(func(idx: int) -> void: manual_cast_requested.emit(idx))
		slot_btn.auto_cast_toggled.connect(func(idx: int) -> void: auto_cast_toggled.emit(idx))


func refresh_magic_summary() -> void:
	var auto_count: int = 0
	var equipped_count: int = 0
	for i: int in range(GameManager.abilities.size()):
		if GameManager.abilities[i] != null:
			equipped_count += 1
			if GameManager.is_ability_auto_cast(i):
				auto_count += 1
	magic_status_label.text = "✨\n%d/%d" % [auto_count, equipped_count]


func refresh_active_buffs() -> void:
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


func set_overcharge_state(is_active: bool, slot_idx: int, tick_num: int) -> void:
	var slots: Array[AbilitySlotButtonScript] = [ability_slot_0, ability_slot_1, ability_slot_2]
	for i: int in range(slots.size()):
		if is_active and i == slot_idx:
			slots[i].set_overcharge_tick(tick_num)
		else:
			slots[i].set_overcharge_tick(0)
