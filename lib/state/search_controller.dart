import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/stock_repository.dart';
import '../models/stock.dart';

class StockSearchController extends ChangeNotifier {
  StockSearchController(this.repository);
  final StockRepository repository;
  String query = '';
  List<Stock> results = [];
  bool loading = false;
  String? error;
  Timer? _timer;
  int _revision = 0;
  bool _disposed = false;

  void setQuery(String value) {
    query = value;
    final revision = ++_revision;
    _timer?.cancel();
    results = [];
    error = null;
    loading = value.trim().isNotEmpty;
    notifyListeners();
    if (loading) {
      _timer = Timer(
        const Duration(milliseconds: 300),
        () => _search(revision, value),
      );
    }
  }

  void retry() {
    _timer?.cancel();
    if (query.trim().isNotEmpty) _search(++_revision, query);
  }

  Future<void> _search(int revision, String value) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await repository.search(value);
      if (_disposed || revision != _revision) return;
      results = rows;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      error = '검색 결과를 불러오지 못했습니다.';
    } finally {
      if (!_disposed && revision == _revision) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _timer?.cancel();
    super.dispose();
  }
}
