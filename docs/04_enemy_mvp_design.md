# 04. Enemy MVP Design

## 1. MVP 적 개요

MVP에서는 적 1명만 구현합니다.

적 이름 예시:

```text
검투병 / Duelist
```

역할:

- 근접 압박형 적
- 기본 공격, 돌진, 방어 자세를 가짐
- 7초 코어 시퀀스와 7초 이후 확장 시퀀스를 가짐
- 플레이어 거리와 공격 여부에 따라 제한적으로 반응

## 2. 적 기본 스펙

| 항목 | 값 |
|---|---:|
| HP | 120 |
| 이동 속도 | 플레이어의 80~90% |
| 기본 피해 | 8~12 |
| 강공격 피해 | 18 |
| 경직 저항 | 중간 |
| 패링 가능 여부 | 가능 |
| 가드 브레이크 | MVP에서는 선택 |

## 3. 적 상태

```text
IDLE
APPROACH
ATTACK_LIGHT
ATTACK_HEAVY
DASH_ATTACK
GUARD
COUNTER
STAGGERED
DEAD
```

## 4. 적 의도 예고

계획 단계에서 플레이어에게 적 시퀀스 요약을 보여줍니다.

예:

```text
적 의도: 압박
예고: 접근 → 빠른 공격 → 돌진 공격 → 방어
```

액션 시간이 10초라면:

```text
적 의도: 압박 확장
예고: 접근 → 빠른 공격 → 돌진 공격 → 방어 → 재접근 → 2연격
```

## 5. 코어 시퀀스

기본 액션 시간 7초 기준입니다.

```text
0.0s: 접근 시작
1.2s: 빠른 공격
2.4s: 횡이동 또는 짧은 후퇴
3.5s: 돌진 공격
5.2s: 강공격 준비
6.2s: 강공격 판정
6.8s: 방어 자세 진입
```

## 6. 확장 시퀀스

액션 시간이 7초보다 길 때 이어집니다.

```text
7.3s: 재접근
8.3s: 빠른 공격 1
9.0s: 빠른 공격 2
10.2s: 후퇴
11.0s: 방어 또는 반격 자세
```

## 7. 장기 루프 패턴

액션 시간이 12초 이상으로 늘어나면 시퀀스 대신 상태 기반 반복 행동을 사용합니다.

```text
if distanceToPlayer > farRange:
    use DASH_ATTACK
else if playerIsAttacking:
    use GUARD or COUNTER
else:
    use ATTACK_LIGHT
```

MVP에서는 12초 이후 다음 세 행동을 반복해도 됩니다.

```text
재접근 → 빠른 공격 → 후퇴
```

## 8. 액션 시간이 짧아질 때

적 행동을 압축하지 않습니다.

규칙:

```text
액션 시간이 짧아지면 아직 시작하지 않은 후반 행동은 생략한다.
이미 시작된 행동은 마무리한다.
```

예:

```text
액션 시간 5초:
0.0s 접근
1.2s 빠른 공격
2.4s 횡이동
3.5s 돌진 공격
5.0s 종료
```

## 9. 반응 행동 MVP

적은 너무 복잡한 AI가 아니라, 특정 체크포인트에서만 반응합니다.

체크포인트:

```text
2.4s
5.2s
7.3s 이후
```

반응 규칙:

```text
if player is far:
    next action = DASH_ATTACK

if player attacked enemy 3 times within 2 seconds:
    next action = GUARD

if player is behind enemy:
    next action = TURN_AROUND_ATTACK
```

MVP에서는 `TURN_AROUND_ATTACK`을 별도 구현하지 않고 빠른 공격으로 대체해도 됩니다.

## 10. 방어 자세

방어 자세는 가만히 있는 행동이 아니라 심리전 상태입니다.

MVP 규칙:

```text
GUARD 지속 시간: 1.2초
정면 피해 70% 감소
방어 중 플레이어가 공격하면 COUNTER 준비
후방에서 맞으면 방어 무시
```

COUNTER:

```text
짧은 선딜 후 빠른 반격
피해 10
패링 가능
회피 가능
```

## 11. 적 경직

플레이어 공격에는 경직 수치가 있습니다.

```text
enemyStagger += card.staggerDamage
if enemyStagger >= staggerThreshold:
    enemy enters STAGGERED for 1.5s
    enemyStagger = 0
```

권장 수치:

```text
staggerThreshold = 30
빠른 베기 경직 5
강타 경직 20
돌진 경직 10
```

## 12. 구현 우선순위

1. 적 HP와 피격 처리
2. 코어 시퀀스 타임라인 실행
3. 공격 판정
4. 방어 자세
5. 액션 시간 증가 시 확장 시퀀스
6. 거리 기반 반응
7. 경직 처리
