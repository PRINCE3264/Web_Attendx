import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/announcement_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';

class CreateAnnouncementSheet extends StatefulWidget {
  const CreateAnnouncementSheet({super.key});

  @override
  State<CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<CreateAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _type = 'holiday';
  String _audience = 'everyone';
  DateTime _holidayDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _applyPreset(String title, String message, String type) {
    setState(() {
      _type = type;
      _titleController.text = title;
      _messageController.text = message;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final finalAudience = _type == 'holiday' ? 'everyone' : _audience;

    final announcement = AnnouncementModel(
      id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      type: _type,
      audience: finalAudience,
      date: _type == 'holiday' ? _holidayDate : DateTime.now(),
      createdBy: user.userId,
      createdAt: DateTime.now(),
    );

    await FirestoreService().publishAnnouncement(announcement);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == 'holiday'
                ? '🏖️ Holiday Announced! Sent to TLs & all staff.'
                : '📢 Announcement Published & Delivered!',
          ),
          backgroundColor: AppTheme.success,
        ),
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
    final isHoliday = _type == 'holiday';
    final accentColor = isHoliday ? const Color(0xFFD97706) : AppTheme.primary;

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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isHoliday ? Icons.beach_access_rounded : Icons.campaign_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Broadcast Notice',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Send holiday or company announcements',
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
                    // Category
                    _sectionLabel('Category', isDark),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _type,
                      decoration: _fieldDecoration('Announcement Type', icon: Icons.category_outlined),
                      dropdownColor: isDark ? AppTheme.bgDark : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                      selectedItemBuilder: (BuildContext context) {
                        return const [
                          Text('🏖️ Official Holiday Announcement', overflow: TextOverflow.ellipsis),
                          Text('📢 General Company Announcement', overflow: TextOverflow.ellipsis),
                          Text('⚠️ Important Operational Notice', overflow: TextOverflow.ellipsis),
                        ];
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'holiday',
                          child: Text('🏖️ Official Holiday Announcement', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'announcement',
                          child: Text('📢 General Company Announcement', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'notice',
                          child: Text('⚠️ Important Operational Notice', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _type = v;
                            if (_type == 'holiday') _audience = 'everyone';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Holiday Date Picker
                    if (_type == 'holiday') ...[
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _holidayDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _holidayDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: _fieldDecoration('Holiday Date', icon: Icons.event_available),
                          child: Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(_holidayDate),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Target Audience
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _audience,
                      decoration: _fieldDecoration('Target Audience', icon: Icons.groups_outlined),
                      dropdownColor: isDark ? AppTheme.bgDark : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                      selectedItemBuilder: (BuildContext context) {
                        return const [
                          Text('🌐 Everyone (Company-wide & TLs)', overflow: TextOverflow.ellipsis),
                          Text('👥 All Employees & Staff', overflow: TextOverflow.ellipsis),
                          Text('👔 Team Leads & Managers Only', overflow: TextOverflow.ellipsis),
                        ];
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'everyone',
                          child: Text('🌐 Everyone (Company-wide & TLs)', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'all_employees',
                          child: Text('👥 All Employees & Staff', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'all_tls',
                          child: Text('👔 Team Leads & Managers Only', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (v) => setState(() => _audience = v!),
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('Content', isDark),
                    const SizedBox(height: 8),

                    // Quick Presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip('🏖️ Public Holiday', 'Office closed for official public holiday. Enjoy your time off!', 'holiday', isDark),
                          const SizedBox(width: 8),
                          _buildPresetChip('🪔 Festival Holiday', 'Warm festival greetings! Office will remain closed on this auspicious occasion.', 'holiday', isDark),
                          const SizedBox(width: 8),
                          _buildPresetChip('📢 All-Hands', 'Team lead & all-hands sync meeting scheduled for all teams.', 'announcement', isDark),
                          const SizedBox(width: 8),
                          _buildPresetChip('⚠️ Maintenance', 'Upcoming infrastructure update. Services will remain active.', 'notice', isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _titleController,
                      decoration: _fieldDecoration('Title', icon: Icons.title_rounded),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: _fieldDecoration('Message / Description', icon: Icons.notes_rounded),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_active_rounded, color: accentColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _type == 'holiday'
                                  ? 'Holiday notification will be broadcast directly to TLs, employees, and all team members.'
                                  : 'Notification will be delivered to all users in the selected target audience.',
                              style: TextStyle(fontSize: 11.5, color: accentColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Icon(isHoliday ? Icons.beach_access_rounded : Icons.send_rounded, size: 18),
                        label: Text(
                          _isLoading
                              ? 'Broadcasting...'
                              : (isHoliday ? 'BROADCAST HOLIDAY' : 'PUBLISH ANNOUNCEMENT'),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
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

  Widget _buildPresetChip(String label, String message, String type, bool isDark) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
      side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      onPressed: () => _applyPreset(label, message, type),
    );
  }
}
