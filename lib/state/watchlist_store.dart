import 'package:flutter/foundation.dart';

import '../data/stock_repository.dart';
import '../models/stock.dart';

class WatchlistStore extends ChangeNotifier {
  WatchlistStore(this.repository);
  final StockRepository repository;
  final _favorites = <String, Stock>{};
  final _stocks = <String, Stock>{};
  final _quotes = <String, Quote>{};
  final _quoteErrors = <String, String>{};
  final _loading = <String>{};
  final _quoteLoads = <String, Future<void>>{};
  SortOrder order = SortOrder.price;
  bool refreshing = false;
  String? refreshError;
  int _revision = 0;
  bool _disposed = false;

  bool contains(Stock stock) => _favorites.containsKey(stock.id);
  Stock stockFor(Stock stock) => _stocks[stock.id] ?? stock;
  Quote? quoteFor(String symbol) => _quotes[symbol];
  String? errorFor(String symbol) => _quoteErrors[symbol];
  bool loading(String symbol) => _loading.contains(symbol);

  List<Stock> get favorites {
    final rows = _favorites.values.map(stockFor).toList();
    rows.sort((a, b) {
      int comparison;
      if (order == SortOrder.name) {
        comparison = a.name.compareTo(b.name);
      } else {
        final aValue = order == SortOrder.price
            ? _quotes[a.symbol]?.current
            : _quotes[a.symbol]?.changePercent;
        final bValue = order == SortOrder.price
            ? _quotes[b.symbol]?.current
            : _quotes[b.symbol]?.changePercent;
        comparison = aValue == null
            ? (bValue == null ? 0 : 1)
            : bValue == null
            ? -1
            : bValue.compareTo(aValue);
      }
      return comparison == 0 ? a.symbol.compareTo(b.symbol) : comparison;
    });
    return rows;
  }

  void remember(Stock stock) {
    if (_disposed) return;
    _stocks[stock.id] = stock;
    notifyListeners();
  }

  void sortBy(SortOrder value) {
    order = value;
    notifyListeners();
  }

  bool toggle(Stock stock) {
    final added = !contains(stock);
    if (added) {
      _favorites[stock.id] = stockFor(stock);
      _stocks.putIfAbsent(stock.id, () => stock);
      _updateMetadata(stock.symbol);
    } else {
      _favorites.remove(stock.id);
    }
    notifyListeners();
    refresh();
    return added;
  }

  Future<void> _updateMetadata(String symbol) async {
    try {
      remember(await repository.metadata(symbol));
    } catch (_) {
      // 검색 응답에도 이름·시장이 있다. 메타데이터 실패는 상세 화면에서 재시도한다.
    }
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final revision = ++_revision;
    final symbols = _favorites.values.map((s) => s.symbol).toList();
    _loading.clear();
    refreshError = null;
    refreshing = symbols.isNotEmpty;
    for (final symbol in symbols) {
      _loading.add(symbol);
      _quoteErrors.remove(symbol);
    }
    notifyListeners();
    if (symbols.isEmpty) return;
    try {
      final result = await repository.quotes(symbols);
      if (_disposed || revision != _revision) return;
      _quotes.addAll(result);
      for (final symbol in symbols) {
        if (!result.containsKey(symbol)) {
          _quoteErrors[symbol] = '시세 정보가 없습니다';
        }
      }
    } catch (_) {
      if (_disposed || revision != _revision) return;
      refreshError = '시세를 불러오지 못했습니다. 다시 시도해 주세요.';
      for (final symbol in symbols) {
        _quoteErrors[symbol] = '시세 조회 실패';
      }
    } finally {
      if (!_disposed && revision == _revision) {
        _loading.clear();
        refreshing = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadQuote(String symbol) async {
    final existing = _quoteLoads[symbol];
    if (existing != null) return existing;
    final future = _loadSingleQuote(symbol);
    _quoteLoads[symbol] = future;
    try {
      await future;
    } finally {
      _quoteLoads.remove(symbol);
    }
  }

  Future<void> _loadSingleQuote(String symbol) async {
    final rows = await repository.quotes([symbol]);
    if (_disposed) return;
    final quote = rows[symbol];
    if (quote == null) throw StateError('시세 정보가 없습니다.');
    _quotes[symbol] = quote;
    _quoteErrors.remove(symbol);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
