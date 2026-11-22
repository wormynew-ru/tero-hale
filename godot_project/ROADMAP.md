# ROADMAP.md — Карта файлов проекта

Используй эту карту для мгновенной навигации по проекту без ручного поиска файлов.

## Корень проекта (`res://`)
- `project.godot` — конфигурация Godot 4.7, Autoload `GameManager`, горизонтальные настройки экрана (1280x720, `canvas_items` + `expand`, `orientation=0` для телефона и ПК), `run/low_processor_mode=false` для фоновой работы, рендерер `gl_compatibility`.
- `icon.svg` — векторная иконка проекта для запуска и экспорта.
- `CLAUDE.md` — обязательные правила работы с проектом, архитектура, формулы баланса и описание сигналов.
- `ROADMAP.md` — текущая карта файлов проекта (обязательно обновлять при изменении структуры).
- `CHANGELOG.md` — журнал прогрессии, версий и выполненных изменений.
- `TZ.md` — техническое задание от пользователя (если файл пустой — игнорируется; если заполнен — задачи берутся в работу).

## Сцены (`res://scenes/`)
- `scenes/Main.tscn` — корневая сцена-композиция (1280x720): содержит `CombatSystem` и инстансит модульные сцены (`BattleArenaUI`, `RightSidebarUI`, `HeroMenuUI`, `AfkOverlayUI`).
- `scenes/BattleArenaUI.tscn` — модульная сцена боевой арены (левая часть экрана): кликабельный круглый герб героя, 3 стат-круга, **кнопка `🏡 Деревня` справа сверху**, **отдельный слот путника/питомца (`CompanionSlotButton`)**, персонажи с `AttackDiamond` над головой и полосами HP/Маны с текстом и процентами внутри, 3 активных слота магии (`AbilitySlotButton`) + индикатор баффов слева снизу, кнопка поиска боя (`⚔️`/`🏳️`) по центру и `РЮКЗАК 🎒` (со счётчиком снарядов для дальнобойного оружия) справа.
- `scenes/RightSidebarUI.tscn` — модульная сцена правой боковой панели: прокручиваемый блок `КАРТА` (включая всегда открытую бонус-локацию `Горнило Проклятий` после 100-й сложности) и сетка `2×3` быстрых слотов первых 6 предметов из `GameManager.inventory[0..5]`.
- `scenes/HeroMenuUI.tscn` — модульная сцена меню героя, открываемая нажатием на герб: хаб со всеми разделами (`🏡 Карта деревни`, `🌱 Убежище: Сад и Зелья`, `Статы и Навыки`, `Класс героя`, `Путники`, `Заклинания (20)`, `Древо талантов`, `Тёмные навыки`, `Инвентарь`, `Кузня`, `Лавка`, `Сложность / Ран`, `F.A.Q.`, `AFK-режим`) и встроенными подсценами.
- `scenes/VillageMapUI.tscn` — модульная сцена иллюстрированной карты деревни поверх `res://assets/textures/village_map.jpg` с 4 невидимыми кликабельными кнопками: Домик (`Убежище`), «МАГАЗИН» (выбор `Лавка` / `Кузня`), Щенок (`Путники`), Горы (возврат к бою).
- `scenes/SanctuaryUI.tscn` — модульная сцена Убежища (открывается с Сл.10+): Сад для выращивания редких семян (включая `🌺 Алый лепесток` за 2000 убийств Вечного титана) и многоступенчатое Зельеварение (как в Minecraft: Вода → Шаг 1 → Шаг 2 → Шаг 3, взрывы и флаг Алхимика).
- `scenes/ClassUI.tscn` — модульная сцена выбора класса героя (открываются на Сл.50+: *Странник*, *Алхимик*, *Тролль*, *Спирит*, *Снайпер Бездны*, *Архимаг Крови*, *Отражатель*).
- `scenes/PetUI.tscn` — модульная сцена приюта путников: покупка и экипировка бессмертных питомцев в отдельный слот без HP (включая `🎆 Фейерверк`).
- `scenes/SpellbookUI.tscn` — модульная сцена Книги заклинаний (20 заклинаний: 14 общих + 6 эксклюзивов Архимага Крови; выбор до 3 активных слотов боя).
- `scenes/AttackDiamond.tscn` — модульный виджет ромба перезарядки атаки над сущностями (заполнение снизу вверх).
- `scenes/AbilitySlotButton.tscn` — модульная круглая кнопка магической способности (одиночный тап — применение, удержание 1 сек — переключение автоприменения).
- `scenes/StatsUI.tscn` — модульная сцена характеристик, сводки активного класса и путника, 3 прогресс-баров *Learn by Doing* (Ближний бой, Дальний бой, Магия), прокачки за очки навыков/золото и полного сброса прогресса.
- `scenes/InventoryUI.tscn` — модульная сцена инвентаря: слоты оружия/брони (`+N`), **снарядов** и активного **путника**, предупреждение класса Спирит, авто-зелье, быстрые кнопки **HP и MP зелий** и список рюкзака (включая посадку семян и урожай).
- `scenes/EnchantUI.tscn` — модульная сцена Кузни для зачарования слотов Оружия и Брони от `+0` до `+100` (или до **`+250`** для Алхимика) за золото.
- `scenes/SkillTreeUI.tscn` — модульная сцена Дерева навыков (34 узла, включая 2 закрытых до Сл.10 садовых/алхимических таланта).
- `scenes/DarkSkillTreeUI.tscn` — модульная сцена Тёмных навыков (26 постоянных узлов в 4 расходящихся ветках Бездны за 🌑 Очки Тьмы, включая 2 узла Убежища Сл.10+).
- `scenes/DifficultyUI.tscn` — модульная сцена выбора сложности, реролла проклятий каждого тира за жетоны `🎲`, статуса босса 100-й сложности и запуска Нового рана.
- `scenes/ShopUI.tscn` — модульная сцена лавки торговца с покупкой зелий HP, **зелий маны**, **бафф-зелий**, оружия (ближнего и дальнего боя), пачек снарядов (x50) и брони.
- `scenes/FaqUI.tscn` — модульная сцена справочника `F.A.Q.` с описанием *Learn by Doing*, луков/арбалетов/снарядов, классов (Сл.50+), **Карты деревни, Сада и многоступенчатого Зельеварения (Сл.10+)**, 100-й локации и рероллов.
- `scenes/AfkOverlayUI.tscn` — модульная сцена карманного OLED AFK-оверлея (`#000000`, 2 FPS) со статистикой текущей сессии и кнопкой полного отключения рендера.

## Ассеты (`res://assets/`)
- `assets/textures/village_map.jpg` — иллюстрированная карта деревни (1408×768 JPEG) с домиком, магазином, щенком и горами для `VillageMapUI.tscn`.

## Основные скрипты (`res://scripts/`)
- `scripts/GameManager.gd` — Autoload-синглтон (`PROCESS_MODE_ALWAYS`): статы, *Learn by Doing* мастерство (`melee`/`ranged`/`magic`), классы (Сл.50+), экипировка и заточка (`+100`/`+250`), инвентарь (включая зелья маны/баффов, семена, урожай), 34 обычных и 26 тёмных навыков (с блокировкой Сл.10+ до открытия Убежища), **Сад и многоступенчатое Зельеварение (сохраняются между ранами, тики в реальном времени, взрывы котлов и детерминированный спас-флаг Алхимика)**, сложности, реролл проклятий и автосохранение в `user://save.tres`.
- `scripts/CombatSystem.gd` — машина состояний боя (`PROCESS_MODE_ALWAYS`): ближний/дальний бой с расходом снарядов и двойным выстрелом, опыт *Learn by Doing*, бесконечный `-1` армор-шред Тролля, 4 природных духа Спирита, механики Отражателя и Путников, **дроп редких семян (от 0.05%) и учёт убийств Вечного титана для роста Алого лепестка (2000 побед)**, эскалация Хранителя Проклятий.
- `scripts/MainUI.gd` — корневой оркестратор `Main.tscn`: привязывает `CombatSystem` к `BattleArenaUI`, скрывает `RootHBox` в AFK-режиме и связывает открытие `HeroMenuUI` (включая прямой переход на карту деревни).
- `scripts/SkillTreeUI.gd` — контроллер `SkillTreeUI.tscn`: построение графа из 34 узлов с автоцентрированием на корневой узел `hero_foundation` и блокировкой `🔒 Сл.10` для талантов Убежища.
- `scripts/utils/NumberFormatter.gd` — статический форматер крупных чисел с суффиксами `K`, `M`, `B`, `T`, `Qa`, `Qi`, `Sx`, `Sp`, `Oc`, `No`, `Dc` и т.д.

## Контроллеры UI-модулей (`res://scripts/ui/`)
- `scripts/ui/BattleArenaUI.gd` — контроллер `BattleArenaUI.tscn`: аватар с классом/оружием, кнопка `🏡 Деревня`, анимация летящих стрел/болтов, попапы духов природы и уровней мастерства, счётчик среза брони Тролля `[🦴-N]`, счётчик снарядов и награда реролла.
- `scripts/ui/RightSidebarUI.gd` — контроллер `RightSidebarUI.tscn`: список локаций `КАРТА` (включая `abyss_crucible` от Сл.100) и сетка `СЛОТ 1–6` (поддержка HP, MP, бафф-зелий и семян).
- `scripts/ui/HeroMenuUI.gd` — контроллер `HeroMenuUI.tscn`: навигация по всем разделам включая `VillageMapUI`, `SanctuaryUI`, `ClassUI`, `PetUI` и `SpellbookUI`, отображение жетонов `🎲`.
- `scripts/ui/VillageMapUI.gd` — контроллер `VillageMapUI.tscn`: обработка невидимых кнопок карты деревни и всплывающего выбора «Лавка / Кузня» для здания «МАГАЗИН».
- `scripts/ui/SanctuaryUI.gd` — контроллер `SanctuaryUI.tscn`: управление грядками (время / счётчик `0/2000` боссов для Алого лепестка), котлами многоступенчатой варки, книгой рецептов и индикатором спас-флага Алхимика.
- `scripts/ui/ClassUI.gd` — контроллер `ClassUI.tscn`: отображение разблокировки классов (Сл.50+) и переключение активного класса.
- `scripts/ui/PetUI.gd` — контроллер `PetUI.tscn`: каталог, покупка и экипировка путников (питомцев).
- `scripts/ui/SpellbookUI.gd` — контроллер `SpellbookUI.tscn`: каталог 20 заклинаний (14 общих + 6 Архимага Крови) и привязка до 3 активных слотов.
- `scripts/ui/AttackDiamond.gd` — отрисовка 45°-ромба шкалы атаки через `_draw()`.
- `scripts/ui/AbilitySlotButton.gd` — обработка короткого тапа и удержания `1.0 сек` для автокаста магии, отображение КД, активных баффов, тика перегрузки `🔥Тn` и стоимости маны.
- `scripts/ui/StatsUI.gd` — контроллер `StatsUI.tscn`: сводка класса, боевого стиля, 3 прогресс-бара *Learn by Doing*, тренировка статов и сброс.
- `scripts/ui/InventoryUI.gd` — контроллер `InventoryUI.tscn`: слоты оружия/брони/снарядов, быстрое питьё HP и MP зелий, посадка семян и операции с рюкзаком.
- `scripts/ui/EnchantUI.gd` — контроллер `EnchantUI.tscn`: динамический лимит заточки (`+100` / `+250` у Алхимика), скидка и шанс Алхимика, блокировка для Спирита.
- `scripts/ui/DarkSkillTreeUI.gd` — контроллер `DarkSkillTreeUI.tscn`: граф из 26 узлов Бездны с автоцентрированием на корень `abyss_awakening` и блокировкой `🔒 Сл.10`.
- `scripts/ui/DifficultyUI.gd` — контроллер `DifficultyUI.tscn`: реролл проклятий каждого тира кнопкой `🎲 Реролл`, статус Горнила Проклятий и запуск Нового рана.
- `scripts/ui/ShopUI.gd` — контроллер `ShopUI.tscn`: список товаров (зелья HP, MP, баффы, оружие, снаряды `x50`, броня).
- `scripts/ui/FaqUI.gd` — контроллер `FaqUI.tscn`: актуальный справочник по всем системам.
- `scripts/ui/AfkOverlayUI.gd` — контроллер `AfkOverlayUI.tscn`: карманный OLED AFK-оверлей (`2 FPS` / отключение рендера).

## Классы ресурсов (`res://scripts/resources/`)
- `scripts/resources/ItemData.gd` — класс `ItemData` (`WEAPON`, `ARMOR`, `CONSUMABLE`, `AMMO`, `SEED`, `HARVEST`, восстановление HP/MP, параметры бафф-зелий `buff_id` / `buff_duration` / статы баффа, привязка `seed_crop_id`).
- `scripts/resources/CropData.gd` — класс `CropData` (`id`, `crop_name`, `icon_emoji`, `grow_seconds`, `required_final_boss_kills`, `base_drop_chance`, `boss_drop_chance`, `min_enemy_xp`, `harvest_min`, `harvest_max`, `seed_item_path`, `harvest_item_path`).
- `scripts/resources/EnemyData.gd` — класс `EnemyData` (`icon_emoji`, HP, `max_mana`, урон, ловкость, защита, награды XP/золото, пул дропа и шансы).
- `scripts/resources/LocationData.gd` — класс `LocationData` (`icon_emoji`, название, `required_level`, `required_difficulty`, `always_open_once_unlocked`, список врагов, цвет фона).
- `scripts/resources/SkillNodeData.gd` — класс `SkillNodeData` (включая `requires_alchemy` для блокировки Сл.10+ и бонусы `garden_mastery` / `extra_brew_slot`).
- `scripts/resources/DarkSkillNodeData.gd` — класс `DarkSkillNodeData` (26 эффектов Бездны, включая `requires_alchemy`, `seed_drop_mult` и `brew_speed_mult`).
- `scripts/resources/HeroClassData.gd` — класс `HeroClassData` (`id`, `title`, `icon_emoji`, `subtitle`, `description`, `passive_summary`, `required_difficulty`, `disables_equipment`, `accent_color`).
- `scripts/resources/AbilityData.gd` — класс `AbilityData` (`id`, `title`, `icon_emoji`, `description`, `required_class_id`, `mana_cost`, `cooldown`, `effect_type`, `power_multiplier`, параметры баффов/DoT/мульти-ударов/жертвы HP).
- `scripts/resources/PetData.gd` — класс `PetData` (`id`, `pet_name`, `icon_emoji`, `subtitle`, `description`, `effect_type`, `effect_value`, `effect_secondary`, `buy_price`, `required_difficulty`, `accent_color`).
- `scripts/resources/SaveData.gd` — класс `SaveData` (включая `garden_plots`, `brewing_slots`, `alchemist_next_mistake_safe`, сохраняемые между ранами, а также `dark_points_claimed_difficulties`).

## Данные и ресурсы (`res://resources/`)
### Классы героя (`res://resources/classes/`)
- `resources/classes/wanderer.tres` — 🧭 Странник (базовый класс без ограничений).
- `resources/classes/alchemist.tres` — ⚗️ Алхимик (заточка до +250, -40% цены, x1.60 шанса, +60% лечения зелий и 20% сохранение зелья, +15% золота/регена маны).
- `resources/classes/troll.tres` — 🧌 Тролль (бесконечный -1 брони за удар в минус, +2.5% HP/с в бою, +25% HP, +20% Силы).
- `resources/classes/spirit.tres` — 🌿 Спирит (без экипировки, +35% всех статов, +50% брони, 4 духа природы: Огонь, Ветер, Лес, Земля).
- `resources/classes/abyss_ranger.tres` — 🎯 Снайпер Бездны (+40% урон луков/арбалетов, 60% экономия снарядов, 30% двойной выстрел, криты игнорируют плоскую броню, крит-множитель от Ловкости).
- `resources/classes/blood_archmage.tres` — 🩸 Архимаг Крови (+75% силы магии, -50% манакост, -30% КД, каст за 8% HP без маны, удары снижают КД на 0.5с).
- `resources/classes/reflector.tres` — 🪞 Отражатель (0 прямого урона, +30% Max HP, +40% брони, отражает 20% входящего урона, каждую секунду бьёт на 5% своего Max HP + 0.1% гниения Max HP врага).

### Путники / Питомцы (`res://resources/pets/`, всего 6 спутников без HP)
- `resources/pets/firework_spark.tres` — 🎆 Фейерверк (оглушает врага в начале каждого боя на 5.0 секунд, 1 раз за бой).
- `resources/pets/healing_wisp.tres` — 🧚 Лесной светлячок (+2.5% Max HP/с в бою и +25% регена маны).
- `resources/pets/abyss_mimic.tres` — 🪙 Мимик-копилка (+45% золота и 25% шанс удвоить золото за убийство).
- `resources/pets/ember_fox.tres` — 🦊 Огненный лисёнок (поджигает врага на 0.8% его Max HP/с и даёт +15% урона героя).
- `resources/pets/chrono_owl.tres` — 🦉 Хроно-сова (+35% скорость КД магии и 15% шанс мгновенного сброса КД).
- `resources/pets/thunder_griffin.tres` — 🦅 Грозовой сокол (+12% крита, замедляет врага на 15%, удар молнией каждые 4.0с).

### Предметы (`res://resources/items/`, всего 53 предмета)
- Оружие ближнего боя: `wooden_sword.tres`, `hunter_dagger.tres`, `iron_sword.tres`, `steel_halberd.tres`, `assassin_kris.tres`, `dragonbone_blade.tres`, `trident_of_abyss.tres`, `astral_greatsword.tres`.
- Луки и арбалеты: `wooden_bow.tres` (🏹), `iron_crossbow.tres` (🎯), `elven_longbow.tres` (🌿), `dragon_crossbow.tres` (🔥), `astral_bow.tres` (🌠).
- Снаряды (пачки x50): `wooden_arrows.tres`, `steel_arrows.tres`, `astral_arrows.tres`, `iron_bolts.tres`, `mithril_bolts.tres`, `abyss_bolts.tres`.
- Броня: `leather_jacket.tres`, `chainmail_armor.tres`, `steel_plate.tres`, `dragonscale_armor.tres`, `abyssal_carapace.tres`, `celestial_aegis.tres`.
- Зелья лечения: `small_healing_potion.tres`, `medium_healing_potion.tres`, `large_healing_potion.tres`, `elixir_of_life.tres`, `divine_nectar.tres`, `ambrosia_flask.tres`.
- Зелья маны (4 шт.): `small_mana_potion.tres`, `medium_mana_potion.tres`, `large_mana_potion.tres`, `arcane_nectar.tres`.
- Бафф-зелья (4 шт.): `fury_potion.tres`, `ironhide_potion.tres`, `swiftwind_potion.tres`, `arcane_wisdom_potion.tres`.
- Сваренные мастер-зелья Убежища (4 шт.): `moonlight_elixir.tres`, `titan_blood_brew.tres`, `immortal_dew_potion.tres`, `crimson_petal_elixir.tres`.
- Редкие семена (5 шт., `ItemType.SEED`, не пропадают при новом ране): `moon_mint_seed.tres`, `sun_root_seed.tres`, `azure_lotus_seed.tres`, `star_truffle_seed.tres`, `scarlet_petal_seed.tres`.
- Урожай Сада (5 шт., `ItemType.HARVEST`, не пропадает при новом ране): `moon_mint_harvest.tres`, `sun_root_harvest.tres`, `azure_lotus_harvest.tres`, `star_truffle_harvest.tres`, `scarlet_petal_harvest.tres`.

### Культуры Сада (`res://resources/crops/`, всего 5 культур)
- `moon_mint.tres` (🌿 Лунная мята, шанс от 0.05%, рост 45с), `sun_root.tres` (🥕 Солнечный корень, рост 90с), `azure_lotus.tres` (🪷 Лазурный лотос, рост 150с), `star_truffle.tres` (🍄 Звёздный трюфель, рост 240с), `scarlet_petal.tres` (🌺 Алый лепесток, рост только за **2000 убийств Вечного титана**).

### Способности (`res://resources/abilities/`, всего 20 заклинаний; 3 активных слота в бою)
- **14 общих заклинаний**:
  - Прямой/мульти/спец-урон и лечение: `fireball.tres` (🔥), `nature_mend.tres` (💚), `arcane_surge.tres` (⚡), `ice_lance.tres` (❄️ пробивает 100% брони), `chain_thunder.tres` (🌩️ 3 удара), `meteor_strike.tres` (☄️ 390%), `mana_siphon.tres` (🌀 урон + хил + мана), `execute_sigil.tres` (🗡️ добивание <40% HP).
  - Периодический и бёрст-урон: `poison_cloud.tres` (☠️ яд DoT 8с), `soul_overload.tres` (🌋 бёрст-перегрузка: сжигает 1/1 → 2/2 → 4/5 → 8/10 → ... HP/MP с растущим взрывом `x1.75^(тик-1)`).
  - Баффы: `battle_frenzy.tres` (⚔️ +45% урона/+25% скорости 10с), `stone_aegis.tres` (🛡️ +120% брони/+15% уклона 10с), `eagle_focus.tres` (🎯 +25% крита/+60% крит-урона 10с), `arcane_meditation.tres` (🔮 +120% регена маны/+40% силы магии 10с).
- **6 эксклюзивов Архимага Крови (`required_class_id = "blood_archmage"`)**:
  - `crimson_lance.tres` (🩸 6% HP + 340% урона), `hemorrhage_curse.tres` (💔 кровотечение 8с с отхилом), `crimson_ward.tres` (🧣 бафф +150% брони/+25% вампиризма/60% шипы), `blood_frenzy.tres` (🦇 бафф +85% урона и чар/+35% скорости), `crimson_nova.tres` (💢 12% HP, 460% чистого урона + отхил), `sanguine_apotheosis.tres` (👑 ульт-бафф +100% чар/+35% крита/+30% вампиризма/+150% мана-регена).

### Враги (`res://resources/enemies/`, всего 22 врага)
- Тиры 1–10: `slime.tres`, `wolf.tres`, `goblin.tres`, `bandit.tres`, `skeleton.tres`, `dark_mage.tres`, `bog_toad.tres`, `swamp_witch.tres`, `ice_golem.tres`, `frost_wyvern.tres`, `orc_warlord.tres`, `shadow_lich.tres`, `fire_elemental.tres`, `ember_knight.tres`, `ancient_dragon.tres`, `abyssal_naga.tres`, `krakens_spawn.tres`, `void_stalker.tres`, `astral_archon.tres`, `fallen_seraph.tres`, `eternal_titan.tres`.
- Босс 100-й сложности: `resources/enemies/curse_warden.tres` — 🧿 Хранитель Проклятий (эскалирует с каждым убийством в ране, выдаёт +1 🎲 жетон реролла).

### Локации (`res://resources/locations/`, всего 11 локаций)
- `quiet_glade.tres` (1+), `dark_forest.tres` (3+), `ancient_ruins.tres` (6+), `swamp_marshes.tres` (10+), `frost_peaks.tres` (15+), `obsidian_citadel.tres` (20+), `dragon_lair.tres` (26+), `sunken_temple.tres` (32+), `astral_spire.tres` (40+), `celestial_throne.tres` (50+).
- `resources/locations/abyss_crucible.tres` — 🌀 Горнило Проклятий (`required_difficulty = 100`, `always_open_once_unlocked = true`).

### Обычные навыки (`res://resources/skills/`, всего 34 узла)
- Центр `(4, 3)`: `hero_foundation.tres`.
- Ветка Ближнего боя и Силы (Вверх-влево / Влево): `heavy_strike.tres`, `melee_practice.tres`, `deadly_precision.tres`, `titan_might.tres`, `executioner_focus.tres`, `colossus_wrath.tres`, `apex_predator.tres`.
- Ветка Дальнего боя и Ловкости (Вниз-влево): `swift_reflexes.tres`, `wind_step.tres`, `eagle_eye.tres`, `lightning_tempo.tres`, `quiver_conservation.tres`, `phantom_stride.tres`, `wind_archer_mastery.tres`.
- Ветка Магии и Практики (Вверх): `arcane_spark.tres`, `spell_weaving.tres`, `mana_flow.tres`, `archmage_focus.tres`, `elemental_mastery.tres`, `quick_learning.tres`.
- Ветка Стойкости и Защиты (Вниз): `iron_bastion.tres`, `thick_hide.tres`, `vital_surge.tres`, `immortal_vessel.tres`, `guardian_aegis.tres`.
- Ветка Процветания, Мудрости и Убежища (Вправо): `treasure_hunter.tres`, `golden_greed.tres`, `midas_blessing.tres`, `battle_scholar.tres`, `ancient_wisdom.tres`, `cosmic_enlightenment.tres`, **`herbal_mastery.tres`** (`🔒 Сл.10+`), **`master_brewer.tres`** (`🔒 Сл.10+`).

### Тёмные навыки (`res://resources/dark_skills/`, всего 26 узлов)
- Центр `(3, 2)`: `abyss_awakening.tres`.
- Кровь и Ярость (Влево-вверх): `blood_vampirism.tres`, `echo_strike.tres`, `armor_rend.tres`, `dark_execution.tres`, `berserk_fury.tres`, `immortal_pact.tres`.
- Стрелки и Ветер (Влево-вниз): `shadow_quiver.tres`, `piercing_volley.tres`, `phantom_arrows.tres`, `deadeye_abyss.tres`, `wind_mastery_dark.tres`.
- Тайная Аркана и Духи (Вправо-вверх): `mana_fountain.tres`, `swift_runes.tres`, `spell_overload.tres`, `arcane_barrier.tres`, `arcane_echo.tres`, `spirit_communion.tres`.
- Тёмная Алхимия, Жатва и Убежище (Вправо-вниз): `titan_heritage.tres`, `blacksmith_brand.tres`, `abyssal_greed.tres`, `curse_ward.tres`, `ancient_memory.tres`, `soul_harvest.tres`, **`abyss_botanist.tres`** (`🔒 Сл.10+`), **`eternal_cauldron.tres`** (`🔒 Сл.10+`).
