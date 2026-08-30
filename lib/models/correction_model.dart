enum CorrectionStatus {
  pending,
  approved,
  rejected,
}

extension CorrectionStatusExtension on CorrectionStatus {
  String get label {
    switch (this) {
      case CorrectionStatus.pending:
        return 'Pending Review';
      case CorrectionStatus.approved:
        return 'Approved';
      case CorrectionStatus.rejected:
        return 'Rejected';
    }
  }

  String get code {
    switch (this) {
      case CorrectionStatus.pending:
        return 'pending';
      case CorrectionStatus.approved:
        return 'approved';
      case CorrectionStatus.rejected:
        return 'rejected';
    }
  }

  static CorrectionStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'approved':
        return CorrectionStatus.approved;
      case 'rejected':
        return CorrectionStatus.rejected;
      case 'pending':
      default:
        return CorrectionStatus.pending;
    }
  }
}

class AttendanceCorrectionModel {
  final String correctionId;
  final String attendanceId;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String date; // yyyy-MM-dd
  final DateTime requestedClockIn;
  final DateTime requestedClockOut;
  final String reason;
  final CorrectionStatus status;
  final String? reviewedBy;
  final String? reviewerName;
  final DateTime? reviewedAt;
  final String? managerNote;
  final DateTime createdAt;

  AttendanceCorrectionModel({
    required this.correctionId,
    required this.attendanceId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.date,
    required this.requestedClockIn,
    required this.requestedClockOut,
    required this.reason,
    this.status = CorrectionStatus.pending,
    this.reviewedBy,
    this.reviewerName,
    this.reviewedAt,
    this.managerNote,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'correctionId': correctionId,
      'attendanceId': attendanceId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'date': date,
      'requestedClockIn': requestedClockIn.toIso8601String(),
      'requestedClockOut': requestedClockOut.toIso8601String(),
      'reason': reason,
      'status': status.code,
      'reviewedBy': reviewedBy,
      'reviewerName': reviewerName,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'managerNote': managerNote,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AttendanceCorrectionModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return AttendanceCorrectionModel(
      correctionId: id ?? map['correctionId'] ?? '',
      attendanceId: map['attendanceId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      employeeCode: map['employeeCode'] ?? '',
      date: map['date'] ?? '',
      requestedClockIn: DateTime.tryParse(map['requestedClockIn'].toString()) ?? DateTime.now(),
      requestedClockOut: DateTime.tryParse(map['requestedClockOut'].toString()) ?? DateTime.now(),
      reason: map['reason'] ?? '',
      status: CorrectionStatusExtension.fromString(map['status']),
      reviewedBy: map['reviewedBy'],
      reviewerName: map['reviewerName'],
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.tryParse(map['reviewedAt'].toString())
          : null,
      managerNote: map['managerNote'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AttendanceCorrectionModel copyWith({
    String? correctionId,
    String? attendanceId,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? date,
    DateTime? requestedClockIn,
    DateTime? requestedClockOut,
    String? reason,
    CorrectionStatus? status,
    String? reviewedBy,
    String? reviewerName,
    DateTime? reviewedAt,
    String? managerNote,
    DateTime? createdAt,
  }) {
    return AttendanceCorrectionModel(
      correctionId: correctionId ?? this.correctionId,
      attendanceId: attendanceId ?? this.attendanceId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      date: date ?? this.date,
      requestedClockIn: requestedClockIn ?? this.requestedClockIn,
      requestedClockOut: requestedClockOut ?? this.requestedClockOut,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      managerNote: managerNote ?? this.managerNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
