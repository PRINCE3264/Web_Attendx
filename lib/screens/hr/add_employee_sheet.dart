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
  final _departmentController = TextEditingController();

  UserModel? _selectedTL;
  String? _selectedProject;
  DateTime _joiningDate = DateTime.now();
  late UserRole _selectedRole;
  bool _obscurePassword = true;

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
    _departmentController.dispose();
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
    final dept = _departmentController.text.trim().isEmpty ? 'General' : _departmentController.text.trim();

    final success = await auth.adminCreateEmployeeAccount(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
      employeeId: empId,
      department: dept,
      managerId: _selectedTL != null ? _selectedTL!.userId : 'unassigned',
      managerName: _selectedTL != null ? _selectedTL!.name : 'Unassigned',
      joiningDate: _joiningDate,
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

      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final managers = FirestoreService().getAllUsers().where((u) => u.role == UserRole.manager).toList();
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _selectedRole == UserRole.manager
                    ? 'Add New TL'
                    : (_selectedRole == UserRole.hr ? 'Add New HR' : 'Add New Employee'),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Employee Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(labelText: 'Employee ID', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Temporary Password (Min 6 chars)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
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
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ],
                  ),
                ),
                validator: (v) => (v == null || v.trim().length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              if (currentUser?.role == UserRole.admin) ...[
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(labelText: 'User Role', border: OutlineInputBorder()),
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
                const SizedBox(height: 12),
              ],
              if (_selectedRole == UserRole.employee) ...[
                DropdownButtonFormField<UserModel>(
                  initialValue: _selectedTL,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'TL / Manager', border: OutlineInputBorder()),
                  hint: const Text('Select TL'),
                  items: managers.map((m) => DropdownMenuItem(value: m, child: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedTL = v),
                ),
                const SizedBox(height: 12),
              ],
              if (_selectedRole == UserRole.employee || _selectedRole == UserRole.manager) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedProject,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Project',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder_special_outlined),
                  ),
                  hint: const Text('Select Project'),
                  items: context.watch<HrProvider>().projectsList.map((proj) => DropdownMenuItem(
                    value: proj,
                    child: Text(proj, maxLines: 1, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedProject = v),
                ),
                const SizedBox(height: 12),
              ],
              InkWell(
                onTap: _pickJoiningDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Joining Date', border: OutlineInputBorder()),
                  child: Text(DateFormat('dd/MM/yyyy').format(_joiningDate)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: auth.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Employee'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
