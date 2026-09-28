/// Weight measurement unit chosen by the user in settings.
enum WeightUnit {
  kg,
  lb;

  String get suffix => this == WeightUnit.kg ? 'kg' : 'lb';

  static const double _lbPerKg = 2.2046226218;

  /// Convert a value stored in kilograms into this unit for display.
  double fromKg(double kg) => this == WeightUnit.kg ? kg : kg * _lbPerKg;

  /// Convert a user-entered value in this unit back into kilograms for storage.
  double toKg(double value) => this == WeightUnit.kg ? value : value / _lbPerKg;
}

class Formatters {
  Formatters._();

  /// Formats a weight (stored in kg) for display in the given unit.
  static String weight(double kg, WeightUnit unit, {bool withSuffix = true}) {
    final value = unit.fromKg(kg);
    final text = _trim(value, 1);
    return withSuffix ? '$text ${unit.suffix}' : text;
  }

  /// Signed delta such as "-2.4" / "+0.6".
  static String signedWeight(double kgDelta, WeightUnit unit) {
    final value = unit.fromKg(kgDelta);
    final sign = value > 0 ? '+' : '';
    return '$sign${_trim(value, 1)}';
  }

  static String calories(num kcal) => '${kcal.round()}';

  /// Formats a stored body-fat percentage value, e.g. `23.5%`.
  static String bodyFat(num pct, {bool withSuffix = true}) {
    final text = _trim(pct.toDouble(), 1);
    return withSuffix ? '$text%' : text;
  }

  static String percent(double ratio) =>
      '${(ratio * 100).clamp(0, 100).round()}%';

  /// Weekly pace such as "-0.4 kg/周" / "+0.3 kg/周". Null-safe.
  static String weeklyDelta(double? deltaKg, WeightUnit unit) {
    if (deltaKg == null) return '—';
    final v = unit.fromKg(deltaKg);
    final sign = v > 0.004 ? '+' : '';
    return '$sign${_trim(v, 1)} ${unit.suffix}/周';
  }

  static String _trim(double value, int decimals) {
    final s = value.toStringAsFixed(decimals);
    if (s.endsWith('.0')) return s.substring(0, s.length - 2);
    return s;
  }
}
