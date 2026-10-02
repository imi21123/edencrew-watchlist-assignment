import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/data/stock_source.dart';

Object? fixture(String file) =>
    jsonDecode(File('assets/mock/$file').readAsStringSync());

class FakeSource implements StockSource {
  FakeSource({this.handler});
  final FutureOr<Object?> Function(Uri)? handler;
  final requests = <Uri>[];
  @override
  Future<Object?> get(Uri uri) async {
    requests.add(uri);
    if (handler != null) return handler!(uri);
    return fixtureResponse(uri);
  }

  @override
  void close() {}
}

Object? fixtureResponse(Uri uri) {
  if (uri.host == 'ac.stock.naver.com') {
    final all = [
      ...(fixture('search.json') as Map)['items'] as List,
      ...(fixture('search_sk.json') as Map)['items'] as List,
    ];
    final query = uri.queryParameters['q']!.toLowerCase();
    return {
      'items': all
          .where(
            (row) =>
                row['name'].toString().toLowerCase().contains(query) ||
                row['code'].toString().contains(query),
          )
          .toList(),
    };
  }
  if (uri.host == 'polling.finance.naver.com') return fixture('quotes.json');
  final symbol = uri.pathSegments.firstWhere(
    (part) => RegExp(r'^\d{6}$').hasMatch(part),
  );
  if (uri.host != 'api.stock.naver.com') {
    return fixture('metadata_$symbol.json');
  }
  final start = uri.queryParameters['startDateTime']!.substring(0, 8);
  final end = uri.queryParameters['endDateTime']!.substring(0, 8);
  return (fixture('daily_$symbol.json') as List)
      .where(
        (row) =>
            row['localDate'].toString().compareTo(start) >= 0 &&
            row['localDate'].toString().compareTo(end) <= 0,
      )
      .toList();
}
