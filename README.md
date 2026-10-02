# 국내 주식 관심종목

이든크루 Lucy Studio Front 신입 개발자 과제 1. 제공된 Flutter 스타터의 디자인 토큰과 NotoSansKR 폰트를 유지합니다.

## 실행

Flutter stable 3.47.6 / Dart 3.13.5, macOS Apple Silicon을 개발 대상으로 사용합니다.

```sh
flutter pub get
flutter run -d macos
```

macOS에는 전체 Xcode와 CocoaPods가 필요합니다. 앱 콘텐츠를 393 × 852에 가깝게 맞춰 비교합니다. Chrome에서는 Naver의 CORS 정책 때문에 실제 API를 사용할 수 없습니다.

## 구현 진행

- [x] 스타터 복제, 공식 Flutter SDK 준비
- [x] 네 종류의 실제 Naver 응답 샘플 확보
- [ ] 데이터 모델, 날짜 구간 재사용
- [ ] 관심·검색·상세와 공유 관심 상태
- [ ] 상태별 UI, 예외 처리, 검증

## 요구사항 변경

구현 시작 시 스타터의 최신 커밋 `86d19ed`를 확인했습니다. 일별 시세는 HTML API에서 JSON 차트 API로 변경되었으며, 기간은 달력 기준입니다. 현재 `docs/NAVER_API.md`를 따릅니다. 따라서 HTML 파서와 거래일 개수 기준은 사용하지 않습니다. 시세 polling 응답은 한글 인코딩 변환이 필요하여 `charset_converter`를 사용합니다.

## 기술 선택

Flutter 기본 ChangeNotifier로 상태를 관리하고, 요청·DTO 변환·화면을 분리합니다. 요청은 http, 캔들 차트는 candlesticks를 사용합니다. 구현과 검증 결과는 진행에 따라 갱신합니다.
