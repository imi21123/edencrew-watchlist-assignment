import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/state/search_controller.dart';

import '../support.dart';

void main() {
  testWidgets('300ms 디바운스 뒤 최신 검색만 요청하고 늦은 이전 응답을 무시한다', (tester) async {
    final samsung = Completer<Object?>(), sk = Completer<Object?>();
    final source = FakeSource(
      handler: (uri) =>
          uri.queryParameters['q'] == '삼성' ? samsung.future : sk.future,
    );
    final controller = StockSearchController(StockRepository(source));
    controller.setQuery('삼');
    await tester.pump(const Duration(milliseconds: 150));
    controller.setQuery('삼성');
    await tester.pump(const Duration(milliseconds: 299));
    expect(source.requests, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(source.requests.single.queryParameters['q'], '삼성');
    controller.setQuery('SK');
    await tester.pump(const Duration(milliseconds: 300));
    sk.complete(fixture('search_sk.json'));
    await tester.pump();
    expect(controller.results.any((stock) => stock.symbol == '000660'), isTrue);
    samsung.complete(fixture('search.json'));
    await tester.pump();
    expect(controller.query, 'SK');
    expect(
      controller.results.any((stock) => stock.symbol == '005930'),
      isFalse,
    );
    controller.dispose();
  });

  testWidgets('검색어를 지운 후 도착한 응답은 초기 상태를 바꾸지 않는다', (tester) async {
    final response = Completer<Object?>();
    final controller = StockSearchController(
      StockRepository(FakeSource(handler: (_) => response.future)),
    );
    controller.setQuery('삼성');
    await tester.pump(const Duration(milliseconds: 300));
    controller.setQuery('');
    response.complete(fixture('search.json'));
    await tester.pump();
    expect(controller.results, isEmpty);
    expect(controller.loading, isFalse);
    controller.dispose();
  });

  testWidgets('검색 오류는 표시하고 재시도 성공 시 해제한다', (tester) async {
    var fail = true;
    final source = FakeSource(
      handler: (uri) {
        if (fail) throw StateError('offline');
        return fixtureResponse(uri);
      },
    );
    final controller = StockSearchController(StockRepository(source));
    controller.setQuery('삼성');
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.error, isNotNull);
    fail = false;
    controller.retry();
    await tester.pump();
    expect(controller.error, isNull);
    expect(controller.results, isNotEmpty);
    controller.dispose();
  });
}
