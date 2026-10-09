extends SceneTree

## Validates the shape of every level and diplomacy JSON file njinga_game.gd
## reads at runtime (see LEVEL_PATHS/DIPLOMACY_PATHS in scripts/njinga_game.gd).
## njinga_game.gd's own loader silently drops a file that fails to parse, so
## this is the only thing that catches a malformed content file. Run via:
##   godot --headless --path . -s test/content_integrity.gd

const LEVEL_PATHS := [
	"res://data/levels/nivel1.json",
	"res://data/levels/nivel2.json",
	"res://data/levels/nivel3.json",
	"res://data/levels/nivel4.json",
	"res://data/levels/nivel5.json",
	"res://data/levels/nivel6.json",
]
const DIPLOMACY_IDS := ["luanda1622", "holandeses1641", "tratado1656"]
const DIPLOMACY_CHOICES := ["Firme", "Conciliadora", "Astuta"]

var _failed := false

func _initialize() -> void:
	for path in LEVEL_PATHS:
		_check_level(path)
	for id in DIPLOMACY_IDS:
		_check_diplomacy("res://data/diplomacy/%s.json" % id)

	if _failed:
		quit(1)
		return
	print("[CONTENT_PASS] %d levels and %d diplomacy files are well-formed" % [LEVEL_PATHS.size(), DIPLOMACY_IDS.size()])
	quit(0)

func _check_level(path: String) -> void:
	var data := _read_json(path)
	if data.is_empty():
		return
	for key in ["id", "title", "spawn", "world_width", "goal_x", "platforms"]:
		_check(data.has(key), "%s missing required key '%s'" % [path, key])
	if not data.has("spawn") or not data.has("world_width") or not data.has("goal_x") or not data.has("platforms"):
		return
	_check(data["spawn"] is Array and data["spawn"].size() == 2, "%s 'spawn' must be a 2-element array" % path)
	_check(data["platforms"] is Array and data["platforms"].size() > 0, "%s must define at least one platform" % path)
	for p in data["platforms"]:
		_check(p is Array and p.size() == 4, "%s has a malformed platform entry: %s" % [path, p])
	_check(float(data["goal_x"]) <= float(data["world_width"]), "%s 'goal_x' (%s) is beyond 'world_width' (%s)" % [path, data["goal_x"], data["world_width"]])
	if data.has("diplomacy"):
		_check(str(data["diplomacy"]) in DIPLOMACY_IDS, "%s references unknown diplomacy id '%s'" % [path, data["diplomacy"]])

func _check_diplomacy(path: String) -> void:
	var data := _read_json(path)
	if data.is_empty():
		return
	for key in ["title", "interlocutor", "rounds"]:
		_check(data.has(key), "%s missing required key '%s'" % [path, key])
	if not data.has("rounds"):
		return
	var rounds: Array = data["rounds"]
	_check(not rounds.is_empty(), "%s has no diplomacy rounds" % path)
	for round_data in rounds:
		for key in ["request", "hint", "best"]:
			_check(round_data.has(key), "%s has a round missing '%s'" % [path, key])
		if round_data.has("best"):
			_check(str(round_data["best"]) in DIPLOMACY_CHOICES, "%s round 'best' value '%s' is not a valid choice" % [path, round_data["best"]])

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not _check(file != null, "could not open %s" % path):
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not _check(data is Dictionary, "%s is not valid JSON" % path):
		return {}
	return data

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("[CONTENT_FAIL] " + message)
		_failed = true
	return condition
