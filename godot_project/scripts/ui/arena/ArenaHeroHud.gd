class_name ArenaHeroHud
extends HBoxContainer

signal open_menu_requested

@onready var hero_crest_button: Button = %HeroCrestButton
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var xp_label: Label = %XPLabel
@onready var hero_crest_hp_bar: ProgressBar = %HeroCrestHPBar
@onready var hero_crest_hp_label: Label = %HeroCrestHPLabel

@onready var str_badge_label: Label = %StrBadgeLabel
@onready var agi_badge_label: Label = %AgiBadgeLabel
@onready var end_badge_label: Label = %EndBadgeLabel
@onready var int_badge_label: Label = %IntBadgeLabel
@onready var crest_red_label: Label = %CrestRedLabel
@onready var crest_blue_label: Label = %CrestBlueLabel


func _ready() -> void:
	hero_crest_button.pressed.connect(func() -> void: open_menu_requested.emit())


func refresh_stats() -> void:
	if GameManager.is_afk_mode:
		return
	level_label.text = "Lv. %d" % GameManager.level
	var xp_req: float = GameManager.get_xp_to_next_level()
	xp_bar.max_value = xp_req
	xp_bar.value = GameManager.current_xp
	xp_label.text = "%s / %s" % [
		NumberFormatter.format_number(GameManager.current_xp),
		NumberFormatter.format_number(xp_req),
	]

	var total_str: int = GameManager.get_total_strength()
	var total_agi: int = GameManager.get_total_agility()
	var total_end: int = GameManager.get_total_endurance()
	var total_int: int = GameManager.get_total_intellect()

	str_badge_label.text = "⚔️\n%d" % total_str
	agi_badge_label.text = "⚡\n%d" % total_agi
	end_badge_label.text = "🛡️\n%d" % total_end
	int_badge_label.text = "🧠\n%d" % total_int


func update_hp(current_hp: float, max_hp: float, cur_str: String, max_str: String, update_labels: bool) -> void:
	hero_crest_hp_bar.max_value = max_hp
	hero_crest_hp_bar.value = current_hp
	if update_labels:
		hero_crest_hp_label.text = "%s/%s" % [cur_str, max_str]
		crest_red_label.text = "❤️ %s" % cur_str


func update_mana_label(has_mana: bool, cur_str: String) -> void:
	crest_blue_label.text = "💧 %s" % (cur_str if has_mana else "0")
