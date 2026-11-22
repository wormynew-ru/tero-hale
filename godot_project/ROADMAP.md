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
- `scenes/BattleArenaUI.tscn` — модульная сцена боевой арены (левая часть экрана): кликабельный круглый герб героя, 3 стат-круга, **кнопка `🏡 Деревня` справа сверху**, **отдельный слот путника/питомца (`CompanionSlotButton`)**, персонажи с `AttackDiamond` над головой и полосами HP/Маны с текстом и процентами внутри, 3 активных слота магии (`AbilitySlotButton`) + индикатор баффов слева снизу, кнопка поиска боя (`⚔️`/`🏳️`) по центру и `РЮКЗАК 🎒` (со счётчиком снарядов/книг-фолиантов для дальнобойного и магического оружия) справа.
- `scenes/RightSidebarUI.tscn` — модульная сцена правой боковой панели: прокручиваемый блок `КАРТА` (включая `⛏️ Древнюю Шахту` с пометкой `(1 заход)` / `(Заход окончен)` и всегда открытую бонус-локацию `Горнило Проклятий` после 100-й сложности) и сетка `2×3` быстрых слотов первых 6 предметов из `GameManager.inventory[0..5]`.
- `scenes/HeroMenuUI.tscn` — модульная сцена меню героя, открываемая нажатием на герб: хаб со всеми разделами (`🏡 Карта деревни`, `☀️/🏡 Убежище: Сады и Зелья`, `Статы и Навыки`, `Класс героя`, `Путники`, `Заклинания (20)`, `Древо талантов`, `Тёмные навыки`, `Инвентарь`, `Кузня`, `🔥 Тёмная кузня`, `Лавка`, `Сложность / Ран`, `F.A.Q.`, `AFK-режим`) и встроенными подсценами.
- `scenes/VillageMapUI.tscn` — модульная сцена иллюстрированной карты деревни поверх `res://assets/textures/village_map.jpg` с 4 невидимыми кликабельными кнопками: Домик (`Убежище: Светлый сад Сл.1+, Тёмный и Зелья Сл.10+`), «МАГАЗИН» (выбор `Лавка` / `Кузня` / `🔥 Тёмная кузня`), Щенок (`Путники`), Горы (возврат к бою).
- `scenes/SanctuaryUI.tscn` — модульная сцена Убежища: **☀️ Светлый сад (Сл.1+, 3 грядки)** для простых растений, приманки путников по 3-слотовому узору и выращивания пряников; **🌿 Дрессировка духов Спирита**; **🌑 Тёмный сад (Сл.10+)** для редких зельевых семян (`🌺 Алый лепесток` за 2000 побед и `🌟 Первоцвет духов` с `0.03%` шансом от Вечного титана и мгновенным ростом при кормлении духам базовых светлых растений) и многоступенчатое Зельеварение.
- `scenes/ClassUI.tscn` — модульная сцена выбора класса героя (открываются на Сл.50+: *Странник*, *Алхимик*, *Тролль*, *Спирит*, *Снайпер Бездны*, *Архимаг Крови*, *Отражатель*).
- `scenes/PetUI.tscn` — модульная сцена приюта путников: просмотр приманки в Светлом саду (без покупки за золото), экипировка бессмертных питомцев и **дрессировка пряниками (`★`/`👍`/`🍪`)** до Ур.10 (`+12%` за уровень).
- `scenes/SpellbookUI.tscn` — модульная сцена Книги заклинаний (20 заклинаний: 14 общих + 6 эксклюзивов Архимага Крови; выбор до 3 активных слотов боя).
- `scenes/AttackDiamond.tscn` — модульный виджет ромба перезарядки атаки над сущностями (заполнение снизу вверх).
- `scenes/AbilitySlotButton.tscn` — модульная круглая кнопка магической способности (одиночный тап — применение, удержание 1 сек — переключение автоприменения).
- `scenes/StatsUI.tscn` — модульная сцена характеристик (Сила, Ловкость, Выносливость, **Инта**, бонусы посохов/книг к силе заклинаний, снижению манакоста и длительности эффектов), сводки активного класса, уровня дрессировки путника и 4 духов Спирита, 3 прогресс-баров *Learn by Doing* (Ближний бой, Дальний бой, Магия), прокачки за очки навыков/золото, **экспорта/импорта сохранения в `.txt` и буфер обмена (`ExportTxtDialog` / `ImportTxtDialog`)** и полного сброса прогресса.
- `scenes/InventoryUI.tscn` — модульная сцена инвентаря: слоты оружия/брони (`+N` и `🌑+D`), **снарядов/книг**, активного **путника**, предупреждение класса Спирит, **карточка настроек авто-зелий (пороги и условия для HP/MP, авто-бафф по истечению с фильтром бафф-зелий)**, быстрые кнопки **HP и MP зелий** и список рюкзака (включая `♾️` вечные предметы, материалы Шахты, семена и урожай).
- `scenes/EnchantUI.tscn` — модульная сцена Кузни для зачарования слотов Оружия и Брони от `+0` до `+100` (или до **`+250`** для Алхимика) за золото с отображением суммарной Тёмной заточки `🌑+D` и бонуса Инты.
- `scenes/DarkForgeUI.tscn` — модульная сцена **🔥 Тёмной кузни**: вечная Тёмная заточка слотов за `🌑 Очки Тьмы` (`+0→+1: 25%`, `+1→+2: 20%`, мин. `15%`, не сбрасывается между ранами) и ковка вечных предметов (`is_dark_forged`) + сшивание книг Типа 1/2 из `⛏️ Руды Бездны` и `📜 Древних листов`.
- `scenes/SkillTreeUI.tscn` — модульная сцена Дерева навыков (34 узла, включая 2 закрытых до Сл.10 садовых/алхимических таланта).
- `scenes/DarkSkillTreeUI.tscn` — модульная сцена Тёмных навыков (26 постоянных узлов в 4 расходящихся ветках Бездны за 🌑 Очки Тьмы, включая 2 узла Убежища Сл.10+).
- `scenes/DifficultyUI.tscn` — модульная сцена выбора сложности, реролла проклятий каждого тира за жетоны `🎲`, статуса босса 100-й сложности и запуска Нового рана.
- `scenes/ShopUI.tscn` — модульная сцена лавки торговца с покупкой зелий HP, **зелий маны**, **бафф-зелий**, базового снаряжения ближнего боя/брони/стартовых посохов/книг/мантий и всего дальнего боя (луки/арбалеты/снаряды x50); топовая экипировка ближнего боя, редкая броня и топовые посохи/мантии выпадают только с врагов.
- `scenes/FaqUI.tscn` — модульная сцена справочника `F.A.Q.` с описанием *Learn by Doing*, луков/арбалетов/снарядов, **магических посохов/книг-снарядов/мантий и Инты**, **🔥 Тёмной кузни**, **⛏️ Древней Шахты (1 заход за ран)**, **настроек авто-зелий**, классов (Сл.50+), **Светлого и Тёмного садов, приманки/дрессировки путников, Первоцвета духов (`0.03%`) и многоступенчатого Зельеварения**, 100-й локации и рероллов.
- `scenes/AfkOverlayUI.tscn` — модульная сцена карманного OLED AFK-оверлея (`#000000`, 2 FPS) со статистикой текущей сессии и кнопкой полного отключения рендера.

## Ассеты (`res://assets/`)
- `assets/textures/village_map.jpg` — иллюстрированная карта деревни (1408×768 JPEG) с домиком, магазином, щенком и горами для `VillageMapUI.tscn`.

## Основные скрипты (`res://scripts/`)
- `scripts/GameManager.gd` — Autoload-синглтон (`PROCESS_MODE_ALWAYS`): статы (включая Инту, силу заклинаний, снижение манакоста и длительность эффектов), *Learn by Doing* мастерство (`melee`/`ranged`/`magic`), классы (Сл.50+), экипировка (мечи, луки/арбалеты, **посохи + книги-снаряды + мантии**, вечные предметы `is_dark_forged`) и заточка (`+100`/`+250` + **вечная Тёмная заточка**), **🔥 Тёмная кузня**, инвентарь (`ItemType.MATERIAL` для `abyss_ore` / `ancient_page`), **⛏️ Шахта (1 заход за ран, глубина, блокировка при смерти)**, **настраиваемые авто-зелья (HP, MP и авто-баффы по истечению с фильтром)**, 34 обычных и 26 тёмных навыков, **☀️ Светлый сад и 🌑 Тёмный сад + Зельеварение (сохраняются между ранами)**, сложности, реролл проклятий, атомарное автосохранение каждые 8 минут в `user://save.tres` (с бэкапом `user://save.bak.tres`) и **экспорт/импорт прогресса в `.txt`**.
- `scripts/CombatSystem.gd` — машина состояний боя (`PROCESS_MODE_ALWAYS`): ближний/дальний/магический бой (посохи + книги-снаряды с опытом `magic`), двойной выстрел, опыт *Learn by Doing*, бесконечный `-1` армор-шред Тролля, **4 природных духа Спирита**, механики Отражателя и **масштабируемых дрессировкой Путников**, **дроп редких семян (`0.03%` Первоцвет духов)**, **случайные находки в Шахте (`mine_find_triggered`), масштабирование глубины и блокировка Шахты при смерти**, периодический тик всех настраиваемых авто-зелий (`try_auto_use_all_potions`) и эскалация Хранителя Проклятий.
- `scripts/MainUI.gd` — корневой оркестратор `Main.tscn`: привязывает `CombatSystem` к `BattleArenaUI`, скрывает `RootHBox` в AFK-режиме и связывает открытие `HeroMenuUI` (включая прямой переход на карту деревни).
- `scripts/SkillTreeUI.gd` — контроллер `SkillTreeUI.tscn`: построение графа из 34 узлов с автоцентрированием на корневой узел `hero_foundation` и блокировкой `🔒 Сл.10` для талантов Убежища.
- `scripts/utils/NumberFormatter.gd` — статический форматер крупных чисел с суффиксами `K`, `M`, `B`, `T`, `Qa`, `Qi`, `Sx`, `Sp`, `Oc`, `No`, `Dc` и т.д.
- `scripts/utils/HoldAutoClicker.gd` — класс `HoldAutoClicker`: подключает к кнопкам автоклик **50 раз/с** при удержании на ПК и сенсорных экранах (без повторного срабатывания на отпускание и с защитным guard-условием).

## Контроллеры UI-модулей (`res://scripts/ui/`)
- `scripts/ui/BattleArenaUI.gd` — контроллер `BattleArenaUI.tscn`: аватар с классом/оружием, кнопка `🏡 Деревня`, анимация летящих стрел/болтов/магических разрядов, попапы духов природы, уровней мастерства, **находок в Шахте и провала захода в Шахте**, счётчик среза брони Тролля `[🦴-N]`, счётчик снарядов/книг и награда реролла.
- `scripts/ui/RightSidebarUI.gd` — контроллер `RightSidebarUI.tscn`: список локаций `КАРТА` (с кэшированием сигнатуры и статусами `⛏️ Древней Шахты`) и сетка `СЛОТ 1–6` (автоклик 50/с при удержании расходуемых зелий со страховкой от смены предмета в слоте).
- `scripts/ui/HeroMenuUI.gd` — контроллер `HeroMenuUI.tscn`: навигация по всем разделам включая `VillageMapUI`, `SanctuaryUI`, `DarkForgeUI`, `ClassUI`, `PetUI` и `SpellbookUI`, отображение жетонов `🎲`.
- `scripts/ui/VillageMapUI.gd` — контроллер `VillageMapUI.tscn`: обработка невидимых кнопок карты деревни и всплывающего выбора «Лавка / Кузня / 🔥 Тёмная кузня» для здания «МАГАЗИН».
- `scripts/ui/SanctuaryUI.gd` — контроллер `SanctuaryUI.tscn`: управление Светлым садом, дрессировкой 4 духов Спирита (удержание 50/с), Тёмным садом, котлами варки и книгой рецептов с кэшированием сигнатур и обновлением на месте.
- `scripts/ui/ClassUI.gd` — контроллер `ClassUI.tscn`: отображение разблокировки классов (Сл.50+) и переключение активного класса.
- `scripts/ui/PetUI.gd` — контроллер `PetUI.tscn`: подсказки приманки, экипировка и прямое кормление пряниками с обновлением карточек на месте и автокликом 50/с при удержании.
- `scripts/ui/SpellbookUI.gd` — контроллер `SpellbookUI.tscn`: каталог 20 заклинаний (14 общих + 6 Архимага Крови) и привязка до 3 активных слотов.
- `scripts/ui/AttackDiamond.gd` — отрисовка 45°-ромба шкалы атаки через `_draw()`.
- `scripts/ui/AbilitySlotButton.gd` — обработка короткого тапа и удержания `1.0 сек` для автокаста магии, отображение КД, активных баффов, тика перегрузки `🔥Тn` и стоимости маны.
- `scripts/ui/StatsUI.gd` — контроллер `StatsUI.tscn`: сводка статов (включая Инту, силу чар, манакост, длительность), класса, духов, *Learn by Doing*, тренировка за ОН и золото с автокликом 50/с при удержании, **экспорт/импорт `.txt` файла и буфера обмена**.
- `scripts/ui/InventoryUI.gd` — контроллер `InventoryUI.tscn`: слоты экипировки (включая `♾️` вечные вещи), настройки **авто-зелий (HP/MP пороги и условия, авто-бафф по истечению + фильтр баффов)**, быстрые кнопки HP/MP (50/с при удержании), обновление строк на месте и автоклик 50/с при удержании для расходуемых зелий и продажи стеков.
- `scripts/ui/EnchantUI.gd` — контроллер `EnchantUI.tscn`: ковка от `+0` до `+100`/`+250` (с учётом суммарной Тёмной заточки `🌑+D` и бонуса Инты) с автокликом 50/с при удержании кнопок зачарования.
- `scripts/ui/DarkForgeUI.gd` — контроллер `DarkForgeUI.tscn`: вечная Тёмная заточка за `🌑 Очки Тьмы` (50/с при удержании) и ковка вечного снаряжения + книг-снарядов из `⛏️ Руды Бездны` и `📜 Древних листов`.
- `scripts/ui/DarkSkillTreeUI.gd` — контроллер `DarkSkillTreeUI.tscn`: граф из 26 узлов Бездны с автоцентрированием на корень `abyss_awakening` и блокировкой `🔒 Сл.10`.
- `scripts/ui/DifficultyUI.gd` — контроллер `DifficultyUI.tscn`: выбор сложности (кнопки `-` / `+` с автокликом 50/с при удержании), реролл проклятий `🎲` и запуск Нового рана.
- `scripts/ui/ShopUI.gd` — контроллер `ShopUI.tscn`: обновление цен на месте и автоклик 50/с при удержании кнопок покупки.
- `scripts/ui/FaqUI.gd` — контроллер `FaqUI.tscn`: актуальный справочник по всем системам.
- `scripts/ui/AfkOverlayUI.gd` — контроллер `AfkOverlayUI.tscn`: карманный OLED AFK-оверлей (`2 FPS` / отключение рендера).

## Классы ресурсов (`res://scripts/resources/`)
- `scripts/resources/ItemData.gd` — класс `ItemData` (`WEAPON`, `ARMOR`, `CONSUMABLE`, `AMMO`, `SEED`, `HARVEST`, `MATERIAL`; стили `MELEE`, `BOW`, `CROSSBOW`, `STAFF`; снаряды `ARROW`, `BOLT`, `TOME`; статы Инты, силы чар, снижения манакоста, длительности эффектов; флаг `is_dark_forged`, параметры бафф-зелий и садовые категории).
- `scripts/resources/CropData.gd` — класс `CropData` (`id`, `crop_name`, `icon_emoji`, `garden_type`, `grow_seconds`, `required_final_boss_kills`, `base_drop_chance`, `boss_drop_chance`, `final_boss_only`, `is_spirit_training_crop`, `instant_grow_feed_items`, `min_enemy_xp`, `harvest_min`, `harvest_max`, `seed_item_path`, `harvest_item_path`).
- `scripts/resources/EnemyData.gd` — класс `EnemyData` (`icon_emoji`, HP, `max_mana`, урон, ловкость, защита, награды XP/золото, пул дропа и шансы).
- `scripts/resources/LocationData.gd` — класс `LocationData` (`icon_emoji`, название, `required_level`, `required_difficulty`, `always_open_once_unlocked`, `is_one_attempt_mine`, список врагов, цвет фона).
- `scripts/resources/SkillNodeData.gd` — класс `SkillNodeData` (включая `requires_alchemy` для блокировки Сл.10+ и бонусы `garden_mastery` / `extra_brew_slot`).
- `scripts/resources/DarkSkillNodeData.gd` — класс `DarkSkillNodeData` (26 эффектов Бездны, включая `requires_alchemy`, `seed_drop_mult` и `brew_speed_mult`).
- `scripts/resources/HeroClassData.gd` — класс `HeroClassData` (`id`, `title`, `icon_emoji`, `subtitle`, `description`, `passive_summary`, `required_difficulty`, `disables_equipment`, `accent_color`).
- `scripts/resources/AbilityData.gd` — класс `AbilityData` (`id`, `title`, `icon_emoji`, `description`, `required_class_id`, `mana_cost`, `cooldown`, `effect_type`, `power_multiplier`, параметры баффов/DoT/мульти-ударов/жертвы HP).
- `scripts/resources/PetData.gd` — класс `PetData` (`id`, `pet_name`, `icon_emoji`, `subtitle`, `description`, `effect_type`, `effect_value`, `effect_secondary`, `buy_price`, `required_difficulty`, `accent_color`, `favorite_treat_id`, `secondary_treat_id`, `lure_hint`).
- `scripts/resources/SaveData.gd` — класс `SaveData` (`save_version`, вечные `dark_weapon_enchant_level`, `dark_armor_enchant_level`, постоянные вещи/материалы, `mine_locked_this_run`, `mine_depth`, настройки авто-зелий HP/MP/баффов и фильтр `auto_buff_whitelist`, а также сады, котлы и `dark_points_claimed_difficulties`).

## Данные и ресурсы (`res://resources/`)
### Классы героя (`res://resources/classes/`)
- `resources/classes/wanderer.tres` — 🧭 Странник (базовый класс без ограничений).
- `resources/classes/alchemist.tres` — ⚗️ Алхимик (заточка до +250, -40% цены, x1.60 шанса, +60% лечения зелий и 20% сохранение зелья, +15% золота/регена маны).
- `resources/classes/troll.tres` — 🧌 Тролль (бесконечный -1 брони за удар в минус, +2.5% HP/с в бою, +25% HP, +20% Силы).
- `resources/classes/spirit.tres` — 🌿 Спирит (без экипировки, +35% всех статов, +50% брони, 4 духа природы: Огонь, Ветер, Лес, Земля).
- `resources/classes/abyss_ranger.tres` — 🎯 Снайпер Бездны (+40% урон луков/арбалетов, 60% экономия снарядов, 30% двойной выстрел, криты игнорируют плоскую броню, крит-множитель от Ловкости).
- `resources/classes/blood_archmage.tres` — 🩸 Архимаг Крови (+75% силы магии, -50% манакост, -30% КД, каст за 8% HP без маны, удары снижают КД на 0.5с).
- `resources/classes/reflector.tres` — 🪞 Отражатель (0 прямого урона, +30% Max HP, +40% брони, отражает 20% входящего урона, каждую секунду бьёт на 5% своего Max HP + 0.1% гниения Max HP врага).

### Путники / Питомцы (`res://resources/pets/`, всего 6 спутников без HP; приманиваются в ☀️ Светлом саду и дрессируются пряниками)
- `resources/pets/firework_spark.tres` — 🎆 Фейерверк (оглушает врага в начале каждого боя на 5.0с+, приманка: Искроперчик + Ромашка + Искроперчик).
- `resources/pets/healing_wisp.tres` — 🧚 Лесной светлячок (+2.5%+ Max HP/с в бою и +25%+ регена маны, приманка: Клевер + Ромашка + Клевер).
- `resources/pets/abyss_mimic.tres` — 🪙 Мимик-копилка (+45%+ золота и шанс x2 золота, приманка: Медоягода + Клевер + Медоягода).
- `resources/pets/ember_fox.tres` — 🦊 Огненный лисёнок (поджигает врага на 0.8%+ Max HP/с и даёт +15%+ урона, приманка: Искроперчик + Медоягода + Искроперчик).
- `resources/pets/chrono_owl.tres` — 🦉 Хроно-сова (+35%+ скорость КД магии и шанс сброса КД, приманка: Ромашка + Ромашка + Клевер).
- `resources/pets/thunder_griffin.tres` — 🦅 Грозовой сокол (+12%+ крита, замедление врага, удар молнией каждые 4.0с, приманка: Ромашка + Искроперчик + Медоягода).

### Предметы (`res://resources/items/`, всего 82 предмета)
- Оружие ближнего боя: `wooden_sword.tres`, `hunter_dagger.tres`, `iron_sword.tres`, `steel_halberd.tres`, `assassin_kris.tres`, `dragonbone_blade.tres`, `trident_of_abyss.tres`, `astral_greatsword.tres`.
- Луки и арбалеты: `wooden_bow.tres` (🏹), `iron_crossbow.tres` (🎯), `elven_longbow.tres` (🌿), `dragon_crossbow.tres` (🔥), `astral_bow.tres` (🌠).
- Магические посохи (`WeaponStyle.STAFF`, 5 шт.): `apprentice_staff.tres`, `crystal_wand.tres`, `druid_staff.tres`, `lich_scepter.tres`, `astral_staff.tres`.
- Снаряды (пачки x50): `wooden_arrows.tres`, `steel_arrows.tres`, `astral_arrows.tres`, `iron_bolts.tres`, `mithril_bolts.tres`, `abyss_bolts.tres`.
- Книги-снаряды для посохов (`AmmoKind.TOME`, 4 шт.): Тип 1 (Инта + снижение манакоста) `tome_intellect_flow.tres`, `tome_archon_mind.tres`; Тип 2 (усиление заклинаний + продление эффектов) `tome_spell_amplify.tres`, `tome_primordial_grimoire.tres`.
- Броня и мантии магов (8 шт.): `leather_jacket.tres`, `chainmail_armor.tres`, `steel_plate.tres`, `dragonscale_armor.tres`, `abyssal_carapace.tres`, `celestial_aegis.tres`, **`mage_robe.tres`**, **`astral_vestments.tres`**.
- Материалы Шахты (`ItemType.MATERIAL`, не сбрасываются между ранами): `abyss_ore.tres` (⛏️ Руда Бездны), `ancient_page.tres` (📜 Древний лист).
- Вечные предметы Тёмной кузни (`is_dark_forged = true`, 6 шт., не сбрасываются при Новом ране): `eternal_abyss_blade.tres`, `eternal_void_bow.tres`, `eternal_astral_staff.tres`, `eternal_titan_plate.tres`, `eternal_mage_archrobe.tres`, `tome_eternal_codex.tres` (бесконечная книга-снаряд).
- Зелья лечения: `small_healing_potion.tres`, `medium_healing_potion.tres`, `large_healing_potion.tres`, `elixir_of_life.tres`, `divine_nectar.tres`, `ambrosia_flask.tres`.
- Зелья маны (4 шт.): `small_mana_potion.tres`, `medium_mana_potion.tres`, `large_mana_potion.tres`, `arcane_nectar.tres`.
- Бафф-зелья (4 шт.): `fury_potion.tres`, `ironhide_potion.tres`, `swiftwind_potion.tres`, `arcane_wisdom_potion.tres`.
- Сваренные мастер-зелья Убежища (4 шт.): `moonlight_elixir.tres`, `titan_blood_brew.tres`, `immortal_dew_potion.tres`, `crimson_petal_elixir.tres`.
- Семена **☀️ Светлого сада** (4 шт., `ItemType.SEED`, `garden_category = "light"`): `light_clover_seed.tres`, `honey_berry_seed.tres`, `sky_chamomile_seed.tres`, `spark_chili_seed.tres`.
- Урожай / пряники **☀️ Светлого сада** (4 шт., `ItemType.HARVEST`, `garden_category = "light"`): `light_clover_harvest.tres`, `honey_berry_harvest.tres`, `sky_chamomile_harvest.tres`, `spark_chili_harvest.tres`.
- Семена **🌑 Тёмного сада** (6 шт., `ItemType.SEED`, не пропадают при новом ране): `moon_mint_seed.tres`, `sun_root_seed.tres`, `azure_lotus_seed.tres`, `star_truffle_seed.tres`, `scarlet_petal_seed.tres`, **`spirit_primordial_seed.tres`** (`0.03%` с Вечного титана).
- Урожай **🌑 Тёмного сада** (6 шт., `ItemType.HARVEST`, не пропадает при новом ране): `moon_mint_harvest.tres`, `sun_root_harvest.tres`, `azure_lotus_harvest.tres`, `star_truffle_harvest.tres`, `scarlet_petal_harvest.tres`, **`spirit_primordial_harvest.tres`** (плод для дрессировки духов Спирита).

### Культуры Садов (`res://resources/crops/`, всего 10 культур)
- **☀️ Светлый сад (4 культуры для приманки и пряников путникам)**: `light_clover.tres` (🍀 Светлый клевер, 15с), `honey_berry.tres` (🫐 Медоягода, 20с), `sky_chamomile.tres` (🌼 Небесная ромашка, 25с), `spark_chili.tres` (🌶️ Искроперчик, 30с).
- **🌑 Тёмный сад (6 редких культур)**: `moon_mint.tres` (🌿 Лунная мята, от 0.05%, 45с), `sun_root.tres` (🥕 Солнечный корень, 90с), `azure_lotus.tres` (🪷 Лазурный лотос, 150с), `star_truffle.tres` (🍄 Звёздный трюфель, 240с), `scarlet_petal.tres` (🌺 Алый лепесток, рост за **2000 убийств Вечного титана**), **`spirit_primordial.tres`** (🌟 Первоцвет духов, дроп **`0.03%`** только с Вечного титана, рост 3600с или **мгновенно при кормлении духам по `2×` всех 4 светлых урожаев**).

### Способности (`res://resources/abilities/`, всего 20 заклинаний; 3 активных слота в бою)
- **14 общих заклинаний**:
  - Прямой/мульти/спец-урон и лечение: `fireball.tres` (🔥), `nature_mend.tres` (💚), `arcane_surge.tres` (⚡), `ice_lance.tres` (❄️ пробивает 100% брони), `chain_thunder.tres` (🌩️ 3 удара), `meteor_strike.tres` (☄️ 390%), `mana_siphon.tres` (🌀 урон + хил + мана), `execute_sigil.tres` (🗡️ добивание <40% HP).
  - Периодический и бёрст-урон: `poison_cloud.tres` (☠️ яд DoT 8с), `soul_overload.tres` (🌋 бёрст-перегрузка **12 тиков/с**, до 12 тиков за 1с: сжигает 1/1 → 2/2 → 4/5 → 8/10 → ... HP/MP с растущим взрывом `x1.75^(тик-1)`).
  - Баффы: `battle_frenzy.tres` (⚔️ +45% урона/+25% скорости 10с), `stone_aegis.tres` (🛡️ +120% брони/+15% уклона 10с), `eagle_focus.tres` (🎯 +25% крита/+60% крит-урона 10с), `arcane_meditation.tres` (🔮 +120% регена маны/+40% силы магии 10с).
- **6 эксклюзивов Архимага Крови (`required_class_id = "blood_archmage"`)**:
  - `crimson_lance.tres` (🩸 6% HP + 340% урона), `hemorrhage_curse.tres` (💔 кровотечение 8с с отхилом), `crimson_ward.tres` (🧣 бафф +150% брони/+25% вампиризма/60% шипы), `blood_frenzy.tres` (🦇 бафф +85% урона и чар/+35% скорости), `crimson_nova.tres` (💢 12% HP, 460% чистого урона + отхил), `sanguine_apotheosis.tres` (👑 ульт-бафф +100% чар/+35% крита/+30% вампиризма/+150% мана-регена).

### Враги (`res://resources/enemies/`, всего 26 врагов)
- Тиры 1–10: `slime.tres`, `wolf.tres`, `goblin.tres`, `bandit.tres`, `skeleton.tres`, `dark_mage.tres`, `bog_toad.tres`, `swamp_witch.tres`, `ice_golem.tres`, `frost_wyvern.tres`, `orc_warlord.tres`, `shadow_lich.tres`, `fire_elemental.tres`, `ember_knight.tres`, `ancient_dragon.tres`, `abyssal_naga.tres`, `krakens_spawn.tres`, `void_stalker.tres`, `astral_archon.tres`, `fallen_seraph.tres`, `eternal_titan.tres`.
- Враги Древней Шахты (4 шт.): `mine_kobold.tres`, `rock_golem.tres`, `crystal_spider.tres`, `mine_overseer.tres`.
- Босс 100-й сложности: `resources/enemies/curse_warden.tres` — 🧿 Хранитель Проклятий (эскалирует с каждым убийством в ране, выдаёт +1 🎲 жетон реролла).

### Локации (`res://resources/locations/`, всего 12 локаций)
- `quiet_glade.tres` (1+), `dark_forest.tres` (3+), **`abandoned_mine.tres` (`⛏️ Древняя Шахта`, Ур. 3+, 1 заход за ран)**, `ancient_ruins.tres` (6+), `swamp_marshes.tres` (10+), `frost_peaks.tres` (15+), `obsidian_citadel.tres` (20+), `dragon_lair.tres` (26+), `sunken_temple.tres` (32+), `astral_spire.tres` (40+), `celestial_throne.tres` (50+).
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
