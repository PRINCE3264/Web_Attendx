import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/department_model.dart';
import '../../models/team_model.dart';

class AddEmployeeSheet extends StatefulWidget {
  final UserRole? initialRole;
  const AddEmployeeSheet({super.key, this.initialRole});

  @override
  State<AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Pass@2026');
  final _employeeIdController = TextEditingController();

  DepartmentModel? _selectedDepartment;
  TeamModel? _selectedTeam;
  UserModel? _selectedTL;
  String? _selectedProject;
  DateTime _joiningDate = DateTime.now();
  late UserRole _selectedRole;
  bool _obscurePassword = true;
  String _selectedShiftId = 'shift_general';
  String _selectedShiftName = 'General Shift (09:30 AM - 06:30 PM)';

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.employee;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _pickJoiningDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _joiningDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final hrProv = context.read<HrProvider>();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final empId = _employeeIdController.text.trim();
    final dept = _selectedDepartment?.name ?? 'General';
    final teamId = _selectedTeam?.teamId ?? 'team_general';
    final teamName = _selectedTeam?.name ?? 'Unassigned';

    final success = await auth.adminCreateEmployeeAccount(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
      employeeId: empId,
      department: dept,
      teamId: teamId,
      teamName: teamName,
      managerId: _selectedTL != null ? _selectedTL!.userId : 'unassigned',
      managerName: _selectedTL != null ? _selectedTL!.name : 'Unassigned',
      joiningDate: _joiningDate,
      shiftId: _selectedShiftId,
      shiftName: _selectedShiftName,
    );

    if (success && mounted) {
      if (_selectedProject != null && _selectedProject!.isNotEmpty) {
        final allUsers = FirestoreService().getAllUsers();
        try {
          final createdUser = allUsers.firstWhere(
            (u) => u.email.toLowerCase() == email.toLowerCase(),
            orElse: () => allUsers.last,
          );
          await hrProv.assignProjectToEmployee(createdUser.userId, _selectedProject!);
        } catch (_) {}
      }

      if (!mounted) return;
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employee $name enrolled! Email: $email | Pass: $password'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'COPY',
            textColor: Colors.white,
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Email: $email\nPassword: $password\nEmployee ID: $empId',
              ));
            },
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Failed to add user')),
      );
    }
  }

  InputDecoration _fieldDecoration(String label, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: AppTheme.primary) : null,
      labelStyle: TextStyle(
        color: isDark ? Colors.white60 : Colors.black54,
        fontSize: 13,
      ),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final managers = FirestoreService().getAllUsers().where((u) => u.role == UserRole.manager).toList();
    final titleLabel = _selectedRole == UserRole.manager
        ? 'Add New Team Lead'
        : (_selectedRole == UserRole.hr ? 'Add New HR' : 'Add New Employee');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Fill in details to enroll a new member',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: isDark ? Colors.white38 : Colors.black38),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Form Body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Personal Info Section
                    _sectionLabel('Personal Info', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _fieldDecoration('Full Name', icon: Icons.badge_outlined),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _employeeIdController,
                            decoration: _fieldDecoration('Employee ID', icon: Icons.tag_rounded),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StreamBuilder<List<DepartmentModel>>(
                            stream: FirestoreService().departmentsStream,
                            builder: (context, snapshot) {
                              var depts = snapshot.data ?? [];
                              if (depts.isEmpty) {
                                depts = FirestoreService().getAllDepartments();
                              }
                              return DropdownButtonFormField<DepartmentModel>(
                                initialValue: _selectedDepartment,
                                isExpanded: true,
                                decoration: _fieldDecoration('Department', icon: Icons.business_outlined),
                                dropdownColor: isDark ? AppTheme.bgDark : Colors.white,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                                items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedDepartment = v;
                                    _selectedTeam = null;
                                  });
                                },
                                validator: (v) => v == null ? 'Required' : null,
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<List<TeamModel>>(
                      stream: FirestoreService().teamsStream,
                      builder: (context, snapshot) {
                        var teams = snapshot.data ?? [];
                        if (teams.isEmpty) teams = FirestoreService().getAllTeams();
                        if (_selectedDepartment != null) {
                          teams = teams.where((t) => t.departmentId == _selectedDepartment!.departmentId).toList();
                        }
                        return DropdownButtonFormField<TeamModel>(
                          initialValue: _selectedTeam,
                          isExpanded: true,
                          decoration: _fieldDecoration('Team', icon: Icons.groups_outlined),
                          hint: Text('Select Team', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
                          dropdownColor: isDark ? AppTheme.bgDark : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                          items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedTeam = v;
                              if (v != null && v.managerId.isNotEmpty) {
                                final allUsers = FirestoreService().getAllUsers();
                                final tl = allUsers.cast<UserModel?>().firstWhere((u) => u?.userId == v.managerId, orElse: () => null);
                                if (tl != null) _selectedTL = tl;
                              }
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('Work Details', isDark),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedShiftId,
                      isExpanded: true,
                      decoration: _fieldDecoration('Assigned Shift', icon: Icons.schedule_rounded),
                      dropdownColor: isDark ? AppTheme.bgDark : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                      items: const [
                        DropdownMenuItem(
                          value: 'shift_general',
                          child: Text('🏢 General Shift (09:30 AM - 06:30 PM)', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'shift_morning',
                          child: Text('🌅 Morning Shift (07:00 AM - 04:00 PM)', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedShiftId = val;
                            _selectedShiftName = val == 'shift_morning'
                                ? 'Morning Shift (07:00 AM - 04:00 PM)'
                                : 'General Shift (09:30 AM - 06:30 PM)';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    if (currentUser?.role == UserRole.admin) ...[
                      DropdownButtonFormField<UserRole>(
                        initialValue: _selectedRole,
                        decoration: _fieldDecoration('User Role', icon: Icons.verified_user_outlined),
                        dropdownColor: isDark ? AppTheme.bgDark : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                        items: UserRole.values.map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text(r.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (_selectedRole == UserRole.employee) ...[
                      DropdownButtonFormField<UserModel>(
                        initialValue: _selectedTL,
                        isExpanded: true,
                        decoration: _fieldDecoration('TL / Manager', icon: Icons.manage_accounts_outlined),
                        hint: Text('Select TL', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
                        dropdownColor: isDark ? AppTheme.bgDark : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                        items: managers.map((m) => DropdownMenuItem(value: m, child: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _selectedTL = v),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (_selectedRole == UserRole.employee || _selectedRole == UserRole.manager) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProject,
                        isExpanded: true,
                        decoration: _fieldDecoration('Assigned Project', icon: Icons.folder_special_outlined),
                        hint: Text('Select Project', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
                        dropdownColor: isDark ? AppTheme.bgDark : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                        items: context.watch<HrProvider>().projectsList.map((proj) => DropdownMenuItem(
                          value: proj,
                          child: Text(proj, maxLines: 1, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedProject = v),
                      ),
                      const SizedBox(height: 10),
                    ],

                    InkWell(
                      onTap: _pickJoiningDate,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: _fieldDecoration('Joining Date', icon: Icons.calendar_today_rounded),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_joiningDate),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('Account Credentials', isDark),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _emailController,
                      decoration: _fieldDecoration('Email Address', icon: Icons.email_outlined),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _fieldDecoration('Temporary Password (Min 6 chars)', icon: Icons.lock_outline).copyWith(
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shuffle, size: 18, color: AppTheme.primary),
                              tooltip: 'Generate random password',
                              onPressed: () {
                                final randPass = 'Emp@${DateTime.now().millisecondsSinceEpoch % 10000}!';
                                setState(() => _passwordController.text = randPass);
                              },
                            ),
                            IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  size: 18, color: isDark ? Colors.white38 : Colors.black38),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ],
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().length < 6) ? 'Min 6 characters' : null,
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: auth.isLoading ? null : _submit,
                        icon: auth.isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.person_add_rounded, size: 18),
                        label: Text(
                          auth.isLoading ? 'Creating Account...' : 'Create Employee Account',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white38 : Colors.black38,
        letterSpacing: 0.8,
      ),
    );
  }
}
