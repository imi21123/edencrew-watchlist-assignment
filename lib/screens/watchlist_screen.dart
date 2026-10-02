import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../state/watchlist_store.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart' as format;
import '../widgets/common.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key, required this.store, required this.onOpen});
  final WatchlistStore store;
  final ValueChanged<Stock> onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Column(
      children: [
        SizedBox(
          height: context.dimens.rowMinHeight,
          child: Padding(
            padding: EdgeInsets.only(
              left: context.dimens.space4,
              right: context.dimens.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '관심',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 20,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                InkWell(
                  key: const ValueKey('sort-open'),
                  borderRadius: BorderRadius.circular(context.dimens.radiusSm),
                  onTap: () => _showSort(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.dimens.space2,
                      vertical: context.dimens.space1,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceBase,
                      borderRadius: BorderRadius.circular(
                        context.dimens.radiusSm,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          store.order.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        SizedBox(width: context.dimens.space1),
                        Icon(
                          Icons.south_rounded,
                          color: context.colors.textTertiary,
                          size: context.dimens.iconSm,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '시세 새로고침',
                  onPressed: store.refreshing ? null : store.refresh,
                  icon: store.refreshing
                      ? SizedBox(
                          width: context.dimens.iconMd,
                          height: context.dimens.iconMd,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.accentDefault,
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: context.colors.textSecondary,
                          size: context.dimens.iconMd,
                        ),
                ),
              ],
            ),
          ),
        ),
        if (store.refreshError != null)
          ErrorNotice(message: store.refreshError!, onRetry: store.refresh),
        Expanded(
          child: store.favorites.isEmpty
              ? const EmptyMessage(
                  icon: Icons.star_border_rounded,
                  title: '관심 종목이 없습니다',
                  description: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
                )
              : ListView.builder(
                  itemCount: store.favorites.length,
                  itemBuilder: (context, index) =>
                      _row(context, store.favorites[index]),
                ),
        ),
      ],
    ),
  );

  Widget _row(BuildContext context, Stock stock) {
    final quote = store.quoteFor(stock.symbol);
    final error = store.errorFor(stock.symbol);
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
        child: InkWell(
          onTap: () => onOpen(stock),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.dimens.space2),
            child: Row(
              children: [
                Expanded(child: StockIdentity(stock: stock)),
                SizedBox(width: context.dimens.space3),
                if (quote == null && store.loading(stock.symbol))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Skeleton(width: 64),
                      SizedBox(height: context.dimens.space2),
                      const Skeleton(width: 48, height: 10),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        format.number(quote?.current),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: context.dimens.space1),
                      Text(
                        '${format.signed(quote?.change)} (${format.percent(quote?.changePercent)})',
                        style: TextStyle(
                          fontSize: 10,
                          color: movementColor(context, quote?.change),
                        ),
                      ),
                      if (error != null)
                        Text(
                          error,
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.feedbackWarning,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSort(BuildContext context) async {
    final selection = await showModalBottomSheet<SortOrder>(
      context: context,
      backgroundColor: context.colors.surfaceSunken,
      constraints: const BoxConstraints(maxWidth: 393),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimens.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.dimens.space6,
            context.dimens.space6,
            context.dimens.space6,
            34,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '정렬',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 20,
                  fontWeight: AppTypography.bold,
                ),
              ),
              SizedBox(height: context.dimens.space4),
              for (final order in SortOrder.values)
                InkWell(
                  key: ValueKey('sort-${order.name}'),
                  onTap: () => Navigator.of(context).pop(order),
                  child: SizedBox(
                    height: context.dimens.rowMinHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.label,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (order == store.order)
                          Icon(
                            Icons.check_rounded,
                            color: context.colors.textPrimary,
                            size: context.dimens.iconMd,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (selection != null) store.sortBy(selection);
  }
}
