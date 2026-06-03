# 06. Data Schema

이 문서는 엔진/언어에 상관없이 구현 가능한 데이터 구조 예시입니다.

## 1. CardDefinition

```json
{
  "id": "quick_slash",
  "name": "빠른 베기",
  "type": "ATTACK",
  "baseUses": 3,
  "damage": 8,
  "staggerDamage": 5,
  "startup": 0.1,
  "active": 0.15,
  "recovery": 0.25,
  "range": 2.0,
  "canDodgeCancel": true,
  "effects": []
}
```

## 2. CardInstance

전투 중 실제 카드 객체입니다.

```json
{
  "definitionId": "quick_slash",
  "remainingUses": 3,
  "isTemporary": false,
  "slotIndex": 0
}
```

## 3. CardEffect

효과는 리스트로 처리합니다.

```json
{
  "trigger": "ON_HIT",
  "effectType": "DRAW_CARD",
  "value": 1
}
```

권장 trigger:

```text
ON_USE
ON_HIT
ON_KILL
ON_PARRY_SUCCESS
ON_EQUIP
```

권장 effectType:

```text
DEAL_DAMAGE
DRAW_CARD
MODIFY_ACTION_TIME
APPLY_STAGGER
MOVE_PLAYER
ACTIVATE_PARRY_WINDOW
```

## 4. ActionSlot

```json
{
  "slotIndex": 0,
  "slotType": "BASIC",
  "state": "READY",
  "cardInstance": null
}
```

slotType:

```text
BASIC
TEMPORARY
```

state:

```text
EMPTY
READY
EXECUTING
DEPLETED
```

## 5. CombatConfig

```json
{
  "startingHandSize": 5,
  "rerollCountPerTurn": 1,
  "baseActionTime": 7.0,
  "baseSlotCount": 5,
  "temporarySlotCount": 2,
  "playerMaxHP": 100,
  "enemyMaxHP": 120
}
```

## 6. EnemyDefinition

```json
{
  "id": "duelist",
  "name": "검투병",
  "maxHP": 120,
  "moveSpeed": 3.5,
  "staggerThreshold": 30,
  "coreSequence": [
    { "time": 0.0, "action": "APPROACH" },
    { "time": 1.2, "action": "LIGHT_ATTACK" },
    { "time": 2.4, "action": "SIDE_STEP" },
    { "time": 3.5, "action": "DASH_ATTACK" },
    { "time": 5.2, "action": "HEAVY_ATTACK" },
    { "time": 6.8, "action": "GUARD" }
  ],
  "extensionSequence": [
    { "time": 7.3, "action": "APPROACH" },
    { "time": 8.3, "action": "LIGHT_ATTACK" },
    { "time": 9.0, "action": "LIGHT_ATTACK" },
    { "time": 10.2, "action": "RETREAT" },
    { "time": 11.0, "action": "GUARD" }
  ]
}
```

## 7. EnemyActionDefinition

```json
{
  "id": "LIGHT_ATTACK",
  "startup": 0.25,
  "active": 0.2,
  "recovery": 0.4,
  "damage": 8,
  "range": 2.0,
  "isParryable": true,
  "isDodgeable": true
}
```

## 8. CombatRuntimeState

```json
{
  "combatState": "ACTION_PHASE",
  "turnNumber": 1,
  "remainingActionTime": 5.6,
  "elapsedActionTime": 1.4,
  "drawPile": [],
  "discardPile": [],
  "hand": [],
  "actionSlots": [],
  "playerHP": 100,
  "enemyHP": 120
}
```
