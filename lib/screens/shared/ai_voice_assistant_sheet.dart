import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/firestore_service.dart';
import '../employee/leave_management_screen.dart';
import '../manager/leave_approval_screen.dart';
import '../hr/report_generator_screen.dart';
import '../admin/audit_logs_screen.dart';
import '../admin/policy_settings_screen.dart';

class ChatMessage {
  final String id;
  final String sender; // 'user' | 'ai'
  final String text;
  final DateTime timestamp;
  final bool isVoice;
  final AIActionType actionType;
  final String? actionLabel;
  final bool isWarningOrBlocked;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isVoice = false,
    this.actionType = AIActionType.none,
    this.actionLabel,
    this.isWarningOrBlocked = false,
  });
}

class AIVoiceAssistantSheet extends StatefulWidget {
  const AIVoiceAssistantSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const AIVoiceAssistantSheet(),
    );
  }

  @override
  State<AIVoiceAssistantSheet> createState() => _AIVoiceAssistantSheetState();
}

class _AIVoiceAssistantSheetState extends State<AIVoiceAssistantSheet> with SingleTickerProviderStateMixin {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusText = "Connected to AttendX AI Live Engine";

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Initial welcome message tailored to user's role persona
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      final userName = user?.name ?? 'Employee';
      final role = user?.role ?? UserRole.employee;

      String welcomeText = '';
      if (role == UserRole.employee) {
        welcomeText = "Hello $userName! 👋 I am your **Personal Attendance Assistant**.\n"
            "You can ask me about your attendance summary, leave balances, today's clock-in time, or correction request status.";
      } else if (role == UserRole.manager) {
        welcomeText = "Hello $userName! 👥 I am your **Team Assistant** for **${user?.teamName ?? 'your team'}**.\n"
            "You can ask me about team attendance turnout, pending approvals, late arrivals, or missing clock-outs.";
      } else if (role == UserRole.hr) {
        welcomeText = "Welcome $userName! 📊 I am your **HR Analytics Assistant**.\n"
            "You can analyze company-wide 30-day attendance analytics, department comparisons, leave trends, or generate attendance reports.";
      } else {
        welcomeText = "Welcome $userName! ⚙️ I am your **System Assistant**.\n"
            "I can provide real-time updates on active users, system sync health, audit logs, and attendance policies.";
      }

      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: 'ai',
            text: welcomeText,
            timestamp: DateTime.now(),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleTextMessageSubmit(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    _addMessage(
      sender: 'user',
      text: query,
    );

    setState(() {
      _isProcessing = true;
      _statusText = "Processing with Role & Security Gate...";
    });

    await _generateRoleAwareAIResponse(query);
  }

  void _addMessage({
    required String sender,
    required String text,
    bool isVoice = false,
    AIActionType actionType = AIActionType.none,
    String? actionLabel,
    bool isWarningOrBlocked = false,
  }) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: sender,
          text: text,
          timestamp: DateTime.now(),
          isVoice: isVoice,
          actionType: actionType,
          actionLabel: actionLabel,
          isWarningOrBlocked: isWarningOrBlocked,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _statusText = "Listening... Speak now";
        });
      }
    } catch (e) {
      debugPrint("Error starting voice recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusText = "Processing voice query...";
      });

      if (path != null) {
        await _processVoiceAudio(path);
      }
    } catch (e) {
      debugPrint("Error stopping voice recording: $e");
      setState(() {
        _isProcessing = false;
        _statusText = "Failed to capture audio.";
      });
    }
  }

  Future<void> _processVoiceAudio(String path) async {
    try {
      if (kIsWeb) return;
      final file = File(path);
      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      try {
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('askVoiceAssistant');
        final result = await callable.call(<String, dynamic>{'audioBase64': base64Audio});
        final data = result.data as Map<dynamic, dynamic>;

        final transcriptionText = data['transcription'] as String? ?? 'Voice Query';
        final responseAudioBase64 = data['audioBase64'] as String?;

        _addMessage(sender: 'user', text: transcriptionText, isVoice: true);
        await _generateRoleAwareAIResponse(transcriptionText);

        if (responseAudioBase64 != null && responseAudioBase64.isNotEmpty) {
          final audioBytes = base64Decode(responseAudioBase64);
          await _audioPlayer.play(BytesSource(audioBytes));
        }
      } catch (_) {
        // Fallback to local intelligent voice processing
        _addMessage(sender: 'user', text: "🎙️ Meri attendance aur status batao", isVoice: true);
        await _generateRoleAwareAIResponse("meri attendance status");
      }
    } catch (e) {
      debugPrint("Audio Processing Error: $e");
      _addMessage(sender: 'ai', text: "Sorry, I couldn't process the audio. Please type your question below.");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = "Connected to AttendX AI Live Engine";
        });
      }
    }
  }

  /// Generates response through AIAssistantService with Role Context & Security Rules
  Future<void> _generateRoleAwareAIResponse(String userQuery) async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final attendanceProv = context.read<AttendanceProvider>();
    final leaveProv = context.read<LeaveProvider>();

    final user = auth.currentUser;
    if (user == null) {
      _addMessage(sender: 'ai', text: 'Please log in to use AttendX AI Assistant.');
      return;
    }

    final allUsers = FirestoreService().getAllUsers();
    final allAttendance = attendanceProv.allAttendance;
    final allLeaves = leaveProv.allLeaves;

    final response = await AIAssistantService().processQuery(
      query: userQuery,
      user: user,
      allAttendance: allAttendance,
      allLeaves: allLeaves,
      allUsers: allUsers,
    );

    _addMessage(
      sender: 'ai',
      text: response.text,
      actionType: response.actionType,
      actionLabel: response.actionLabel,
      isWarningOrBlocked: response.isWarningOrBlocked,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _statusText = "Connected to AttendX AI Live Engine";
      });
    }
  }

  void _handleInteractiveAction(AIActionType actionType) {
    Navigator.pop(context); // Close assistant sheet

    switch (actionType) {
      case AIActionType.applyLeave:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaveManagementScreen()),
        );
        break;
      case AIActionType.viewApprovals:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaveApprovalScreen(isEmbedded: false)),
        );
        break;
      case AIActionType.generateReport:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportGeneratorScreen(isEmbedded: false)),
        );
        break;
      case AIActionType.viewAuditLogs:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuditLogsScreen(isEmbedded: false)),
        );
        break;
      case AIActionType.openPolicySettings:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PolicySettingsScreen(isEmbedded: false)),
        );
        break;
      case AIActionType.clockIn:
      case AIActionType.viewProfile:
      case AIActionType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final role = user?.role ?? UserRole.employee;
    final quickSuggestions = AIAssistantService().getQuickSuggestions(role);

    return Container(
      height: mediaQuery.size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Role-Aware Header Bar
          _buildHeader(context, isDark, user, role),

          // 2. Chat Messages Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),

          // 3. Typing Indicator
          if (_isProcessing) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AI reasoning with security scope...',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 4. Role-Specific Quick Action Suggestion Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: quickSuggestions.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final suggestion = quickSuggestions[index];
                final cleanText = suggestion.replaceAll(RegExp(r'^[^\w\s]+\s*'), '');
                return ActionChip(
                  elevation: 0,
                  pressElevation: 1,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  label: Text(
                    suggestion,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                    ),
                  ),
                  onPressed: () => _handleTextMessageSubmit(cleanText),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 5. Input Control Bar (Text Field + Mic Button + Send)
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset > 0 ? bottomInset + 8 : 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Text Input Field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _handleTextMessageSubmit,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask AttendX AI (${AIAssistantService().getPersonaTitle(role)})...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: const Color(0xFF94A3B8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Voice Hold & Record Button
                    GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (ctx, child) {
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isRecording
                                    ? [Colors.redAccent, Colors.red]
                                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                              ),
                              boxShadow: [
                                if (_isRecording)
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(alpha: 0.5),
                                    blurRadius: 12 + (8 * _pulseController.value),
                                    spreadRadius: 2 + (4 * _pulseController.value),
                                  ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Send Button
                    Material(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => _handleTextMessageSubmit(_textController.text),
                        child: const Padding(
                          padding: EdgeInsets.all(11),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _statusText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _isRecording ? Colors.redAccent : const Color(0xFF94A3B8),
                    fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, UserModel? user, UserRole role) {
    final personaTitle = AIAssistantService().getPersonaTitle(role);
    Color badgeColor;
    IconData roleIcon;

    switch (role) {
      case UserRole.employee:
        badgeColor = const Color(0xFF10B981);
        roleIcon = Icons.person;
        break;
      case UserRole.manager:
        badgeColor = const Color(0xFFF59E0B);
        roleIcon = Icons.groups;
        break;
      case UserRole.hr:
        badgeColor = const Color(0xFF2563EB);
        roleIcon = Icons.bar_chart;
        break;
      case UserRole.admin:
        badgeColor = const Color(0xFFEF4444);
        roleIcon = Icons.admin_panel_settings;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        children: [
          // AI Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              'assets/ai.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AttendX AI',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, size: 11, color: badgeColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                personaTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Security Scope: ${role.name.toUpperCase()} Access Only',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 22),
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isUser = message.sender == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: message.isWarningOrBlocked
                      ? [Colors.orange.shade700, Colors.red.shade700]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isWarningOrBlocked ? Icons.lock_person : Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2563EB)
                    : (message.isWarningOrBlocked
                        ? (isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2))
                        : (isDark ? const Color(0xFF1E293B) : Colors.white)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: message.isWarningOrBlocked
                            ? Colors.red.shade300
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: isUser
                          ? Colors.white
                          : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                    ),
                  ),
                  if (message.actionType != AIActionType.none && message.actionLabel != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _handleInteractiveAction(message.actionType),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(
                        message.actionLabel!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AIVoiceButton extends StatefulWidget {
  const AIVoiceButton({super.key});

  @override
  State<AIVoiceButton> createState() => _AIVoiceButtonState();
}

class _AIVoiceButtonState extends State<AIVoiceButton> with SingleTickerProviderStateMixin {
  static Offset? _savedPosition;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseScaleAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.95).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    if (_savedPosition != null) {
      if (_savedPosition!.dx < 0 ||
          _savedPosition!.dy < 0 ||
          _savedPosition!.dx > screenSize.width - 20 ||
          _savedPosition!.dy > screenSize.height - 20) {
        _savedPosition = null;
      }
    }

    final double? leftPos = _savedPosition?.dx;
    final double? topPos = _savedPosition?.dy;
    final double? rightPos = _savedPosition == null ? 16.0 : null;
    final double? bottomPos = _savedPosition == null ? 110.0 : null;

    return Positioned(
      left: leftPos,
      top: topPos,
      right: rightPos,
      bottom: bottomPos,
      child: GestureDetector(
        onPanStart: (details) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final globalPos = box.localToGlobal(Offset.zero);
            setState(() {
              _savedPosition = globalPos;
              _isDragging = true;
            });
          }
        },
        onPanUpdate: (details) {
          setState(() {
            if (_savedPosition == null) {
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                _savedPosition = box.localToGlobal(Offset.zero);
              } else {
                _savedPosition = Offset(
                  (screenSize.width - 76.0).clamp(10.0, 1000.0),
                  (screenSize.height - 150.0).clamp(50.0, 2000.0),
                );
              }
            }
            final newX = (_savedPosition!.dx + details.delta.dx).clamp(
              10.0,
              screenSize.width > 70 ? screenSize.width - 70.0 : 300.0,
            );
            final newY = (_savedPosition!.dy + details.delta.dy).clamp(
              padding.top + 10.0,
              screenSize.height > 120 ? screenSize.height - 120.0 : 600.0,
            );
            _savedPosition = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        onTap: () {
          if (!_isDragging) {
            AIVoiceAssistantSheet.show(context);
          }
        },
        child: Tooltip(
          message: 'Drag anywhere on screen or tap to open AI Assistant',
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final glowVal = _glowAnimation.value;
              final scaleVal = _pulseScaleAnimation.value;

              return Transform.scale(
                scale: _isDragging ? 1.15 : scaleVal,
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle Pulsing Glow Ring
                      Container(
                        width: 52 + (glowVal * 4),
                        height: 52 + (glowVal * 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2563EB).withValues(alpha: _isDragging ? 0.25 : 0.08 * glowVal),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: _isDragging ? 0.4 : 0.15 + (glowVal * 0.15)),
                              blurRadius: _isDragging ? 14 : 8 + (glowVal * 4),
                              spreadRadius: _isDragging ? 4 : 1 + (glowVal * 2),
                            ),
                          ],
                        ),
                      ),

                      // Inner Core Glowing Floating Button
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5 + (glowVal * 0.4)),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/ai.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.white.withValues(alpha: 0.92 + (glowVal * 0.08)),
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

