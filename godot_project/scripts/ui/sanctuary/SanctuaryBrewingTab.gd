class_name SanctuaryBrewingTab
extends VBoxContainer

signal feedback_emitted(msg: String)

const BrewCauldronCardScene := preload("res://scenes/sanctuary/BrewCauldronCard.tscn")

@onready var brew_cauldrons_box: VBoxContainer = %BrewCauldronsBox
@onready var recipe_guide_label: RichTextLabel = %RecipeGuideLabel

var _brew_cards: Array[BrewCauldronCard] = []
var _last_brew_sig: String = ""


func reset_cache() -> void:
	_last_brew_sig = ""


func sync_state(unlocked: bool, force: bool = false) -> void:
	if not is_visible_in_tree() and not force:
		return
	_sync_brew_cauldrons(unlocked, force)
	if force or recipe_guide_label.text.is_empty():
		_refresh_recipe_guide()


func update_timers() -> void:
	if not is_visible_in_tree():
		return
	var total_cauldrons: int = GameManager.get_brewing_slot_count()
	for i: int in range(mini(total_cauldrons, _brew_cards.size())):
		if i < GameManager.brewing_slots.size():
			_brew_cards[i].update_timer(GameManager.brewing_slots[i])


func _collect_dark_brewing_harvests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in GameManager.inventory:
		var item: ItemData = entry["item"] as ItemData
		var cnt: int = int(entry["count"])
		if item == null or cnt <= 0 or item.item_type != ItemData.ItemType.HARVEST:
			continue
		if item.garden_category == "light" or item.id == "spirit_primordial_harvest":
			continue
		result.append({"item": item, "count": cnt})
	return result


func _compute_brew_sig(unlocked: bool, harvests_owned: Array[Dictionary]) -> String:
	var parts: Array[String] = ["U:%s" % ("1" if unlocked else "0")]
	for i: int in range(GameManager.get_brewing_slot_count()):
		var cauldron: Dictionary = GameManager.brewing_slots[i] if i < GameManager.brewing_slots.size() else {}
		var acc: bool = unlocked and GameManager.is_brewing_slot_accessible(i)
		parts.append("%d:%s:%s:%s:%d:%s" % [
			i,
			"1" if acc else "0",
			str(cauldron.get("state", "empty")),
			str(cauldron.get("brew_id", "")),
			int(cauldron.get("stage", 0)),
			"1" if bool(cauldron.get("can_collect", false)) else "0",
		])
	for h_entry: Dictionary in harvests_owned:
		var it: ItemData = h_entry["item"] as ItemData
		parts.append("%s=%d" % [it.id, int(h_entry["count"])])
	return "|".join(parts)


func _ensure_cauldron_pool(target_count: int) -> void:
	while _brew_cards.size() < target_count:
		var card: BrewCauldronCard = BrewCauldronCardScene.instantiate() as BrewCauldronCard
		card.feedback_emitted.connect(func(msg: String) -> void: feedback_emitted.emit(msg))
		brew_cauldrons_box.add_child(card)
		_brew_cards.append(card)


func _sync_brew_cauldrons(unlocked: bool, force: bool) -> void:
	var harvests_owned: Array[Dictionary] = _collect_dark_brewing_harvests()
	var sig: String = _compute_brew_sig(unlocked, harvests_owned)
	if not force and sig == _last_brew_sig:
		return
	_last_brew_sig = sig

	var total_cauldrons: int = GameManager.get_brewing_slot_count()
	_ensure_cauldron_pool(total_cauldrons)
	for i: int in range(_brew_cards.size()):
		var card: BrewCauldronCard = _brew_cards[i]
		if i < total_cauldrons:
			card.visible = true
			var cauldron: Dictionary = GameManager.brewing_slots[i] if i < GameManager.brewing_slots.size() else {}
			var accessible: bool = unlocked and GameManager.is_brewing_slot_accessible(i)
			card.configure(i, unlocked, accessible, cauldron, harvests_owned)
		else:
			card.visible = false


func _refresh_recipe_guide() -> void:
	recipe_guide_label.text = (
		"[b][color=#facc15]☀️ Светлый сад (Сл.1+) — Приманка и Дрессировка путников:[/color][/b]\n"
		+ "• Простые семена падают с любых врагов: 🍀 [b]Солнечный клевер[/b] (4.5%, 20с), 🍓 [b]Медовая ягода[/b] (3.5%, 30с), 🌼 [b]Небесная ромашка[/b] (3.0%, 35с), 🌶️ [b]Искристый перчик[/b] (2.5%, 40с).\n"
		+ "• Путников [b]нельзя купить за золото[/b] — только выманить высадкой на 3 грядки Светлого сада! Если узор ведёт к уже приручённому путнику (повторке) или никому не подходит — [color=#fb7185]ничего не происходит, а растения завянут[/color]:\n"
		+ "   — 🎆 [b]Фейерверк[/b]: 🌶️ Перчик + 🌼 Ромашка + 🌶️ Перчик\n"
		+ "   — 🧚 [b]Лесной светлячок[/b]: 🍀 Клевер + 🌼 Ромашка + 🍀 Клевер\n"
		+ "   — 🪙 [b]Мимик-копилка[/b]: 🍓 Ягода + 🍀 Клевер + 🍓 Ягода\n"
		+ "   — 🦊 [b]Огненный лисёнок[/b]: 🌶️ Перчик + 🍓 Ягода + 🌶️ Перчик\n"
		+ "   — 🦉 [b]Хроно-сова[/b]: 🌼 Ромашка + 🌼 Ромашка + 🍀 Клевер\n"
		+ "   — 🦅 [b]Грозовой сокол[/b]: 🌼 Ромашка + 🌶️ Перчик + 🍓 Ягода\n"
		+ "• Собранный урожай Светлого сада идёт на [b]🍪 пряники[/b] для дрессировки путников в разделе «Путники» (у каждого свой любимый пряник с повышенным % успеха).\n\n"
		+ "[b][color=#c084fc]🌑 Тёмный сад (Сл.10+) — Супер-зелья и 🌟 Духи:[/color][/b]\n"
		+ "• 🌿 [b]Лунная мята[/b] (0.05%, 45с), 🥕 [b]Солнечный корень[/b] (0.03%, 90с), 🪷 [b]Лазурный лотос[/b] (0.02%, 150с), 🍄 [b]Звёздный трюфель[/b] (0.012%, 240с), 🌺 [b]Алый лепесток[/b] (0.005%/0.025%, растёт за 2000 побед над Вечным титаном).\n"
		+ "• 🌟 [b]Первоцвет духов[/b] — ультра-редкое семя с шансом [color=#22d3ee]0.03% ТОЛЬКО с Вечного титана[/color]. Растёт целый час ([b]3600с[/b]), [color=#34d399]НО если скормить духам 🍀x2 + 🍓x2 + 🌼x2 + 🌶️x2 — созревает МОМЕНТАЛЬНО![/color] Плод дрессирует духов Спирита.\n\n"
		+ "[b][color=#38bdf8]⚗️ Многоступенчатые рецепты котла:[/color][/b]\n"
		+ "• [b]Ветка Восстановления[/b]: Вода → [i]🌿 Мята[/i] → (+ [i]🌿 Мята[/i] = 🌙 [b]Лунный эликсир[/b] → + [i]🍄 Трюфель[/i] = 🥛 [b]Роса бессмертия[/b]) / (+ [i]🪷 Лотос[/i] = 🔮 [b]Нектар арканы x2[/b] → + [i]🍄 Трюфель[/i] = 📜 [b]Мудрость арканы x2[/b])\n"
		+ "• [b]Ветка Ярости[/b]: Вода → [i]🥕 Корень[/i] → (+ [i]🥕 Корень[/i] = 🩸 [b]Зелье ярости x2[/b] → + [i]🍄 Трюфель[/i] = 🔥 [b]Отвар крови титана[/b]) / (+ [i]🪷 Лотос[/i] = 🌪️ [b]Зелье вихря x2[/b] → + [i]🍄 Трюфель[/i] = 🛡️ [b]Железная кожа x3[/b])\n"
		+ "• [b]🌺 Вершина алхимии[/b]: [i]🌙 Лунный эликсир[/i] ИЛИ [i]🩸 Зелье ярости[/i] + [i]🌺 Алый лепесток[/i] = 🌺 [b]Эликсир Алого Лепестка[/b]."
	)
