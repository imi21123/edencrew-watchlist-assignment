import 'package:flutter/material.dart';

import 'data/stock_repository.dart';
import 'data/stock_source.dart';
import 'screens/home_screen.dart';
import 'state/watchlist_store.dart';
import 'theme/theme.dart';

void main() => runApp(const EdencrewAssignmentApp());

class EdencrewAssignmentApp extends StatefulWidget {
  const EdencrewAssignmentApp({super.key, this.repository, this.anchor});
  final StockRepository? repository;
  final DateTime? anchor;

  @override
  State<EdencrewAssignmentApp> createState() => _AppState();
}

class _AppState extends State<EdencrewAssignmentApp> {
  late final StockRepository _repository =
      widget.repository ??
      StockRepository(
        const bool.fromEnvironment('USE_MOCK') ? SampleSource() : NaverSource(),
      );
  late final WatchlistStore _store = WatchlistStore(_repository);

  @override
  void dispose() {
    _store.dispose();
    _repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '국내 주식 관심종목',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    builder: (context, child) => ColoredBox(
      color: context.colors.surfaceBase,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: child!,
        ),
      ),
    ),
    home: HomeScreen(store: _store, anchor: widget.anchor),
  );
}
