# 10. Godot 4.6.3 GDScript (에이전트·개발 필수)

이 프로젝트는 **Godot 4.6.3 전용**입니다. 코드·씬·에디터 API는 **4.6.3 문서·동작**만 기준으로 하고, Godot 3.x·다른 4.x 블로그/예제를 **그대로 복사하지 않습니다**.

`project.godot`의 `config/features`에 `4.6`이 포함되어 있어야 합니다.

---

## 1. 반드시 지킬 것

| 항목 | 규칙 |
|------|------|
| 엔진 버전 | **4.6.3** (팀·CI·에디터 동일) |
| 언어 | **GDScript 2.0** (Godot 4 문법) |
| 스펙 우선 | 게임 규칙은 `docs/01`~`09`, 구현 순서는 `docs/08` |
| 타입 | 공개 함수·필드에 타입 힌트 (`func f(x: int) -> void`, `Array[CardInstance]` 등) |
| 데이터 | 카드·적 수치는 `data/mvp/` JSON 또는 `resources/`, 플레이어 스크립트에 매직 넘버 금지 |

---

## 2. Godot 3 / 잘못된 4.x 패턴 (사용 금지)

| ❌ 쓰지 않음 | ✅ 4.6.3에서 |
|-------------|-------------|
| `Engine.get_real_delta_time()` | **없음** → `_physics_process(delta)`의 `delta`, 또는 `Time.get_ticks_usec()` 차이 |
| `Vector3.lerp(a, b, t)` (정적 3인자) | `a.lerp(b, t)` **인스턴스** 메서드 |
| `JSON.parse()` / `FileAccess.get_as_text()` 후 구식 Parser | `JSON.parse_string(text)` |
| `yield()` / `setget` | `await` / `@export` 프로퍼티 |
| `KinematicBody` / `Spatial` | `CharacterBody3D` / `Node3D` |
| `instance()` | `instantiate()` |

---

## 3. 이 프로젝트에서 검증된 API

### 시간·히트스톱

```gdscript
# 히트스톱 종료 — scaled delta 말고 실시간 시계
_hit_stop_end_usec = Time.get_ticks_usec() + int(duration * 1_000_000.0)
```

### 벡터 보간

```gdscript
velocity = velocity.lerp(Vector3.ZERO, delta * 8.0)
```

### JSON 로드

```gdscript
var parsed: Variant = JSON.parse_string(file.get_as_text())
if typeof(parsed) != TYPE_DICTIONARY:
    push_error("invalid json")
```

### 씬 트리 준비 순서

형제 노드끼리 `_ready()` 순서는 **씬 트리 위에서 아래**입니다.  
다른 노드보다 늦게 `_ready()` 되는 객체는, 데이터 접근 전에 **지연 로드**(`_ensure_data()` 등)를 합니다.

### Autoload 시그널

`EventBus` 등 Autoload에는 시그널만 선언하고, `emit`은 전투·카드·적 스크립트에서 합니다.

---

## 4. 입력·MVP 조작 (현재 구현)

| 구분 | 입력 |
|------|------|
| 계획 | UI·Enter |
| 액션 카드 | **마우스 휠**(선택) + **좌클릭**(`use_card`) |
| 이동·회피 | WASD, Space |
| 디버그 피해 | `[` `]` (F9/F10 아님 — 에디터 단축키와 충돌) |

슬롯 **1~5 키**는 기획 초안(`docs/03`)에 있으나, MVP 코드는 **손패+휠+좌클릭**입니다.

---

## 5. 에이전트 작업 체크리스트

코드 작성·수정 전:

1. 루트 `README.md` + 관련 `docs/` 확인  
2. **이 문서(`10`)** — API가 4.6.3에 맞는지 확인  
3. `.cursor/rules/godot-gdscript-mvp.mdc` 준수  
4. 완료 후 `docs/08` 체크리스트와 대조  

문법이 불확실하면 [Godot 4.6 공식 문서](https://docs.godotengine.org/en/4.4/)에서 **4.x stable** 항목을 확인하고, **4.6.3 에디터에서 열어 파싱 오류가 없는지** 검증합니다.

---

## 6. 자주 나는 파서 오류

| 오류 메시지 | 흔한 원인 |
|-------------|-----------|
| `get_real_delta_time() not found` | §2 표 참고 |
| `Too many arguments for lerp()` | `Vector3.lerp` 정적 호출 → 인스턴스 `lerp` |
| `Invalid access ... Nil` | `_ready()` 순서 — 데이터 지연 로드 |
| `Cannot infer type of "dt"` | 존재하지 않는 API 반환값 — 명시 타입 `var dt: float` |

이 표는 발견 시 여기에 항목을 추가합니다.
