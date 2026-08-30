import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../shared/custom_widgets.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _empCodeController = TextEditingController();
  final _deptController = TextEditingController();
  UserRole _newRole = UserRole.employee;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _empCodeController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  void _openAddEmployeeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                    'Add New Employee',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Company Email', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _empCodeController,
                      decoration: const InputDecoration(labelText: 'Employee Code (e.g. EMP-1050)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _deptController,
                      decoration: const InputDecoration(labelText: 'Department (e.g. Engineering)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _newRole,
                decoration: const InputDecoration(labelText: 'Assigned Role'),
                items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => _newRole = val);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  final adminProv = context.read<AdminProvider>();
                  final admin = auth.currentUser;
                  if (admin == null) return;

                  final newUser = UserModel(
                    userId: 'emp_${DateTime.now().millisecondsSinceEpoch}',
                    name: _nameController.text.trim().isEmpty ? 'New Employee' : _nameController.text.trim(),
                    email: _emailController.text.trim().isEmpty ? 'employee@company.com' : _emailController.text.trim(),
                    role: _newRole,
                    employeeId: _empCodeController.text.trim().isEmpty ? 'EMP-1099' : _empCodeController.text.trim(),
                    teamId: 'team_mobile',
                    teamName: 'General Team',
                    department: _deptController.text.trim().isEmpty ? 'General' : _deptController.text.trim(),
                    managerId: 'mgr_01',
                    managerName: 'Vikram Mehta (TL)',
                  );

                  final nav = Navigator.of(ctx);
                  await adminProv.addEmployee(newUser, admin);
                  _nameController.clear();
                  _emailController.clear();
                  _empCodeController.clear();
                  _deptController.clear();
                  nav.pop();
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Enroll Employee'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
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

              ElevatedButton.icon(
                onPressed: _openAddEmployeeModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ENROLL NEW EMPLOYEE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),

              const SizedBox(height: 20),

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
                      if (u.role == UserRole.employee) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Assigned TL: ${u.managerName ?? "Not Assigned"}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: u.managerName != null ? AppTheme.secondary : Colors.grey,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _openAssignTLModal(u),
                              icon: const Icon(Icons.assignment_ind, size: 16),
                              label: const Text('Change TL', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
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
