enum BreakType {
  tea,
  lunch,
  personal,
}

extension BreakTypeExtension on BreakType {
  String get label {
    switch (this) {
      case BreakType.tea:
        return 'Tea / Coffee Break ☕';
      case BreakType.lunch:
        return 'Lunch Break 🍱';
      case BreakType.personal:
        return 'Personal Break 🚶';
    }
  }

  String get code {
    switch (this) {
      case BreakType.tea:
        return 'tea';
      case BreakType.lunch:
        return 'lunch';
      case BreakType.personal:
        return 'personal';
    }
  }

  static BreakType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'lunch':
        return BreakType.lunch;
      case 'personal':
        return BreakType.personal;
      case 'tea':
      default:
        return BreakType.tea;
    }
  }
}

class BreakRecord {
  final String breakId;
  final BreakType type;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;

  BreakRecord({
    required this.breakId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
  });

  bool get isActive => endTime == null;

  int get currentDurationMinutes {
    if (durationMinutes != null) return durationMinutes!;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  String get formattedDuration {
    final mins = currentDurationMinutes;
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    if (hrs > 0) return '${hrs}h ${rem}m';
    return '${rem}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'breakId': breakId,
      'type': type.code,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes ?? currentDurationMinutes,
    };
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    try {
      if (val.runtimeType.toString() == 'Timestamp' || val.toString().startsWith('Timestamp(')) {
        final dynamic ts = val;
        try {
          return ts.toDate() as DateTime;
        } catch (_) {}
      }
    } catch (_) {}
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is double) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
    final str = val.toString().trim();
    if (str.isEmpty) return null;
    if (str.contains('Timestamp(seconds=')) {
      final match = RegExp(r'seconds=(\d+)').firstMatch(str);
      if (match != null) {
        final seconds = int.tryParse(match.group(1) ?? '');
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
    }
    return DateTime.tryParse(str);
  }

  factory BreakRecord.fromMap(Map<String, dynamic> map) {
    return BreakRecord(
      breakId: map['breakId'] ?? '',
      type: BreakTypeExtension.fromString(map['type']),
      startTime: _parseDateTime(map['startTime']) ?? DateTime.now(),
      endTime: _parseDateTime(map['endTime']),
      durationMinutes: map['durationMinutes'],
    );
  }

  BreakRecord copyWith({
    String? breakId,
    BreakType? type,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
  }) {
    return BreakRecord(
      breakId: breakId ?? this.breakId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
