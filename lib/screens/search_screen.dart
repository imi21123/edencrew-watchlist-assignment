import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../state/search_controller.dart';
import '../state/watchlist_store.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({
    super.key,
    required this.store,
    required this.controller,
    required this.input,
    required this.onOpen,
  });
  final WatchlistStore store;
  final StockSearchController controller;
  final TextEditingController input;
  final ValueChanged<Stock> onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, store]),
    builder: (context, _) => Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.dimens.space4,
            vertical: context.dimens.space2,
          ),
          child: TextField(
            key: const ValueKey('stock-search'),
            controller: input,
            onChanged: controller.setQuery,
            style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
            cursorColor: context.colors.accentDefault,
            decoration: InputDecoration(
              hintText: '종목명 또는 종목코드',
              hintStyle: TextStyle(
                color: context.colors.textTertiary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: context.colors.surfaceSunken,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: context.dimens.space2,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: context.dimens.iconSm,
                color: context.colors.textTertiary,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: IconButton(
                tooltip: '검색어 지우기',
                icon: Icon(
                  Icons.close_rounded,
                  size: context.dimens.iconSm,
                  color: context.colors.textTertiary,
                ),
                onPressed: () {
                  input.clear();
                  controller.setQuery('');
                },
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.dimens.radiusMd),
                borderSide: BorderSide(
                  color: context.colors.borderSubtle,
                  width: context.dimens.borderHairline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.dimens.radiusMd),
                borderSide: BorderSide(
                  color: context.colors.accentDefault,
                  width: context.dimens.borderHairline,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: _results(context)),
      ],
    ),
  );

  Widget _results(BuildContext context) {
    if (controller.query.trim().isEmpty) {
      return const EmptyMessage(
        icon: Icons.search_rounded,
        title: '종목을 검색해 보세요',
        description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      );
    }
    if (controller.loading) return const LoadingRows();
    if (controller.error != null) {
      return Center(
        child: ErrorNotice(
          message: controller.error!,
          onRetry: controller.retry,
        ),
      );
    }
    if (controller.results.isEmpty) {
      return EmptyMessage(
        icon: Icons.search_off_rounded,
        title: '검색 결과가 없습니다',
        description: "'${controller.query}'와 일치하는 검색 결과를 찾지 못했습니다.",
      );
    }
    return ListView.builder(
      itemCount: controller.results.length,
      itemBuilder: (context, index) {
        final stock = store.stockFor(controller.results[index]);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dimens.space4),
          child: Container(
            constraints: BoxConstraints(minHeight: context.dimens.rowMinHeight),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.colors.borderSubtle,
                  width: context.dimens.borderHairline,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onOpen(stock),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.dimens.space2,
                      ),
                      child: StockIdentity(
                        stock: stock,
                        query: controller.query,
                      ),
                    ),
                  ),
                ),
                FavoriteButton(
                  active: store.contains(stock),
                  onPressed: () =>
                      showFavoriteToast(context, store.toggle(stock)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
