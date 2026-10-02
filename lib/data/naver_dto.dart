import '../models/stock.dart';

double? readNumber(Object? value) {
  final result = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().replaceAll(',', '') ?? '');
  return result != null && result.isFinite ? result : null;
}

class SearchStockDto {
  SearchStockDto.fromJson(Map<String, dynamic> json)
    : symbol = json['code']?.toString() ?? '',
      name = json['name']?.toString() ?? '',
      market = json['typeName']?.toString() ?? '',
      nation = json['nationCode']?.toString() ?? '',
      category = json['category']?.toString() ?? '';
  final String symbol, name, market, nation, category;
  bool get isDomesticStock =>
      nation == 'KOR' &&
      category == 'stock' &&
      RegExp(r'^\d{6}$').hasMatch(symbol) &&
      name.isNotEmpty;
  Stock toModel() => Stock(symbol: symbol, name: name, market: market);
}

class MetadataDto {
  MetadataDto.fromJson(Map<String, dynamic> json)
    : symbol = json['symbolCode']?.toString() ?? '',
      name = json['stockName']?.toString() ?? '',
      market = json['stockExchangeNameKor']?.toString() ?? '';
  final String symbol, name, market;
  Stock toModel() {
    if (!RegExp(r'^\d{6}$').hasMatch(symbol) ||
        name.isEmpty ||
        market.isEmpty) {
      throw const FormatException('종목 정보 응답 형식이 올바르지 않습니다.');
    }
    return Stock(symbol: symbol, name: name, market: market);
  }
}

class QuoteDto {
  QuoteDto.fromJson(Map<String, dynamic> json)
    : value = Quote(
        symbol: json['cd']?.toString() ?? '',
        current: readNumber(json['nv']),
        previousClose: readNumber(json['pcv']),
        open: readNumber(json['ov']),
        high: readNumber(json['hv']),
        low: readNumber(json['lv']),
        volume: readNumber(json['aq']),
        listedShares: readNumber(json['countOfListedStock']),
      );
  final Quote value;
  Quote toModel() => value;
}

class DailyPriceDto {
  DailyPriceDto.fromJson(Map<String, dynamic> json) {
    final raw = json['localDate']?.toString() ?? '';
    final open = readNumber(json['openPrice']);
    final high = readNumber(json['highPrice']);
    final low = readNumber(json['lowPrice']);
    final close = readNumber(json['closePrice']);
    final volume = readNumber(json['accumulatedTradingVolume']);
    if (!RegExp(r'^\d{8}$').hasMatch(raw) ||
        [open, high, low, close, volume].any((n) => n == null)) {
      throw const FormatException('일별 시세 응답 형식이 올바르지 않습니다.');
    }
    final date = DateTime(
      int.parse(raw.substring(0, 4)),
      int.parse(raw.substring(4, 6)),
      int.parse(raw.substring(6, 8)),
    );
    if (dateKey(date) != raw ||
        low! > high! ||
        open! < low ||
        open > high ||
        close! < low ||
        close > high ||
        volume! < 0) {
      throw const FormatException('일별 시세 값이 올바르지 않습니다.');
    }
    value = DailyPrice(
      date: date,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume,
    );
  }
  late final DailyPrice value;
  DailyPrice toModel() => value;
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}'
    '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

List<Stock> parseSearch(Object? json) {
  if (json is! Map<String, dynamic> || json['items'] is! List) {
    throw const FormatException('검색 응답 형식이 올바르지 않습니다.');
  }
  final unique = <String, Stock>{};
  for (final item in json['items'] as List) {
    if (item is! Map<String, dynamic>) continue;
    final dto = SearchStockDto.fromJson(item);
    if (dto.isDomesticStock) unique[dto.symbol] = dto.toModel();
  }
  return unique.values.toList();
}

Map<String, Quote> parseQuotes(Object? json) {
  if (json is! Map<String, dynamic> || json['resultCode'] != 'success') {
    throw const FormatException('시세 응답 형식이 올바르지 않습니다.');
  }
  final result = json['result'];
  if (result is! Map || result['areas'] is! List) {
    throw const FormatException('시세 목록이 없습니다.');
  }
  final quotes = <String, Quote>{};
  for (final area in result['areas'] as List) {
    if (area is! Map || area['datas'] is! List) continue;
    for (final item in area['datas'] as List) {
      if (item is! Map<String, dynamic>) continue;
      final quote = QuoteDto.fromJson(item).toModel();
      if (quote.symbol.isNotEmpty && quote.current != null) {
        quotes[quote.symbol] = quote;
      }
    }
  }
  return quotes;
}

List<DailyPrice> parseDaily(Object? json) {
  if (json is! List) throw const FormatException('일별 시세 목록이 없습니다.');
  final rows = <DateTime, DailyPrice>{};
  for (final item in json) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException('일별 시세 행이 올바르지 않습니다.');
    }
    final row = DailyPriceDto.fromJson(item).toModel();
    rows[row.date] = row;
  }
  return rows.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}
