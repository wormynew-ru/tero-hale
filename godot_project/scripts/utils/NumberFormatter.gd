class_name NumberFormatter
extends RefCounted

const SUFFIXES: Array[String] = [
	"",
	"K",
	"M",
	"B",
	"T",
	"Qa",
	"Qi",
	"Sx",
	"Sp",
	"Oc",
	"No",
	"Dc",
	"Ud",
	"Dd",
	"Td",
	"Qad",
	"Qid",
	"Sxd",
	"Spd",
	"Ocd",
	"Nod",
	"Vg",
]


static func format_number(value: float) -> String:
	var sign_prefix: String = "-" if value < 0.0 else ""
	var abs_val: float = absf(value)
	if is_nan(abs_val) or is_inf(abs_val):
		return "∞"
	if abs_val < 1000.0:
		return "%s%d" % [sign_prefix, roundi(abs_val)]

	var tier: int = int(floor(log(abs_val) / log(1000.0)))
	if tier < 0:
		tier = 0
	if tier >= SUFFIXES.size():
		tier = SUFFIXES.size() - 1

	var divisor: float = pow(1000.0, float(tier))
	var scaled: float = abs_val / divisor
	if scaled >= 999.95 and tier + 1 < SUFFIXES.size():
		tier += 1
		scaled /= 1000.0

	var suffix: String = SUFFIXES[tier]
	if scaled >= 100.0:
		return "%s%.0f%s" % [sign_prefix, scaled, suffix]
	if scaled >= 10.0:
		return "%s%.1f%s" % [sign_prefix, scaled, suffix]
	return "%s%.2f%s" % [sign_prefix, scaled, suffix]
