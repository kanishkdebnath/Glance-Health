/// Share of the day's steps the user has usually taken by [now], from past
/// days' hourly buckets (each a list of 24). Returns null without history.
double? usualFractionBy(List<List<int>> pastDays, DateTime now) {
  final fractions = <double>[];
  for (final hours in pastDays) {
    final total = hours.fold(0, (a, b) => a + b);
    if (total == 0) continue;
    var done = 0.0;
    for (var h = 0; h < now.hour; h++) {
      done += hours[h];
    }
    done += hours[now.hour] * now.minute / 60;
    fractions.add(done / total);
  }
  if (fractions.isEmpty) return null;
  return fractions.reduce((a, b) => a + b) / fractions.length;
}

enum StepProgress { goalMet, onPace, behind, noData }

/// "On pace" allows 5% slack so the label doesn't flicker around the line.
StepProgress stepProgress({
  required int steps,
  required int goal,
  required double? usualFraction,
}) {
  if (steps >= goal) return StepProgress.goalMet;
  if (steps == 0 && usualFraction == null) return StepProgress.noData;
  final expected = (usualFraction ?? 0) * goal;
  return steps >= expected * 0.95 ? StepProgress.onPace : StepProgress.behind;
}
