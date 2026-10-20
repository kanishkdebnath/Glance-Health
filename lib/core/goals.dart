/// The user's current goals.
class Goals {
  const Goals({
    this.steps = 8000,
    this.weekendSteps,
    this.sleep = const Duration(hours: 7, minutes: 30),
  });

  final int steps;

  /// Optional Saturday and Sunday goal.
  final int? weekendSteps;
  final Duration sleep;

  /// Limits and step sizes used by the goal sheets.
  static const stepsMin = 1000, stepsMax = 30000, stepsStep = 500;
  static const sleepMin = Duration(hours: 5);
  static const sleepMax = Duration(hours: 11);
  static const sleepStep = Duration(minutes: 15);

  int stepsFor(DateTime day) =>
      day.weekday >= DateTime.saturday ? (weekendSteps ?? steps) : steps;
}
