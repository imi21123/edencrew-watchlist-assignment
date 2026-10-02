import 'package:flutter/foundation.dart';

import '../models/stock.dart';
import 'watchlist_store.dart';

class DetailController extends ChangeNotifier {
  DetailController(this.store, this.initialStock, {DateTime? anchor})
    : anchor = anchor ?? DateTime.now();
  final WatchlistStore store;
  final Stock initialStock;
  final DateTime anchor;
  HistoryPeriod period = HistoryPeriod.month;
  List<DailyPrice> rows = [];
  bool quoteLoading = false, historyLoading = false;
  String? quoteError, historyError, metadataError;
  bool _disposed = false;
  int _historyRevision = 0;
  Stock get stock => store.stockFor(initialStock);

  Future<void> load() async {
    await Future.wait([_loadMetadata(), _loadQuote(), loadHistory(period)]);
  }

  Future<void> _loadMetadata() async {
    try {
      store.remember(await store.repository.metadata(initialStock.symbol));
      metadataError = null;
    } catch (_) {
      metadataError = '종목 정보를 갱신하지 못했습니다.';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadQuote() async {
    quoteLoading = true;
    quoteError = null;
    if (!_disposed) notifyListeners();
    try {
      await store.loadQuote(initialStock.symbol);
    } catch (_) {
      quoteError = '현재 시세를 불러오지 못했습니다.';
    }
    quoteLoading = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> loadHistory(HistoryPeriod value) async {
    if (_disposed) return;
    final revision = ++_historyRevision;
    if (period != value) rows = [];
    period = value;
    historyLoading = true;
    historyError = null;
    notifyListeners();
    try {
      final result = await store.repository.history(
        initialStock.symbol,
        value,
        anchor,
      );
      if (_disposed || revision != _historyRevision) return;
      rows = result;
    } catch (_) {
      if (_disposed || revision != _historyRevision) return;
      historyError = '일별 시세를 불러오지 못했습니다.';
    } finally {
      if (!_disposed && revision == _historyRevision) {
        historyLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _historyRevision++;
    super.dispose();
  }
}
