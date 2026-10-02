import 'package:flutter_test/flutter_test.dart';
import 'package:edencrew_assignment_starter/data/naver_dto.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';

import '../support.dart';

void main() {
  test('실제 검색 응답에서 국내 주식만 선택하고 중복을 제거한다', () {
    final json = fixture('search.json') as Map<String, dynamic>;
    final samsung =
        (json['items'] as List).firstWhere((item) => item['code'] == '005930')
            as Map;
    final stocks = parseSearch({
      'items': [
        samsung,
        samsung,
        {...samsung, 'code': 'AAPL', 'nationCode': 'USA'},
        {...samsung, 'code': '100000', 'category': 'index'},
      ],
    });
    expect(stocks.single.id, 'domestic:005930');
    expect(stocks.single.name, '삼성전자');
    expect(stocks.single.market, '코스피');
  });

  test('실제 배치 시세 응답의 가격·전일 대비·시가총액을 계산한다', () {
    final quotes = parseQuotes(fixture('quotes.json'));
    expect(quotes['005930']!.current, 276000);
    expect(quotes['005930']!.change, 0);
    expect(quotes['005930']!.changePercent, 0);
    expect(quotes['000660']!.change, 9000);
    expect(
      quotes['000660']!.changePercent,
      closeTo(9000 / 1833000 * 100, 0.00001),
    );
    expect(quotes['005930']!.marketCap, 276000 * 5846278608);
  });

  test('누락과 보합 0을 구분하고 숫자 문자열을 변환한다', () {
    expect(readNumber('1,234.5'), 1234.5);
    expect(readNumber('NaN'), isNull);
    expect(readNumber(null), isNull);
    expect(readNumber(0), 0);
    const quote = Quote(symbol: '005930', current: 0);
    expect(quote.change, isNull);
    expect(quote.changePercent, isNull);
    expect(
      const Quote(
        symbol: '005930',
        current: 10,
        previousClose: 0,
      ).changePercent,
      isNull,
    );
  });

  test('실제 메타데이터와 일별 JSON을 모델로 변환한다', () {
    final metadata = MetadataDto.fromJson(
      fixture('metadata_005930.json') as Map<String, dynamic>,
    ).toModel();
    expect(metadata.symbol, '005930');
    expect(metadata.market, '코스피');
    final rows = parseDaily(fixture('daily_005930.json'));
    expect(rows.length, greaterThan(200));
    expect(rows.first.date.isBefore(rows.last.date), isTrue);
    expect(rows.last.close, greaterThanOrEqualTo(rows.last.low));
    expect(rows.last.close, lessThanOrEqualTo(rows.last.high));
    expect(rows.last.volume, greaterThan(0));
  });

  test('일별 데이터는 날짜순 정렬·중복 제거하고 잘못된 OHLC를 거부한다', () {
    final rows = fixture('daily_005930.json') as List;
    expect(parseDaily([rows[1], rows[0], rows[1]]).length, 2);
    expect(
      () => parseDaily([
        {...rows[0] as Map, 'closePrice': -1},
      ]),
      throwsFormatException,
    );
    expect(
      () => parseDaily([
        {...rows[0] as Map, 'localDate': '20260230'},
      ]),
      throwsFormatException,
    );
    expect(
      () => parseDaily([
        {...rows[0] as Map, 'openPrice': null},
      ]),
      throwsFormatException,
    );
    expect(() => parseQuotes({'resultCode': 'fail'}), throwsFormatException);
  });

  test('기간은 거래일 개수 대신 달력 기준이며 월말을 보정한다', () {
    expect(
      HistoryPeriod.month.start(DateTime(2026, 3, 31)),
      DateTime(2026, 2, 28),
    );
    expect(
      HistoryPeriod.year.start(DateTime(2024, 2, 29)),
      DateTime(2023, 2, 28),
    );
    expect(
      HistoryPeriod.quarter.start(DateTime(2026, 10, 2)),
      DateTime(2026, 7, 2),
    );
  });
}
