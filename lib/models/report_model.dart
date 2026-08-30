class MonthlyAttendanceReport {
  final String reportId;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final int pendingDays;
  final int rejectedDays;
  final double attendancePercentage;
  final double totalHoursWorked;
  final double averageDailyHours;
  final int lateArrivals;
  final DateTime generatedAt;

  MonthlyAttendanceReport({
    required this.reportId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.periodStart,
    required this.periodEnd,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    this.pendingDays = 0,
    this.rejectedDays = 0,
    required this.attendancePercentage,
    required this.totalHoursWorked,
    required this.averageDailyHours,
    this.lateArrivals = 0,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'department': department,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalWorkingDays': totalWorkingDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'pendingDays': pendingDays,
      'rejectedDays': rejectedDays,
      'attendancePercentage': attendancePercentage,
      'totalHoursWorked': totalHoursWorked,
      'averageDailyHours': averageDailyHours,
      'lateArrivals': lateArrivals,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory MonthlyAttendanceReport.fromMap(Map<String, dynamic> map, [String? id]) {
    return MonthlyAttendanceReport(
      reportId: id ?? map['reportId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      employeeCode: map['employeeCode'] ?? '',
      department: map['department'] ?? '',
      periodStart: DateTime.tryParse(map['periodStart'].toString()) ?? DateTime.now(),
      periodEnd: DateTime.tryParse(map['periodEnd'].toString()) ?? DateTime.now(),
      totalWorkingDays: map['totalWorkingDays'] ?? 30,
      presentDays: map['presentDays'] ?? 0,
      absentDays: map['absentDays'] ?? 0,
      pendingDays: map['pendingDays'] ?? 0,
      rejectedDays: map['rejectedDays'] ?? 0,
      attendancePercentage: (map['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      totalHoursWorked: (map['totalHoursWorked'] as num?)?.toDouble() ?? 0.0,
      averageDailyHours: (map['averageDailyHours'] as num?)?.toDouble() ?? 0.0,
      lateArrivals: map['lateArrivals'] ?? 0,
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
