/// The user's goals. Goal history (changes apply from a date forward)
/// arrives with local storage; for now these are the current goals.
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

  int stepsFor(DateTime day) =>
      day.weekday >= DateTime.saturday ? (weekendSteps ?? steps) : steps;
}
