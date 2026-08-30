class AttendancePolicyModel {
  final String policyId;
  final String officeStartTime; // "09:30"
  final int gracePeriodMinutes; // 15
  final String lateThresholdTime; // "09:45"
  final double minimumWorkingHours; // 8.0
  final int maxBreakMinutes; // 60
  final bool isAutoClockOutEnabled;
  final double officeLatitude; // 28.6139
  final double officeLongitude; // 77.2090
  final double geofenceRadiusMeters; // 300.0
  final String officeName;
  final DateTime updatedAt;

  AttendancePolicyModel({
    this.policyId = 'default_policy',
    this.officeStartTime = '09:30',
    this.gracePeriodMinutes = 15,
    this.lateThresholdTime = '09:45',
    this.minimumWorkingHours = 8.0,
    this.maxBreakMinutes = 60,
    this.isAutoClockOutEnabled = false,
    this.officeLatitude = 28.6139,
    this.officeLongitude = 77.2090,
    this.geofenceRadiusMeters = 300.0,
    this.officeName = 'HQ Enterprise Tech Park (Cyber Tower)',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'policyId': policyId,
      'officeStartTime': officeStartTime,
      'gracePeriodMinutes': gracePeriodMinutes,
      'lateThresholdTime': lateThresholdTime,
      'minimumWorkingHours': minimumWorkingHours,
      'maxBreakMinutes': maxBreakMinutes,
      'isAutoClockOutEnabled': isAutoClockOutEnabled,
      'officeLatitude': officeLatitude,
      'officeLongitude': officeLongitude,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      'officeName': officeName,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AttendancePolicyModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return AttendancePolicyModel(
      policyId: id ?? map['policyId'] ?? 'default_policy',
      officeStartTime: map['officeStartTime'] ?? '09:30',
      gracePeriodMinutes: map['gracePeriodMinutes'] ?? 15,
      lateThresholdTime: map['lateThresholdTime'] ?? '09:45',
      minimumWorkingHours: (map['minimumWorkingHours'] as num?)?.toDouble() ?? 8.0,
      maxBreakMinutes: map['maxBreakMinutes'] ?? 60,
      isAutoClockOutEnabled: map['isAutoClockOutEnabled'] ?? false,
      officeLatitude: (map['officeLatitude'] as num?)?.toDouble() ?? 28.6139,
      officeLongitude: (map['officeLongitude'] as num?)?.toDouble() ?? 77.2090,
      geofenceRadiusMeters: (map['geofenceRadiusMeters'] as num?)?.toDouble() ?? 300.0,
      officeName: map['officeName'] ?? 'HQ Enterprise Tech Park',
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AttendancePolicyModel copyWith({
    String? policyId,
    String? officeStartTime,
    int? gracePeriodMinutes,
    String? lateThresholdTime,
    double? minimumWorkingHours,
    int? maxBreakMinutes,
    bool? isAutoClockOutEnabled,
    double? officeLatitude,
    double? officeLongitude,
    double? geofenceRadiusMeters,
    String? officeName,
    DateTime? updatedAt,
  }) {
    return AttendancePolicyModel(
      policyId: policyId ?? this.policyId,
      officeStartTime: officeStartTime ?? this.officeStartTime,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      lateThresholdTime: lateThresholdTime ?? this.lateThresholdTime,
      minimumWorkingHours: minimumWorkingHours ?? this.minimumWorkingHours,
      maxBreakMinutes: maxBreakMinutes ?? this.maxBreakMinutes,
      isAutoClockOutEnabled: isAutoClockOutEnabled ?? this.isAutoClockOutEnabled,
      officeLatitude: officeLatitude ?? this.officeLatitude,
      officeLongitude: officeLongitude ?? this.officeLongitude,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      officeName: officeName ?? this.officeName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
