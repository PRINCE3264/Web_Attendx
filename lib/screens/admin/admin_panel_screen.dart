import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/department_model.dart';
import '../../models/team_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../../providers/leave_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/firestore_seeder_service.dart';
import '../../services/report_service.dart';
import '../shared/custom_widgets.dart';
import '../manager/leave_approval_screen.dart';
import '../hr/create_announcement_sheet.dart';
import '../shared/project_reports_screen.dart';
import 'departments_management_screen.dart';
import 'teams_management_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  final String initialRoleFilter; // 'All', 'Employee', 'TL', 'HR', 'Admin'

  const AdminPanelScreen({
    super.key,
    this.initialRoleFilter = 'All',
  });

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late String _selectedRoleFilter;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Password@123');
  final _empCodeController = TextEditingController();
  final _deptController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _newRole = UserRole.employee;

  @override
  void initState() {
    super.initState();
    _selectedRoleFilter = widget.initialRoleFilter;
  }

  @override
  void didUpdateWidget(covariant AdminPanelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRoleFilter != widget.initialRoleFilter) {
      setState(() {
        _selectedRoleFilter = widget.initialRoleFilter;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _empCodeController.dispose();
    _deptController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showFirebaseSyncDialog() {
    bool isSyncing = false;
    String statusMessage = 'Click "Start Sync" to seed & sync all 17 Firestore collections directly with Firebase.';
    bool isPermissionError = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.cloud_sync, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Firebase Cloud Sync', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: isPermissionError ? Colors.red.shade800 : Colors.black87,
                    fontWeight: isPermissionError ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSyncing) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
                if (isPermissionError) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💡 How to Fix Permission Denied:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '1. Open Firebase Console ➔ attendx-8b4c5\n'
                          '2. Go to "Firestore Database" ➔ "Rules" tab\n'
                          '3. Set rule: allow read, write: if true;\n'
                          '4. Click "Publish", then tap "Start Sync" below.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D), height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            const rulesText = '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}''';
                            Clipboard.setData(const ClipboardData(text: rulesText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📋 Firestore Rules copied! Paste in Firebase Console > Rules tab.'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('COPY FIRESTORE RULES', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade900,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSyncing ? null : () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: isSyncing
                  ? null
                  : () async {
                      setDialogState(() {
                        isSyncing = true;
                        isPermissionError = false;
                        statusMessage = 'Connecting to Firebase & verifying credentials...';
                      });
                      try {
                        await FirestoreSeederService().seedAll17Collections(
                          onProgress: (status) {
                            setDialogState(() {
                              statusMessage = status;
                            });
                          },
                        );
                        setDialogState(() {
                          isSyncing = false;
                          isPermissionError = false;
                          statusMessage = '✅ All 17 collections synced to Firebase Cloud successfully!';
                        });
                      } catch (e) {
                        final err = e.toString();
                        setDialogState(() {
                          isSyncing = false;
                          isPermissionError = err.contains('permission-denied') || err.contains('permission');
                          statusMessage = 'Sync Error: $err';
                        });
                      }
                    },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Start Sync'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCredentialsDialog({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String employeeId,
    required UserRole role,
    String? managerName,
    String? department,
    DateTime? joiningDate,
    String? phoneNumber,
  }) {
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.cardDark : Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employee Enrolled! 🎉',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Account created successfully',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Share these login credentials with the employee so they can log in and start work immediately.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMutedLight, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCredentialRow(Icons.person_rounded, 'NAME', name),
                          Divider(height: 14, color: AppTheme.primary.withValues(alpha: 0.12)),
                          _buildCredentialRow(Icons.badge_rounded, 'EMPLOYEE ID', employeeId),
                          Divider(height: 14, color: AppTheme.primary.withValues(alpha: 0.12)),
                          _buildCredentialRow(Icons.email_rounded, 'LOGIN EMAIL', email),
                          Divider(height: 14, color: AppTheme.primary.withValues(alpha: 0.12)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.key_rounded, size: 13, color: AppTheme.primary),
                                        const SizedBox(width: 5),
                                        Text(
                                          'LOGIN PASSWORD',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      obscurePassword ? '••••••••' : password,
                                      style: GoogleFonts.firaCode(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 19,
                                  color: AppTheme.primary,
                                ),
                                onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                              ),
                            ],
                          ),
                          if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
                            Divider(height: 14, color: AppTheme.primary.withValues(alpha: 0.12)),
                            _buildCredentialRow(Icons.phone_rounded, 'PHONE NUMBER', phoneNumber),
                          ],
                          if (joiningDate != null) ...[
                            Divider(height: 14, color: AppTheme.primary.withValues(alpha: 0.12)),
                            _buildCredentialRow(
                              Icons.event_rounded,
                              'JOINING DATE & TIME',
                              DateFormat('dd MMM yyyy, hh:mm a').format(joiningDate),
                            ),
                          ],
                          Divider(height: 14, color: AppTheme.primary.withValues(alpha: 0.12)),
                          _buildCredentialRow(Icons.work_rounded, 'ROLE & DEPT', '${role.name.toUpperCase()} • ${department ?? "General"}'),
                          if (managerName != null) ...[
                            Divider(height: 14, color: AppTheme.primary.withValues(alpha: 0.12)),
                            _buildCredentialRow(Icons.supervisor_account_rounded, 'ASSIGNED TL', managerName),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        final text = '''
🌟 AttendX Login Credentials 🌟
Name: $name
Employee ID: $employeeId
Role: ${role.name}
Department: ${department ?? 'General'}
${phoneNumber != null && phoneNumber.isNotEmpty ? 'Phone: $phoneNumber\n' : ''}${joiningDate != null ? 'Joining Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(joiningDate)}\n' : ''}
📧 Login Email: $email
🔑 Password: $password

Use this Email and Password to log into AttendX and start your shifts & attendance.
''';
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📋 Credentials copied to clipboard! Share with employee.'),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 17, color: Colors.white),
                      label: Text(
                        'COPY LOGIN CREDENTIALS',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: 0.5, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(IconData icon, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMainLight,
          ),
        ),
      ],
    );
  }

  void _openAddEmployeeModal() {
    final adminProv = context.read<AdminProvider>();
    final tls = adminProv.users.where((u) => u.role == UserRole.manager).toList();
    UserModel? selectedTL = tls.isNotEmpty ? tls.first : null;
    String? selectedProject;
    bool obscurePass = true;
    bool isSaving = false;
    DateTime joiningDateTime = DateTime.now();
    String? formError;
    final formKey = GlobalKey<FormState>();

    // Pre-fill suggested employee ID and password
    if (_empCodeController.text.trim().isEmpty) {
      _empCodeController.text = 'EMP-${1050 + adminProv.users.length}';
    }
    if (_passwordController.text.trim().isEmpty) {
      _passwordController.text = 'Pass@${DateTime.now().year}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Enroll New Employee',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text(
                    'Create employee profile and set Login Email & Password for workspace access.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (formError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(formError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _empCodeController,
                          decoration: const InputDecoration(labelText: 'Employee ID *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _deptController,
                          decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Login Email Address *', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: modalCtx,
                        initialDate: joiningDateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null && modalCtx.mounted) {
                        final pickedTime = await showTimePicker(
                          context: modalCtx,
                          initialTime: TimeOfDay.fromDateTime(joiningDateTime),
                        );
                        setModalState(() {
                          joiningDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime?.hour ?? joiningDateTime.hour,
                            pickedTime?.minute ?? joiningDateTime.minute,
                          );
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Joining Date & Time *',
                        prefixIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(joiningDateTime),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Login Password *',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shuffle, size: 18, color: AppTheme.primary),
                            tooltip: 'Generate random password',
                            onPressed: () {
                              final randPass = 'Emp@${DateTime.now().millisecondsSinceEpoch % 10000}!';
                              _passwordController.text = randPass;
                              setModalState(() {});
                            },
                          ),
                          IconButton(
                            icon: Icon(obscurePass ? Icons.visibility : Icons.visibility_off, size: 18),
                            onPressed: () => setModalState(() => obscurePass = !obscurePass),
                          ),
                        ],
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().length < 6) ? 'Password must be at least 6 chars' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: _newRole,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase(), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => _newRole = val);
                    },
                  ),
                  if (_newRole == UserRole.employee && tls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserModel>(
                      initialValue: selectedTL,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assigned TL / Manager',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      hint: const Text('Select TL'),
                      items: tls.map((t) => DropdownMenuItem(value: t, child: Text(t.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedTL = val);
                      },
                    ),
                  ],
                  if (_newRole == UserRole.employee || _newRole == UserRole.manager) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProject,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Project',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder_special_outlined),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      hint: const Text('Select Project'),
                      items: context.watch<HrProvider>().projectsList.map((proj) => DropdownMenuItem(
                        value: proj,
                        child: Text(proj, maxLines: 1, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedProject = val),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            setModalState(() {
                              isSaving = true;
                              formError = null;
                            });

                            final auth = context.read<AuthProvider>();
                            final name = _nameController.text.trim();
                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();
                            final empId = _empCodeController.text.trim();
                            final dept = _deptController.text.trim().isEmpty ? 'Engineering' : _deptController.text.trim();
                            final phone = _phoneController.text.trim();

                            final success = await auth.adminCreateEmployeeAccount(
                              name: name,
                              email: email,
                              password: password,
                              role: _newRole,
                              employeeId: empId,
                              department: dept,
                              teamId: selectedTL?.teamId ?? 'team_general',
                              teamName: selectedTL?.teamName ?? 'General Team',
                              managerId: _newRole == UserRole.employee ? selectedTL?.userId : null,
                              managerName: _newRole == UserRole.employee ? selectedTL?.name : null,
                              joiningDate: joiningDateTime,
                              phoneNumber: phone,
                            );

                            if (success && mounted) {
                              if (selectedProject != null && selectedProject!.isNotEmpty) {
                                final hrProv = context.read<HrProvider>();
                                final allUsers = adminProv.users;
                                try {
                                  final createdUser = allUsers.firstWhere(
                                    (u) => u.email.toLowerCase() == email.toLowerCase(),
                                    orElse: () => allUsers.last,
                                  );
                                  await hrProv.assignProjectToEmployee(createdUser.userId, selectedProject!);
                                } catch (_) {}
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _nameController.clear();
                              _emailController.clear();
                              _empCodeController.clear();
                              _deptController.clear();
                              _passwordController.clear();
                              _phoneController.clear();

                              if (mounted) {
                                _showCredentialsDialog(
                                  context: context,
                                  name: name,
                                  email: email,
                                  password: password,
                                  employeeId: empId,
                                  role: _newRole,
                                  managerName: selectedTL?.name,
                                  department: dept,
                                  joiningDate: joiningDateTime,
                                  phoneNumber: phone.isNotEmpty ? phone : null,
                                );
                              }
                            } else {
                              setModalState(() {
                                isSaving = false;
                                formError = auth.errorMessage ?? 'Failed to enroll employee.';
                              });
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.person_add, size: 18),
                    label: Text(isSaving ? 'Enrolling...' : 'ENROLL & GENERATE CREDENTIALS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  void _openAssignTLModal(UserModel employee) {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final adminProv = context.read<AdminProvider>();
    final tls = adminProv.users.where((u) => u.role == UserRole.manager).toList();

    UserModel? selectedTL;
    if (employee.managerId != null && employee.managerId != 'unassigned') {
      try {
        selectedTL = tls.firstWhere((m) => m.userId == employee.managerId);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assignment_ind_rounded, color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign Team Lead (TL)',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'Assign ${employee.name} (${employee.employeeId}) to a manager.',
                              style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (tls.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No Team Leads / Managers available.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'SELECT MANAGER / TL:',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: tls.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final m = tls[index];
                          final isSelected = selectedTL?.userId == m.userId;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedTL = m;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.12)
                                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isSelected ? AppTheme.primary : Colors.grey.shade400,
                                    child: Text(
                                      m.name.isNotEmpty ? m.name[0].toUpperCase() : 'M',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.name,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isSelected ? AppTheme.primary : (isDark ? Colors.white : Colors.black87),
                                          ),
                                        ),
                                        Text(
                                          '${m.department} • ${m.employeeId}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isSelected ? AppTheme.primary : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: selectedTL == null
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            final adminProv = context.read<AdminProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await adminProv.assignEmployeeToTL(
                              employeeId: employee.userId,
                              tlUser: selectedTL!,
                              admin: currentUser,
                            );

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? '✅ ${employee.name} assigned to TL ${selectedTL!.name}!'
                                        : '❌ Failed to assign TL.',
                                  ),
                                  backgroundColor: success ? AppTheme.success : AppTheme.danger,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Confirm TL Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignProjectSheet(BuildContext context, UserModel employee) {
    final hrProv = context.read<HrProvider>();
    final projects = hrProv.projectsList;
    String? selectedProject = employee.assignedProjectName;
    if (selectedProject == null || !projects.contains(selectedProject)) {
      selectedProject = projects.isNotEmpty ? projects.first : null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.folder_special_rounded, color: AppTheme.accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign Active Project',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'Assign ${employee.name} (${employee.employeeId}) to a project.',
                              style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (projects.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No projects available in workspace.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'SELECT PROJECT:',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accent, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: projects.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final proj = projects[index];
                          final isSelected = selectedProject == proj;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedProject = proj;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accent.withValues(alpha: 0.12)
                                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.accent : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.accent : Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.folder_rounded, size: 14, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      proj,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isSelected ? AppTheme.accent : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isSelected ? AppTheme.accent : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: selectedProject == null
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            final hrProv = context.read<HrProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            await hrProv.assignProjectToEmployee(
                              employee.userId,
                              selectedProject!,
                            );

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('✅ ${employee.name} assigned to "$selectedProject"!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Confirm Project Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    UserModel emp,
    dynamic report,
    UserModel? currentUser,
    AdminProvider adminProv,
    bool isDark,
  ) {
    final isActive = emp.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppTheme.cardDark : Colors.white)
            : (isDark ? const Color(0xFF1E1E2E) : AppTheme.dangerSoft.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? (isDark ? AppTheme.borderDark : AppTheme.primary.withValues(alpha: 0.15))
              : AppTheme.danger.withValues(alpha: 0.35),
          width: isActive ? 1.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Role/Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  PhotoDisplayWidget(
                    photoUrl: emp.avatarUrl,
                    size: 48,
                    borderRadius: 24,
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.success : AppTheme.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppTheme.cardDark : Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            emp.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textMainLight,
                            ),
                          ),
                        ),
                        // Status Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.successSoft : AppTheme.dangerSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                                size: 12,
                                color: isActive ? AppTheme.success : AppTheme.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'ACTIVE' : 'INACTIVE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? AppTheme.success : AppTheme.danger,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${emp.employeeId} • ${emp.department} • ${emp.role.name.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                    if (emp.role == UserRole.employee) ...[
                      const SizedBox(height: 3),
                      Text(
                        'TL: ${emp.managerName ?? 'Unassigned'} • Proj: ${emp.assignedProjectName ?? 'Unassigned'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ] else if (emp.role == UserRole.manager) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Proj: ${emp.assignedProjectName ?? 'Unassigned'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Admin/HR Action Bar Row
          if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.hr) ...[ 
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Edit button — Admin only (has password access inside)
                if (currentUser?.role == UserRole.admin) ...[ 
                  _buildCardActionButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Edit',
                    color: AppTheme.primary,
                    onTap: () => _openEditEmployeeModal(emp),
                  ),
                ],
                if (emp.role == UserRole.employee) ...[
                  _buildCardActionButton(
                    icon: Icons.supervisor_account_rounded,
                    label: 'Assign TL',
                    color: const Color(0xFF2563EB),
                    onTap: () => _openAssignTLModal(emp),
                  ),
                ],
                if (emp.role == UserRole.employee || emp.role == UserRole.manager) ...[
                  _buildCardActionButton(
                    icon: Icons.folder_special_rounded,
                    label: 'Assign Proj',
                    color: AppTheme.accent,
                    onTap: () => _showAssignProjectSheet(context, emp),
                  ),
                ],
                _buildCardActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: AppTheme.danger,
                  onTap: () => _confirmDeleteEmployee(emp),
                ),
              ],
            ),
          ],

          // Inactive Warning Banner (if deactivated)
          if (!isActive) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.dangerSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_person_outlined, size: 16, color: AppTheme.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account suspended - Workspace & login access revoked.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 24),

          // Lower Section: Attendance Metrics & Admin Active Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('30-Day Rate', '${report.attendancePercentage.toStringAsFixed(1)}%'),
              _buildStatItem('Days Present', '${report.presentDays}d'),
              _buildStatItem('Late In', '${report.lateArrivals}x'),
              _buildStatItem('Absent', '${report.absentDays}d'),
              // Admin/HR Activation Toggle Switch
              if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.hr) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isActive ? 'Deactivate' : 'Reactivate',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: isActive,
                        activeThumbColor: AppTheme.success,
                        onChanged: (val) {
                          if (currentUser != null) {
                            adminProv.toggleUserStatus(emp.userId, val, currentUser);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCardActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditEmployeeModal(UserModel targetUser) {
    final nameController = TextEditingController(text: targetUser.name);
    final emailController = TextEditingController(text: targetUser.email);
    final empIdController = TextEditingController(text: targetUser.employeeId);
    final newPasswordController = TextEditingController();
    UserRole selectedRole = targetUser.role;
    bool obscureCurrentPass = true;
    bool obscureNewPass = true;
    bool isSavingPassword = false;
    final formKey = GlobalKey<FormState>();

    // Pre-select department and team based on current user data
    final allDepts = FirestoreService().getAllDepartments();
    final allTeams = FirestoreService().getAllTeams();
    DepartmentModel? selectedDept = allDepts.cast<DepartmentModel?>().firstWhere(
      (d) => d?.name == targetUser.department,
      orElse: () => null,
    );
    TeamModel? selectedTeam = allTeams.cast<TeamModel?>().firstWhere(
      (t) => t?.teamId == targetUser.teamId,
      orElse: () => null,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_rounded, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Edit Employee Profile',
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: empIdController,
                        decoration: const InputDecoration(
                          labelText: 'Employee ID *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Employee ID is required' : null,
                      ),
                      const SizedBox(height: 12),

                      // ── Department Dropdown ──
                      StreamBuilder<List<DepartmentModel>>(
                        stream: FirestoreService().departmentsStream,
                        builder: (context, snapshot) {
                          var depts = snapshot.data ?? [];
                          if (depts.isEmpty) {
                            depts = FirestoreService().getAllDepartments();
                          }
                          // Validate selectedDept is still in the list
                          if (selectedDept != null && !depts.any((d) => d.departmentId == selectedDept!.departmentId)) {
                            selectedDept = null;
                          }
                          return DropdownButtonFormField<DepartmentModel>(
                            value: selectedDept,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Department *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.domain_rounded),
                            ),
                            hint: const Text('Select Department'),
                            items: depts.where((d) => d.isActive).map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (v) {
                              setModalState(() {
                                selectedDept = v;
                                selectedTeam = null; // Reset team when department changes
                              });
                            },
                            validator: (v) => v == null ? 'Department is required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── Team Dropdown ──
                      StreamBuilder<List<TeamModel>>(
                        stream: FirestoreService().teamsStream,
                        builder: (context, snapshot) {
                          var teams = snapshot.data ?? [];
                          if (teams.isEmpty) {
                            teams = FirestoreService().getAllTeams();
                          }
                          if (selectedDept != null) {
                            teams = teams.where((t) => t.departmentId == selectedDept!.departmentId).toList();
                          }
                          // Validate selectedTeam is still in the filtered list
                          if (selectedTeam != null && !teams.any((t) => t.teamId == selectedTeam!.teamId)) {
                            selectedTeam = null;
                          }
                          return DropdownButtonFormField<TeamModel>(
                            value: selectedTeam,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Team',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.groups_rounded),
                            ),
                            hint: const Text('Select Team'),
                            items: teams.where((t) => t.isActive).map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (v) {
                              setModalState(() => selectedTeam = v);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<UserRole>(
                        isExpanded: true,
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'User Role *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(role.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Save Profile Updates', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final admin = context.read<AuthProvider>().currentUser;
                          if (admin == null) return;

                          final updatedUser = targetUser.copyWith(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            employeeId: empIdController.text.trim(),
                            department: selectedDept?.name ?? targetUser.department,
                            teamId: selectedTeam?.teamId ?? targetUser.teamId,
                            teamName: selectedTeam?.name ?? targetUser.teamName,
                            managerId: selectedTeam?.managerId ?? targetUser.managerId,
                            managerName: selectedTeam?.managerName ?? targetUser.managerName,
                            role: selectedRole,
                          );

                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          final adminProv = context.read<AdminProvider>();
                          final success = await adminProv.updateEmployee(updatedUser, admin);
                          nav.pop();

                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '✅ Profile for ${updatedUser.name} updated successfully!'
                                      : '❌ Failed to update employee.',
                                ),
                                backgroundColor: success ? AppTheme.success : AppTheme.danger,
                              ),
                            );
                          }
                        },
                      ),


                      // ── Password Management Section (Admin only) ──────────────
                      Consumer<AuthProvider>(
                        builder: (ctx2, authProv, _) {
                          final admin = authProv.currentUser;
                          if (admin?.role != UserRole.admin) return const SizedBox.shrink();
                          final currentPass = targetUser.initialPassword ?? '(not set)';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              Divider(color: AppTheme.primary.withValues(alpha: 0.18), thickness: 1),
                              const SizedBox(height: 14),

                              // Section Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.lock_person_rounded, size: 17, color: Color(0xFFDC2626)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Password Management',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      'ADMIN ONLY',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFDC2626),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Current Password Display Card
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.22)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.key_rounded, size: 15, color: Color(0xFFDC2626)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'CURRENT PASSWORD',
                                            style: GoogleFonts.inter(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFDC2626),
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            obscureCurrentPass ? '•  •  •  •  •  •  •  •' : currentPass,
                                            style: GoogleFonts.firaCode(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF991B1B),
                                              letterSpacing: obscureCurrentPass ? 2 : 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => setModalState(() => obscureCurrentPass = !obscureCurrentPass),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            obscureCurrentPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            size: 20,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // New Password Field
                              TextFormField(
                                controller: newPasswordController,
                                obscureText: obscureNewPass,
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Set New Password',
                                  hintText: 'Min 6 characters',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.8),
                                  ),
                                  prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFFDC2626), size: 20),
                                  suffixIcon: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => setModalState(() => obscureNewPass = !obscureNewPass),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Icon(
                                          obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          color: const Color(0xFFDC2626),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  labelStyle: const TextStyle(color: Color(0xFFDC2626)),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Change Password Button
                              ElevatedButton.icon(
                                icon: isSavingPassword
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.lock_reset_rounded, size: 18),
                                label: Text(
                                  isSavingPassword ? 'Changing Password...' : '🔑  Change Password',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isSavingPassword
                                    ? null
                                    : () async {
                                        final newPass = newPasswordController.text.trim();
                                        if (newPass.length < 6) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('⚠️ Password must be at least 6 characters.'),
                                              backgroundColor: Color(0xFFDC2626),
                                            ),
                                          );
                                          return;
                                        }
                                        setModalState(() => isSavingPassword = true);
                                        try {
                                          await AuthService().adminChangePassword(
                                            targetUser: targetUser,
                                            newPassword: newPass,
                                            actor: admin!,
                                          );
                                          newPasswordController.clear();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('🔑 Password for ${targetUser.name} changed!'),
                                                backgroundColor: AppTheme.success,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('❌ $e'),
                                                backgroundColor: AppTheme.danger,
                                              ),
                                            );
                                          }
                                        } finally {
                                          setModalState(() => isSavingPassword = false);
                                        }
                                      },
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEmployee(UserModel targetUser) {
    final admin = context.read<AuthProvider>().currentUser;
    if (admin == null) return;

    if (admin.userId == targetUser.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ You cannot delete your own active Admin account.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
              const SizedBox(width: 10),
              Text('Delete Account?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete employee "${targetUser.name}" (${targetUser.employeeId})?\n\nThis action cannot be undone.',
            style: GoogleFonts.inter(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final adminProv = context.read<AdminProvider>();
                final success = await adminProv.deleteEmployee(targetUser.userId, admin);
                nav.pop();

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '🗑️ Employee "${targetUser.name}" has been deleted.'
                            : '❌ Failed to delete employee.',
                      ),
                      backgroundColor: success ? AppTheme.danger : Colors.grey,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminProv = context.watch<AdminProvider>();
    final attendanceProv = context.watch<AttendanceProvider>();
    final admin = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    var users = adminProv.users;
    if (_selectedRoleFilter == 'Employee') {
      users = users.where((u) => u.role == UserRole.employee).toList();
    } else if (_selectedRoleFilter == 'TL') {
      users = users.where((u) => u.role == UserRole.manager).toList();
    } else if (_selectedRoleFilter == 'HR') {
      users = users.where((u) => u.role == UserRole.hr).toList();
    } else if (_selectedRoleFilter == 'Admin') {
      users = users.where((u) => u.role == UserRole.admin).toList();
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    child: const Icon(Icons.admin_panel_settings, color: Color(0xFFEF4444), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administration & Workforce Control',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Manage employee roles, TL team assignments, and account statuses',
                          style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openAddEmployeeModal,
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: Text(
                        'Enroll Employee',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showFirebaseSyncDialog,
                      icon: const Icon(Icons.cloud_sync_rounded, size: 18, color: AppTheme.primary),
                      label: Text(
                        'Firebase Sync',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Organization Management Quick Actions (Departments & Teams)
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DepartmentsManagementScreen(isEmbedded: false),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.domain_rounded,
                                  color: Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Departments',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      'Manage Depts',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TeamsManagementScreen(isEmbedded: false),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.groups_rounded,
                                  color: Color(0xFF0EA5E9),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Teams & TLs',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      'Configure Teams',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Leave Approvals Quick Action Button for Admin
              Builder(
                builder: (ctx) {
                  final leaveProv = ctx.watch<LeaveProvider>();
                  final pendingCount = leaveProv.getPendingLeaves().length;

                  return Material(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaveApprovalScreen(isEmbedded: false),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pendingCount > 0
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                            width: pendingCount > 0 ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.beach_access_rounded,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Review Leave Requests',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    pendingCount > 0
                                        ? '$pendingCount pending applications require authorization'
                                        : 'Company-wide leave applications and authorizations',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? AppTheme.textMutedDark
                                          : AppTheme.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (pendingCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$pendingCount Pending',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Daily Project Work Reports Quick Action Button for Admin
              Builder(
                builder: (ctx) {
                  final hrProv = ctx.watch<HrProvider>();
                  final reportCount = hrProv.dailyProjectReports.length;

                  return Material(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProjectReportsScreen(isEmbedded: false),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? AppTheme.cardDark : AppTheme.primarySoft,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_outlined,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Employee Work Reports Feed ($reportCount Submitted)',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'View all employee project work updates, screenshots & proof',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Broadcast Announcements / Holidays Button for Admin
              Material(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => const CreateAnnouncementSheet(),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Broadcast Holiday / Notice',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Publish official holidays & notices to TLs & employees',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppTheme.textMutedDark
                                      : AppTheme.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Role Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Employee', 'TL', 'HR', 'Admin'].map((filter) {
                    final isSelected = _selectedRoleFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRoleFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Organization Directory (${users.length} Users)',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...users.map((u) {
                final report = ReportService.calculate30DayReport(
                  employee: u,
                  attendanceList: attendanceProv.getEmployeeHistory(u.userId),
                );

                return _buildEmployeeCard(
                  context,
                  u,
                  report,
                  admin,
                  adminProv,
                  isDark,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
