import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/leave_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  LeaveType _selectedType = LeaveType.casual;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _openApplyLeaveModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalDays = _endDate.difference(_startDate).inDays + 1;

          return Padding(
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
                      'Apply for Leave',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LeaveType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Leave Category'),
                  items: LeaveType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.label));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setModalState(() {
                              _startDate = picked;
                              if (_endDate.isBefore(_startDate)) _endDate = _startDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Start Date'),
                          child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setModalState(() => _endDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'End Date'),
                          child: Text(DateFormat('dd MMM yyyy').format(_endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total Duration: $totalDays ${totalDays > 1 ? "Days" : "Day"}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Leave',
                    hintText: 'e.g. Medical emergency, family function, travel...',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final leaveProv = context.read<LeaveProvider>();
                    final user = auth.currentUser;
                    if (user == null) return;

                    final reason = _reasonController.text.trim().isEmpty
                        ? 'Personal leaves'
                        : _reasonController.text.trim();

                    final nav = Navigator.of(ctx);
                    await leaveProv.applyLeave(
                      employee: user,
                      leaveType: _selectedType,
                      startDate: _startDate,
                      endDate: _endDate,
                      totalDays: totalDays,
                      reason: reason,
                    );

                    _reasonController.clear();
                    nav.pop();
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Submit Leave Request'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leaveProv = context.watch<LeaveProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final balance = leaveProv.getLeaveBalance(user.userId);
    final userLeaves = leaveProv.getLeavesForEmployee(user.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leave & Absence Portal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leave Quota Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildBalanceCard(
                      'Casual (CL)',
                      '${balance.casualRemaining}',
                      'used ${balance.casualUsed}/${balance.casualTotal}',
                      AppTheme.primary,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildBalanceCard(
                      'Sick (SL)',
                      '${balance.sickRemaining}',
                      'used ${balance.sickUsed}/${balance.sickTotal}',
                      AppTheme.secondary,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildBalanceCard(
                      'Earned (EL)',
                      '${balance.earnedRemaining}',
                      'used ${balance.earnedUsed}/${balance.earnedTotal}',
                      AppTheme.accent,
                      isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _openApplyLeaveModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('APPLY FOR NEW LEAVE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),

              const SizedBox(height: 24),

              // Leave History Title
              Text(
                'My Leave Requests',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (userLeaves.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: const Center(child: Text('No leave requests submitted yet.')),
                )
              else
                ...userLeaves.map((l) => _buildLeaveItem(context, l, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String title, String remain, String used, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(remain, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(used, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLeaveItem(BuildContext context, LeaveRequestModel l, bool isDark) {
    Color statusColor;
    switch (l.status) {
      case LeaveStatus.approved:
        statusColor = AppTheme.success;
        break;
      case LeaveStatus.rejected:
        statusColor = AppTheme.danger;
        break;
      case LeaveStatus.pending:
        statusColor = AppTheme.warning;
        break;
    }

    final df = DateFormat('dd MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.leaveType.label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  l.status.label,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${df.format(l.startDate)} - ${df.format(l.endDate)} (${l.totalDays} ${l.totalDays > 1 ? "Days" : "Day"})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Reason: ${l.reason}',
            style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
          ),
        ],
      ),
    );
  }
}
