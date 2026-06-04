# 12. 세션 핸드오프 (에이전트용)

> **다음 작업 전에 이 파일 + 루트 `README.md` + `docs/08`을 먼저 읽을 것.**  
> 정본 스펙은 `docs/01`~`11`. Godot **4.6.3 GDScript만** (`docs/10`).

## Git / 환경

| 항목 | 값 |
|------|-----|
| 최신 커밋 | `cf70c18` — `Implement MVP combat through enemy GLB animations` |
| 브랜치 | `main` (origin 동기화됨, 2026-06-04 푸시 완료) |
| 메인 씬 | `scenes/combat/combat_arena.tscn` (F5) |
| 엔진 | Godot 4.6.3 |

## 완료된 것 (코드 기준)

| Step | 상태 | 요약 |
|:----:|:----:|------|
| 1 | ✅ | `CombatController` FSM — INIT→PLAN→ACTION(7초)→RESOLVE→반복→VICTORY/DEFEAT |
| 2 | ✅ | 1인칭 `PlayerController` + `default_player_feel.tres` |
| 3 | ✅ | JSON 덱·`DeckManager` — 12장, 턴 5장, 교체 1회, draw/discard pile |
| 4~5 | ✅(1차) | 손패 **휠 선택 + 좌클릭** 사용, `CardExecutor` 기본 효과 |
| 6 | ✅ | `EnemyDuelist` + `data/mvp/enemy_duelist.json` — 코어/확장 시퀀스, 패링·방어·경직 |
| 7~9 | ✅ | 시간 연장(`gain_time`), 턴 정산, `combat_debug_ui` |
| 애니 | 🟡 | 적 `Enemy.glb` 1차 — 계획 Idle, 액션 시 행동별 클립 |

**MVP 1차 로직·데이터·디버그 UI는 동작 가능.** 연출·타이밍 검증은 미완.

## 입력 (현재 구현, docs와 일부 다름)

| 구분 | 입력 |
|------|------|
| 계획 | UI·**Enter** (WASD 비활성) |
| 액션 | WASD, Space(회피), **휠**(카드 선택), **좌클릭**(카드 사용) |
| 디버그 | `[` `]` (플레이어/적 피해), **R** 재시작 |
| 맵 프리뷰 | **B** (계획 단계만) |

슬롯 **1~5 키**는 스펙(`docs/03`)에 있으나 **미구현**(의도적 후순위).

## 핵심 파일 맵

```
scenes/combat/combat_arena.tscn   # 전투 루트
scenes/player/player.tscn         # 1인칭, 검(sword_08.glb)만 — 몸 메시 없음
scenes/enemy/enemy_placeholder.tscn
scripts/combat/combat_controller.gd
scripts/combat/combat_map_preview.gd      # B 키
scripts/combat/combat_character_animation.gd  # 계획 Idle / 액션만 전투 애니
scripts/cards/deck_manager.gd, card_executor.gd
scripts/enemy/enemy_duelist.gd, enemy_duelist_data.gd
scripts/enemy/enemy_visual.gd            # GLB 스폰 + 크기 맞춤
scripts/enemy/enemy_model_loader.gd       # GLTFDocument — preload로 참조
scripts/enemy/enemy_animation.gd        # EventBus.enemy_action_changed
scripts/autoload/event_bus.gd
data/mvp/*.json
assets/animation/Enemy.glb              # 스켈레탈 + 애니 (적 전용, ~8MB)
assets/models/Player/sword_08.glb
```

## 적 비주얼·애니 (중요)

1. **모델**: `assets/animation/Enemy.glb` — `enemy_visual.gd`가 `EnemyModelLoader.spawn_model()`로 **런타임 생성** (씬에 GLB 인스턴스 직접 안 둠).
2. **애니 주입**: 임포트 씬의 `AnimationPlayer`가 비어 있을 수 있음 → `EnemyModelLoader.ensure_animations_on_player()`가 GLTF에서 라이브러리 복사.
3. **참조 방식**: `class_name` 말고 `preload("res://scripts/enemy/enemy_model_loader.gd")` as `_ModelLoader` (파서 오류 방지).
4. **계획 단계**: `CombatCharacterAnimation` — `PLAN_PHASE` 등 time_frozen 시 `Idle_FoldArms_Loop`(후보 탐색), `face_opponent_in_plan`으로 플레이어 방향.
5. **액션 단계**: `EventBus.enemy_action_changed`만 전투 클립 재생 (`enemy_animation.gd`의 `ACTION_TO_ANIM`).
6. **방향**: `model_yaw_deg = 180` on Visual, `enemy_duelist._face_spawn_toward_player()`.

## 플레이어 비주얼

- **3인칭 몸 없음** — `Enemy.glb`를 플레이어에 붙였다가 제거함(1인칭 겹침 문제).
- 플레이어 Idle 애니는 **미구현** (`docs/11` 참고).

## Git에서 제외된 에셋

- `assets/models/Enemy/Sc-Fi Cyborg Katana.glb` (**114MB**, GitHub 100MB 초과) — **저장소에 없음**. 로컬에만 있을 수 있음. 현재 코드는 **사용 안 함**.

## 알려진 이슈 / 확인할 것

- [ ] 적 Idle이 여전히 T포즈면: `Enemy.glb` Reimport(Animation Import), 출력 패널 `Idle 클립을 찾지 못함` / `GLB에서 애니 라이브러리 주입 실패` 확인.
- [ ] 애니 길이 ↔ JSON `startup`/`active`/`recovery`, 적 시퀀스 `time` 동기화 (`docs/11`).
- [ ] `combat_map_preview.gd`: `MapPreviewCamera` 경로는 `../MapPreviewCamera` (형제 노드).

## 다음 작업 우선순위 (제안)

1. **적 애니 안정화** — Idle·방향·클립 이름 매핑 플레이 테스트 후 `ACTION_TO_ANIM` 조정.
2. **플레이어 연출** — 전용 GLB 또는 1인칭 팔/무기 애니 + `EventBus.card_used` 연동 (`docs/11`).
3. **체크리스트 잔여** — `docs/08`의 `[ ]` 항목(슬롯 키, UI 아트, 사운드 등).
4. **플레이 밸런스** — `docs/09`, JSON 수치.

## EventBus (애니·UI 연동)

| 시그널 | 용도 |
|--------|------|
| `combat_state_changed` | 계획/액션 전환, Idle vs 전투 애니 |
| `enemy_action_changed` | 적 행동 라벨 + 애니 (액션 페이즈만 처리) |
| `turn_started` | 턴 시작 시 plan stance 갱신 |
| `card_used` | (플레이어 공격 모션 후보, 미연결) |

## 커밋 시 주의

- **100MB 초과 GLB** GitHub 거절 — 대용량은 LFS 또는 저장소 제외.
- `*.import`는 gitignore — 팀원은 Godot에서 Reimport 필요.

---

*마지막 갱신: 2026-06-04 세션 (대화: MVP 구현, 적 애니, 맵 프리뷰 B, 커밋 cf70c18)*
