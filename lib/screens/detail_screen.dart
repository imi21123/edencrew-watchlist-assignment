import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../state/detail_controller.dart';
import '../state/watchlist_store.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart' as format;
import '../widgets/common.dart';
import '../widgets/stock_chart.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.store,
    required this.stock,
    this.anchor,
  });
  final WatchlistStore store;
  final Stock stock;
  final DateTime? anchor;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final DetailController _detail = DetailController(
    widget.store,
    widget.stock,
    anchor: widget.anchor,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detail.load();
    });
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_detail, widget.store]),
    builder: (context, _) {
      final quote = widget.store.quoteFor(widget.stock.symbol);
      return Scaffold(
        body: ScreenSafeArea(
          child: Column(
            children: [
              Container(
                height: context.dimens.rowMinHeight,
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
                    IconButton(
                      tooltip: '뒤로 가기',
                      onPressed: () {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        size: context.dimens.iconSm,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Expanded(child: StockIdentity(stock: _detail.stock)),
                    FavoriteButton(
                      active: widget.store.contains(_detail.stock),
                      onPressed: () => showFavoriteToast(
                        context,
                        widget.store.toggle(_detail.stock),
                        aboveTabs: false,
                      ),
                    ),
                    SizedBox(width: context.dimens.space1),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.all(context.dimens.space4),
                      sliver: SliverList.list(
                        children: [
                          _price(context, quote),
                          if (_detail.quoteError != null)
                            ErrorNotice(
                              message: _detail.quoteError!,
                              onRetry: _detail.load,
                            ),
                          if (_detail.metadataError != null)
                            ErrorNotice(
                              message: _detail.metadataError!,
                              onRetry: _detail.load,
                            ),
                          SizedBox(height: context.dimens.space2),
                          Row(
                            children: [
                              for (final period in HistoryPeriod.values)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: period == HistoryPeriod.year
                                          ? 0
                                          : context.dimens.space2,
                                    ),
                                    child: InkWell(
                                      key: ValueKey('period-${period.name}'),
                                      onTap: () => _detail.loadHistory(period),
                                      borderRadius: BorderRadius.circular(
                                        context.dimens.radiusMd,
                                      ),
                                      child: Container(
                                        height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _detail.period == period
                                              ? context.colors.accentBg
                                              : context.colors.surfaceBase,
                                          borderRadius: BorderRadius.circular(
                                            context.dimens.radiusMd,
                                          ),
                                        ),
                                        child: Text(
                                          period.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _detail.period == period
                                                ? context.colors.accentDefault
                                                : context.colors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: context.dimens.space2),
                          SizedBox(height: 216, child: _historyChart(context)),
                          SizedBox(height: context.dimens.space3),
                          _metrics(context, quote),
                          SizedBox(height: context.dimens.space6),
                          Text(
                            '일별 시세',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          SizedBox(height: context.dimens.space2),
                          _tableHeader(context),
                        ],
                      ),
                    ),
                    if (_detail.historyLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(context.dimens.space4),
                          child: const Skeleton(width: 120),
                        ),
                      )
                    else if (_detail.historyError != null)
                      SliverToBoxAdapter(
                        child: ErrorNotice(
                          message: _detail.historyError!,
                          onRetry: () => _detail.loadHistory(_detail.period),
                        ),
                      )
                    else if (_detail.rows.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(context.dimens.space4),
                          child: Text(
                            '이 기간의 일별 시세가 없습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.colors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dimens.space4,
                        ),
                        sliver: SliverList.builder(
                          itemCount: _detail.rows.length,
                          itemBuilder: (context, index) =>
                              _dailyRow(context, _detail.rows[index]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _price(BuildContext context, Quote? quote) {
    if (quote == null && _detail.quoteLoading) {
      return SizedBox(
        height: 40,
        child: Row(
          children: [
            const Skeleton(width: 148, height: 28),
            SizedBox(width: context.dimens.space3),
            const Skeleton(width: 96),
          ],
        ),
      );
    }
    final change = quote?.change;
    final direction = change == null || change == 0
        ? ''
        : change > 0
        ? '▲ '
        : '▼ ';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.dimens.space2,
      runSpacing: context.dimens.space1,
      children: [
        Text(
          format.number(quote?.current),
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 32,
            fontWeight: AppTypography.bold,
          ),
        ),
        Text(
          '$direction${format.number(change?.abs())} (${format.percent(quote?.changePercent)})',
          style: TextStyle(color: movementColor(context, change), fontSize: 14),
        ),
      ],
    );
  }

  Widget _historyChart(BuildContext context) {
    if (_detail.historyLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: context.colors.accentDefault,
          strokeWidth: 2,
        ),
      );
    }
    if (_detail.historyError != null) {
      return Center(
        child: ErrorNotice(
          message: _detail.historyError!,
          onRetry: () => _detail.loadHistory(_detail.period),
        ),
      );
    }
    if (_detail.rows.length < 2) {
      return Center(
        child: Text(
          '차트를 그릴 시세가 부족합니다.',
          style: TextStyle(color: context.colors.textTertiary, fontSize: 12),
        ),
      );
    }
    return StockChart(
      key: ValueKey('${widget.stock.symbol}-${_detail.period.name}'),
      rows: _detail.rows,
    );
  }

  Widget _metrics(BuildContext context, Quote? quote) => Column(
    children: [
      Row(
        children: [
          _metric(context, '시가', format.number(quote?.open)),
          SizedBox(width: context.dimens.space2),
          _metric(context, '고가', format.number(quote?.high)),
          SizedBox(width: context.dimens.space2),
          _metric(context, '저가', format.number(quote?.low)),
        ],
      ),
      SizedBox(height: context.dimens.space2),
      Row(
        children: [
          _metric(context, '거래량', format.volume(quote?.volume)),
          SizedBox(width: context.dimens.space2),
          _metric(context, '시가총액', format.marketCap(quote?.marketCap)),
        ],
      ),
    ],
  );

  Widget _metric(BuildContext context, String label, String value) => Expanded(
    child: Container(
      height: context.dimens.rowMinHeight,
      padding: EdgeInsets.symmetric(
        horizontal: context.dimens.space3,
        vertical: context.dimens.space2,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceSunken,
        borderRadius: BorderRadius.circular(context.dimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: context.colors.textTertiary, fontSize: 10),
          ),
          SizedBox(height: context.dimens.space1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 14,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tableHeader(BuildContext context) => Container(
    padding: EdgeInsets.only(bottom: context.dimens.space2),
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
        _cell('날짜', context.colors.textTertiary, flex: 2, left: true),
        _cell('종가', context.colors.textTertiary, flex: 3),
        _cell('등락', context.colors.textTertiary, flex: 2),
        _cell('거래량', context.colors.textTertiary, flex: 3),
      ],
    ),
  );

  Widget _dailyRow(BuildContext context, DailyPrice row) => Container(
    height: 32,
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
        _cell(
          '${row.date.month.toString().padLeft(2, '0')}.${row.date.day.toString().padLeft(2, '0')}',
          context.colors.textSecondary,
          flex: 2,
          left: true,
        ),
        _cell(format.number(row.close), context.colors.textSecondary, flex: 3),
        _cell(
          format.signed(row.change),
          movementColor(context, row.change),
          flex: 2,
        ),
        _cell(format.number(row.volume), context.colors.textSecondary, flex: 3),
      ],
    ),
  );

  Widget _cell(
    String text,
    Color color, {
    required int flex,
    bool left = false,
  }) => Expanded(
    flex: flex,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: left ? TextAlign.left : TextAlign.right,
      style: TextStyle(color: color, fontSize: 10),
    ),
  );
}
