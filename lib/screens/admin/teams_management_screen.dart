import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../models/department_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/admin_provider.dart';

class TeamsManagementScreen extends StatefulWidget {
  final bool isEmbedded;
  const TeamsManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<TeamsManagementScreen> createState() => _TeamsManagementScreenState();
}

class _TeamsManagementScreenState extends State<TeamsManagementScreen> {
  final _nameController = TextEditingController();
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddTeamModal(BuildContext context, [TeamModel? existing]) {
    final adminProv = context.read<AdminProvider>();
    final tls = adminProv.users.where((u) => u.role == UserRole.manager).toList();
    final depts = FirestoreService().getAllDepartments();

    UserModel? selectedTL;
    if (existing != null && existing.managerId.isNotEmpty) {
      try {
        selectedTL = tls.firstWhere((t) => t.userId == existing.managerId);
      } catch (_) {}
    }
    if (selectedTL == null && tls.isNotEmpty) {
      selectedTL = tls.first;
    }

    DepartmentModel? selectedDept;
    if (existing != null && existing.departmentId.isNotEmpty) {
      try {
        selectedDept = depts.firstWhere((d) => d.departmentId == existing.departmentId);
      } catch (_) {}
    }
    if (selectedDept == null && depts.isNotEmpty) {
      selectedDept = depts.first;
    }

    if (existing != null) {
      _nameController.text = existing.name;
      _isActive = existing.isActive;
    } else {
      _nameController.clear();
      _isActive = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
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
                      const Icon(Icons.groups_rounded, color: Color(0xFF0EA5E9)),
                      const SizedBox(width: 8),
                      Text(
                        existing == null ? 'Configure New Team' : 'Edit Team',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name *',
                  hintText: 'e.g. Mobile Apps Team (Flutter)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group_work_rounded),
                ),
              ),
              const SizedBox(height: 12),
              if (depts.isNotEmpty) ...[
                DropdownButtonFormField<DepartmentModel>(
                  initialValue: selectedDept,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Parent Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.domain_rounded),
                  ),
                  items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setModalState(() => selectedDept = val),
                ),
                const SizedBox(height: 12),
              ],
              if (tls.isNotEmpty) ...[
                DropdownButtonFormField<UserModel>(
                  initialValue: selectedTL,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Team Lead (TL / Manager)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.supervisor_account_rounded),
                  ),
                  items: tls.map((t) => DropdownMenuItem(value: t, child: Text('${t.name} (${t.employeeId})', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setModalState(() => selectedTL = val),
                ),
                const SizedBox(height: 12),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Active Team', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: const Text('Active teams appear in onboarding & employee roster', style: TextStyle(fontSize: 12)),
                value: _isActive,
                activeThumbColor: AppTheme.success,
                onChanged: (v) => setModalState(() => _isActive = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(existing == null ? Icons.add_circle_outline : Icons.save, size: 18),
                label: Text(
                  existing == null ? 'CREATE TEAM' : 'SAVE TEAM CONFIGURATION',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;

                  final team = TeamModel(
                    teamId: existing?.teamId ?? 'team_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    departmentId: selectedDept?.departmentId ?? existing?.departmentId ?? 'dept_eng',
                    managerId: selectedTL?.userId ?? existing?.managerId ?? 'unassigned',
                    managerName: selectedTL?.name ?? existing?.managerName ?? 'Unassigned TL',
                    memberCount: existing?.memberCount ?? 0,
                    isActive: _isActive,
                  );

                  await FirestoreService().saveTeam(team);
                  if (modalCtx.mounted) Navigator.pop(modalCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Team "$name" saved successfully!'),
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

    return StreamBuilder<List<TeamModel>>(
      stream: FirestoreService().teamsStream,
      builder: (context, snapshot) {
        var teams = snapshot.data;
        if (teams == null || teams.isEmpty) {
          teams = FirestoreService().getAllTeams();
        }

        Widget content;
        if (teams.isEmpty) {
          content = Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.group_off_rounded, size: 48, color: Color(0xFF0EA5E9)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Teams Configured',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap "+" to configure teams and assign Team Leads (TLs).',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTeamModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Team'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          );
        } else {
          content = ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (ctx, i) {
              final team = teams![i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: team.isActive
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
                      color: team.isActive ? const Color(0xFF0EA5E9).withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: team.isActive ? const Color(0xFF0EA5E9) : Colors.grey,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    team.name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Assigned TL: ${team.managerName.isNotEmpty ? team.managerName : "Unassigned"}',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Member Count: ${team.memberCount} Employees',
                        style: GoogleFonts.inter(fontSize: 11.5, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: team.isActive,
                        activeThumbColor: AppTheme.success,
                        onChanged: (v) async {
                          final updated = team.copyWith(isActive: v);
                          await FirestoreService().saveTeam(updated);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0EA5E9)),
                        onPressed: () => _showAddTeamModal(context, team),
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
              title: Text('Team Directory', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                  onPressed: () => _showAddTeamModal(context),
                  tooltip: 'Add Team',
                ),
              ],
            ),
            body: content,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Teams Management', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                onPressed: () => _showAddTeamModal(context),
                tooltip: 'Add Team',
              ),
            ],
          ),
          body: content,
        );
      },
    );
  }
}
