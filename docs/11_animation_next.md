# 11. 다음 단계 — 플레이어·적 애니메이션

MVP 1차 **로직·데이터·UI**는 `docs/08` Step 1~9 기준으로 구현 완료했습니다.  
이후 **연출** 없이는 전투 리듬·타격 타이밍을 기획 의도대로 검증하기 어렵습니다.

## 권장 순서

1. **플레이어** (`scenes/player/player.tscn`)
   - 이동, 회피, 카드 공격(빠른 베기/강타 등) 최소 3~4 클립 또는 프로시저
   - 1인칭: 무기/팔 메시만 보이거나 화면 흔들림+VFX로 대체 가능
2. **검투병** (`scenes/enemy/enemy_placeholder.tscn`)
   - 비주얼·애니: `assets/animation/Enemy.glb` (`Visual/AnimatedEnemy`)
   - 크기·높이: `Visual`의 `enemy_visual.gd` (`manual_scale`, `auto_fit_height`)
   - `scripts/combat/combat_character_animation.gd` — 계획·정산: `Idle_FoldArms_Loop` / 액션만 전투 클립
   - `scripts/enemy/enemy_animation.gd` — `EventBus.enemy_action_changed`
   - 플레이어: **1인칭** — 몸 메시 없음(검·카메라만). Idle 연출은 추후 전용 GLB
   - APPROACH / LIGHT_ATTACK / GUARD / STAGGERED 등
3. **타이밍**
   - 카드 `startup` / `active` / `recovery`와 애니 길이 맞추기 (`docs/06`, JSON)
   - 적 시퀀스 `time` 키프레임과 동기화

## 코드 연동 포인트

| 시그널 | 용도 |
|--------|------|
| `EventBus.enemy_action_changed` | 적 행동 라벨·애니 상태 |
| `EventBus.card_used` | 플레이어 공격 모션 트리거 |
| `PlayerController` 회피/이동 | 속도·무적 플래그로 블렌드 |

## MVP에서 아직 없는 것 (의도적)

- 완성 UI/HUD 아트
- 사운드
- 복잡 VFX
- 슬롯 1~5 키 입력 (손패+휠+좌클릭 사용)

애니메이션 작업 시에도 **Godot 4.6.3** — `docs/10_godot_463_gdscript.md` 준수.
