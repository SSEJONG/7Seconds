# 05. Combat Resolution Rules

## 0. 적용 범위

- 판정·피해·승패는 **전투 1판** 동안 유효하다. 턴이 바뀌어도 HP·덱 상태는 전투 전체에 이어진다.
- **계획 단계**에서는 실시간 피격·회피 판정을 하지 않는다 (시간 정지).
- **액션 페이즈**에서만 이동·회피·카드·적 시퀀스 판정이 일어난다.

## 1. 피해 처리

기본 피해 공식은 단순하게 시작합니다.

```text
finalDamage = baseDamage
```

방어/가드 상태에서는:

```text
finalDamage = baseDamage * damageMultiplier
```

예:

```text
적 GUARD 상태 정면 피격: 30% 피해만 적용
후방 피격: 100% 피해 적용
```

## 2. 플레이어 피격

플레이어가 적 공격 판정에 맞았을 때:

```text
if player is invincible from dodge:
    no damage
else if active parry window exists:
    parry success
else:
    apply damage
```

## 3. 기본 회피 판정

회피 중 일정 시간 무적입니다.

```text
dodgeInvincible = true during i-frame
```

MVP에서는 저스트 회피 보상은 없어도 됩니다.

선택 구현:

```text
if enemyAttack would hit within perfectDodgeWindow:
    trigger perfect dodge feedback
```

## 4. 패링 카드 판정

패링은 기본 행동이 아니라 카드 행동입니다.

패링 카드 사용 시:

```text
parryWindowActive = true for N seconds
```

적 공격이 패링 윈도우 중 들어오면:

```text
cancel enemy attack damage
enemy stagger += parryStagger
optional: draw 1 card if card has drawOnParry
optional: actionTime += timeGainOnParry
```

MVP 권장:

```text
패링 성공 시 적 경직 15
패링 성공 시 카드별 효과 실행
```

## 5. 공격 적중

카드 공격이 적에게 적중하면:

```text
apply damage
apply stagger
trigger onHit effects
```

예:

```text
연속 베기 적중 시 카드 1장 드로우
강타 적중 시 적 경직 크게 증가
```

## 6. 실시간 드로우 트리거

드로우는 액션 페이즈 중 조건으로 발생합니다.

트리거 예:

```text
onCardUse
onHit
onKill
onParrySuccess
onPerfectDodge
```

MVP에서는 `onCardUse`와 `onHit`만 먼저 구현해도 됩니다.

## 7. 액션 시간 증감

시간 증감은 현재 남은 시간에 직접 적용합니다.

```text
remainingActionTime += delta
```

규칙:

```text
remainingActionTime <= 0 이면 액션 페이즈 종료
remainingActionTime 증가 시 적은 확장 시퀀스 진행 가능
```

## 8. 액션 페이즈 종료

종료 조건:

```text
remainingActionTime <= 0
playerHP <= 0
enemyHP <= 0
```

종료 시:

```text
현재 진행 중인 신규 입력 차단
투사체/장판은 MVP에서는 즉시 제거
카드 슬롯 정리
RESOLVE_PHASE로 이동
```

## 9. 승패 처리

```text
if enemyHP <= 0:
    state = VICTORY
else if playerHP <= 0:
    state = DEFEAT
else:
    next turn
```

동시 사망 시 MVP에서는 승리 우선 또는 패배 우선 중 하나를 정합니다.

권장:

```text
동시 사망은 VICTORY 처리
```

## 10. 경직 처리

적 경직:

```text
if enemyStagger >= threshold:
    enemy state = STAGGERED
    interrupt current action
    staggerDuration = 1.5s
```

경직 중:

```text
적 이동/공격 불가
받는 피해 100%
시퀀스 타임라인은 계속 흐르거나 정지 가능
```

MVP 권장:

```text
경직 중에도 액션 시간은 흐름
적 시퀀스는 정지
경직 종료 후 현재 시간 기준으로 다음 가능한 행동 수행
```
