extends Node
## docs/01, docs/06 — 전투 규칙 수치 (카드/손맛과 무관한 규칙만)

const PLAYER_MAX_HP: int = 100
const ENEMY_MAX_HP: int = 120

const STARTING_HAND_SIZE: int = 5
const REROLL_COUNT_PER_TURN: int = 1
const BASE_ACTION_TIME: float = 7.0
const MAX_ACTION_TIME: float = 15.0
const ACTION_TIME_GAIN_CAP_PER_USE: float = 3.0
const BASE_SLOT_COUNT: int = 5
const TEMPORARY_SLOT_COUNT: int = 2

const RESOLVE_PHASE_DELAY_SEC: float = 0.35
