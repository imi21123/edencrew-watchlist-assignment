class Stock {
  const Stock({required this.symbol, required this.name, required this.market});
  final String symbol;
  final String name;
  final String market;
  String get id => 'domestic:$symbol';
}

class Quote {
  const Quote({
    required this.symbol,
    this.current,
    this.previousClose,
    this.open,
    this.high,
    this.low,
    this.volume,
    this.listedShares,
  });
  final String symbol;
  final double? current, previousClose, open, high, low;
  final double? volume, listedShares;
  double? get change => current != null && previousClose != null
      ? current! - previousClose!
      : null;
  double? get changePercent => change != null && previousClose! > 0
      ? change! / previousClose! * 100
      : null;
  double? get marketCap =>
      current != null && listedShares != null ? current! * listedShares! : null;
}

class DailyPrice {
  const DailyPrice({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    this.change,
  });
  final DateTime date;
  final double open, high, low, close, volume;
  final double? change;
  DailyPrice withChange(double? value) => DailyPrice(
    date: date,
    open: open,
    high: high,
    low: low,
    close: close,
    volume: volume,
    change: value,
  );
}

enum HistoryPeriod {
  month('1개월', 1),
  quarter('3개월', 3),
  halfYear('6개월', 6),
  year('1년', 12);

  const HistoryPeriod(this.label, this.months);
  final String label;
  final int months;
  DateTime start(DateTime end) {
    final first = DateTime(end.year, end.month - months);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(
      first.year,
      first.month,
      end.day > lastDay ? lastDay : end.day,
    );
  }
}

enum SortOrder {
  price('현재가순'),
  change('등락률순'),
  name('가나다순');

  const SortOrder(this.label);
  final String label;
}
