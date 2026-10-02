String number(double? value) {
  if (value == null || !value.isFinite) return '—';
  return value.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

String signed(double? value) =>
    value == null ? '—' : '${value > 0 ? '+' : ''}${number(value)}';

String percent(double? value) => value == null
    ? '—'
    : '${value > 0 ? '+' : ''}${value == 0 ? '0.00' : value.toStringAsFixed(2)}%';

String volume(double? value) =>
    value == null ? '—' : '${number(value / 1000)}천';
String marketCap(double? value) {
  if (value == null) return '—';
  if (value.abs() >= 1000000000000) return '${number(value / 1000000000000)}조';
  return '${number(value / 100000000)}억';
}
