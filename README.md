# 7Seconds — Godot 4.6.3 MVP

3D 액션 덱빌딩 로그라이크 **전투 1판 MVP** 프로젝트입니다.  
기획·설계의 단일 소스는 `docs/` 폴더입니다. 코드·씬을 추가·수정할 때는 반드시 해당 문서와 일치시킵니다.

## MVP가 의미하는 것 (오해 방지)

| ✅ MVP | ❌ MVP 아님 |
|--------|-------------|
| **적 1명과의 전투 1판** — 턴을 여러 번 반복 | **턴 1회만** (7초 한 번하고 끝) |
| 7초 후 **시간 정지** → 다시 카드 계획 | 로그라이크 **전체 런** (맵·여러 방·보상) |
| **승리 또는 패배**까지 한 판 완료 | |

**한 턴 사이클**: `[정지] 계획 → [실시간] 7초 액션 → [정산]` → (생존 시) 다음 턴 … → 승/패

## 한 줄 정의

> 손패가 이번 턴의 액션 세트가 되고, 7초 액션 후 시간이 멈춰 다시 카드를 고르며, 한 전투에서 승패할 때까지 턴이 반복되는 3D 액션 덱빌딩 전투.

## 엔진

- **Godot 4.6.3** (프로젝트 루트의 `project.godot`로 열기)
- 언어: **GDScript 2.0** — **4.6.3 문법·API만** 사용 (Godot 3·다른 버전 예제 무단 복사 금지)
- 필수 참고: [`docs/10_godot_463_gdscript.md`](docs/10_godot_463_gdscript.md)

## MVP 범위 (포함 / 제외)

| 포함 | 제외 |
|------|------|
| **전투 1판** (적 1, **여러 턴**, 승/패까지) | **턴 1회만** 플레이 후 종료 |
| 플레이어 1, 카드 8~10종, 시작 덱 12장 | 맵·보상·유물·복수 적·로그라이크 런 |
| 턴: [정지] 계획 → [실시간] 7초 → 정산 → 반복 | 성장·세이브/로드 |
| 기본 이동/회피, 카드 슬롯 공격/패링 | 완성 아트·사운드 |
| 실시간 드로우·즉시 장착, 적 코어/확장 시퀀스 | 복잡 상태이상·각인 |

## 현재 구현 상태 (개발 진행)

| 완료 | 내용 |
|:----:|------|
| ✅ | Step 1: 전투 상태 머신, 계획 시 `time_scale=0`, 액션 7초, 턴 반복, 승/패 |
| ✅ | Step 2 (1차): 1인칭 이동·회피·시점, `default_player_feel.tres` 튜닝 |
| ✅ | Step 3: 카드 정의(JSON)·덱 12장·드로우/버림 pile·턴 5장·교체 1회 |
| ✅ | Step 4~5(1차): 손패 휠·좌클릭 카드 사용·기본 카드 효과 |
| ✅ | Step 6: 검투병 코어 시퀀스·공격·방어·패링·경직·적 예고 UI |
| ✅ | Step 7~9: 액션 시간 연장·턴 정산·디버그 UI — **MVP 1차 코드 완료** |
| 🟡 | 적 **Enemy.glb** 애니 연동(1차) — 플레이어 애니·타이밍 미세조정 남음 |

**실행**: Godot 4.6.3 → F5 → `scenes/combat/combat_arena.tscn`

**맵에서 적 모델 확인**: `scenes/combat/combat_arena.tscn` 더블클릭(에디터 3D 뷰) 또는 F5 후 계획 단계에서 **B** (맵 프리뷰 카메라)

**손맛 조정**: `docs/09_player_feel_tuning.md` · `resources/combat/default_player_feel.tres`

**이어서 개발(에이전트)**: [`docs/12_session_handoff.md`](docs/12_session_handoff.md)

## 문서 인덱스 (`docs/`)

| 파일 | 용도 |
|------|------|
| `00_README.md` | 문서 세트 개요 |
| `09_player_feel_tuning.md` | 이동·회피·타격감 수치 조정 (기획자) |
| `01_core_game_loop.md` | 전투 상태 머신·턴 흐름 |
| `02_player_controls_and_action_phase.md` | 이동·회피·액션 페이즈 조작 |
| `03_card_slot_draw_system.md` | 카드·덱·슬롯·드로우 |
| `04_enemy_mvp_design.md` | MVP 적(검투병) AI·시퀀스 |
| `05_combat_resolution_rules.md` | 피해·회피·패링·승패 |
| `06_data_schema.md` | JSON/리소스 데이터 스키마 |
| `07_mvp_content_list.md` | 카드·덱·적 스펙 |
| `08_implementation_checklist.md` | 구현 순서·완료 조건 |
| `10_godot_463_gdscript.md` | **Godot 4.6.3 GDScript 필수 규칙** |
| `11_animation_next.md` | 플레이어·적 애니 다음 단계 |
| `12_session_handoff.md` | **에이전트/이어하기용** 현재 진행 스냅샷 |

## 권장 구현 순서

`docs/08_implementation_checklist.md` 및 문서 팁 기준:

1. 전투 상태 머신 (`01`)
2. 카드/덱/슬롯 (`03`, `06`, `07`)
3. 플레이어 이동·회피 (`02`)
4. 적 1명 (`04`)
5. 전투 판정·정산 (`05`)
6. 디버그 UI

## 폴더 구조

```text
7Seconds/
├── README.md                 ← 이 파일 (에이전트·개발자 공통 진입점)
├── project.godot
├── docs/                     ← 기획 MVP 스펙 (수정 시 코드와 동기화)
├── scenes/                   ← .tscn 씬 트리
│   ├── main/                 # 진입·전투 루트
│   ├── combat/               # 전투 필드·상태 UI
│   ├── player/
│   ├── enemy/
│   └── ui/                   # 디버그·승패 HUD
├── scripts/                  ← .gd 로직
│   ├── autoload/             # 싱글톤 (EventBus, GameConstants 등)
│   ├── combat/               # 상태 머신·턴·타이머·정산
│   ├── cards/                # 덱·손패·슬롯·카드 실행
│   ├── player/
│   ├── enemy/
│   └── ui/
├── resources/                # Godot Resource (.tres) — 런타임 정의
│   ├── cards/
│   ├── enemies/
│   └── combat/
├── data/mvp/                 # JSON 등 원본 데이터 (Resource로 임포트 가능)
├── assets/                   # 아트·오디오 (MVP는 플레이스홀더 허용)
│   ├── models/
│   ├── textures/
│   ├── audio/
│   └── fonts/
└── addons/
```

## 전투 상태 (코드 상수와 동기화)

`INIT` → `PLAN_PHASE` → `ACTION_PHASE` → `RESOLVE_PHASE` → (`VICTORY` | `DEFEAT`)

## 턴 기본값 (기획 고정)

| 항목 | 값 |
|------|---:|
| 턴 시작 드로우 | 5장 |
| 카드 교체 | 턴당 1회 |
| 액션 시간 | 7초 (증감 가능) |
| 기본 슬롯 | 5 |
| 임시 슬롯 | 최대 2 |
| 플레이어 HP | 100 |
| 적 HP | 120 |

## Autoload 권장 (추가 시)

| 이름 | 역할 |
|------|------|
| `EventBus` | 전투·카드·UI 시그널 허브 |
| `GameConstants` | `docs/06`, `07` 수치 상수 |

`project.godot`에 등록할 때 경로: `scripts/autoload/`.

## 작업 시 규칙

1. **스펙 우선**: 모호하면 `docs/`를 읽고, 필요 시 기획자에게 질문.
2. **작은 단위**: 체크리스트 Step 단위로 씬·스크립트 추가.
3. **데이터 분리**: 카드/적 정의는 `resources/` 또는 `data/mvp/` + Resource 클래스.
4. **설명**: 저장소 소유자는 기획자 — 코드 변경 시 `.cursor/rules/`의 플래너 커뮤니케이션 규칙을 따릅니다.

## 로컬 실행

1. Godot 4.6.3에서 프로젝트 폴더 열기
2. (씬 추가 후) `scenes/main/` 진입 씬을 Main Scene으로 설정
3. F5로 실행

진입 씬은 `scenes/combat/combat_arena.tscn`입니다. `scenes/main/main.tscn`은 추후 추가 가능합니다.
