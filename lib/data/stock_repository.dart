import 'dart:async';

import '../models/stock.dart';
import 'naver_dto.dart';
import 'stock_source.dart';

class StockRepository {
  StockRepository(this.source);
  final StockSource source;
  final _metadata = <String, Stock>{};
  final _metadataLoads = <String, Future<Stock>>{};
  final _history = <String, _HistoryCache>{};
  final _queues = <String, Future<void>>{};

  Future<List<Stock>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final rows = parseSearch(
      await source.get(
        Uri.https('ac.stock.naver.com', '/ac', {
          'q': query.trim(),
          'target': 'stock,ipo,index,marketindicator',
        }),
      ),
    );
    return rows.map((stock) => _metadata[stock.symbol] ?? stock).toList();
  }

  Future<Stock> metadata(String symbol) async {
    final cached = _metadata[symbol];
    if (cached != null) return cached;
    final pending = _metadataLoads[symbol];
    if (pending != null) return pending;
    final future = _loadMetadata(symbol);
    _metadataLoads[symbol] = future;
    try {
      return await future;
    } finally {
      _metadataLoads.remove(symbol);
    }
  }

  Future<Stock> _loadMetadata(String symbol) async {
    final json = await source.get(
      Uri.https(
        'stock.naver.com',
        '/api/securityFe/api/fchart/domestic/stock/$symbol',
      ),
    );
    if (json is! Map<String, dynamic>) {
      throw const FormatException('종목 정보가 없습니다.');
    }
    final stock = MetadataDto.fromJson(json).toModel();
    if (stock.symbol != symbol) {
      throw const FormatException('종목 코드가 일치하지 않습니다.');
    }
    _metadata[symbol] = stock;
    return stock;
  }

  Future<Map<String, Quote>> quotes(Iterable<String> symbols) async {
    final unique = symbols.toSet();
    if (unique.isEmpty) return {};
    final parsed = parseQuotes(
      await source.get(
        Uri.https('polling.finance.naver.com', '/api/realtime', {
          'query': 'SERVICE_ITEM:${unique.join(',')}',
        }),
      ),
    );
    return Map.fromEntries(
      parsed.entries.where((entry) => unique.contains(entry.key)),
    );
  }

  /// 종목별로 요청을 직렬화하여 빠른 탭 전환도 중복 구간을 받지 않는다.
  Future<List<DailyPrice>> history(
    String symbol,
    HistoryPeriod period,
    DateTime anchor,
  ) async {
    final previous = _queues[symbol] ?? Future<void>.value();
    final released = Completer<void>();
    final tail = previous.then((_) => released.future);
    _queues[symbol] = tail;
    await previous;
    try {
      final end = DateTime(anchor.year, anchor.month, anchor.day);
      final start = period.start(end);
      // 긴 연휴에도 첫 표시 행의 직전 거래일을 확보하기 위한 버퍼.
      final fetchStart = start.subtract(const Duration(days: 14));
      var cache = _history[symbol];
      if (cache == null) {
        final rows = await _fetchHistory(symbol, fetchStart, end);
        cache = _HistoryCache(fetchStart, end, rows);
        _history[symbol] = cache;
      } else {
        if (fetchStart.isBefore(cache.start)) {
          final rows = await _fetchHistory(
            symbol,
            fetchStart,
            cache.start.subtract(const Duration(days: 1)),
          );
          cache.merge(rows);
          cache.start = fetchStart;
        }
        if (end.isAfter(cache.end)) {
          final rows = await _fetchHistory(
            symbol,
            cache.end.add(const Duration(days: 1)),
            end,
          );
          cache.merge(rows);
          cache.end = end;
        }
      }
      final sorted = cache.rows.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final visible = <DailyPrice>[];
      DailyPrice? previousRow;
      for (final row in sorted) {
        if (!row.date.isBefore(start) && !row.date.isAfter(end)) {
          visible.add(
            row.withChange(
              previousRow == null ? null : row.close - previousRow.close,
            ),
          );
        }
        previousRow = row;
      }
      return visible.reversed.toList();
    } finally {
      released.complete();
      if (identical(_queues[symbol], tail)) _queues.remove(symbol);
    }
  }

  Future<List<DailyPrice>> _fetchHistory(
    String symbol,
    DateTime start,
    DateTime end,
  ) async {
    return parseDaily(
      await source.get(
        Uri.https('api.stock.naver.com', '/chart/domestic/item/$symbol/day', {
          'startDateTime': '${dateKey(start)}0000',
          'endDateTime': '${dateKey(end)}2359',
        }),
      ),
    );
  }

  void close() => source.close();
}

class _HistoryCache {
  _HistoryCache(this.start, this.end, List<DailyPrice> values) {
    merge(values);
  }
  DateTime start, end;
  final rows = <DateTime, DailyPrice>{};
  void merge(List<DailyPrice> values) {
    for (final row in values) {
      rows[row.date] = row;
    }
  }
}
