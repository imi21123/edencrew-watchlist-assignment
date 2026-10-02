import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/main.dart';
import 'package:edencrew_assignment_starter/screens/search_screen.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('NotoSansKR');
    for (final face in ['Regular', 'Medium', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$face.otf'));
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('393×852에서 검색·관심·상세 상태를 동기화하고 모든 기간을 전환한다', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final captureKey = GlobalKey();
    final source = FakeSource();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: EdencrewAssignmentApp(
          repository: StockRepository(source),
          anchor: DateTime(2026, 10, 2),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    await capture(tester, captureKey, 'watchlist_empty');
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    await capture(tester, captureKey, 'search_empty');
    await tester.enterText(find.byKey(const ValueKey('stock-search')), '삼성');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('삼성전자', findRichText: true), findsOneWidget);
    await capture(tester, captureKey, 'search_results');
    await tester.tap(find.byTooltip('관심 등록').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    expect(find.byTooltip('관심 해제'), findsOneWidget);
    await capture(tester, captureKey, 'favorite_toast');
    await tester.tap(find.byKey(const ValueKey('tab-0')));
    await tester.pumpAndSettle();
    expect(find.text('276,000'), findsOneWidget);
    await capture(tester, captureKey, 'watchlist');
    await tester.tap(find.byKey(const ValueKey('sort-open')));
    await tester.pumpAndSettle();
    await capture(tester, captureKey, 'sort');
    await tester.tap(find.byKey(const ValueKey('sort-name')));
    await tester.pumpAndSettle();
    expect(find.text('가나다순'), findsOneWidget);
    await tester.tap(find.text('삼성전자', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('일별 시세'), findsOneWidget);
    final monthCount = tester
        .widget<Candlesticks>(find.byType(Candlesticks))
        .candles
        .length;
    expect(monthCount, greaterThan(10));
    await capture(tester, captureKey, 'detail_month');
    for (final period in ['quarter', 'halfYear', 'year']) {
      await tester.tap(find.byKey(ValueKey('period-$period')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Candlesticks>(find.byType(Candlesticks)).candles.length,
        greaterThan(monthCount),
      );
      expect(tester.takeException(), isNull);
    }
    final historyRequests = source.requests
        .where((uri) => uri.host == 'api.stock.naver.com')
        .length;
    await tester.tap(find.byKey(const ValueKey('period-month')));
    await tester.pumpAndSettle();
    expect(
      source.requests.where((uri) => uri.host == 'api.stock.naver.com').length,
      historyRequests,
    );
    await tester.tap(find.byTooltip('관심 해제'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('관심이 해제되었습니다'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('관심 해제'), findsNothing);
    expect(find.text('삼성전자', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('긴 종목명과 긴 미일치 검색어가 넘치지 않고 지우면 초기 상태가 된다', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final original = (fixture('search.json') as Map)['items'] as List;
    final name = List.filled(20, '아주 긴 종목명').join();
    final source = FakeSource(
      handler: (uri) => uri.queryParameters['q'] == '긴'
          ? {
              'items': [
                <String, dynamic>{
                  ...original.firstWhere((row) => row['code'] == '005930')
                      as Map,
                  'name': name,
                },
              ],
            }
          : {'items': []},
    );
    await tester.pumpWidget(
      EdencrewAssignmentApp(repository: StockRepository(source)),
    );
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('stock-search')), '긴');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(source.requests, isNotEmpty);
    expect(source.requests.single.queryParameters['q'], '긴');
    final searchState = tester.widget<SearchScreen>(find.byType(SearchScreen)).controller;
    expect(searchState.error, isNull);
    expect(searchState.loading, isFalse);
    expect(searchState.query, '긴');
    expect(source.handler!(source.requests.single), isA<Map>());
    expect(searchState.results.map((stock) => stock.name), contains(name));
    expect(find.text(name, findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
    final query = List.filled(20, '없는검색어').join();
    await tester.enterText(find.byKey(const ValueKey('stock-search')), query);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text("'$query'와 일치하는 검색 결과를 찾지 못했습니다."), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('연속 토글은 최신 토스트로 대체하고 2초 뒤 제거한다', (tester) async {
    await tester.pumpWidget(
      EdencrewAssignmentApp(repository: StockRepository(FakeSource())),
    );
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('stock-search')), '삼성');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('관심 등록').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('관심 해제'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('관심이 등록되었습니다'), findsNothing);
    expect(find.text('관심이 해제되었습니다'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('관심이 해제되었습니다'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// 평가용 화면은 로컬 QA용으로만 생성하며 validation/은 Git에서 제외한다.
Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('validation').createSync();
    File('validation/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
