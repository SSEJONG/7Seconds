class_name CardDefinition
extends Resource
## docs/06 CardDefinition — 카드 정적 정의

enum CardType {
	ATTACK,
	DEFENSE,
	MOBILITY,
	TACTIC,
	TECHNIQUE,
}

@export var id: String = ""
@export var display_name: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var base_uses: int = 1
@export var damage: int = 0
@export var stagger_damage: int = 0
@export var startup_sec: float = 0.1
@export var active_sec: float = 0.15
@export var recovery_sec: float = 0.25
@export var range_m: float = 2.0
@export var can_dodge_cancel: bool = true
@export var action_time_delta: float = 0.0
@export var draw_on_hit: bool = false


static func card_type_from_string(raw: String) -> CardType:
	match raw.to_upper():
		"ATTACK":
			return CardType.ATTACK
		"DEFENSE":
			return CardType.DEFENSE
		"MOBILITY":
			return CardType.MOBILITY
		"TACTIC":
			return CardType.TACTIC
		"TECHNIQUE":
			return CardType.TECHNIQUE
		_:
			return CardType.ATTACK


static func card_type_to_string(t: CardType) -> String:
	match t:
		CardType.ATTACK:
			return "ATTACK"
		CardType.DEFENSE:
			return "DEFENSE"
		CardType.MOBILITY:
			return "MOBILITY"
		CardType.TACTIC:
			return "TACTIC"
		CardType.TECHNIQUE:
			return "TECHNIQUE"
		_:
			return "ATTACK"
