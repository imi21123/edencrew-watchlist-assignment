import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/state/watchlist_store.dart';

import '../support.dart';

void main() {
  const samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
  const sk = Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피');
  test('등록·해제는 즉시 반영되고 시세 기준 정렬을 바꿀 수 있다', () async {
    final store = WatchlistStore(StockRepository(FakeSource()));
    expect(store.favorites, isEmpty);
    expect(store.toggle(samsung), isTrue);
    expect(store.contains(samsung), isTrue);
    store.toggle(sk);
    await store.refresh();
    expect(store.favorites.map((s) => s.symbol), ['000660', '005930']);
    store.sortBy(SortOrder.change);
    expect(store.favorites.first.symbol, '000660');
    store.sortBy(SortOrder.name);
    expect(store.favorites.first.symbol, '000660');
    expect(store.toggle(samsung), isFalse);
    expect(store.contains(samsung), isFalse);
    store.dispose();
  });

  test('시세 미수신 행은 뒤로 정렬하고 새로고침 실패 시 기존 가격을 유지한다', () async {
    var fail = false;
    final source = FakeSource(
      handler: (uri) {
        if (fail && uri.host == 'polling.finance.naver.com') {
          throw StateError('offline');
        }
        return fixtureResponse(uri);
      },
    );
    final store = WatchlistStore(StockRepository(source));
    store.toggle(samsung);
    await store.refresh();
    fail = true;
    store.toggle(sk);
    await store.refresh();
    expect(store.favorites.first.symbol, '005930');
    expect(store.quoteFor('005930')!.current, 276000);
    expect(store.quoteFor('000660'), isNull);
    expect(store.refreshError, isNotNull);
    expect(store.loading('000660'), isFalse);
    store.dispose();
  });

  test('등록 후 해제했을 때 뒤늦은 시세 응답이 목록을 복구하지 않는다', () async {
    final quote = Completer<Object?>();
    final source = FakeSource(
      handler: (uri) => uri.host == 'polling.finance.naver.com'
          ? quote.future
          : fixtureResponse(uri),
    );
    final store = WatchlistStore(StockRepository(source));
    store.toggle(samsung);
    store.toggle(samsung);
    quote.complete(fixture('quotes.json'));
    await Future<void>.delayed(Duration.zero);
    expect(store.favorites, isEmpty);
    expect(store.refreshing, isFalse);
    store.dispose();
  });
}
