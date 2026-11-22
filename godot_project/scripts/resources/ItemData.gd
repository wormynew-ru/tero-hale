class_name ItemData
extends Resource

enum ItemType {
	WEAPON,
	ARMOR,
	CONSUMABLE,
	AMMO,
	SEED,
	HARVEST,
}

enum WeaponStyle {
	MELEE,
	BOW,
	CROSSBOW,
}

enum AmmoKind {
	NONE,
	ARROW,
	BOLT,
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

@export_group("Ranged & Ammo")
@export var weapon_style: WeaponStyle = WeaponStyle.MELEE
@export var required_ammo: AmmoKind = AmmoKind.NONE
@export var ammo_kind: AmmoKind = AmmoKind.NONE
@export var bonus_damage: float = 0.0
@export var bonus_crit_chance: float = 0.0
@export var armor_penetration: float = 0.0
@export var shop_pack_amount: int = 1

@export_group("Consumable & Economy")
@export var heal_amount: float = 0.0
@export var mana_amount: float = 0.0
@export var buy_price: int = 20
@export var sell_value: int = 5
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
			_:
				return "⚔️ Ближний"
	if item_type == ItemType.AMMO:
		match ammo_kind:
			AmmoKind.ARROW:
				return "🏹 Стрелы"
			AmmoKind.BOLT:
				return "🔩 Болты"
	if item_type == ItemType.SEED:
		return "☀️ Семя Светлого сада" if garden_category == "light" else "🌑 Семя Тёмного сада"
	if item_type == ItemType.HARVEST:
		return "☀️ Светлое растение (Приманка/Дрессировка)" if garden_category == "light" else "🌑 Тёмный урожай (Зельеварение/Духи)"
	return ""


func get_summary_text() -> String:
	var parts: Array[String] = []
	var tag: String = get_style_tag()
	if not tag.is_empty():
		parts.append(tag)
	if bonus_damage > 0.0:
		parts.append("+%d Урон" % int(bonus_damage))
	if bonus_strength > 0:
		parts.append("+%d Сила" % bonus_strength)
	if bonus_agility > 0:
		parts.append("+%d Ловкость" % bonus_agility)
	if bonus_endurance > 0:
		parts.append("+%d Выносливость" % bonus_endurance)
	if bonus_crit_chance > 0.0:
		parts.append("+%d%% Крит" % roundi(bonus_crit_chance * 100.0))
	if armor_penetration > 0.0:
		parts.append("+%d Пробитие" % int(armor_penetration))
	if item_type == ItemType.CONSUMABLE:
		if heal_amount > 0.0:
			parts.append("+%d HP" % int(heal_amount))
		if mana_amount > 0.0:
			parts.append("+%d MP" % int(mana_amount))
		if is_buff_potion():
			var bparts: Array[String] = []
			if buff_damage_pct > 0.0:
				bparts.append("+%d%% Урон" % roundi(buff_damage_pct * 100.0))
			if buff_attack_speed_pct > 0.0:
				bparts.append("+%d%% Скорость" % roundi(buff_attack_speed_pct * 100.0))
			if buff_armor_pct > 0.0:
				bparts.append("+%d%% Броня" % roundi(buff_armor_pct * 100.0))
			if buff_crit_chance_bonus > 0.0:
				bparts.append("+%d%% Крит" % roundi(buff_crit_chance_bonus * 100.0))
			if buff_spell_power_pct > 0.0:
				bparts.append("+%d%% Чары" % roundi(buff_spell_power_pct * 100.0))
			if buff_mana_regen_pct > 0.0:
				bparts.append("+%d%% Реген MP" % roundi(buff_mana_regen_pct * 100.0))
			if buff_lifesteal_pct > 0.0:
				bparts.append("+%d%% Вампиризм" % roundi(buff_lifesteal_pct * 100.0))
			if not bparts.is_empty():
				parts.append("Бафф %dс (%s)" % [roundi(buff_duration), ", ".join(bparts)])
	return ", ".join(parts) if not parts.is_empty() else description
