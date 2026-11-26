class_name SanctuarySpiritTab
extends VBoxContainer

signal feedback_emitted(msg: String)

const PetExpeditionCardScene := preload("res://scenes/sanctuary/PetExpeditionCard.tscn")
const SpiritTrainingCardScene := preload("res://scenes/sanctuary/SpiritTrainingCard.tscn")

@onready var expeditions_box: VBoxContainer = %ExpeditionsBox
@onready var spirit_training_status_label: Label = %SpiritTrainingStatusLabel
@onready var spirit_training_box: VBoxContainer = %SpiritTrainingBox

var _pet_cards: Array[PetExpeditionCard] = []
var _spirit_cards: Array[SpiritTrainingCard] = []
var _last_exp_sig: String = ""
var _last_spirit_sig: String = ""


func _ready() -> void:
	_build_pet_expeditions()
	_build_spirit_training()


func reset_cache() -> void:
	_last_exp_sig = ""
	_last_spirit_sig = ""


func sync_state(force: bool = false) -> void:
	if not is_visible_in_tree() and not force:
		return
	_sync_pet_expeditions(force)
	_sync_spirit_training(force)


func update_timers() -> void:
	if not is_visible_in_tree():
		return
	for card: PetExpeditionCard in _pet_cards:
		card.update_timer()


func _build_pet_expeditions() -> void:
	if expeditions_box == null:
		return
	if _pet_cards.is_empty():
		for p: PetData in GameManager.all_pets:
			if p == null:
				continue
			var card: PetExpeditionCard = PetExpeditionCardScene.instantiate() as PetExpeditionCard
			card.feedback_emitted.connect(func(msg: String) -> void: feedback_emitted.emit(msg))
			expeditions_box.add_child(card)
			card.bind_pet(p)
			_pet_cards.append(card)
		return
	var p_idx: int = 0
	for p: PetData in GameManager.all_pets:
		if p == null:
			continue
		if p_idx >= _pet_cards.size():
			var extra_card: PetExpeditionCard = PetExpeditionCardScene.instantiate() as PetExpeditionCard
			extra_card.feedback_emitted.connect(func(msg: String) -> void: feedback_emitted.emit(msg))
			expeditions_box.add_child(extra_card)
			_pet_cards.append(extra_card)
		_pet_cards[p_idx].bind_pet(p)
		p_idx += 1
	for i: int in range(p_idx, _pet_cards.size()):
		_pet_cards[i].visible = false


func _sync_pet_expeditions(force: bool) -> void:
	if expeditions_box == null:
		return
	if _pet_cards.size() < GameManager.all_pets.size():
		_build_pet_expeditions()
		force = true

	var sig_parts: Array[String] = [GameManager.equipped_pet_id]
	for p: PetData in GameManager.all_pets:
		if p == null:
			continue
		var owned: int = 1 if GameManager.has_pet_owned(p.id) else 0
		var pet_exp: Dictionary = GameManager.get_pet_expedition(p.id)
		var state_tag: String = "idle"
		if not pet_exp.is_empty():
			state_tag = "done" if bool(pet_exp.get("completed", false)) else "run:%s" % str(pet_exp.get("plan_id", ""))
		sig_parts.append("%s:%d:%s" % [p.id, owned, state_tag])
	var sig: String = "|".join(sig_parts)

	if not force and sig == _last_exp_sig:
		return
	_last_exp_sig = sig

	for card: PetExpeditionCard in _pet_cards:
		card.refresh_state()


func _build_spirit_training() -> void:
	if not _spirit_cards.is_empty():
		return
	var defs: Array[Dictionary] = [
		{"key": "fire", "title": "🔥 Дух Огня", "desc": "Магический удар каждые 1.4с"},
		{"key": "wind", "title": "🌪️ Дух Ветра", "desc": "Быстрый вихрь каждые 0.95с"},
		{"key": "forest", "title": "🌿 Дух Леса", "desc": "Лечение HP и мана каждые 2.5с"},
		{"key": "earth", "title": "🪨 Дух Земли", "desc": "Тяжёлый удар каждые 2.0с"},
	]
	for d: Dictionary in defs:
		var card: SpiritTrainingCard = SpiritTrainingCardScene.instantiate() as SpiritTrainingCard
		card.feedback_emitted.connect(func(msg: String) -> void: feedback_emitted.emit(msg))
		spirit_training_box.add_child(card)
		card.bind_spirit(str(d["key"]), str(d["title"]), str(d["desc"]))
		_spirit_cards.append(card)


func _sync_spirit_training(force: bool) -> void:
	var fruit_item: ItemData = GameManager.get_cached_item("res://resources/items/spirit_primordial_harvest.tres")
	var fruit_cnt: int = GameManager.get_item_count_in_inventory(fruit_item) if fruit_item != null else 0
	var is_spirit: bool = GameManager.has_hero_class("spirit")
	var lvls: Array[String] = []
	for sk: String in GameManager.SPIRIT_KEYS:
		lvls.append("%s=%d" % [sk, GameManager.get_spirit_training_level(sk)])
	var sig: String = "%s|%d|%s" % ["1" if is_spirit else "0", fruit_cnt, ",".join(lvls)]
	if not force and sig == _last_spirit_sig and _spirit_cards.size() == 4:
		return
	_last_spirit_sig = sig

	if _spirit_cards.size() != 4:
		_build_spirit_training()

	if not is_spirit:
		spirit_training_status_label.text = "🔒 Дрессировка духов открыта только при активном классе 🌿 Спирит (Сл.50+). Плодов первоцвета в рюкзаке: %d." % fruit_cnt
		spirit_training_status_label.modulate = Color(0.84, 0.78, 0.52, 1.0)
	else:
		spirit_training_status_label.text = "🌟 Класс 🌿 Спирит активен! Плодов первоцвета духов в рюкзаке: %d (стоимость дрессировки: 1 плод → +15%% сила и +3%% скорость духа)." % fruit_cnt
		spirit_training_status_label.modulate = Color(0.45, 0.98, 0.85, 1.0)

	for card: SpiritTrainingCard in _spirit_cards:
		card.refresh_state(is_spirit, fruit_cnt)
