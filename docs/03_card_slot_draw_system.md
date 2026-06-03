# 03. Card, Slot, Draw System

## 1. 핵심 개념

> 손패는 **이번 턴**의 액션 세트다. **전투 1판** 동안 턴마다 새 손패를 받는다.

플레이어는 **매 턴** 시작 시(계획 단계, 시간 정지) 5장을 드로우하고, 최종 손패가 액션 슬롯에 장착됩니다. 7초 액션 페이즈가 끝나 카드를 버린 뒤, 전투가 끝나지 않았으면 **다음 턴**에 다시 드로우합니다.

## 2. 카드 기본 구조

카드는 액션 페이즈에서 사용할 수 있는 행동입니다.

카드 종류:

```text
ATTACK
DEFENSE
MOBILITY
TECHNIQUE
TACTIC
PASSIVE_OR_ENGRAVE
```

MVP에서는 `ATTACK`, `DEFENSE`, `MOBILITY`, `TACTIC`만 구현해도 충분합니다.

## 3. 액션 슬롯

기본 슬롯:

```text
slot_1 ~ slot_5
```

임시 슬롯:

```text
temp_slot_1 ~ temp_slot_2
```

슬롯 상태:

```text
EMPTY
READY
EXECUTING
DEPLETED
```

## 4. 카드 사용 횟수

카드는 액션 페이즈 중 정해진 횟수만큼 사용할 수 있습니다.

예:

```text
빠른 베기: 3회
강타: 1회
패링: 2회
돌진: 1회
전술 재장착: 1회
```

카드 사용 시:

```text
remainingUses -= 1
if remainingUses <= 0:
    slot.state = DEPLETED
```

DEPLETED 슬롯은 실시간 드로우 카드가 장착될 수 있는 빈 슬롯로 취급합니다.

## 5. 턴 시작 드로우

기본 규칙:

```text
턴 시작 시 5장 드로우
드로우 pile이 부족하면 버림 pile을 섞어 보충
```

드로우 함수:

```text
DrawCard():
    if drawPile is empty:
        shuffle discardPile into drawPile
    return drawPile.popTop()
```

## 6. 카드 교체

계획 단계에서 1회 교체 가능합니다.

```text
플레이어가 원하는 카드 N장을 선택
선택 카드들을 버림 pile로 이동
N장 새로 드로우
```

MVP에서는 UI 단순화를 위해 카드 클릭으로 교체 대상 표시 후 Confirm 버튼을 사용합니다.

## 7. 액션 슬롯 장착

계획 단계 종료 시:

```text
for each card in hand:
    if card.type == PASSIVE_OR_ENGRAVE:
        activatePassive(card)
        removeFromCombatCycle(card)
    else:
        equipToActionSlot(card)
```

MVP에서는 패시브 카드를 제외하거나, 패시브 없이 구현해도 됩니다.

## 8. 실시간 드로우 / 즉시 장착

액션 페이즈 중 특정 효과로 카드가 드로우될 수 있습니다.

규칙:

```text
1. 카드 1장 드로우
2. 드로우 카드가 패시브면 즉시 발동
3. 액션 카드면 빈 슬롯에 장착
4. 빈 기본 슬롯이 없으면 임시 슬롯에 장착
5. 임시 슬롯도 없으면 드로우 실패 또는 카드 버림
```

MVP 권장:

```text
빈 기본 슬롯 우선
임시 슬롯 최대 2개
임시 슬롯도 꽉 차면 드로우된 카드는 버림 pile로 이동
```

## 9. 빈 슬롯 판단

빈 슬롯으로 간주하는 경우:

```text
slot.state == EMPTY
slot.state == DEPLETED
```

DEPLETED 카드가 새 카드로 교체될 때 기존 카드는 버림 pile로 이동합니다.

## 10. 실시간 드로우 예시

```text
현재 슬롯:
1. 빠른 베기 0/3, DEPLETED
2. 패링 1/2, READY
3. 강타 0/1, DEPLETED
4. 돌진 1/1, READY
5. 전술 재장착 0/1, DEPLETED

드로우 발생:
→ 카드 1장 드로우: 화염 베기
→ 가장 왼쪽 DEPLETED 슬롯 1번에 장착
```

## 11. 턴 종료 시 카드 정리

액션 페이즈 종료 후:

```text
기본 슬롯의 모든 카드 → 버림 pile
임시 슬롯의 모든 카드 → 버림 pile
슬롯 비우기
손패 비우기
```

예외:

- `EXHAUST` 카드: 전투 중 제거
- `PRESERVE` 카드: 다음 턴 유지, MVP에서는 제외 가능

## 12. MVP 필수 구현 카드 효과

최소한 아래 효과 타입을 구현합니다.

```text
DealDamage
MoveForward
ParryWindow
DrawCard
ModifyActionTime
ApplyStagger
```
