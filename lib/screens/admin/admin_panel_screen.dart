import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../services/firestore_seeder_service.dart';
import '../shared/custom_widgets.dart';
import '../manager/leave_approval_screen.dart';
import '../hr/create_announcement_sheet.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Password@123');
  final _empCodeController = TextEditingController();
  final _deptController = TextEditingController();
  UserRole _newRole = UserRole.employee;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _empCodeController.dispose();
    _deptController.dispose();
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
  }) {
    bool obscurePassword = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppTheme.success, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Employee Enrolled! 🎉',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Account created successfully! Share these login credentials with the employee so they can log in and start work immediately.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCredentialRow('👤 Name', name),
                      const Divider(height: 16),
                      _buildCredentialRow('🆔 Employee ID', employeeId),
                      const Divider(height: 16),
                      _buildCredentialRow('📧 Login Email', email),
                      const Divider(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🔑 Login Password', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  obscurePassword ? '••••••••' : password,
                                  style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off, size: 20, color: Colors.grey),
                            onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildCredentialRow('💼 Role & Dept', '${role.name} • ${department ?? "General"}'),
                      if (managerName != null) ...[
                        const Divider(height: 16),
                        _buildCredentialRow('👥 Assigned TL', managerName),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final text = '''
🌟 AttendX Login Credentials 🌟
Name: $name
Employee ID: $employeeId
Role: ${role.name}
Department: ${department ?? 'General'}

📧 Login Email: $email
🔑 Password: $password

Use this Email and Password to log into AttendX and start your shifts & attendance.
''';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 Credentials copied to clipboard! Share with employee.'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('COPY LOGIN CREDENTIALS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  void _openAddEmployeeModal() {
    final adminProv = context.read<AdminProvider>();
    final tls = adminProv.users.where((u) => u.role == UserRole.manager).toList();
    UserModel? selectedTL = tls.isNotEmpty ? tls.first : null;
    bool obscurePass = true;
    bool isSaving = false;
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<UserRole>(
                          initialValue: _newRole,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => _newRole = val);
                          },
                        ),
                      ),
                      if (tls.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<UserModel>(
                            initialValue: selectedTL,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Assigned TL',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: tls.map((t) => DropdownMenuItem(value: t, child: Text(t.name, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedTL = val);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
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

                            final success = await auth.adminCreateEmployeeAccount(
                              name: name,
                              email: email,
                              password: password,
                              role: _newRole,
                              employeeId: empId,
                              department: dept,
                              teamId: selectedTL?.teamId ?? 'team_general',
                              teamName: selectedTL?.teamName ?? 'General Team',
                              managerId: selectedTL?.userId,
                              managerName: selectedTL?.name,
                            );

                            if (success && mounted) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              _nameController.clear();
                              _emailController.clear();
                              _empCodeController.clear();
                              _deptController.clear();
                              _passwordController.clear();

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

  String _selectedRoleFilter = 'All';

  void _openAssignTLModal(UserModel employee) {
    final adminProv = context.read<AdminProvider>();
    final tls = adminProv.users.where((u) => u.role == UserRole.manager).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assign TL to ${employee.name}',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select which Team Lead (TL) is responsible for attendance approvals and team records for this employee.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (tls.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No TLs found. Please create or assign a user to the TL role first.'),
              )
            else
              ...tls.map((tl) {
                final isAssigned = employee.managerId == tl.userId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isAssigned ? AppTheme.primary.withValues(alpha: 0.1) : null,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.secondary.withValues(alpha: 0.2),
                      child: const Icon(Icons.supervisor_account, color: AppTheme.secondary, size: 20),
                    ),
                    title: Text(tl.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${tl.employeeId} • Team: ${tl.teamName}', style: const TextStyle(fontSize: 12)),
                    trailing: isAssigned
                        ? const Icon(Icons.check_circle, color: AppTheme.success)
                        : ElevatedButton(
                            onPressed: () async {
                              final admin = context.read<AuthProvider>().currentUser;
                              if (admin == null) return;
                              final nav = Navigator.of(ctx);
                              await adminProv.assignEmployeeToTL(
                                employeeId: employee.userId,
                                tlUser: tl,
                                admin: admin,
                              );
                              nav.pop();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${employee.name} assigned to TL ${tl.name}')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Text('Assign'),
                          ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _openEditEmployeeModal(UserModel targetUser) {
    final nameController = TextEditingController(text: targetUser.name);
    final emailController = TextEditingController(text: targetUser.email);
    final empIdController = TextEditingController(text: targetUser.employeeId);
    final deptController = TextEditingController(text: targetUser.department);
    UserRole selectedRole = targetUser.role;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                      TextFormField(
                        controller: deptController,
                        decoration: const InputDecoration(
                          labelText: 'Department *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Department is required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        isExpanded: true,
                        initialValue: selectedRole,
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
                            department: deptController.text.trim(),
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
    final admin = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    var users = adminProv.users;
    if (_selectedRoleFilter == 'Employee') {
      users = users.where((u) => u.role == UserRole.employee).toList();
    } else if (_selectedRoleFilter == 'TL') {
      users = users.where((u) => u.role == UserRole.manager).toList();
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
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: Color(0xFF6366F1),
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
                  children: ['All', 'Employee', 'TL', 'Admin'].map((filter) {
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            child: ClipOval(
                              child: PhotoDisplayWidget(
                                photoUrl: u.avatarUrl,
                                size: 40,
                                borderRadius: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${u.employeeId} • ${u.role.name} • ${u.department}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch(
                            value: u.isActive,
                            activeThumbColor: AppTheme.success,
                            onChanged: admin == null ? null : (val) => adminProv.toggleUserStatus(u.userId, val, admin),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          if (u.role == UserRole.employee) ...[
                            Expanded(
                              child: Text(
                                'TL: ${u.managerName ?? "Not Assigned"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: u.managerName != null ? AppTheme.secondary : Colors.grey,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _openAssignTLModal(u),
                              icon: const Icon(Icons.assignment_ind, size: 14),
                              label: const Text('Change TL', style: TextStyle(fontSize: 11)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            const Spacer(),
                          ],
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                                tooltip: 'Edit Employee',
                                onPressed: () => _openEditEmployeeModal(u),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                              if (admin != null && admin.userId != u.userId) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
                                  tooltip: 'Delete Employee',
                                  onPressed: () => _confirmDeleteEmployee(u),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
