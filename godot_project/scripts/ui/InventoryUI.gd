extends ScrollContainer

@onready var spirit_equip_notice: Label = %SpiritEquipNotice
@onready var weapon_slot_label: Label = %WeaponSlotLabel
@onready var unequip_weapon_button: Button = %UnequipWeaponButton
@onready var armor_slot_label: Label = %ArmorSlotLabel
@onready var unequip_armor_button: Button = %UnequipArmorButton
@onready var ammo_slot_label: Label = %AmmoSlotLabel
@onready var unequip_ammo_button: Button = %UnequipAmmoButton
@onready var pet_slot_label: Label = %PetSlotLabel
@onready var unequip_pet_slot_button: Button = %UnequipPetSlotButton

@onready var quick_potion_button: Button = %QuickPotionButton
@onready var quick_mana_potion_button: Button = %QuickManaPotionButton

@onready var auto_potion_toggle: CheckButton = %AutoPotionToggle
@onready var auto_hp_threshold_button: Button = %AutoHpThresholdButton
@onready var auto_hp_condition_button: Button = %AutoHpConditionButton

@onready var auto_mana_toggle: CheckButton = %AutoManaToggle
@onready var auto_mana_threshold_button: Button = %AutoManaThresholdButton
@onready var auto_mana_condition_button: Button = %AutoManaConditionButton

@onready var auto_buff_toggle: CheckButton = %AutoBuffToggle
@onready var auto_buff_condition_button: Button = %AutoBuffConditionButton
@onready var buff_whitelist_flow: HFlowContainer = %BuffWhitelistFlow

@onready var feedback_label: Label = %FeedbackLabel
@onready var inventory_list: VBoxContainer = %InventoryList


var _inv_rows: Array[Dictionary] = []
var _buff_filter_buttons: Dictionary = {}
var _last_inv_sig: String = ""
var _dirty_inv: bool = true
var _dirty_ctrl: bool = true


func _ready() -> void:
	GameManager.inventory_changed.connect(_on_inventory_updated)
	GameManager.stats_changed.connect(_on_controls_updated)
	GameManager.enchant_changed.connect(_on_inventory_updated)
	GameManager.dark_forge_changed.connect(_on_inventory_updated)
	GameManager.difficulty_changed.connect(_on_inventory_updated)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _on_inventory_updated())
	GameManager.pets_changed.connect(_on_inventory_updated)
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.mana_changed.connect(_on_mana_changed)
	GameManager.game_reset.connect(_on_reset)

	unequip_weapon_button.pressed.connect(func() -> void:
		GameManager.unequip_slot(ItemData.ItemType.WEAPON)
		feedback_label.text = "Оружие снято в рюкзак."
	)
	unequip_armor_button.pressed.connect(func() -> void:
		GameManager.unequip_slot(ItemData.ItemType.ARMOR)
		feedback_label.text = "Броня снята в рюкзак."
	)
	unequip_ammo_button.pressed.connect(func() -> void:
		GameManager.unequip_slot(ItemData.ItemType.AMMO)
		feedback_label.text = "Снаряды / Книги убраны в рюкзак."
	)
	unequip_pet_slot_button.pressed.connect(func() -> void:
		GameManager.unequip_pet()
		feedback_label.text = "Путник убран из слота."
	)

	auto_potion_toggle.toggled.connect(func(pressed: bool) -> void:
		GameManager.set_auto_hp_settings(pressed, GameManager.auto_hp_threshold_pct, GameManager.auto_hp_condition)
		feedback_label.text = "Авто-HP (<%d%%) включено." % GameManager.auto_hp_threshold_pct if pressed else "Авто-HP отключено."
	)
	auto_hp_threshold_button.pressed.connect(_cycle_hp_threshold)
	auto_hp_condition_button.pressed.connect(func() -> void:
		var next_cond: String = "always" if GameManager.auto_hp_condition == "combat" else "combat"
		GameManager.set_auto_hp_settings(GameManager.auto_potion_enabled, GameManager.auto_hp_threshold_pct, next_cond)
	)

	auto_mana_toggle.toggled.connect(func(pressed: bool) -> void:
		GameManager.set_auto_mana_settings(pressed, GameManager.auto_mana_threshold_pct, GameManager.auto_mana_condition)
		feedback_label.text = "Авто-MP (<%d%%) включено." % GameManager.auto_mana_threshold_pct if pressed else "Авто-MP отключено."
	)
	auto_mana_threshold_button.pressed.connect(_cycle_mana_threshold)
	auto_mana_condition_button.pressed.connect(func() -> void:
		var next_cond: String = "always" if GameManager.auto_mana_condition == "combat" else "combat"
		GameManager.set_auto_mana_settings(GameManager.auto_mana_enabled, GameManager.auto_mana_threshold_pct, next_cond)
	)

	auto_buff_toggle.toggled.connect(func(pressed: bool) -> void:
		GameManager.set_auto_buff_settings(pressed, GameManager.auto_buff_condition)
		feedback_label.text = "Авто-бафф по истечению включён." if pressed else "Авто-бафф отключён."
	)
	auto_buff_condition_button.pressed.connect(func() -> void:
		var next_cond: String = "on_expire_always" if GameManager.auto_buff_condition == "on_expire_combat" else "on_expire_combat"
		GameManager.set_auto_buff_settings(GameManager.auto_buff_enabled, next_cond)
	)

	quick_potion_button.pressed.connect(func() -> void:
		feedback_label.text = GameManager.use_best_healing_potion()
	)
	quick_mana_potion_button.pressed.connect(func() -> void:
		feedback_label.text = GameManager.use_best_mana_potion()
	)
	HoldAutoClicker.attach(quick_potion_button, 50.0)
	HoldAutoClicker.attach(quick_mana_potion_button, 50.0)

	_build_buff_whitelist_buttons()
	_rebuild_inventory(true)
	_refresh_controls()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		if _dirty_inv:
			_rebuild_inventory(false)
		elif _dirty_ctrl:
			_refresh_controls()


func _on_reset() -> void:
	feedback_label.text = ""
	_last_inv_sig = ""
	_dirty_inv = true
	_dirty_ctrl = true
	if is_visible_in_tree():
		_rebuild_inventory(true)
		_refresh_controls()


func _on_inventory_updated() -> void:
	if not is_visible_in_tree():
		_dirty_inv = true
		return
	_rebuild_inventory(false)


func _on_controls_updated() -> void:
	if not is_visible_in_tree():
		_dirty_ctrl = true
		return
	_refresh_controls()


func _on_hp_changed(_current_hp: float, _max_hp: float) -> void:
	_on_controls_updated()


func _on_mana_changed(_current_mana: float, _max_mana: float) -> void:
	_on_controls_updated()


func _cycle_hp_threshold() -> void:
	var presets: Array[int] = GameManager.HP_THRESHOLD_PRESETS
	var cur: int = GameManager.auto_hp_threshold_pct
	var idx: int = presets.find(cur)
	var next_val: int = presets[(idx + 1) % presets.size()] if idx >= 0 else presets[0]
	GameManager.set_auto_hp_settings(GameManager.auto_potion_enabled, next_val, GameManager.auto_hp_condition)


func _cycle_mana_threshold() -> void:
	var presets: Array[int] = GameManager.MANA_THRESHOLD_PRESETS
	var cur: int = GameManager.auto_mana_threshold_pct
	var idx: int = presets.find(cur)
	var next_val: int = presets[(idx + 1) % presets.size()] if idx >= 0 else presets[0]
	GameManager.set_auto_mana_settings(GameManager.auto_mana_enabled, next_val, GameManager.auto_mana_condition)


func _build_buff_whitelist_buttons() -> void:
	for child: Node in buff_whitelist_flow.get_children():
		child.queue_free()
	_buff_filter_buttons.clear()

	for entry: Dictionary in GameManager.BUFF_POTION_CATALOG:
		var bid: String = str(entry.get("id", ""))
		var lbl: String = str(entry.get("label", bid))
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0.0, 34.0)
		btn.add_theme_font_size_override("font_size", 12)
		btn.toggle_mode = true
		btn.text = lbl
		btn.pressed.connect(func() -> void:
			GameManager.toggle_buff_potion_whitelist(bid)
		)
		buff_whitelist_flow.add_child(btn)
		_buff_filter_buttons[bid] = btn


func _refresh_controls() -> void:
	_dirty_ctrl = false
	auto_potion_toggle.set_pressed_no_signal(GameManager.auto_potion_enabled)
	auto_potion_toggle.text = "🧪 Авто-HP (<%d%%)" % GameManager.auto_hp_threshold_pct
	auto_hp_threshold_button.text = "Порог: <%d%%" % GameManager.auto_hp_threshold_pct
	auto_hp_condition_button.text = "🌐 Всегда" if GameManager.auto_hp_condition == "always" else "⚔️ Только в бою"

	auto_mana_toggle.set_pressed_no_signal(GameManager.auto_mana_enabled)
	auto_mana_toggle.text = "💧 Авто-MP (<%d%%)" % GameManager.auto_mana_threshold_pct
	auto_mana_threshold_button.text = "Порог: <%d%%" % GameManager.auto_mana_threshold_pct
	auto_mana_condition_button.text = "🌐 Всегда" if GameManager.auto_mana_condition == "always" else "⚔️ Только в бою"

	auto_buff_toggle.set_pressed_no_signal(GameManager.auto_buff_enabled)
	auto_buff_condition_button.text = "🌐 Истечение: Всегда" if GameManager.auto_buff_condition == "on_expire_always" else "⚔️ Истечение: В бою"

	for bid_var: Variant in _buff_filter_buttons.keys():
		var bid: String = str(bid_var)
		var btn: Button = _buff_filter_buttons[bid_var] as Button
		if btn != null:
			var allowed: bool = GameManager.is_buff_potion_whitelisted(bid)
			btn.set_pressed_no_signal(allowed)
			btn.modulate = Color(0.55, 0.98, 0.72, 1.0) if allowed else Color(0.62, 0.64, 0.7, 0.7)

	var potions: int = GameManager.get_total_potion_count()
	quick_potion_button.text = "🧪 Выпить HP (%d)" % potions
	quick_potion_button.disabled = potions <= 0 or GameManager.current_hp >= GameManager.get_max_hp()

	var mana_potions: int = GameManager.get_total_mana_potion_count()
	quick_mana_potion_button.text = "💧 Выпить MP (%d)" % mana_potions
	quick_mana_potion_button.disabled = mana_potions <= 0 or GameManager.current_mana >= GameManager.get_max_mana()


func _compute_inventory_sig() -> String:
	var parts: Array[String] = []
	parts.append("E:%s" % ("1" if GameManager.is_equipment_disabled() else "0"))
	parts.append("A:%s" % ("1" if GameManager.is_alchemy_unlocked() else "0"))
	for entry: Dictionary in GameManager.inventory:
		var item: ItemData = entry["item"] as ItemData
		if item != null:
			parts.append(item.id)
	return "|".join(parts)


func _rebuild_inventory(force: bool = false) -> void:
	_dirty_inv = false
	var equip_disabled: bool = GameManager.is_equipment_disabled()
	spirit_equip_notice.visible = equip_disabled

	var w_ench: int = GameManager.weapon_enchant_level
	var w_dark: int = GameManager.dark_weapon_enchant_level
	var w_dark_tag: String = " | 🌑+%d" % w_dark if w_dark > 0 else ""
	if equip_disabled:
		weapon_slot_label.text = "⚔️ Оружие: [Заблокировано классом Спирит]"
		unequip_weapon_button.disabled = true
	elif GameManager.equipped_weapon != null:
		var wb: Dictionary = GameManager.get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
		var w_int_txt: String = ", +%d Инт" % int(wb["intellect"]) if int(wb["intellect"]) > 0 else ""
		weapon_slot_label.text = "⚔️ Оружие [+%d%s]: %s (+%d Сил, +%d Лов, +%d Вын%s)" % [
			w_ench,
			w_dark_tag,
			GameManager.equipped_weapon.get_display_name(),
			int(wb["strength"]),
			int(wb["agility"]),
			int(wb["endurance"]),
			w_int_txt,
		]
		unequip_weapon_button.disabled = false
	else:
		weapon_slot_label.text = "⚔️ Оружие [+%d%s]: [Пусто]" % [w_ench, w_dark_tag]
		unequip_weapon_button.disabled = true

	var a_ench: int = GameManager.armor_enchant_level
	var a_dark: int = GameManager.dark_armor_enchant_level
	var a_dark_tag: String = " | 🌑+%d" % a_dark if a_dark > 0 else ""
	if equip_disabled:
		armor_slot_label.text = "🛡️ Броня: [Заблокировано классом Спирит]"
		unequip_armor_button.disabled = true
	elif GameManager.equipped_armor != null:
		var ab: Dictionary = GameManager.get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
		var a_int_txt: String = ", +%d Инт" % int(ab["intellect"]) if int(ab["intellect"]) > 0 else ""
		armor_slot_label.text = "🛡️ Броня [+%d%s]: %s (+%d Сил, +%d Лов, +%d Вын%s)" % [
			a_ench,
			a_dark_tag,
			GameManager.equipped_armor.get_display_name(),
			int(ab["strength"]),
			int(ab["agility"]),
			int(ab["endurance"]),
			a_int_txt,
		]
		unequip_armor_button.disabled = false
	else:
		armor_slot_label.text = "🛡️ Броня [+%d%s]: [Пусто]" % [a_ench, a_dark_tag]
		unequip_armor_button.disabled = true

	if equip_disabled:
		ammo_slot_label.text = "🏹 Снаряды / Книги: [Заблокировано классом Спирит]"
		unequip_ammo_button.disabled = true
	elif GameManager.equipped_ammo != null and (GameManager.equipped_ammo_count > 0 or GameManager.equipped_ammo.is_dark_forged):
		var slot_prefix: String = "📚 Книга мага:" if GameManager.equipped_ammo.ammo_kind == ItemData.AmmoKind.TOME else "🏹 Снаряды:"
		var cnt_label: String = "♾️" if GameManager.equipped_ammo.is_dark_forged else "x%d" % GameManager.equipped_ammo_count
		ammo_slot_label.text = "%s %s %s (%s)" % [
			slot_prefix,
			GameManager.equipped_ammo.get_display_name(),
			cnt_label,
			GameManager.equipped_ammo.get_summary_text(),
		]
		unequip_ammo_button.disabled = false
	else:
		ammo_slot_label.text = "🏹 Снаряды / Книги: [Пусто]"
		unequip_ammo_button.disabled = true

	var active_pet: PetData = GameManager.get_equipped_pet()
	if active_pet != null:
		pet_slot_label.text = "🐾 Путник (без HP): %s %s — %s" % [active_pet.icon_emoji, active_pet.pet_name, active_pet.subtitle]
		unequip_pet_slot_button.disabled = false
	else:
		pet_slot_label.text = "🐾 Путник (без HP): [Пусто — выберите в меню «Путники»]"
		unequip_pet_slot_button.disabled = true

	_refresh_controls()

	var sig: String = _compute_inventory_sig()
	if not force and sig == _last_inv_sig and not GameManager.inventory.is_empty():
		_update_inventory_rows_in_place()
		return
	_last_inv_sig = sig

	for child: Node in inventory_list.get_children():
		child.queue_free()
	_inv_rows.clear()

	if GameManager.inventory.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Рюкзак пуст. Побеждайте врагов, загляните в 🏪 Лавку или спуститесь в ⛏️ Шахту."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.modulate = Color(0.65, 0.7, 0.78, 1.0)
		inventory_list.add_child(empty_label)
		return

	for index: int in range(GameManager.inventory.size()):
		var entry: Dictionary = GameManager.inventory[index]
		var item: ItemData = entry["item"] as ItemData
		if item == null:
			continue

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon_label: Label = Label.new()
		icon_label.custom_minimum_size = Vector2(36.0, 36.0)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 24)
		icon_label.text = item.icon_emoji
		row.add_child(icon_label)

		var info_label: Label = Label.new()
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(info_label)

		var action_btn: Button = Button.new()
		action_btn.custom_minimum_size = Vector2(124.0, 44.0)
		if item.item_type == ItemData.ItemType.CONSUMABLE:
			action_btn.text = "Выпить"
		elif item.item_type == ItemData.ItemType.AMMO:
			action_btn.text = "В руку (книга)" if item.ammo_kind == ItemData.AmmoKind.TOME else "В колчан"
			action_btn.disabled = equip_disabled
		elif item.item_type == ItemData.ItemType.MATERIAL:
			action_btn.text = "Для Кузни"
			action_btn.disabled = true
		elif item.item_type == ItemData.ItemType.SEED:
			var seed_crop: CropData = GameManager.get_crop_by_id(item.seed_crop_id)
			var is_light_seed: bool = seed_crop != null and seed_crop.is_light_crop()
			if is_light_seed:
				action_btn.text = "☀️ Посадить"
				action_btn.disabled = false
			else:
				action_btn.text = "🌑 Посадить" if GameManager.is_alchemy_unlocked() else "🔒 Сл.%d" % GameManager.ALCHEMY_UNLOCK_DIFFICULTY
				action_btn.disabled = not GameManager.is_alchemy_unlocked()
		elif item.item_type == ItemData.ItemType.HARVEST:
			if item.garden_category == "light":
				action_btn.text = "🍪 Пряник"
				action_btn.disabled = false
			elif item.id == "spirit_primordial_harvest":
				action_btn.text = "🌿 К духам"
				action_btn.disabled = false
			else:
				action_btn.text = "В котёл"
				action_btn.disabled = not GameManager.is_alchemy_unlocked()
		else:
			action_btn.text = "Надеть"
			action_btn.disabled = equip_disabled

		var sell_btn: Button = Button.new()
		sell_btn.custom_minimum_size = Vector2(106.0, 44.0)

		var row_data: Dictionary = {
			"item": item,
			"expected_id": item.id,
			"info_label": info_label,
			"action_btn": action_btn,
			"sell_btn": sell_btn,
		}

		action_btn.pressed.connect(func() -> void:
			var cur_item: ItemData = row_data["item"] as ItemData
			if cur_item != null:
				var msg: String = GameManager.use_or_equip_item(cur_item)
				if not msg.is_empty():
					feedback_label.text = msg
		)
		if item.item_type == ItemData.ItemType.CONSUMABLE:
			var expected_id: String = item.id
			HoldAutoClicker.attach(
				action_btn,
				50.0,
				0.25,
				func() -> bool:
					var cur: ItemData = row_data["item"] as ItemData
					return cur != null and cur.id == expected_id
			)
		row.add_child(action_btn)

		sell_btn.pressed.connect(func() -> void:
			var cur_item: ItemData = row_data["item"] as ItemData
			if cur_item != null:
				var msg: String = GameManager.sell_item(cur_item, 1)
				if not msg.is_empty():
					feedback_label.text = msg
		)
		var expected_sell_id: String = item.id
		HoldAutoClicker.attach(
			sell_btn,
			50.0,
			0.25,
			func() -> bool:
				var cur: ItemData = row_data["item"] as ItemData
				return cur != null and cur.id == expected_sell_id
		)
		row.add_child(sell_btn)

		_inv_rows.append(row_data)
		inventory_list.add_child(row)

	_update_inventory_rows_in_place()


func _update_inventory_rows_in_place() -> void:
	var row_idx: int = 0
	for index: int in range(GameManager.inventory.size()):
		var entry: Dictionary = GameManager.inventory[index]
		var item: ItemData = entry["item"] as ItemData
		var count: int = int(entry["count"])
		if item == null:
			continue
		if row_idx >= _inv_rows.size():
			break
		var row_data: Dictionary = _inv_rows[row_idx]
		row_data["item"] = item
		var info_label: Label = row_data["info_label"] as Label
		var sell_btn: Button = row_data["sell_btn"] as Button
		var slot_prefix: String = "[Слот %d] " % (index + 1) if index < 6 else ""
		info_label.text = "%s%s x%d — %s" % [slot_prefix, item.get_display_name(), count, item.get_summary_text()]
		var sell_val: float = GameManager.get_item_sell_value(item)
		sell_btn.text = "💰 +%s" % NumberFormatter.format_number(sell_val)
		row_idx += 1
