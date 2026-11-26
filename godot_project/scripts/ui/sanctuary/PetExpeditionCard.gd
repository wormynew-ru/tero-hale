class_name PetExpeditionCard
extends PanelContainer

signal feedback_emitted(msg: String)

@onready var status_label: Label = %StatusLabel
@onready var short_button: Button = %ShortButton
@onready var long_button: Button = %LongButton
@onready var claim_button: Button = %ClaimButton
@onready var progress_bar: ProgressBar = %ProgressBar

var _pet: PetData = null


func _ready() -> void:
	short_button.pressed.connect(func() -> void: _start_plan("short"))
	long_button.pressed.connect(func() -> void: _start_plan("long"))
	claim_button.pressed.connect(_on_claim_pressed)


func bind_pet(pet: PetData) -> void:
	_pet = pet


func get_pet() -> PetData:
	return _pet


func refresh_state() -> void:
	if _pet == null:
		visible = false
		return
	var owned: bool = GameManager.has_pet_owned(_pet.id)
	visible = owned
	if not owned:
		return
	var pet_exp: Dictionary = GameManager.get_pet_expedition(_pet.id)
	var is_eq: bool = GameManager.equipped_pet_id == _pet.id
	if pet_exp.is_empty():
		progress_bar.visible = false
		claim_button.visible = false
		short_button.visible = true
		long_button.visible = true
		short_button.disabled = is_eq
		long_button.disabled = is_eq
		if is_eq:
			status_label.text = "%s %s — В бою с героем (снимите для отправки)" % [_pet.icon_emoji, _pet.pet_name]
			status_label.modulate = Color(0.84, 0.88, 0.96, 1.0)
		else:
			status_label.text = "%s %s — Свободен для вылазки (15м / 1ч)" % [_pet.icon_emoji, _pet.pet_name]
			status_label.modulate = Color.WHITE
	elif bool(pet_exp.get("completed", false)):
		progress_bar.visible = true
		progress_bar.max_value = 100.0
		progress_bar.value = 100.0
		short_button.visible = false
		long_button.visible = false
		claim_button.visible = true
		claim_button.disabled = false
		claim_button.modulate = Color(0.45, 0.98, 0.72, 1.0)
		status_label.text = "🎁 %s %s вернулся из экспедиции! Заберите награду." % [_pet.icon_emoji, _pet.pet_name]
		status_label.modulate = Color(0.45, 0.98, 0.72, 1.0)
	else:
		progress_bar.visible = true
		short_button.visible = false
		long_button.visible = false
		claim_button.visible = false
		update_timer()


func update_timer() -> void:
	if _pet == null or not GameManager.has_pet_owned(_pet.id):
		return
	var pet_exp: Dictionary = GameManager.get_pet_expedition(_pet.id)
	if pet_exp.is_empty() or bool(pet_exp.get("completed", false)):
		return
	var elapsed: float = float(pet_exp.get("elapsed", 0.0))
	var dur: float = maxf(1.0, float(pet_exp.get("duration", 900.0)))
	var rem: float = maxf(0.0, dur - elapsed)
	var rem_min: int = floori(rem / 60.0)
	var rem_sec: int = floori(fmod(rem, 60.0))
	status_label.text = "🧭 %s %s в экспедиции — осталось %d:%02d" % [_pet.icon_emoji, _pet.pet_name, rem_min, rem_sec]
	status_label.modulate = Color(0.45, 0.92, 1.0, 1.0)
	progress_bar.max_value = dur
	progress_bar.value = minf(elapsed, dur)


func _start_plan(plan_id: String) -> void:
	if _pet == null:
		return
	var res: Dictionary = GameManager.start_pet_expedition(_pet.id, plan_id)
	feedback_emitted.emit(str(res.get("message", "")))


func _on_claim_pressed() -> void:
	if _pet == null:
		return
	var res: Dictionary = GameManager.claim_pet_expedition(_pet.id)
	feedback_emitted.emit(str(res.get("message", "")))
