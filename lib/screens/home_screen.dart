import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../state/search_controller.dart';
import '../state/watchlist_store.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, this.anchor});
  final WatchlistStore store;
  final DateTime? anchor;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final StockSearchController _search = StockSearchController(
    widget.store.repository,
  );
  final _input = TextEditingController();
  int _tab = 0;

  void _openDetail(Stock stock) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(
          store: widget.store,
          stock: stock,
          anchor: widget.anchor,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ScreenSafeArea(
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                WatchlistScreen(store: widget.store, onOpen: _openDetail),
                SearchScreen(
                  store: widget.store,
                  controller: _search,
                  input: _input,
                  onOpen: _openDetail,
                ),
              ],
            ),
          ),
          Container(
            height: context.dimens.tabBarHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.colors.borderSubtle,
                  width: context.dimens.borderHairline,
                ),
              ),
            ),
            child: Row(
              children: [
                _tabButton(0, '관심', Icons.star_border_rounded),
                _tabButton(1, '검색', Icons.search_rounded),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tabButton(int index, String label, IconData icon) {
    final color = _tab == index
        ? context.colors.navActive
        : context.colors.navInactive;
    return Expanded(
      child: Semantics(
        selected: _tab == index,
        button: true,
        child: InkWell(
          key: ValueKey('tab-$index'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _tab = index);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                index == 0 && _tab == index ? Icons.star_rounded : icon,
                size: context.dimens.iconMd,
                color: color,
              ),
              SizedBox(height: context.dimens.space1),
              Text(label, style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
