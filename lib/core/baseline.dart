/// Compares today's value with the user's own recent history.
library;

enum BaselineStatus { below, typical, above, learning }

/// Days of history needed before the app labels anything.
const baselineMinDays = 14;

/// Days of history the baseline looks at.
const baselineWindowDays = 30;

class UsualRange {
  const UsualRange(this.low, this.high);
  final double low;
  final double high;

  @override
  String toString() => 'UsualRange($low–$high)';
}

/// The middle half of the user's recent values (25th to 75th percentile).
/// Null until there are [baselineMinDays] values.
// ponytail: plain interquartile range. If narrow ranges flag too many
// "below/above" days in the beta, add a minimum width (e.g. ±3% of median).
UsualRange? usualRange(Iterable<num> history) {
  final v = history.map((e) => e.toDouble()).toList()..sort();
  if (v.length < baselineMinDays) return null;
  return UsualRange(_percentile(v, 0.25), _percentile(v, 0.75));
}

BaselineStatus compareToUsual(num value, Iterable<num> history) {
  final r = usualRange(history);
  if (r == null) return BaselineStatus.learning;
  if (value < r.low) return BaselineStatus.below;
  if (value > r.high) return BaselineStatus.above;
  return BaselineStatus.typical;
}

double _percentile(List<double> sorted, double q) {
  final pos = (sorted.length - 1) * q;
  final lo = pos.floor();
  final hi = pos.ceil();
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}
