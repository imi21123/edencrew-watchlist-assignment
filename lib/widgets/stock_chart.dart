import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../theme/theme.dart';

class StockChart extends StatelessWidget {
  const StockChart({super.key, required this.rows});
  final List<DailyPrice> rows;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: '선택 기간의 일별 캔들 차트',
      child: Candlesticks(
        candles: rows
            .map(
              (row) => Candle(
                date: row.date,
                open: row.open,
                high: row.high,
                low: row.low,
                close: row.close,
                volume: row.volume,
              ),
            )
            .toList(),
        style: CandleSticksStyle(
          chartBackgroundColor: colors.surfaceBase,
          gridLineColor: colors.borderSubtle,
          axisTextColor: colors.chartAxisLabel,
          candleBullColor: colors.chartLineUp,
          candleBearColor: colors.chartLineDown,
          volumeBullColor: colors.chartVolumeBar,
          volumeBearColor: colors.chartVolumeBar,
          crosshairLineColor: colors.chartBaseline,
          crosshairLabelBackgroundColor: colors.surfaceOverlay,
          crosshairLabelTextColor: colors.textPrimary,
          ohlcInfoTextColor: colors.chartAxisLabel,
          ohlcInfoBullColor: colors.chartLineUp,
          ohlcInfoBearColor: colors.chartLineDown,
          priceIndicatorBullBackgroundColor: colors.chartLineUp,
          priceIndicatorBearBackgroundColor: colors.chartLineDown,
          priceIndicatorTextColor: colors.textPrimary,
          scaleButtonActiveBackgroundColor: colors.accentBg,
          scaleButtonActiveTextColor: colors.accentDefault,
          scaleButtonInactiveBackgroundColor: colors.surfaceOverlay,
          scaleButtonInactiveTextColor: colors.textSecondary,
          loadingIndicatorColor: colors.accentDefault,
        ),
      ),
    );
  }
}
