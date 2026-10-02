import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:edencrew_assignment_starter/data/stock_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final uri = Uri.https('polling.finance.naver.com', '/api/realtime');

  test('UTF-8 JSON 응답을 디코딩한다', () async {
    final source = NaverSource(
      client: MockClient(
        (_) async =>
            http.Response.bytes(utf8.encode('{"stockName":"삼성전자"}'), 200),
      ),
    );
    expect(await source.get(uri), {'stockName': '삼성전자'});
    source.close();
  });

  test('UTF-8이 아닌 응답은 헤더의 EUC-KR을 native converter에 전달한다', () async {
    var decoded = false;
    const channel = MethodChannel('charset_converter');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'decode');
          expect((call.arguments as Map)['charset'], 'EUC-KR');
          decoded = true;
          return '{"stockName":"삼성전자"}';
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final source = NaverSource(
      client: MockClient(
        (_) async => http.Response.bytes(
          [0xb0, 0xa1],
          200,
          headers: {'content-type': 'text/plain;charset=EUC-KR'},
        ),
      ),
    );
    expect(await source.get(uri), {'stockName': '삼성전자'});
    expect(decoded, isTrue);
    source.close();
  });

  test('HTTP 실패와 잘못된 JSON은 샘플로 대체하지 않는다', () async {
    final offline = NaverSource(
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );
    await expectLater(offline.get(uri), throwsStateError);
    offline.close();
    final malformed = NaverSource(
      client: MockClient((_) async => http.Response('not json', 200)),
    );
    await expectLater(malformed.get(uri), throwsFormatException);
    malformed.close();
  });

  testWidgets('10초 넘는 요청은 타임아웃으로 끝난다', (tester) async {
    final response = Completer<http.Response>();
    final source = NaverSource(client: MockClient((_) => response.future));
    final expectation = expectLater(
      source.get(uri),
      throwsA(isA<TimeoutException>()),
    );
    await tester.pump(const Duration(seconds: 10));
    await expectation;
    response.complete(http.Response('{}', 200));
    await tester.pump();
    source.close();
  });
}
