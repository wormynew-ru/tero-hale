class_name ItemData
extends Resource

enum ItemType {
	WEAPON,
	ARMOR,
	CONSUMABLE,
	AMMO,
	SEED,
	HARVEST,
	MATERIAL,
	OFFHAND,
}

enum WeaponStyle {
	MELEE,
	BOW,
	CROSSBOW,
	STAFF,
}

enum AmmoKind {
	NONE,
	ARROW,
	BOLT,
	TOME,
}

enum OffhandKind {
	NONE,
	SHIELD,
	TALISMAN,
}

@export var id: String = ""
@export var item_name: String = ""
@export var icon_emoji: String = "📦"
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.WEAPON

@export_group("Stat Bonuses")
@export var bonus_strength: int = 0
@export var bonus_agility: int = 0
@export var bonus_endurance: int = 0
@export var bonus_intellect: int = 0

@export_group("Ranged, Offhand & Ammo")
@export var weapon_style: WeaponStyle = WeaponStyle.MELEE
@export var required_ammo: AmmoKind = AmmoKind.NONE
@export var ammo_kind: AmmoKind = AmmoKind.NONE
@export var offhand_kind: OffhandKind = OffhandKind.NONE
@export var bonus_damage: float = 0.0
@export var bonus_crit_chance: float = 0.0
@export var armor_penetration: float = 0.0
@export var bonus_defense: float = 0.0
@export var bonus_barrier: float = 0.0
@export var bonus_barrier_scale: float = 0.0
@export var shop_pack_amount: int = 1

@export_group("Mage & Dark Forge")
@export var bonus_mana_cost_red: float = 0.0
@export var bonus_spell_power_pct: float = 0.0
@export var bonus_effect_duration_pct: float = 0.0
@export var is_dark_forged: bool = false

@export_group("Consumable & Economy")
@export var heal_amount: float = 0.0
@export var mana_amount: float = 0.0
@export var heal_pct: float = 0.0
@export var mana_pct: float = 0.0
@export var buy_price: int = 20
@export var sell_value: int = 5
@export var dark_shop_coin_price: int = 0
@export var resets_claimed_difficulties: bool = false
@export var icon_color: Color = Color(0.75, 0.78, 0.85, 1.0)

@export_group("Buff Potion")
@export var buff_id: String = ""
@export var buff_duration: float = 0.0
@export var buff_damage_pct: float = 0.0
@export var buff_attack_speed_pct: float = 0.0
@export var buff_armor_pct: float = 0.0
@export var buff_dodge_bonus: float = 0.0
@export var buff_crit_chance_bonus: float = 0.0
@export var buff_crit_mult_bonus: float = 0.0
@export var buff_spell_power_pct: float = 0.0
@export var buff_mana_regen_pct: float = 0.0
@export var buff_lifesteal_pct: float = 0.0

@export_group("Garden & Alchemy")
@export var seed_crop_id: String = ""
@export var garden_category: String = "dark"


func is_ranged_weapon() -> bool:
	return item_type == ItemType.WEAPON and (weapon_style == WeaponStyle.BOW or weapon_style == WeaponStyle.CROSSBOW)


func is_mage_staff() -> bool:
	return item_type == ItemType.WEAPON and weapon_style == WeaponStyle.STAFF


func uses_ammo() -> bool:
	return is_ranged_weapon() or is_mage_staff()


func is_equipment() -> bool:
	return item_type == ItemType.WEAPON or item_type == ItemType.ARMOR or item_type == ItemType.OFFHAND


func is_buff_potion() -> bool:
	return item_type == ItemType.CONSUMABLE and not buff_id.is_empty() and buff_duration > 0.0


func get_display_name() -> String:
	return "%s %s" % [icon_emoji, item_name]


func get_style_tag() -> String:
	if item_type == ItemType.WEAPON:
		match weapon_style:
			WeaponStyle.BOW:
				return "🏹 Лук (Стрелы)"
			WeaponStyle.CROSSBOW:
				return "🎯 Арбалет (Болты)"
			WeaponStyle.STAFF:
				return "🪄 Посох (Книга)"
			_:
				return "⚔️ Ближний"
	if item_type == ItemType.OFFHAND:
		match offhand_kind:
			OffhandKind.SHIELD:
				return "🛡️ Щит"
			OffhandKind.TALISMAN:
				return "🔮 Талисман"
			_:
				return "🛡️ Оффхенд"
	if item_type == ItemType.AMMO:
		match ammo_kind:
			AmmoKind.ARROW:
				return "🏹 Стрелы"
			AmmoKind.BOLT:
				return "🔩 Болты"
			AmmoKind.TOME:
				return "📚 Маг. книга"
	if item_type == ItemType.SEED:
		return "☀️ Семя Светлого сада" if garden_category == "light" else "🌑 Семя Тёмного сада"
	if item_type == ItemType.HARVEST:
		return "☀️ Светлое растение (Приманка/Дрессировка)" if garden_category == "light" else "🌑 Тёмный урожай (Зельеварение/Духи)"
	if item_type == ItemType.MATERIAL:
		return "⛏️ Ресурс / Реликвия Шахты"
	return ""


func get_summary_text() -> String:
	var parts: Array[String] = []
	if is_dark_forged:
		parts.append("🔥 Вечный")
	var tag: String = get_style_tag()
	if not tag.is_empty():
		parts.append(tag)
	if bonus_damage > 0.0:
		parts.append("+%d Урон" % int(bonus_damage))
	if bonus_defense > 0.0:
		parts.append("+%d Броня" % int(bonus_defense))
	if bonus_barrier > 0.0:
		parts.append("+%d Барьер" % int(bonus_barrier))
	if bonus_barrier_scale > 0.0:
		var scale_stat: String = "Инт" if offhand_kind == OffhandKind.TALISMAN else "Вын"
		parts.append("+%.1f Барьер/%s" % [bonus_barrier_scale, scale_stat])
	if bonus_strength > 0:
		parts.append("+%d Сила" % bonus_strength)
	if bonus_agility > 0:
		parts.append("+%d Ловкость" % bonus_agility)
	if bonus_endurance > 0:
		parts.append("+%d Выносливость" % bonus_endurance)
	if bonus_intellect > 0:
		parts.append("+%d Инта" % bonus_intellect)
	if bonus_spell_power_pct > 0.0:
		parts.append("+%d%% Чары" % roundi(bonus_spell_power_pct * 100.0))
	if bonus_mana_cost_red > 0.0:
		parts.append("-%d%% Манакост" % roundi(bonus_mana_cost_red * 100.0))
	if bonus_effect_duration_pct > 0.0:
		parts.append("+%d%% Длит. эффектов" % roundi(bonus_effect_duration_pct * 100.0))
	if bonus_crit_chance > 0.0:
		parts.append("+%d%% Крит" % roundi(bonus_crit_chance * 100.0))
	if armor_penetration > 0.0:
		parts.append("+%d Пробитие" % int(armor_penetration))
	if item_type == ItemType.CONSUMABLE:
		if resets_claimed_difficulties:
			parts.append("Сброс наград 🌑 пройденных сложностей (макс. Сл. сохраняется)")
		if heal_amount > 0.0:
			parts.append("+%d HP" % int(heal_amount))
		if heal_pct > 0.0:
			parts.append("+%d%% Max HP" % roundi(heal_pct * 100.0))
		if mana_amount > 0.0:
			parts.append("+%d MP" % int(mana_amount))
		if mana_pct > 0.0:
			parts.append("+%d%% Max MP" % roundi(mana_pct * 100.0))
		if is_buff_potion():
			var bparts: Array[String] = []
			if buff_damage_pct > 0.0:
				bparts.append("+%d%% Урон" % roundi(buff_damage_pct * 100.0))
			if buff_attack_speed_pct > 0.0:
				bparts.append("+%d%% Скорость" % roundi(buff_attack_speed_pct * 100.0))
			if buff_armor_pct > 0.0:
				bparts.append("+%d%% Броня" % roundi(buff_armor_pct * 100.0))
			if buff_dodge_bonus > 0.0:
				bparts.append("+%d%% Уклон" % roundi(buff_dodge_bonus * 100.0))
			if buff_crit_chance_bonus > 0.0:
				bparts.append("+%d%% Крит" % roundi(buff_crit_chance_bonus * 100.0))
			if buff_crit_mult_bonus > 0.0:
				bparts.append("+%d%% Крит.урон" % roundi(buff_crit_mult_bonus * 100.0))
			if buff_spell_power_pct > 0.0:
				bparts.append("+%d%% Чары" % roundi(buff_spell_power_pct * 100.0))
			if buff_mana_regen_pct > 0.0:
				bparts.append("+%d%% Реген MP" % roundi(buff_mana_regen_pct * 100.0))
			if buff_lifesteal_pct > 0.0:
				bparts.append("+%d%% Вампиризм" % roundi(buff_lifesteal_pct * 100.0))
			if not bparts.is_empty():
				parts.append("Бафф %dс (%s)" % [roundi(buff_duration), ", ".join(bparts)])
	return ", ".join(parts) if not parts.is_empty() else description
