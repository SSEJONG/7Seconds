# MVP 데이터 (JSON 등)

`docs/06_data_schema.md`, `docs/07_mvp_content_list.md` 형식의 원본 데이터를 둡니다.

- 카드 정의: `cards_mvp.json` ✅
- 시작 덱: `starting_deck.json` ✅ (12장, docs/07)
- 적 정의: `enemy_duelist.json` ✅ (코어·확장 시퀀스)
- 전투 설정: `combat_config.json` (추가 예정)

Godot에서는 `scripts/cards/` 등에서 로드하거나 `.tres` Resource로 변환해 `resources/`에 둡니다.
