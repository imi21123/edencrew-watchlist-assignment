import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/state/detail_controller.dart';
import 'package:edencrew_assignment_starter/state/watchlist_store.dart';

import '../support.dart';

void main() {
  testWidgets('빠른 기간 전환에서 중간 응답이 최신 탭의 데이터를 덮어쓰지 않는다', (tester) async {
    final first = Completer<Object?>(), second = Completer<Object?>();
    var count = 0;
    final source = FakeSource(
      handler: (_) => ++count == 1 ? first.future : second.future,
    );
    final store = WatchlistStore(StockRepository(source));
    final controller = DetailController(
      store,
      const Stock(symbol: '005930', name: '삼성전자', market: '코스피'),
      anchor: DateTime(2026, 10, 2),
    );
    final month = controller.loadHistory(HistoryPeriod.month);
    final year = controller.loadHistory(HistoryPeriod.year);
    await tester.pump();
    first.complete(fixtureResponse(source.requests.first));
    await tester.pump();
    await month;
    expect(controller.period, HistoryPeriod.year);
    expect(controller.rows, isEmpty);
    expect(controller.historyLoading, isTrue);
    expect(source.requests.length, 2);
    second.complete(fixtureResponse(source.requests.last));
    await tester.pump();
    await year;
    expect(controller.rows.length, greaterThan(200));
    expect(controller.historyLoading, isFalse);
    controller.dispose();
    store.dispose();
  });
}
