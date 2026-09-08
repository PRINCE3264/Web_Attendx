import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../models/department_model.dart';
import '../../services/firestore_service.dart';

class DepartmentsManagementScreen extends StatefulWidget {
  final bool isEmbedded;
  const DepartmentsManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<DepartmentsManagementScreen> createState() => _DepartmentsManagementScreenState();
}

class _DepartmentsManagementScreenState extends State<DepartmentsManagementScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showAddDepartmentModal(BuildContext context, [DepartmentModel? existing]) {
    if (existing != null) {
      _nameController.text = existing.name;
      _codeController.text = existing.code;
      _isActive = existing.isActive;
    } else {
      _nameController.clear();
      _codeController.clear();
      _isActive = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.domain_rounded, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        existing == null ? 'Add New Department' : 'Edit Department',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Department Name *',
                  hintText: 'e.g. Engineering & Technology',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Department Code *',
                  hintText: 'e.g. ENG',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Active Department', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: const Text('Inactive departments are hidden from dynamic selection', style: TextStyle(fontSize: 12)),
                value: _isActive,
                activeThumbColor: AppTheme.success,
                onChanged: (v) => setModalState(() => _isActive = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(existing == null ? Icons.add_circle_outline : Icons.save, size: 18),
                label: Text(
                  existing == null ? 'CREATE DEPARTMENT' : 'SAVE CHANGES',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  final code = _codeController.text.trim().isEmpty ? name.substring(0, name.length > 3 ? 3 : name.length).toUpperCase() : _codeController.text.trim();

                  final dept = DepartmentModel(
                    departmentId: existing?.departmentId ?? 'dept_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    code: code,
                    isActive: _isActive,
                    totalEmployees: existing?.totalEmployees ?? 0,
                    headOfDepartmentName: existing?.headOfDepartmentName ?? 'Unassigned',
                  );

                  await FirestoreService().saveDepartment(dept);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Department "$name" saved successfully!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<DepartmentModel>>(
      stream: FirestoreService().departmentsStream,
      builder: (context, snapshot) {
        var departments = snapshot.data;
        if (departments == null || departments.isEmpty) {
          departments = FirestoreService().getAllDepartments();
        }

        Widget content;
        if (departments.isEmpty) {
          content = Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.domain_disabled_rounded, size: 48, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Departments Found',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap "+" to add your organization\'s first department.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDepartmentModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Department'),
                  ),
                ],
              ),
            ),
          );
        } else {
          content = ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: departments.length,
            itemBuilder: (ctx, i) {
              final dept = departments![i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dept.isActive
                        ? (isDark ? AppTheme.borderDark : AppTheme.borderLight)
                        : AppTheme.danger.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: dept.isActive ? const Color(0xFF8B5CF6).withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.domain_rounded,
                      color: dept.isActive ? const Color(0xFF8B5CF6) : Colors.grey,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    dept.name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${dept.code} • Employees: ${dept.totalEmployees}',
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                      ),
                      if (dept.headOfDepartmentName != null && dept.headOfDepartmentName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Head: ${dept.headOfDepartmentName}',
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.primary),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: dept.isActive,
                        activeThumbColor: AppTheme.success,
                        onChanged: (v) async {
                          final updated = dept.copyWith(isActive: v);
                          await FirestoreService().saveDepartment(updated);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                        onPressed: () => _showAddDepartmentModal(context, dept),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        if (widget.isEmbedded) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Department Directory', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
            body: content,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddDepartmentModal(context),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text('Add Department', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Departments Management', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
          body: content,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDepartmentModal(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text('Add Department', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}
