import '../../core/baseline.dart';
import '../../core/pace.dart';

/// The one-sentence summary at the top of Home. Observational only:
/// it describes change against the user's own history and never judges.
String homeHeadline({
  required StepProgress steps,
  BaselineStatus? sleep,
  BaselineStatus? restingHr,
}) {
  final sleepClause = switch (sleep) {
    BaselineStatus.typical => 'You slept about as long as usual',
    BaselineStatus.below => 'You slept less than usual',
    BaselineStatus.above => 'You slept longer than usual',
    BaselineStatus.learning || null => null,
  };
  final stepsClause = switch (steps) {
    StepProgress.goalMet => "you've reached your step goal",
    StepProgress.onPace => "you're on pace for your step goal",
    StepProgress.behind => "you're a little behind your usual pace",
    StepProgress.noData => null,
  };
  final heart = switch (restingHr) {
    BaselineStatus.below => 'Resting heart rate is a little lower than usual.',
    BaselineStatus.above => 'Resting heart rate is a little higher than usual.',
    _ => null,
  };

  final first = switch ((sleepClause, stepsClause)) {
    (final s?, final t?) => '$s and $t.',
    (final s?, null) => '$s.',
    (null, final t?) => '${t[0].toUpperCase()}${t.substring(1)}.',
    (null, null) => null,
  };
  final parts = [?first, ?heart];
  return parts.isEmpty ? "Here's your day so far." : parts.join(' ');
}
