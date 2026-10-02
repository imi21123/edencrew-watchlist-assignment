import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';

import '../support.dart';

void main() {
  final anchor = DateTime(2026, 10, 2);
  test('더 긴 기간은 부족한 과거 구간만 요청하고 짧은 기간은 재사용한다', () async {
    final source = FakeSource();
    final repository = StockRepository(source);
    final month = await repository.history(
      '005930',
      HistoryPeriod.month,
      anchor,
    );
    expect(
      source.requests.single.queryParameters['startDateTime'],
      '202608190000',
    );
    final firstRequestStart =
        source.requests.single.queryParameters['startDateTime']!;
    final year = await repository.history('005930', HistoryPeriod.year, anchor);
    expect(source.requests.length, 2);
    expect(
      source.requests.last.queryParameters['endDateTime']!.substring(0, 8),
      '20260818',
    );
    expect(
      source.requests.last.queryParameters['endDateTime']!.compareTo(
        firstRequestStart,
      ),
      lessThan(0),
    );
    final quarter = await repository.history(
      '005930',
      HistoryPeriod.quarter,
      anchor,
    );
    await repository.history('005930', HistoryPeriod.month, anchor);
    expect(source.requests.length, 2);
    expect(year.length, greaterThan(quarter.length));
    expect(quarter.length, greaterThan(month.length));
    expect(month.first.date.isAfter(month.last.date), isTrue);
    expect(
      month.every((row) => !row.date.isBefore(DateTime(2026, 9, 2))),
      isTrue,
    );
  });

  test('첫 표시 행의 등락도 버퍼의 직전 거래일 종가와 비교한다', () async {
    final repository = StockRepository(FakeSource());
    final rows = await repository.history(
      '005930',
      HistoryPeriod.month,
      anchor,
    );
    final raw = fixture('daily_005930.json') as List;
    final first = rows.last;
    final index = raw.indexWhere((row) => row['localDate'] == '20260902');
    expect(first.date, DateTime(2026, 9, 2));
    expect(
      first.change,
      (raw[index]['closePrice'] as num) - (raw[index - 1]['closePrice'] as num),
    );
  });

  test('동시에 연간·분기 요청이 들어와도 같은 종목의 구간은 중복 요청하지 않는다', () async {
    final pending = Completer<Object?>();
    final source = FakeSource(handler: (uri) => pending.future);
    final repository = StockRepository(source);
    final year = repository.history('005930', HistoryPeriod.year, anchor);
    final quarter = repository.history('005930', HistoryPeriod.quarter, anchor);
    await Future<void>.delayed(Duration.zero);
    expect(source.requests.length, 1);
    pending.complete(fixtureResponse(source.requests.single));
    expect((await year).length, greaterThan((await quarter).length));
    expect(source.requests.length, 1);
  });

  test('실패한 구간은 캐시에 성공한 것으로 기록하지 않고 재시도한다', () async {
    var fail = true;
    final source = FakeSource(
      handler: (uri) {
        if (fail) throw StateError('offline');
        return fixtureResponse(uri);
      },
    );
    final repository = StockRepository(source);
    await expectLater(
      repository.history('005930', HistoryPeriod.month, anchor),
      throwsStateError,
    );
    fail = false;
    expect(
      await repository.history('005930', HistoryPeriod.month, anchor),
      isNotEmpty,
    );
    expect(source.requests.length, 2);
  });

  test('메타데이터는 동시 요청과 완료 후 요청에서 재사용한다', () async {
    final source = FakeSource();
    final repository = StockRepository(source);
    await Future.wait([
      repository.metadata('005930'),
      repository.metadata('005930'),
    ]);
    await repository.metadata('005930');
    expect(source.requests.length, 1);
    expect(
      await repository.quotes(['005930', '000660', '005930']),
      hasLength(2),
    );
    expect(
      source.requests.last.queryParameters['query'],
      'SERVICE_ITEM:005930,000660',
    );
  });
}
