# 실제 Naver 응답 샘플

2026-10-02에 endpoint 네 개를 호출해 저장했습니다. 테스트와 명시적인 샘플 모드에서 사용합니다.

- `search.json`: 검색어 삼성.
- `search_sk.json`: 검색어 SK.
- `quotes.json`: SERVICE_ITEM:005930,000660 배치 시세. 원본 EUC-KR 응답을 UTF-8 JSON으로 변환해 저장했습니다.
- `metadata_005930.json`, `metadata_000660.json`: 종목 메타데이터.
- `daily_005930.json`, `daily_000660.json`: JSON chart API, 2025-09-25~2026-10-02의 OHLCV.

종목은 삼성전자(005930), SK하이닉스(000660)입니다. 시세 값은 수집 시점의 데이터로 현재 가격과 다를 수 있습니다. Fixture를 실제 요청 실패의 자동 대체용으로 사용하지 않습니다. 실시간 앱은 원본 응답 바이트를 UTF-8 또는 헤더에 명시된 문자셋으로 디코딩합니다.
