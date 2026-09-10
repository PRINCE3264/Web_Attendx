import 'break_model.dart';

enum AttendanceStatus {
  pending,
  approved,
  rejected,
  completed,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.pending:
        return 'Pending Approval';
      case AttendanceStatus.approved:
        return 'Approved (Shift Active)';
      case AttendanceStatus.rejected:
        return 'Rejected';
      case AttendanceStatus.completed:
        return 'Completed';
    }
  }

  String get code {
    switch (this) {
      case AttendanceStatus.pending:
        return 'pending';
      case AttendanceStatus.approved:
        return 'approved';
      case AttendanceStatus.rejected:
        return 'rejected';
      case AttendanceStatus.completed:
        return 'completed';
    }
  }

  static AttendanceStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'approved':
        return AttendanceStatus.approved;
      case 'rejected':
        return AttendanceStatus.rejected;
      case 'completed':
        return AttendanceStatus.completed;
      case 'pending':
      default:
        return AttendanceStatus.pending;
    }
  }
}

enum TimingStatus {
  onTime,
  gracePeriod,
  lateArrival,
  earlyDeparture,
}

extension TimingStatusExtension on TimingStatus {
  String get label {
    switch (this) {
      case TimingStatus.onTime:
        return 'On Time 🟢';
      case TimingStatus.gracePeriod:
        return 'Within Grace 🟡';
      case TimingStatus.lateArrival:
        return 'Late Arrival 🔴';
      case TimingStatus.earlyDeparture:
        return 'Early Departure ⚠️';
    }
  }

  String get code {
    switch (this) {
      case TimingStatus.onTime:
        return 'on_time';
      case TimingStatus.gracePeriod:
        return 'grace_period';
      case TimingStatus.lateArrival:
        return 'late';
      case TimingStatus.earlyDeparture:
        return 'early_departure';
    }
  }

  static TimingStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'late':
        return TimingStatus.lateArrival;
      case 'grace_period':
        return TimingStatus.gracePeriod;
      case 'early_departure':
        return TimingStatus.earlyDeparture;
      case 'on_time':
      default:
        return TimingStatus.onTime;
    }
  }
}

class AttendanceModel {
  final String attendanceId;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? employeeAvatar;
  final String teamId;
  final String teamName;
  final String date; // yyyy-MM-dd
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String? clockInPhotoUrl;
  final String? clockOutPhotoUrl;
  final AttendanceStatus status;
  final TimingStatus timingStatus;
  final int lateMinutes;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? managerComment;
  final int? totalWorkMinutes;
  final int totalBreakMinutes;
  final List<BreakRecord> breaks;
  final double? latitude;
  final double? longitude;
  final bool isWithinGeofence;
  final double distanceFromOfficeMeters;
  final bool isMissingClockOut;
  final DateTime createdAt;
  final String? location;

  AttendanceModel({
    required this.attendanceId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.employeeAvatar,
    required this.teamId,
    this.teamName = 'General',
    required this.date,
    this.clockInTime,
    this.clockOutTime,
    this.clockInPhotoUrl,
    this.clockOutPhotoUrl,
    this.status = AttendanceStatus.pending,
    this.timingStatus = TimingStatus.onTime,
    this.lateMinutes = 0,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.managerComment,
    this.totalWorkMinutes,
    this.totalBreakMinutes = 0,
    this.breaks = const [],
    this.latitude,
    this.longitude,
    this.isWithinGeofence = true,
    this.distanceFromOfficeMeters = 0.0,
    this.isMissingClockOut = false,
    DateTime? createdAt,
    this.location,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isLate => timingStatus == TimingStatus.lateArrival;
  bool get isGracePeriod => timingStatus == TimingStatus.gracePeriod;
  bool get isOnTime => timingStatus == TimingStatus.onTime;

  String get lateDisplayLabel {
    if (isLate) return 'LATE - PENDING APPROVAL (${lateMinutes.toHoursAndMinutes} late)';
    if (isGracePeriod) return 'GRACE PERIOD - PENDING';
    return 'ON TIME - PENDING';
  }

  Duration? get grossDuration {
    if (clockInTime == null) return null;
    final end = clockOutTime ?? DateTime.now();
    return end.difference(clockInTime!);
  }

  // Net productive working duration deducting breaks
  Duration? get netWorkingDuration {
    final gross = grossDuration;
    if (gross == null) return null;
    final netMins = gross.inMinutes - totalBreakMinutes;
    return Duration(minutes: netMins < 0 ? 0 : netMins);
  }

  String get formattedGrossDuration {
    final dur = grossDuration;
    if (dur == null) return '0h 0m';
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String get formattedNetDuration {
    final dur = netWorkingDuration;
    if (dur == null) return '0h 0m';
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  BreakRecord? get activeBreak {
    try {
      return breaks.firstWhere((b) => b.isActive);
    } catch (_) {
      return null;
    }
  }

  bool get isOnBreak => activeBreak != null;

  String get uid => employeeId;

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'uid': employeeId,
      'attendanceDate': date,
      'date': date,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'employeeAvatar': employeeAvatar,
      'teamId': teamId,
      'teamName': teamName,
      'clockIn': clockInTime?.toIso8601String(),
      'clockOut': clockOutTime?.toIso8601String(),
      'clockInTime': clockInTime?.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
      'clockInPhotoUrl': clockInPhotoUrl,
      'clockOutPhotoUrl': clockOutPhotoUrl,
      'status': status.code,
      'attendanceType': timingStatus.code,
      'timingStatus': timingStatus.code,
      'lateMinutes': lateMinutes,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'managerComment': managerComment,
      'totalWorkMinutes': totalWorkMinutes ?? grossDuration?.inMinutes,
      'totalBreakMinutes': totalBreakMinutes,
      'breaks': breaks.map((b) => b.toMap()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'clockInLocation': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'isWithinGeofence': isWithinGeofence,
      'distanceFromOfficeMeters': distanceFromOfficeMeters,
      'isMissingClockOut': isMissingClockOut,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'location': location,
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

  factory AttendanceModel.fromMap(Map<String, dynamic> map, [String? id]) {
    final rawBreaks = map['breaks'] as List<dynamic>?;
    final List<BreakRecord> parsedBreaks = rawBreaks != null
        ? rawBreaks.map((b) => BreakRecord.fromMap(Map<String, dynamic>.from(b))).toList()
        : [];

    double? parsedLat = (map['latitude'] as num?)?.toDouble();
    double? parsedLng = (map['longitude'] as num?)?.toDouble();
    if (parsedLat == null && map['clockInLocation'] is Map) {
      parsedLat = (map['clockInLocation']['latitude'] as num?)?.toDouble();
      parsedLng = (map['clockInLocation']['longitude'] as num?)?.toDouble();
    }

    final rawTiming = map['timingStatus'] ?? map['attendanceType'];

    final rawClockIn = map['clockInTime'] ?? map['clockIn'];
    final rawClockOut = map['clockOutTime'] ?? map['clockOut'];

    return AttendanceModel(
      attendanceId: id ?? map['attendanceId'] ?? '',
      employeeId: map['uid'] ?? map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? 'Employee',
      employeeCode: map['employeeCode'] ?? 'EMP-0000',
      employeeAvatar: map['employeeAvatar'],
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? 'General',
      date: map['date'] ?? map['attendanceDate'] ?? '',
      clockInTime: _parseDateTime(rawClockIn),
      clockOutTime: _parseDateTime(rawClockOut),
      clockInPhotoUrl: map['clockInPhotoUrl'],
      clockOutPhotoUrl: map['clockOutPhotoUrl'],
      status: AttendanceStatusExtension.fromString(map['status']),
      timingStatus: TimingStatusExtension.fromString(rawTiming),
      lateMinutes: (map['lateMinutes'] as num?)?.toInt() ?? 0,
      approvedBy: map['approvedBy'],
      approvedByName: map['approvedByName'],
      approvedAt: _parseDateTime(map['approvedAt']),
      rejectionReason: map['rejectionReason'],
      managerComment: map['managerComment'],
      totalWorkMinutes: map['totalWorkMinutes'] is int
          ? map['totalWorkMinutes']
          : (map['totalWorkMinutes'] != null
              ? int.tryParse(map['totalWorkMinutes'].toString())
              : null),
      totalBreakMinutes: map['totalBreakMinutes'] ?? 0,
      breaks: parsedBreaks,
      latitude: parsedLat,
      longitude: parsedLng,
      isWithinGeofence: map['isWithinGeofence'] ?? true,
      distanceFromOfficeMeters: (map['distanceFromOfficeMeters'] as num?)?.toDouble() ?? 0.0,
      isMissingClockOut: map['isMissingClockOut'] ?? false,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      location: map['location'],
    );
  }

  AttendanceModel copyWith({
    String? attendanceId,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? employeeAvatar,
    String? teamId,
    String? teamName,
    String? date,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    String? clockInPhotoUrl,
    String? clockOutPhotoUrl,
    AttendanceStatus? status,
    TimingStatus? timingStatus,
    int? lateMinutes,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    String? managerComment,
    int? totalWorkMinutes,
    int? totalBreakMinutes,
    List<BreakRecord>? breaks,
    double? latitude,
    double? longitude,
    bool? isWithinGeofence,
    double? distanceFromOfficeMeters,
    bool? isMissingClockOut,
    DateTime? createdAt,
    String? location,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId ?? this.attendanceId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeAvatar: employeeAvatar ?? this.employeeAvatar,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      date: date ?? this.date,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      clockInPhotoUrl: clockInPhotoUrl ?? this.clockInPhotoUrl,
      clockOutPhotoUrl: clockOutPhotoUrl ?? this.clockOutPhotoUrl,
      status: status ?? this.status,
      timingStatus: timingStatus ?? this.timingStatus,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      managerComment: managerComment ?? this.managerComment,
      totalWorkMinutes: totalWorkMinutes ?? this.totalWorkMinutes,
      totalBreakMinutes: totalBreakMinutes ?? this.totalBreakMinutes,
      breaks: breaks ?? this.breaks,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      distanceFromOfficeMeters: distanceFromOfficeMeters ?? this.distanceFromOfficeMeters,
      isMissingClockOut: isMissingClockOut ?? this.isMissingClockOut,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension IntTimeExtension on int {
  String get toHoursAndMinutes {
    if (this < 60) return '$this min';
    final int hours = this ~/ 60;
    final int mins = this % 60;
    if (mins == 0) return '$hours hour${hours > 1 ? 's' : ''}';
    return '$hours hour${hours > 1 ? 's' : ''} $mins min';
  }

  String get toHoursAndMinutesCompact {
    if (this < 60) return '${this}m';
    final int hours = this ~/ 60;
    final int mins = this % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}
