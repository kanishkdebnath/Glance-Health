import 'package:health/health.dart';

import 'health_data_source.dart';

/// Findings for one Health Connect record type over the last 30 days.
class TypeFinding {
  const TypeFinding({
    required this.type,
    required this.count,
    required this.sources,
    required this.window,
    this.first,
    this.last,
    this.lastValue,
    this.typicalSpan,
    this.methods = const {},
  });

  final HealthDataType type;
  final int count;

  /// How far back this type was searched.
  final Duration window;

  /// App name → number of records.
  final Map<String, int> sources;
  final DateTime? first;
  final DateTime? last;
  final String? lastValue;

  /// Median length of one record, a hint at granularity.
  final Duration? typicalSpan;
  final Set<String> methods;
}

class DataCheckReport {
  const DataCheckReport({
    required this.at,
    required this.findings,
    required this.stepsTodayAggregate,
    required this.stepsTodayBySource,
    required this.oldestSteps,
  });

  final DateTime at;
  final List<TypeFinding> findings;

  /// Health Connect's de-duplicated total for today.
  final int? stepsTodayAggregate;

  /// Raw sum of today's step records per app. If these add up to more than
  /// the aggregate, more than one app is writing steps.
  final Map<String, int> stepsTodayBySource;
  final DateTime? oldestSteps;

  String toText() {
    String d(DateTime? t) =>
        t == null ? '-' : t.toIso8601String().substring(0, 16);
    final b = StringBuffer()
      ..writeln('Glance Health data check, ${d(at)}')
      ..writeln(
        'Steps today: aggregate ${stepsTodayAggregate ?? '-'}; by source ${stepsTodayBySource.isEmpty ? '-' : stepsTodayBySource}',
      )
      ..writeln('Oldest month with steps (12 month search): ${d(oldestSteps)}')
      ..writeln();
    for (final f in findings) {
      b
        ..writeln(
          '${f.type.name}: ${f.count} records in last ${f.window.inDays == 1 ? '24 hours' : '${f.window.inDays} days'}',
        )
        ..writeln('  sources: ${f.sources.isEmpty ? '-' : f.sources}')
        ..writeln(
          '  range: ${d(f.first)} → ${d(f.last)}; typical record: ${f.typicalSpan?.inMinutes ?? '-'} min',
        )
        ..writeln(
          '  last value: ${f.lastValue ?? '-'}; recording: ${f.methods.isEmpty ? '-' : f.methods.join(', ')}',
        );
    }
    return b.toString();
  }
}

const checkedTypes = [
  HealthDataType.STEPS,
  HealthDataType.SLEEP_SESSION,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_REM,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.HEART_RATE,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.WORKOUT,
  HealthDataType.MENSTRUATION_FLOW,
];

/// Raw samples arrive every few seconds for these; 30 days of them runs
/// the app out of memory, so they are checked over one day.
const _highVolume = {HealthDataType.STEPS, HealthDataType.HEART_RATE};

String _source(HealthDataPoint p) =>
    p.sourceName.isEmpty ? p.sourceId : p.sourceName;

Future<DataCheckReport> runDataCheck({Health? health, DateTime? now}) async {
  final h = health ?? Health();
  await h.configure();
  final at = now ?? DateTime.now();
  final today = dayOf(at);

  final findings = <TypeFinding>[];
  for (final type in checkedTypes) {
    final window = _highVolume.contains(type)
        ? const Duration(days: 1)
        : const Duration(days: 30);
    List<HealthDataPoint> pts;
    try {
      pts = await h.getHealthDataFromTypes(
        types: [type],
        startTime: at.subtract(window),
        endTime: at,
      );
    } catch (_) {
      pts = const [];
    }
    pts.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    final spans = pts.map((p) => p.dateTo.difference(p.dateFrom)).toList()
      ..sort();
    final sources = <String, int>{};
    for (final p in pts) {
      sources.update(_source(p), (n) => n + 1, ifAbsent: () => 1);
    }
    findings.add(
      TypeFinding(
        type: type,
        count: pts.length,
        sources: sources,
        window: window,
        first: pts.firstOrNull?.dateFrom,
        last: pts.lastOrNull?.dateTo,
        lastValue: pts.lastOrNull == null
            ? null
            : '${pts.last.value} ${pts.last.unit.name}',
        typicalSpan: spans.isEmpty ? null : spans[spans.length ~/ 2],
        methods: {for (final p in pts) p.recordingMethod.name},
      ),
    );
  }

  final todaySteps = await h.getHealthDataFromTypes(
    types: [HealthDataType.STEPS],
    startTime: today,
    endTime: at,
  );
  final bySource = <String, int>{};
  for (final p in todaySteps) {
    final n = (p.value as NumericHealthValue).numericValue.round();
    bySource.update(_source(p), (v) => v + n, ifAbsent: () => n);
  }
  // History depth: the earliest month (of the last 12) with any steps,
  // found with the aggregate rather than raw records.
  DateTime? oldest;
  for (var m = 12; m >= 1; m--) {
    final start = DateTime(today.year, today.month - m, 1);
    final total = await h.getTotalStepsInInterval(
      start,
      DateTime(today.year, today.month - m + 1, 1),
    );
    if ((total ?? 0) > 0) {
      oldest = start;
      break;
    }
  }

  return DataCheckReport(
    at: at,
    findings: findings,
    stepsTodayAggregate: await h.getTotalStepsInInterval(today, at),
    stepsTodayBySource: bySource,
    oldestSteps: oldest,
  );
}
