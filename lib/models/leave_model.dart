enum LeaveType {
  casual,
  sick,
  earned,
  unpaid,
}

extension LeaveTypeExtension on LeaveType {
  String get label {
    switch (this) {
      case LeaveType.casual:
        return 'Casual Leave (CL)';
      case LeaveType.sick:
        return 'Sick Leave (SL)';
      case LeaveType.earned:
        return 'Earned / Paid Leave (EL)';
      case LeaveType.unpaid:
        return 'Unpaid / Loss of Pay (LOP)';
    }
  }

  String get code {
    switch (this) {
      case LeaveType.casual:
        return 'casual';
      case LeaveType.sick:
        return 'sick';
      case LeaveType.earned:
        return 'earned';
      case LeaveType.unpaid:
        return 'unpaid';
    }
  }

  static LeaveType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'sick':
        return LeaveType.sick;
      case 'earned':
      case 'paid':
        return LeaveType.earned;
      case 'unpaid':
      case 'lop':
        return LeaveType.unpaid;
      case 'casual':
      default:
        return LeaveType.casual;
    }
  }
}

enum LeaveStatus {
  pending,
  approved,
  rejected,
}

extension LeaveStatusExtension on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending Approval';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  String get code {
    switch (this) {
      case LeaveStatus.pending:
        return 'pending';
      case LeaveStatus.approved:
        return 'approved';
      case LeaveStatus.rejected:
        return 'rejected';
    }
  }

  static LeaveStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'pending':
      default:
        return LeaveStatus.pending;
    }
  }
}

class LeaveRequestModel {
  final String leaveId;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final LeaveStatus status;
  final String? reviewedBy;
  final String? reviewerName;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  LeaveRequestModel({
    required this.leaveId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    this.status = LeaveStatus.pending,
    this.reviewedBy,
    this.reviewerName,
    this.reviewedAt,
    this.rejectionReason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'leaveId': leaveId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'department': department,
      'leaveType': leaveType.code,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDays': totalDays,
      'reason': reason,
      'status': status.code,
      'reviewedBy': reviewedBy,
      'reviewerName': reviewerName,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return LeaveRequestModel(
      leaveId: id ?? map['leaveId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      employeeCode: map['employeeCode'] ?? '',
      department: map['department'] ?? '',
      leaveType: LeaveTypeExtension.fromString(map['leaveType']),
      startDate: DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'].toString()) ?? DateTime.now(),
      totalDays: map['totalDays'] ?? 1,
      reason: map['reason'] ?? '',
      status: LeaveStatusExtension.fromString(map['status']),
      reviewedBy: map['reviewedBy'],
      reviewerName: map['reviewerName'],
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.tryParse(map['reviewedAt'].toString())
          : null,
      rejectionReason: map['rejectionReason'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  LeaveRequestModel copyWith({
    String? leaveId,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? department,
    LeaveType? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    String? reason,
    LeaveStatus? status,
    String? reviewedBy,
    String? reviewerName,
    DateTime? reviewedAt,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return LeaveRequestModel(
      leaveId: leaveId ?? this.leaveId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LeaveBalanceModel {
  final String employeeId;
  final int casualTotal;
  final int casualUsed;
  final int sickTotal;
  final int sickUsed;
  final int earnedTotal;
  final int earnedUsed;

  LeaveBalanceModel({
    required this.employeeId,
    this.casualTotal = 12,
    this.casualUsed = 2,
    this.sickTotal = 8,
    this.sickUsed = 1,
    this.earnedTotal = 15,
    this.earnedUsed = 3,
  });

  int get casualRemaining => casualTotal - casualUsed;
  int get sickRemaining => sickTotal - sickUsed;
  int get earnedRemaining => earnedTotal - earnedUsed;
  int get totalRemaining => casualRemaining + sickRemaining + earnedRemaining;

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'casualTotal': casualTotal,
      'casualUsed': casualUsed,
      'sickTotal': sickTotal,
      'sickUsed': sickUsed,
      'earnedTotal': earnedTotal,
      'earnedUsed': earnedUsed,
    };
  }

  factory LeaveBalanceModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return LeaveBalanceModel(
      employeeId: id ?? map['employeeId'] ?? '',
      casualTotal: map['casualTotal'] ?? 12,
      casualUsed: map['casualUsed'] ?? 0,
      sickTotal: map['sickTotal'] ?? 8,
      sickUsed: map['sickUsed'] ?? 0,
      earnedTotal: map['earnedTotal'] ?? 15,
      earnedUsed: map['earnedUsed'] ?? 0,
    );
  }

  LeaveBalanceModel copyWith({
    String? employeeId,
    int? casualTotal,
    int? casualUsed,
    int? sickTotal,
    int? sickUsed,
    int? earnedTotal,
    int? earnedUsed,
  }) {
    return LeaveBalanceModel(
      employeeId: employeeId ?? this.employeeId,
      casualTotal: casualTotal ?? this.casualTotal,
      casualUsed: casualUsed ?? this.casualUsed,
      sickTotal: sickTotal ?? this.sickTotal,
      sickUsed: sickUsed ?? this.sickUsed,
      earnedTotal: earnedTotal ?? this.earnedTotal,
      earnedUsed: earnedUsed ?? this.earnedUsed,
    );
  }
}
