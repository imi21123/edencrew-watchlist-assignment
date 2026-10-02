import 'dart:convert';

import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

abstract class StockSource {
  Future<Object?> get(Uri uri);
  void close() {}
}

class NaverSource implements StockSource {
  NaverSource({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  @override
  Future<Object?> get(Uri uri) async {
    final response = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }
    String text;
    try {
      text = utf8.decode(response.bodyBytes);
    } on FormatException {
      final type = response.headers['content-type'] ?? '';
      final charset =
          RegExp(
            r'charset=([^;\s]+)',
            caseSensitive: false,
          ).firstMatch(type)?.group(1)?.replaceAll('"', '') ??
          'EUC-KR';
      text = await CharsetConverter.decode(charset, response.bodyBytes);
    }
    return jsonDecode(text);
  }

  @override
  void close() => _client.close();
}

/// 명시적으로 선택한 개발 모드만 사용한다. 실제 요청 실패를 숨기지 않는다.
class SampleSource implements StockSource {
  static const symbols = {'005930', '000660'};
  @override
  Future<Object?> get(Uri uri) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    String file;
    if (uri.host == 'ac.stock.naver.com') {
      final samsung =
          jsonDecode(await rootBundle.loadString('assets/mock/search.json'))
              as Map;
      final sk =
          jsonDecode(await rootBundle.loadString('assets/mock/search_sk.json'))
              as Map;
      final query = (uri.queryParameters['q'] ?? '').toLowerCase();
      return {
        'items': [...samsung['items'] as List, ...sk['items'] as List]
            .where(
              (item) =>
                  symbols.contains(item['code']) &&
                  ('${item['name']}'.toLowerCase().contains(query) ||
                      '${item['code']}'.contains(query)),
            )
            .toList(),
      };
    } else if (uri.host == 'polling.finance.naver.com') {
      file = 'quotes.json';
    } else {
      final symbol = uri.pathSegments.where(symbols.contains).firstOrNull;
      if (symbol == null) throw StateError('샘플 모드는 삼성전자·SK하이닉스만 지원합니다.');
      file = uri.host == 'api.stock.naver.com'
          ? 'daily_$symbol.json'
          : 'metadata_$symbol.json';
    }
    final json = jsonDecode(await rootBundle.loadString('assets/mock/$file'));
    if (json is List) {
      final start = uri.queryParameters['startDateTime']!.substring(0, 8);
      final end = uri.queryParameters['endDateTime']!.substring(0, 8);
      return json
          .where(
            (row) =>
                row['localDate'].toString().compareTo(start) >= 0 &&
                row['localDate'].toString().compareTo(end) <= 0,
          )
          .toList();
    }
    return json;
  }

  @override
  void close() {}
}
