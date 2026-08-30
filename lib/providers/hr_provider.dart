import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/report_model.dart';
import '../models/leave_model.dart';
import '../services/firestore_service.dart';
import '../services/report_service.dart';

class HrProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _users = [];
  List<AttendanceModel> _allAttendance = [];
  List<LeaveRequestModel> _allLeaves = [];
  List<MonthlyAttendanceReport> _cachedReports = [];

  bool _isGeneratingReport = false;
  String _selectedDepartmentFilter = 'All';
  String _searchQuery = '';
  String _selectedReportPeriod = '30-Day'; // 'Daily', 'Weekly', 'Monthly', '30-Day'

  HrProvider() {
    _init();
  }

  void _init() {
    _users = _firestoreService.getAllUsers();
    _allAttendance = _firestoreService.getAllAttendance();
    _allLeaves = _firestoreService.getAllLeaves();

    _firestoreService.usersStream.listen((users) {
      _users = users;
      notifyListeners();
    });

    _firestoreService.attendanceStream.listen((records) {
      _allAttendance = records;
      _cachedReports.clear();
      notifyListeners();
    });

    _firestoreService.leavesStream.listen((leaves) {
      _allLeaves = leaves;
      notifyListeners();
    });
  }

  bool get isGeneratingReport => _isGeneratingReport;
  String get selectedDepartmentFilter => _selectedDepartmentFilter;
  String get searchQuery => _searchQuery;
  String get selectedReportPeriod => _selectedReportPeriod;

  void setDepartmentFilter(String dept) {
    _selectedDepartmentFilter = dept;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setReportPeriod(String period) {
    _selectedReportPeriod = period;
    notifyListeners();
  }

  List<UserModel> get filteredEmployees {
    final employees = _users.where((u) => u.role == UserRole.employee).toList();
    return employees.where((e) {
      final matchesDept = _selectedDepartmentFilter == 'All' ||
          e.department.toLowerCase() == _selectedDepartmentFilter.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.employeeId.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDept && matchesSearch;
    }).toList();
  }

  // Company Overview KPIs
  int get totalEmployeesCount => _users.where((u) => u.role == UserRole.employee).length;

  int get presentTodayCount {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _allAttendance.where((a) =>
        a.date == todayStr &&
        (a.status == AttendanceStatus.approved || a.status == AttendanceStatus.completed)).length;
  }

  int get pendingApprovalsCount {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _allAttendance.where((a) => a.date == todayStr && a.status == AttendanceStatus.pending).length;
  }

  int get lateTodayCount {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _allAttendance.where((a) => a.date == todayStr && a.timingStatus == TimingStatus.lateArrival).length;
  }

  int get onLeaveTodayCount {
    final now = DateTime.now();
    return _allLeaves.where((l) =>
        l.status == LeaveStatus.approved &&
        !now.isBefore(l.startDate) &&
        !now.isAfter(l.endDate.add(const Duration(days: 1)))).length;
  }

  int get absentTodayCount {
    final diff = totalEmployeesCount - presentTodayCount - pendingApprovalsCount - onLeaveTodayCount;
    return diff < 0 ? 0 : diff;
  }

  double get companyAttendanceRate {
    if (totalEmployeesCount == 0) return 0.0;
    return (presentTodayCount / totalEmployeesCount * 100).clamp(0.0, 100.0);
  }

  // Generate Reports
  List<MonthlyAttendanceReport> generateAll30DayReports() {
    final employees = filteredEmployees;
    final List<MonthlyAttendanceReport> reports = [];

    for (final emp in employees) {
      final empAttendance = _allAttendance.where((a) => a.employeeId == emp.userId).toList();
      final rep = ReportService.calculate30DayReport(
        employee: emp,
        attendanceList: empAttendance,
      );
      reports.add(rep);
    }

    _cachedReports = reports;
    return reports;
  }

  Future<void> exportAndPrintPdfReport(BuildContext context) async {
    _isGeneratingReport = true;
    notifyListeners();

    final reports = generateAll30DayReports();
    final pdfBytes = await ReportService.generatePdfReport(
      reports: reports,
      title: 'Company-Wide $_selectedReportPeriod Attendance & Payroll Audit',
    );

    _isGeneratingReport = false;
    notifyListeners();

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Attendance_${_selectedReportPeriod}_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  String getCsvExportContent() {
    final reports = generateAll30DayReports();
    return ReportService.generateCsvReport(reports);
  }

  // Excel (TSV / XML format compatible with MS Excel)
  String getExcelExportContent() {
    final reports = generateAll30DayReports();
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Employee\tEmployee Code\tDepartment\tWorking Days\tPresent\tAbsent\tPending\tRate %\tTotal Hours\tAvg Daily Hours\tLate Arrivals');

    for (final r in reports) {
      buffer.writeln('${r.employeeName}\t${r.employeeCode}\t${r.department}\t${r.totalWorkingDays}\t${r.presentDays}\t${r.absentDays}\t${r.pendingDays}\t${r.attendancePercentage}%\t${r.totalHoursWorked}\t${r.averageDailyHours}\t${r.lateArrivals}');
    }
    return buffer.toString();
  }

  Future<void> sendReportEmail({required String emailAddress}) async {
    _isGeneratingReport = true;
    notifyListeners();

    final reports = generateAll30DayReports();
    final summary = 'Generated ${reports.length} employee records with average ${companyAttendanceRate.toStringAsFixed(1)}% attendance. Total on leave: $onLeaveTodayCount, Late arrivals: $lateTodayCount.';

    await ReportService.triggerAutomatedEmail(
      recipients: [emailAddress],
      subject: '$_selectedReportPeriod Attendance Report (${DateFormat('MMMM yyyy').format(DateTime.now())})',
      reportSummary: summary,
    );

    _isGeneratingReport = false;
    notifyListeners();
  }
}
