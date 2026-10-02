# Naver 데이터 연동 가이드

이번 과제는 endpoint를 직접 추적하는 과제가 아닙니다. 어떤 API를 써야 하는지는 아래에 정리되어 있습니다.

대신 **요청, 파싱, DTO 작성, 모델 연결은 직접 구현해야 합니다. 네 가지 모두 필수입니다.**

| | endpoint | 쓰이는 화면 |
| --- | --- | --- |
| 1 | 검색 자동완성 | 검색 |
| 2 | 실시간 시세 | 관심, 상세 |
| 3 | 종목 메타데이터 | 검색, 관심, 상세 |
| 4 | 일별 시세 | 상세 |

---

## 1. 검색 자동완성

검색어로 종목 후보를 조회합니다.

```text
GET https://ac.stock.naver.com/ac
```

주요 query parameter

- `q`: 검색어
- `target`: `stock,ipo,index,marketindicator`

응답에서 주로 사용하는 필드

- `code`, `name`, `typeCode`, `typeName`, `url`, `nationCode`, `category`

구현해야 하는 처리

- 국내 주식만 남깁니다.
- 6자리 종목코드만 통과시킵니다.
- canonical id를 `domestic:{symbol}` 형태로 만듭니다.
- 검색 결과 모델로 변환합니다.

---

## 2. 실시간 시세

현재가, 전일 종가, 시가 / 고가 / 저가, 거래량을 조회합니다.

```text
GET https://polling.finance.naver.com/api/realtime
```

주요 query parameter

- `query`: `SERVICE_ITEM:005930,000660` 같은 형태

응답에서 주로 사용하는 필드

| 필드 | 의미 |
| --- | --- |
| `cd` | symbol |
| `nv` | current price |
| `pcv` | previous close |
| `ov` | open |
| `hv` | high |
| `lv` | low |
| `aq` | accumulated trading volume |
| `countOfListedStock` | 상장 주식 수 |

구현해야 하는 처리

- **관심종목을 한 번의 요청으로 조회할 수 있습니다. 종목마다 따로 호출하지 않도록 구성해 주세요.**
- symbol 기준으로 빠르게 찾을 수 있는 형태로 정리합니다.
- 등락액은 `nv - pcv`, 등락률은 `(nv - pcv) / pcv` 로 계산합니다.
- 시가총액은 `nv × countOfListedStock` 으로 계산합니다.

---

## 3. 종목 메타데이터

종목명, 거래소명 같은 기본 정보를 조회합니다.

```text
GET https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol}
```

응답에서 주로 사용하는 필드

- `symbolCode`, `stockName`, `stockExchangeNameKor`

구현해야 하는 처리

- 이름과 거래소명을 검색 / 관심 / 상세 UI 모델에 연결합니다.
- 화면에서 `005930 · 코스피` 로 보이는 부분이 이 값입니다.

---

## 4. 일별 시세

날짜별 종가, 시가, 고가, 저가, 거래량을 가져옵니다. 상세 화면의 차트와 일별 시세 표에 쓰입니다.

```text
GET https://api.stock.naver.com/chart/domestic/item/{symbol}/day
```

주요 query parameter

- `startDateTime`: `yyyyMMddHHmm` (예: `202509010000`)
- `endDateTime`: `yyyyMMddHHmm`

`{symbol}` 자리에 6자리 종목코드가 들어갑니다. 페이지 번호가 아니라 **날짜 구간**으로 조회합니다.

응답에서 주로 사용하는 필드

- `localDate`, `closePrice`, `openPrice`, `highPrice`, `lowPrice`, `accumulatedTradingVolume`

### 주의할 점

- 응답은 거래일만 담은 배열이며, **오래된 날짜가 앞**입니다. 휴장일은 애초에 내려오지 않습니다.
- `localDate`는 이미 `yyyyMMdd` 형태입니다. 가격은 `261000.0` 같은 실수로 내려옵니다.
- **전일비는 응답에 없습니다.** 일별 시세 표의 `등락` 컬럼은 직전 거래일 종가와의 차이로 직접 계산해 주세요.
- 이때 조회 구간의 **가장 오래된 행은 직전 거래일이 응답에 없어서 등락을 구할 수 없습니다.** 시작일을 며칠 앞당겨 받은 뒤 표시할 때 잘라내는 식으로 처리해 주세요.
- 당일 장중에는 마지막 행이 아직 확정되지 않은 값입니다. 실시간 시세 API의 값과 미세하게 다를 수 있습니다.
- 기간 탭은 거래일 수가 아니라 달력 기준으로 잡으면 됩니다. `1개월`은 1개월 전, `1년`은 1년 전을 `startDateTime`으로 주면 됩니다.
- **탭을 오갈 때 이미 받아둔 구간을 다시 요청하지 않도록 구성해 주세요. 이 부분을 비중 있게 봅니다.** 예를 들어 `1년`을 받은 뒤 `3개월`로 돌아갈 때는 새로 요청할 필요가 없습니다.

---

## 네트워크가 막힐 때

위 endpoint는 공개되어 있지만, 호출이 잦으면 응답이 느려지거나 차단될 수 있습니다. 개발 중에는 응답을 파일로 저장해 두고 사용하는 것을 권장합니다.

- 응답 JSON을 `assets/mock/` 에 저장해 두고 파싱 로직을 먼저 맞추세요.
- 그러면 네트워크 상태와 무관하게 파싱과 UI 작업을 진행할 수 있습니다.
- 저장한 mock 파일도 함께 커밋해 주시면 리뷰할 때 도움이 됩니다.

브라우저(Chrome)에서는 CORS 때문에 요청이 막힙니다. 실행 대상 관련 안내는 [루트 README](../README.md#실행하기)를 참고하세요.
