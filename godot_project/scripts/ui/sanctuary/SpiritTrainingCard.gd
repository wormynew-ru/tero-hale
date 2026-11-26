class_name SpiritTrainingCard
extends PanelContainer

signal feedback_emitted(msg: String)

@onready var info_label: Label = %InfoLabel
@onready var train_button: Button = %TrainButton

var _spirit_key: String = ""
var _spirit_title: String = ""
var _spirit_desc: String = ""


func _ready() -> void:
	train_button.pressed.connect(_on_train_pressed)
	HoldAutoClicker.attach(train_button, 50.0)


func bind_spirit(skey: String, title_text: String, desc_text: String) -> void:
	_spirit_key = skey
	_spirit_title = title_text
	_spirit_desc = desc_text


func refresh_state(is_spirit: bool, fruit_cnt: int) -> void:
	var lvl: int = GameManager.get_spirit_training_level(_spirit_key)
	info_label.text = "%s [Ур.%d] — %s (+%d%% сила, +%d%% скорость)" % [
		_spirit_title, lvl, _spirit_desc, lvl * 15, lvl * 3
	]
	train_button.disabled = (not is_spirit) or (fruit_cnt <= 0)
	train_button.text = "🌟 Дрессировать (1 плод)" if is_spirit else "🔒 Нужен Спирит"


func _on_train_pressed() -> void:
	if _spirit_key.is_empty():
		return
	var res: Dictionary = GameManager.train_spirit(_spirit_key)
	feedback_emitted.emit(str(res.get("message", "")))
