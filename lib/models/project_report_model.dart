class ProjectReportModel {
  final String reportId;
  final String employeeId;
  final String employeeName;
  final String? employeeAvatar;
  final String projectId;
  final String projectName;
  final String date; // YYYY-MM-DD
  final DateTime submittedAt;
  final String workSummary;
  final double hoursSpent;
  final String? blockers;
  final List<String> screenshotUrls;
  final List<String> videoUrls;
  final String status; // 'submitted', 'approved', 'reviewed'

  ProjectReportModel({
    required this.reportId,
    required this.employeeId,
    required this.employeeName,
    this.employeeAvatar,
    required this.projectId,
    required this.projectName,
    required this.date,
    required this.submittedAt,
    required this.workSummary,
    required this.hoursSpent,
    this.blockers,
    required this.screenshotUrls,
    required this.videoUrls,
    this.status = 'submitted',
  });

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeAvatar': employeeAvatar,
      'projectId': projectId,
      'projectName': projectName,
      'date': date,
      'submittedAt': submittedAt.toIso8601String(),
      'workSummary': workSummary,
      'hoursSpent': hoursSpent,
      'blockers': blockers,
      'screenshotUrls': screenshotUrls,
      'videoUrls': videoUrls,
      'status': status,
    };
  }

  factory ProjectReportModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return ProjectReportModel(
      reportId: id ?? map['reportId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      employeeAvatar: map['employeeAvatar'],
      projectId: map['projectId'] ?? '',
      projectName: map['projectName'] ?? 'General Project',
      date: map['date'] ?? '',
      submittedAt: map['submittedAt'] != null
          ? (map['submittedAt'] is DateTime
              ? map['submittedAt']
              : (map['submittedAt'].runtimeType.toString().contains('Timestamp') ||
                      map['submittedAt'].toString().startsWith('Timestamp'))
                  ? (map['submittedAt'] as dynamic).toDate()
                  : DateTime.tryParse(map['submittedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      workSummary: map['workSummary'] ?? '',
      hoursSpent: (map['hoursSpent'] is num) ? (map['hoursSpent'] as num).toDouble() : 0.0,
      blockers: map['blockers'],
      screenshotUrls: List<String>.from(map['screenshotUrls'] ?? []),
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      status: map['status'] ?? 'submitted',
    );
  }

  ProjectReportModel copyWith({
    String? reportId,
    String? employeeId,
    String? employeeName,
    String? employeeAvatar,
    String? projectId,
    String? projectName,
    String? date,
    DateTime? submittedAt,
    String? workSummary,
    double? hoursSpent,
    String? blockers,
    List<String>? screenshotUrls,
    List<String>? videoUrls,
    String? status,
  }) {
    return ProjectReportModel(
      reportId: reportId ?? this.reportId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeAvatar: employeeAvatar ?? this.employeeAvatar,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      date: date ?? this.date,
      submittedAt: submittedAt ?? this.submittedAt,
      workSummary: workSummary ?? this.workSummary,
      hoursSpent: hoursSpent ?? this.hoursSpent,
      blockers: blockers ?? this.blockers,
      screenshotUrls: screenshotUrls ?? this.screenshotUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      status: status ?? this.status,
    );
  }
}
