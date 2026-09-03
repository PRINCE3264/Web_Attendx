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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _type == 'holiday'
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                : AppTheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _type == 'holiday'
                                ? Icons.beach_access_rounded
                                : Icons.campaign_rounded,
                            color: _type == 'holiday' ? const Color(0xFFD97706) : AppTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Broadcast Notice / Holiday',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Type Selector
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Announcement Category *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
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
              const SizedBox(height: 12),

              // Holiday Date Picker (if category is holiday)
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
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Holiday Date *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event_available, color: Color(0xFFD97706)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    child: Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_holidayDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Target Audience
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _audience,
                decoration: const InputDecoration(
                  labelText: 'Target Audience *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups_outlined),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
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
              const SizedBox(height: 12),

              // Preset Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('🏖️ Public Holiday', 'Office closed for official public holiday. Enjoy your time off!', 'holiday'),
                    const SizedBox(width: 8),
                    _buildPresetChip('🪔 Festival Holiday', 'Warm festival greetings! Office will remain closed on this auspicious occasion.', 'holiday'),
                    const SizedBox(width: 8),
                    _buildPresetChip('📢 All-Hands Meeting', 'Team lead & all-hands sync meeting scheduled for all teams.', 'announcement'),
                    const SizedBox(width: 8),
                    _buildPresetChip('⚠️ System Maintenance', 'Upcoming infrastructure update. Services will remain active.', 'notice'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g. Diwali Holiday Announcement 🪔',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message / Description *',
                  hintText: 'e.g. In observation of the upcoming festival, the office will remain closed. Wishing everyone joyful celebrations!',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _type == 'holiday'
                            ? 'Holiday notification will be broadcast directly to TLs, employees, and all team members.'
                            : 'Notification will be delivered to all users in the selected target audience.',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isLoading
                      ? 'Broadcasting...'
                      : (_type == 'holiday' ? 'BROADCAST HOLIDAY NOTIFICATION' : 'PUBLISH ANNOUNCEMENT'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: _type == 'holiday' ? const Color(0xFFD97706) : AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String message, String type) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      onPressed: () => _applyPreset(label, message, type),
    );
  }
}
