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
@onready var auto_potion_toggle: CheckButton = %AutoPotionToggle
@onready var quick_potion_button: Button = %QuickPotionButton
@onready var quick_mana_potion_button: Button = %QuickManaPotionButton
@onready var feedback_label: Label = %FeedbackLabel
@onready var inventory_list: VBoxContainer = %InventoryList


var _inv_rows: Array[Dictionary] = []
var _last_inv_sig: String = ""
var _dirty_inv: bool = true
var _dirty_ctrl: bool = true


func _ready() -> void:
	GameManager.inventory_changed.connect(_on_inventory_updated)
	GameManager.stats_changed.connect(_on_controls_updated)
	GameManager.enchant_changed.connect(_on_inventory_updated)
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
		feedback_label.text = "Снаряды убраны в рюкзак."
	)
	unequip_pet_slot_button.pressed.connect(func() -> void:
		GameManager.unequip_pet()
		feedback_label.text = "Путник убран из слота."
	)
	auto_potion_toggle.toggled.connect(func(pressed: bool) -> void:
		GameManager.set_auto_potion(pressed)
		feedback_label.text = "Авто-зелье (<35% HP) включено." if pressed else "Авто-зелье отключено."
	)
	quick_potion_button.pressed.connect(func() -> void:
		feedback_label.text = GameManager.use_best_healing_potion()
	)
	quick_mana_potion_button.pressed.connect(func() -> void:
		feedback_label.text = GameManager.use_best_mana_potion()
	)
	HoldAutoClicker.attach(quick_potion_button, 50.0)
	HoldAutoClicker.attach(quick_mana_potion_button, 50.0)

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


func _refresh_controls() -> void:
	_dirty_ctrl = false
	auto_potion_toggle.set_pressed_no_signal(GameManager.auto_potion_enabled)
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
	if equip_disabled:
		weapon_slot_label.text = "⚔️ Оружие: [Заблокировано классом Спирит]"
		unequip_weapon_button.disabled = true
	elif GameManager.equipped_weapon != null:
		var wb: Dictionary = GameManager.get_equipped_stat_bonuses(ItemData.ItemType.WEAPON)
		weapon_slot_label.text = "⚔️ Оружие [+%d]: %s (+%d Сил, +%d Лов, +%d Вын)" % [
			w_ench,
			GameManager.equipped_weapon.get_display_name(),
			int(wb["strength"]),
			int(wb["agility"]),
			int(wb["endurance"]),
		]
		unequip_weapon_button.disabled = false
	else:
		weapon_slot_label.text = "⚔️ Оружие [+%d]: [Пусто]" % w_ench
		unequip_weapon_button.disabled = true

	var a_ench: int = GameManager.armor_enchant_level
	if equip_disabled:
		armor_slot_label.text = "🛡️ Броня: [Заблокировано классом Спирит]"
		unequip_armor_button.disabled = true
	elif GameManager.equipped_armor != null:
		var ab: Dictionary = GameManager.get_equipped_stat_bonuses(ItemData.ItemType.ARMOR)
		armor_slot_label.text = "🛡️ Броня [+%d]: %s (+%d Сил, +%d Лов, +%d Вын)" % [
			a_ench,
			GameManager.equipped_armor.get_display_name(),
			int(ab["strength"]),
			int(ab["agility"]),
			int(ab["endurance"]),
		]
		unequip_armor_button.disabled = false
	else:
		armor_slot_label.text = "🛡️ Броня [+%d]: [Пусто]" % a_ench
		unequip_armor_button.disabled = true

	if equip_disabled:
		ammo_slot_label.text = "🏹 Снаряды: [Заблокировано классом Спирит]"
		unequip_ammo_button.disabled = true
	elif GameManager.equipped_ammo != null and GameManager.equipped_ammo_count > 0:
		ammo_slot_label.text = "🏹 Снаряды: %s x%d (%s)" % [
			GameManager.equipped_ammo.get_display_name(),
			GameManager.equipped_ammo_count,
			GameManager.equipped_ammo.get_summary_text(),
		]
		unequip_ammo_button.disabled = false
	else:
		ammo_slot_label.text = "🏹 Снаряды: [Пусто]"
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
		empty_label.text = "Рюкзак пуст. Побеждайте врагов или загляните в 🏪 Лавку."
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
		action_btn.custom_minimum_size = Vector2(114.0, 44.0)
		if item.item_type == ItemData.ItemType.CONSUMABLE:
			action_btn.text = "Выпить"
		elif item.item_type == ItemData.ItemType.AMMO:
			action_btn.text = "В колчан"
			action_btn.disabled = equip_disabled
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
		info_label.text = "%s%s x%d — %s" % [slot_prefix, item.item_name, count, item.get_summary_text()]
		var sell_val: float = GameManager.get_item_sell_value(item)
		sell_btn.text = "💰 +%s" % NumberFormatter.format_number(sell_val)
		row_idx += 1

