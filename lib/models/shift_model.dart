class ShiftModel {
  final String shiftId;
  final String name;
  final String startTime; // "09:30" or "07:00"
  final String endTime;   // "18:30" or "16:00"
  final int gracePeriodMinutes; // 15
  final bool isNightShift;
  final List<int> workDays; // [1,2,3,4,5]

  const ShiftModel({
    required this.shiftId,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.gracePeriodMinutes = 15,
    this.isNightShift = false,
    this.workDays = const [1, 2, 3, 4, 5],
  });

  String get formattedTiming {
    final startFormatted = _formatTimeStr(startTime);
    final endFormatted = _formatTimeStr(endTime);
    return '$startFormatted - $endFormatted';
  }

  static String _formatTimeStr(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final minStr = min.toString().padLeft(2, '0');
      return '$hour12:$minStr $period';
    } catch (_) {
      return timeStr;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'shiftId': shiftId,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'gracePeriodMinutes': gracePeriodMinutes,
      'isNightShift': isNightShift,
      'workDays': workDays,
    };
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return ShiftModel(
      shiftId: id ?? map['shiftId'] ?? 'shift_general',
      name: map['name'] ?? 'General Shift',
      startTime: map['startTime'] ?? '09:30',
      endTime: map['endTime'] ?? '18:30',
      gracePeriodMinutes: map['gracePeriodMinutes'] ?? 15,
      isNightShift: map['isNightShift'] ?? false,
      workDays: List<int>.from(map['workDays'] ?? [1, 2, 3, 4, 5]),
    );
  }

  // Pre-configured Company Standard Shifts
  static const ShiftModel generalShift = ShiftModel(
    shiftId: 'shift_general',
    name: 'General Shift',
    startTime: '09:30',
    endTime: '18:30',
    gracePeriodMinutes: 15,
  );

  static const ShiftModel morningShift = ShiftModel(
    shiftId: 'shift_morning',
    name: 'Morning Shift',
    startTime: '07:00',
    endTime: '16:00',
    gracePeriodMinutes: 15,
  );

  static List<ShiftModel> get defaultShifts => [generalShift, morningShift];
}
