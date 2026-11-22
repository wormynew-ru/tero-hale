extends ScrollContainer

@onready var sanctuary_status_label: Label = %SanctuaryStatusLabel
@onready var alchemist_flag_label: Label = %AlchemistFlagLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var garden_plots_box: VBoxContainer = %GardenPlotsBox
@onready var brew_cauldrons_box: VBoxContainer = %BrewCauldronsBox
@onready var recipe_guide_label: RichTextLabel = %RecipeGuideLabel


func _ready() -> void:
	GameManager.garden_changed.connect(_rebuild_sanctuary)
	GameManager.brewing_changed.connect(_rebuild_sanctuary)
	GameManager.inventory_changed.connect(_rebuild_sanctuary)
	GameManager.difficulty_changed.connect(_rebuild_sanctuary)
	GameManager.skills_changed.connect(_rebuild_sanctuary)
	GameManager.dark_skills_changed.connect(_rebuild_sanctuary)
	GameManager.class_changed.connect(func(_c: HeroClassData) -> void: _rebuild_sanctuary())
	GameManager.game_reset.connect(_rebuild_sanctuary)

	_rebuild_sanctuary()


func _rebuild_sanctuary() -> void:
	var unlocked: bool = GameManager.is_alchemy_unlocked()
	if unlocked:
		sanctuary_status_label.text = "🏡 Убежище открыто (Сл. %d+) · Скорость Сада: x%.2f · Скорость Варки: x%.2f · Дроп семян: x%.2f" % [
			GameManager.ALCHEMY_UNLOCK_DIFFICULTY,
			GameManager.get_garden_growth_speed_mult(),
			GameManager.get_brewing_speed_mult(),
			GameManager.get_seed_drop_multiplier(),
		]
		sanctuary_status_label.modulate = Color(0.55, 0.96, 0.72, 1.0)
	else:
		sanctuary_status_label.text = "🔒 Убежище заблокировано — победите Вечного титана и откройте %d-ю сложность (сейчас макс. Сл.%d)." % [
			GameManager.ALCHEMY_UNLOCK_DIFFICULTY,
			GameManager.max_unlocked_difficulty,
		]
		sanctuary_status_label.modulate = Color(0.98, 0.65, 0.38, 1.0)

	if GameManager.has_hero_class("alchemist"):
		var flag_text: String = "✅ СЛЕДУЮЩАЯ ОШИБКА НЕ ВЗОРВЁТСЯ (флаг активен)" if GameManager.alchemist_next_mistake_safe else "⚡ Следующая ошибка взорвёт котёл (следующая за ней — спасётся)"
		alchemist_flag_label.text = "⚗️ Алхимик: семена x2, варка x2, каждое 2-е неверное зелье не взрывается → %s" % flag_text
		alchemist_flag_label.modulate = Color(0.45, 0.98, 0.78, 1.0) if GameManager.alchemist_next_mistake_safe else Color(0.95, 0.85, 0.45, 1.0)
	else:
		alchemist_flag_label.text = "ℹ️ Посадки, варящиеся зелья и семена НЕ пропадают при новом ране. У Алхимика (Сл.50+) каждое 2-е неверное зелье сохраняется на своём этапе."
		alchemist_flag_label.modulate = Color(0.76, 0.86, 0.96, 1.0)

	_rebuild_garden_plots(unlocked)
	_rebuild_brew_cauldrons(unlocked)
	_refresh_recipe_guide()


func _collect_inventory_items_of_type(target_type: ItemData.ItemType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in GameManager.inventory:
		var item: ItemData = entry["item"] as ItemData
		var cnt: int = int(entry["count"])
		if item != null and cnt > 0 and item.item_type == target_type:
			result.append({"item": item, "count": cnt})
	return result


func _rebuild_garden_plots(unlocked: bool) -> void:
	for child: Node in garden_plots_box.get_children():
		child.queue_free()

	var seeds_owned: Array[Dictionary] = _collect_inventory_items_of_type(ItemData.ItemType.SEED)
	var total_plots: int = GameManager.get_garden_plot_count()

	for i: int in range(total_plots):
		var plot_idx: int = i
		var plot: Dictionary = GameManager.garden_plots[i] if i < GameManager.garden_plots.size() else {}
		var accessible: bool = unlocked and GameManager.is_garden_plot_accessible(i)
		var status: String = str(plot.get("status", "empty"))

		var card: PanelContainer = PanelContainer.new()
		var card_box: VBoxContainer = VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card.add_child(card_box)

		if not accessible and status == "empty":
			var lock_lbl: Label = Label.new()
			lock_lbl.text = "🔒 Грядка #%d — требуется талант «Зелёные грядки» или Сл.%d" % [i + 1, GameManager.ALCHEMY_UNLOCK_DIFFICULTY]
			lock_lbl.modulate = Color(0.65, 0.70, 0.78, 1.0)
			lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card_box.add_child(lock_lbl)
			garden_plots_box.add_child(card)
			continue

		if status == "empty":
			var title_lbl: Label = Label.new()
			title_lbl.text = "🟫 Грядка #%d — Свободна (выберите семя для посадки)" % (i + 1)
			card_box.add_child(title_lbl)

			if seeds_owned.is_empty():
				var hint_lbl: Label = Label.new()
				hint_lbl.text = "В рюкзаке нет семян. Они крайне редко выпадают с монстров (от 0.05% до 0.005%)."
				hint_lbl.modulate = Color(0.68, 0.74, 0.82, 1.0)
				hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				card_box.add_child(hint_lbl)
			else:
				var btn_flow: HFlowContainer = HFlowContainer.new()
				btn_flow.add_theme_constant_override("h_separation", 8)
				btn_flow.add_theme_constant_override("v_separation", 8)
				for s_entry: Dictionary in seeds_owned:
					var seed_item: ItemData = s_entry["item"] as ItemData
					var cnt: int = int(s_entry["count"])
					var plant_btn: Button = Button.new()
					plant_btn.custom_minimum_size = Vector2(180.0, 44.0)
					plant_btn.disabled = not unlocked
					plant_btn.text = "🌱 %s %s (x%d)" % [seed_item.icon_emoji, seed_item.item_name, cnt]
					plant_btn.pressed.connect(func() -> void:
						var res: Dictionary = GameManager.plant_seed_on_plot(plot_idx, seed_item)
						feedback_label.text = str(res.get("message", ""))
					)
					btn_flow.add_child(plant_btn)
				card_box.add_child(btn_flow)

		elif status == "growing":
			var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
			var header_lbl: Label = Label.new()
			var bar: ProgressBar = ProgressBar.new()
			bar.custom_minimum_size = Vector2(0.0, 18.0)
			bar.show_percentage = true

			if crop != null and crop.is_boss_kill_crop():
				var boss_kills: int = int(plot.get("boss_kills", 0))
				var req_kills: int = maxi(1, crop.required_final_boss_kills)
				header_lbl.text = "%s Грядка #%d: %s — Убито Вечных титанов: %d / %d" % [
					crop.icon_emoji,
					i + 1,
					crop.crop_name,
					boss_kills,
					req_kills,
				]
				header_lbl.modulate = Color(1.0, 0.45, 0.56, 1.0)
				bar.max_value = float(req_kills)
				bar.value = float(mini(boss_kills, req_kills))
			elif crop != null:
				var elapsed: float = float(plot.get("elapsed", 0.0))
				var total_sec: float = maxf(1.0, crop.grow_seconds)
				var rem_sec: float = maxf(0.0, (total_sec - elapsed) / maxf(0.1, GameManager.get_garden_growth_speed_mult()))
				header_lbl.text = "%s Грядка #%d: %s — Осталось %.0fс" % [crop.icon_emoji, i + 1, crop.crop_name, ceil(rem_sec)]
				bar.max_value = total_sec
				bar.value = minf(elapsed, total_sec)
			else:
				header_lbl.text = "🌱 Грядка #%d: Растёт..." % (i + 1)
			card_box.add_child(header_lbl)
			card_box.add_child(bar)

		elif status == "ready":
			var crop: CropData = GameManager.get_crop_by_id(str(plot.get("crop_id", "")))
			var ready_row: HBoxContainer = HBoxContainer.new()
			ready_row.add_theme_constant_override("separation", 10)
			var ready_lbl: Label = Label.new()
			ready_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ready_lbl.text = "✨ %s Грядка #%d: %s созрел! (%d-%d шт.)" % [
				crop.icon_emoji if crop != null else "🌿",
				i + 1,
				crop.crop_name if crop != null else "Урожай",
				crop.harvest_min if crop != null else 1,
				crop.harvest_max if crop != null else 1,
			]
			ready_lbl.modulate = Color(0.42, 0.98, 0.62, 1.0)
			ready_row.add_child(ready_lbl)

			var harvest_btn: Button = Button.new()
			harvest_btn.custom_minimum_size = Vector2(170.0, 44.0)
			harvest_btn.disabled = not unlocked
			harvest_btn.text = "🧺 Собрать"
			harvest_btn.pressed.connect(func() -> void:
				var res: Dictionary = GameManager.harvest_garden_plot(plot_idx)
				feedback_label.text = str(res.get("message", ""))
			)
			ready_row.add_child(harvest_btn)
			card_box.add_child(ready_row)

		garden_plots_box.add_child(card)


func _rebuild_brew_cauldrons(unlocked: bool) -> void:
	for child: Node in brew_cauldrons_box.get_children():
		child.queue_free()

	var harvests_owned: Array[Dictionary] = _collect_inventory_items_of_type(ItemData.ItemType.HARVEST)
	var total_cauldrons: int = GameManager.get_brewing_slot_count()

	for i: int in range(total_cauldrons):
		var slot_idx: int = i
		var cauldron: Dictionary = GameManager.brewing_slots[i] if i < GameManager.brewing_slots.size() else {}
		var accessible: bool = unlocked and GameManager.is_brewing_slot_accessible(i)
		var state: String = str(cauldron.get("state", "empty"))

		var card: PanelContainer = PanelContainer.new()
		var card_box: VBoxContainer = VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 8)
		card.add_child(card_box)

		if not accessible and (state == "empty" or state == "exploded"):
			var lock_lbl: Label = Label.new()
			lock_lbl.text = "🔒 Котёл #%d — требуется талант «Мастер котла» или Сл.%d" % [i + 1, GameManager.ALCHEMY_UNLOCK_DIFFICULTY]
			lock_lbl.modulate = Color(0.65, 0.70, 0.78, 1.0)
			lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card_box.add_child(lock_lbl)
			brew_cauldrons_box.add_child(card)
			continue

		if state == "empty" or state == "exploded":
			var top_row: HBoxContainer = HBoxContainer.new()
			top_row.add_theme_constant_override("separation", 10)
			var status_lbl: Label = Label.new()
			status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if state == "exploded":
				status_lbl.text = "💥 Котёл #%d: Взорвался из-за ошибки! Налейте свежую воду для нового зелья." % (i + 1)
				status_lbl.modulate = Color(0.98, 0.45, 0.42, 1.0)
			else:
				status_lbl.text = "⚗️ Котёл #%d: Пуст — начните варку с колбы воды." % (i + 1)
			status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			top_row.add_child(status_lbl)

			var water_btn: Button = Button.new()
			water_btn.custom_minimum_size = Vector2(180.0, 44.0)
			water_btn.disabled = not unlocked
			water_btn.text = "💧 Налить воду"
			water_btn.pressed.connect(func() -> void:
				var res: Dictionary = GameManager.start_brewing_water(slot_idx)
				feedback_label.text = str(res.get("message", ""))
			)
			top_row.add_child(water_btn)
			card_box.add_child(top_row)

		elif state == "brewing":
			var elapsed: float = float(cauldron.get("elapsed", 0.0))
			var dur: float = maxf(0.1, float(cauldron.get("duration", 10.0)))
			var rem_sec: float = maxf(0.0, (dur - elapsed) / maxf(0.1, GameManager.get_brewing_speed_mult()))
			var brew_lbl: Label = Label.new()
			brew_lbl.text = "🔥 Котёл #%d [Шаг %d]: Варится %s %s — %.1fс" % [
				i + 1,
				int(cauldron.get("pending_stage", 1)),
				str(cauldron.get("pending_emoji", "⚗️")),
				str(cauldron.get("pending_title", "")),
				rem_sec,
			]
			brew_lbl.modulate = Color(0.98, 0.82, 0.38, 1.0)
			card_box.add_child(brew_lbl)

			var bar: ProgressBar = ProgressBar.new()
			bar.custom_minimum_size = Vector2(0.0, 18.0)
			bar.max_value = dur
			bar.value = minf(elapsed, dur)
			bar.show_percentage = true
			card_box.add_child(bar)

		elif state == "ready":
			var stage: int = int(cauldron.get("stage", 0))
			var can_collect: bool = bool(cauldron.get("can_collect", false))
			var header_row: HBoxContainer = HBoxContainer.new()
			header_row.add_theme_constant_override("separation", 10)

			var cur_lbl: Label = Label.new()
			cur_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cur_lbl.text = "%s Котёл #%d [Этап %d/3]: %s" % [
				str(cauldron.get("brew_emoji", "⚗️")),
				i + 1,
				stage,
				str(cauldron.get("brew_title", "")),
			]
			cur_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			header_row.add_child(cur_lbl)

			if can_collect:
				var collect_btn: Button = Button.new()
				collect_btn.custom_minimum_size = Vector2(180.0, 44.0)
				collect_btn.text = "🧪 Забрать (x%d)" % maxi(1, int(cauldron.get("result_count", 1)))
				collect_btn.modulate = Color(0.55, 0.98, 0.72, 1.0)
				collect_btn.pressed.connect(func() -> void:
					var res: Dictionary = GameManager.collect_brewed_potion(slot_idx)
					feedback_label.text = str(res.get("message", ""))
				)
				header_row.add_child(collect_btn)

			var dump_btn: Button = Button.new()
			dump_btn.custom_minimum_size = Vector2(96.0, 44.0)
			dump_btn.text = "🗑️ Слить"
			dump_btn.pressed.connect(func() -> void:
				GameManager.clear_brewing_slot(slot_idx)
				feedback_label.text = "Котёл #%d очищен." % (slot_idx + 1)
			)
			header_row.add_child(dump_btn)
			card_box.add_child(header_row)

			if stage < 3:
				var ing_title: Label = Label.new()
				ing_title.text = "Добавить ингредиент на Шаг %d (⚠️ неверный ингредиент взрывает котёл с шансом 100%%):" % (stage + 1)
				ing_title.add_theme_font_size_override("font_size", 12)
				ing_title.modulate = Color(0.84, 0.88, 0.94, 1.0)
				ing_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				card_box.add_child(ing_title)

				if harvests_owned.is_empty():
					var no_ing: Label = Label.new()
					no_ing.text = "Нет урожая в рюкзаке — соберите урожай с грядок Сада."
					no_ing.modulate = Color(0.68, 0.74, 0.82, 1.0)
					card_box.add_child(no_ing)
				else:
					var ing_flow: HFlowContainer = HFlowContainer.new()
					ing_flow.add_theme_constant_override("h_separation", 8)
					ing_flow.add_theme_constant_override("v_separation", 8)
					for h_entry: Dictionary in harvests_owned:
						var harv: ItemData = h_entry["item"] as ItemData
						var cnt: int = int(h_entry["count"])
						var add_btn: Button = Button.new()
						add_btn.custom_minimum_size = Vector2(180.0, 44.0)
						add_btn.text = "➕ %s %s (x%d)" % [harv.icon_emoji, harv.item_name, cnt]
						add_btn.pressed.connect(func() -> void:
							var res: Dictionary = GameManager.add_brewing_ingredient(slot_idx, harv)
							feedback_label.text = str(res.get("message", ""))
						)
						ing_flow.add_child(add_btn)
					card_box.add_child(ing_flow)

		brew_cauldrons_box.add_child(card)


func _refresh_recipe_guide() -> void:
	recipe_guide_label.text = (
		"[b][color=#34d399]🌱 Редкие семена (падают с монстров):[/color][/b]\n"
		+ "• 🌿 [b]Лунная мята[/b] — 0.05% шанс, растёт 120с (1–2 листа).\n"
		+ "• 🥕 [b]Солнечный корень[/b] — 0.03% шанс (враги ≥15 XP), растёт 240с (1–2 корня).\n"
		+ "• 🪷 [b]Лазурный лотос[/b] — 0.02% шанс (враги ≥40 XP), растёт 420с (1–2 цветка).\n"
		+ "• 🍄 [b]Звёздный трюфель[/b] — 0.012% шанс (враги ≥120 XP), растёт 600с (1–2 шт.).\n"
		+ "• 🌺 [b]Алый лепесток[/b] — 0.005% с мобов (0.025% с боссов): [color=#fb7185]растёт ТОЛЬКО за 2000 убийств Вечного титана после посадки![/color]\n\n"
		+ "[b][color=#38bdf8]⚗️ Многоступенчатые рецепты (как в Minecraft):[/color][/b]\n"
		+ "• [b]Ветка Восстановления[/b]: Вода → [i]🌿 Мята[/i] (10с) →\n"
		+ "   1) + [i]🌿 Мята[/i] (15с) = 🌙 [b]Лунный эликсир[/b] (+3500 HP, +900 MP) → + [i]🍄 Трюфель[/i] (20с) = 🥛 [b]Роса бессмертия[/b] (+12K HP, +100% Брони, +15% Вампиризм)\n"
		+ "   2) + [i]🪷 Лотос[/i] (15с) = 🔮 [b]Нектар арканы x2[/b] (+1100 MP) → + [i]🍄 Трюфель[/i] (20с) = 📜 [b]Мудрость арканы x2[/b]\n"
		+ "• [b]Ветка Ярости[/b]: Вода → [i]🥕 Корень[/i] (10с) →\n"
		+ "   1) + [i]🥕 Корень[/i] (15с) = 🩸 [b]Зелье ярости x2[/b] → + [i]🍄 Трюфель[/i] (20с) = 🔥 [b]Отвар крови титана[/b] (+75% Урон, +35% Скор., +25% Крит на 90с)\n"
		+ "   2) + [i]🪷 Лотос[/i] (15с) = 🌪️ [b]Зелье вихря x2[/b] → + [i]🍄 Трюфель[/i] (20с) = 🛡️ [b]Железная кожа x3[/b]\n"
		+ "• [b]🌺 Вершина алхимии[/b]: [i]🌙 Лунный эликсир[/i] ИЛИ [i]🩸 Зелье ярости[/i] + [i]🌺 Алый лепесток[/i] (20с) = 🌺 [b]Эликсир Алого Лепестка[/b] (+50K HP, +5K MP, +200% Урон, +150% Чары на 120с)."
	)
