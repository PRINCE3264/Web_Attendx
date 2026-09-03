import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/audit_log_model.dart';
import '../../providers/admin_provider.dart';

class AuditLogsScreen extends StatefulWidget {
  final bool isEmbedded;
  const AuditLogsScreen({super.key, this.isEmbedded = true});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logs = adminProv.auditLogs.where((l) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return l.actorName.toLowerCase().contains(q) ||
          l.actionType.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                'Security & Audit Trail Log',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search audit events (actor, action, description)...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'No audit records found.',
                        style: GoogleFonts.inter(
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final entry = logs[index];
                        return _buildLogItem(context, entry, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, AuditLogModel entry, bool isDark) {
    Color typeColor;
    IconData icon;

    switch (entry.actionType) {
      case 'CLOCK_IN':
        typeColor = AppTheme.primary;
        icon = Icons.login;
        break;
      case 'CLOCK_OUT':
        typeColor = AppTheme.info;
        icon = Icons.logout;
        break;
      case 'TL_APPROVED':
      case 'TL_BULK_APPROVE':
        typeColor = AppTheme.success;
        icon = Icons.verified;
        break;
      case 'TL_REJECTED':
        typeColor = AppTheme.danger;
        icon = Icons.cancel;
        break;
      case 'LEAVE_APPLY':
      case 'LEAVE_APPROVE':
        typeColor = AppTheme.secondary;
        icon = Icons.flight_takeoff;
        break;
      case 'POLICY_UPDATE':
        typeColor = AppTheme.accent;
        icon = Icons.tune;
        break;
      default:
        typeColor = Colors.grey;
        icon = Icons.history;
    }

    final timeStr = DateFormat('dd MMM yyyy, hh:mm:ss a').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: typeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${entry.actorName} (${entry.actorRole})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.actionType,
                        style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                if (entry.oldValue != null || entry.newValue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Diff: [${entry.oldValue ?? ""}] ➔ [${entry.newValue ?? ""}]',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blueGrey),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
