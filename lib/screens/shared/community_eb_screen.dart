import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_theme.dart';
import '../../models/community_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'custom_widgets.dart';

class CommunityEbScreen extends StatefulWidget {
  final bool isEmbedded;
  const CommunityEbScreen({super.key, this.isEmbedded = false});

  @override
  State<CommunityEbScreen> createState() => _CommunityEbScreenState();
}

class _CommunityEbScreenState extends State<CommunityEbScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedGroupId;
  XFile? _attachedImage;
  bool _isSending = false;
  String _searchUserQuery = '';
  CommunityMessageModel? _replyingToMessage;
  final Map<String, DateTime> _lastReadTimestamps = {};
  final DateTime _screenInitTime = DateTime.now();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAttachment() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() => _attachedImage = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  Future<void> _sendMessage(UserModel currentUser, String groupId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachedImage == null) return;

    setState(() => _isSending = true);

    String? mediaUrl;
    if (_attachedImage != null) {
      try {
        final storage = StorageService();
        mediaUrl = await storage.uploadProjectReportMedia(
          reportId: 'comm_${DateTime.now().millisecondsSinceEpoch}',
          userId: currentUser.userId,
          fileName: 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
          file: _attachedImage!,
        );
      } catch (e) {
        final bytes = await _attachedImage!.readAsBytes();
        mediaUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    }

    final message = CommunityMessageModel(
      messageId: 'msg_${const Uuid().v4()}',
      groupId: groupId,
      senderId: currentUser.userId,
      senderName: currentUser.name,
      senderRole: currentUser.role.name.toUpperCase(),
      senderAvatar: currentUser.avatarUrl,
      content: text,
      sentAt: DateTime.now(),
      mediaUrl: mediaUrl,
      replyToMessageId: _replyingToMessage?.messageId,
      replyToSenderName: _replyingToMessage?.senderName,
      replyToContent: _replyingToMessage?.content.isNotEmpty == true
          ? _replyingToMessage?.content
          : (_replyingToMessage?.mediaUrl != null
                ? '📷 Image attachment'
                : null),
    );

    _messageController.clear();
    setState(() {
      _attachedImage = null;
      _replyingToMessage = null;
      _isSending = false;
    });

    await FirestoreService().sendCommunityMessage(message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not Authenticated')));
    }

    return StreamBuilder<List<CommunityGroupModel>>(
      stream: FirestoreService().communityGroupsStream,
      builder: (context, groupSnap) {
        final groups =
            groupSnap.data ?? FirestoreService().getAllCommunityGroups();

        // Filter groups visible to currentUser (Admin and HR see all, others see public/member groups)
        final visibleGroups = groups.where((g) {
          if (currentUser.role == UserRole.admin ||
              currentUser.role == UserRole.hr)
            return true;
          if (g.isOfficial || g.memberUserIds.isEmpty) return true;
          return g.memberUserIds.contains(currentUser.userId) ||
              g.memberUserIds.contains(currentUser.employeeId);
        }).toList();

        if (_selectedGroupId == null && visibleGroups.isNotEmpty) {
          _selectedGroupId = visibleGroups.first.groupId;
        }

        final activeGroup = visibleGroups.firstWhere(
          (g) => g.groupId == _selectedGroupId,
          orElse: () => visibleGroups.isNotEmpty
              ? visibleGroups.first
              : CommunityGroupModel(
                  groupId: 'comm_eb_general',
                  name: 'Community EB - General Work Hub',
                  description: 'Official workspace community for all Envision Beyond teams.',
                  createdBy: currentUser.userId,
                  createdAt: DateTime.now(),
                  memberUserIds: [],
                ),
        );

        // Mark current active group as read
        _lastReadTimestamps[activeGroup.groupId] = DateTime.now();

        final isWideScreen = MediaQuery.of(context).size.width > 700;
        final chatArea = _buildChatArea(
          context,
          activeGroup,
          visibleGroups,
          currentUser,
          isDark,
        );

        Widget screenContent;
        if (isWideScreen) {
          screenContent = Row(
            children: [
              _buildVerticalCommunitySidebar(
                context,
                visibleGroups,
                activeGroup,
                currentUser,
                isDark,
              ),
              Expanded(child: chatArea),
            ],
          );
        } else {
          screenContent = chatArea;
        }

        if (widget.isEmbedded) {
          return screenContent;
        }

        return Scaffold(
          backgroundColor: isDark ? AppTheme.bgDark : Colors.white,
          appBar: AppBar(
            title: Text(
              'Community EB',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isDark ? AppTheme.cardDark : AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: screenContent,
        );
      },
    );
  }

  Widget _buildGroupAvatar(CommunityGroupModel group) {
    if (group.groupLogoUrl != null && group.groupLogoUrl!.isNotEmpty) {
      return ClipOval(
        child: PhotoDisplayWidget(
          photoUrl: group.groupLogoUrl,
          size: 40,
          borderRadius: 20,
        ),
      );
    }

    final nameLower = group.name.toLowerCase();
    IconData iconData = Icons.groups_rounded;
    List<Color> gradColors = const [Color(0xFF2563EB), Color(0xFF1D4ED8)];

    if (nameLower.contains('admin')) {
      iconData = Icons.shield_rounded;
      gradColors = const [Color(0xFF9333EA), Color(0xFF7E22CE)];
    } else if (nameLower.contains('hr')) {
      iconData = Icons.badge_rounded;
      gradColors = const [Color(0xFF0284C7), Color(0xFF0369A1)];
    } else if (nameLower.contains('tl') ||
        nameLower.contains('manager') ||
        nameLower.contains('lead')) {
      iconData = Icons.supervisor_account_rounded;
      gradColors = const [Color(0xFFD97706), Color(0xFFB45309)];
    } else if (nameLower.contains('gis') ||
        nameLower.contains('dev') ||
        nameLower.contains('eng')) {
      iconData = Icons.code_rounded;
      gradColors = const [Color(0xFF059669), Color(0xFF047857)];
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradColors),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradColors.first.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(iconData, color: Colors.white, size: 20),
    );
  }

  Widget _buildGroupAvatarSmall(CommunityGroupModel group, bool isSelected) {
    if (group.groupLogoUrl != null && group.groupLogoUrl!.isNotEmpty) {
      return ClipOval(
        child: PhotoDisplayWidget(
          photoUrl: group.groupLogoUrl,
          size: 22,
          borderRadius: 11,
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.25)
            : AppTheme.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.groups_rounded,
        size: 14,
        color: isSelected ? Colors.white : AppTheme.primary,
      ),
    );
  }

  Widget _buildVerticalCommunitySidebar(
    BuildContext context,
    List<CommunityGroupModel> visibleGroups,
    CommunityGroupModel activeGroup,
    UserModel currentUser,
    bool isDark,
  ) {
    return Container(
      width: 310,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDarkAlt : const Color(0xFFF8FAFC),
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mark_chat_unread_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Communities',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: isDark ? Colors.white : AppTheme.textMainLight,
                    ),
                  ),
                ),
                if (currentUser.role == UserRole.admin ||
                    currentUser.role == UserRole.hr) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.group_add_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    tooltip: 'Create New Group',
                    onPressed: () =>
                        _showCreateGroupDialog(context, currentUser),
                  ),
                ],
              ],
            ),
          ),

          // Vertical List — dynamic unread message count badges via StreamBuilder
          Expanded(
            child: StreamBuilder<List<CommunityMessageModel>>(
              stream: FirestoreService().allCommunityMessagesStream,
              builder: (context, msgSnap) {
                final allMessages =
                    msgSnap.data ??
                    FirestoreService().getAllCommunityMessages();

                // Calculate unread messages count map per group
                final Map<String, int> unreadCountMap = {};
                for (final msg in allMessages) {
                  final isMyMsg =
                      msg.senderId == currentUser.userId ||
                      (currentUser.employeeId.isNotEmpty &&
                          msg.senderId == currentUser.employeeId);
                  if (isMyMsg) continue;

                  // Active group is currently being viewed, so 0 unread
                  if (msg.groupId == activeGroup.groupId) continue;

                  final groupLastRead =
                      _lastReadTimestamps[msg.groupId] ?? _screenInitTime;
                  if (msg.sentAt.isAfter(groupLastRead)) {
                    unreadCountMap[msg.groupId] =
                        (unreadCountMap[msg.groupId] ?? 0) + 1;
                  }
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  itemCount: visibleGroups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, idx) {
                    final g = visibleGroups[idx];
                    final isSelected = g.groupId == activeGroup.groupId;
                    final unreadCount = unreadCountMap[g.groupId] ?? 0;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGroupId = g.groupId;
                          _lastReadTimestamps[g.groupId] = DateTime.now();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.4)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildGroupAvatar(g),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 14,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : (isDark
                                                ? Colors.white
                                                : AppTheme.textMainLight),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    g.description.isNotEmpty
                                        ? g.description
                                        : 'Realtime Work Community',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppTheme.textMutedDark
                                          : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Dynamic unread badge: clears when messages are seen
                            if (unreadCount > 0)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  key: ValueKey(unreadCount),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.redAccent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(
    BuildContext context,
    CommunityGroupModel activeGroup,
    List<CommunityGroupModel> visibleGroups,
    UserModel currentUser,
    bool isDark,
  ) {
    return Column(
      children: [
        // Active Selected Group Header Bar with Actions
        _buildActiveGroupHeaderBar(
          context,
          activeGroup,
          visibleGroups,
          currentUser,
          isDark,
        ),

        // Live Chat Messages Body
        Expanded(
          child: StreamBuilder<List<CommunityMessageModel>>(
            stream: FirestoreService().communityMessagesStream(
              activeGroup.groupId,
            ),
            builder: (context, msgSnap) {
              if (msgSnap.hasError) {
                return Center(
                  child: Text(
                    'Unable to load messages: ${msgSnap.error}',
                    style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                  ),
                );
              }

              final messages =
                  msgSnap.data ??
                  FirestoreService().getCommunityMessages(activeGroup.groupId);

              if (messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.forum_outlined,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to ${activeGroup.name}!',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start real-time work communication with team members, Admin, HR, and TLs.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              _scrollToBottom();

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, idx) {
                  final msg = messages[idx];
                  final isMe =
                      msg.senderId == currentUser.userId ||
                      (currentUser.employeeId.isNotEmpty &&
                          msg.senderId == currentUser.employeeId);

                  return _buildMessageBubble(msg, isMe, isDark, currentUser);
                },
              );
            },
          ),
        ),

        // Reply Preview Bar
        _buildReplyPreviewBar(isDark),

        // Attachment Preview Bar
        if (_attachedImage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppTheme.cardDark : Colors.grey.shade100,
            child: Row(
              children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SmartImageWidget(
                      path: _attachedImage!.path,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image Attached',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _attachedImage!.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                  onPressed: () => setState(() => _attachedImage = null),
                ),
              ],
            ),
          ),

        // Message Input Bar
        _buildInputBar(currentUser, activeGroup, isDark),
      ],
    );
  }

  Widget _buildActiveGroupHeaderBar(
    BuildContext context,
    CommunityGroupModel activeGroup,
    List<CommunityGroupModel> visibleGroups,
    UserModel currentUser,
    bool isDark,
  ) {
    final isAdmin =
        currentUser.role == UserRole.admin || currentUser.role == UserRole.hr;
    final isWide = MediaQuery.of(context).size.width > 700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE8EDF3),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildGroupAvatar(activeGroup),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeGroup.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activeGroup.description.isNotEmpty
                            ? activeGroup.description
                            : '${activeGroup.memberUserIds.length} members',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Wide screen: compact icon buttons
          if (isWide && isAdmin) ...[
            _adminIconBtn(
              icon: Icons.group_add_rounded,
              color: AppTheme.primary,
              tooltip: 'Create Group',
              onTap: () => _showCreateGroupDialog(context, currentUser),
            ),
            const SizedBox(width: 4),
            _adminIconBtn(
              icon: Icons.edit_rounded,
              color: AppTheme.primary,
              tooltip: 'Edit Group',
              onTap: () => _showEditGroupDialog(context, activeGroup),
            ),
            const SizedBox(width: 4),
            _adminIconBtn(
              icon: Icons.people_rounded,
              color: const Color(0xFF0EA5E9),
              tooltip: 'Manage Members',
              onTap: () => _showManageMembersDialog(context, activeGroup),
            ),
            const SizedBox(width: 4),
            _adminIconBtn(
              icon: Icons.delete_outline_rounded,
              color: Colors.red,
              tooltip: 'Delete Group',
              onTap: () => _showDeleteGroupConfirmDialog(
                context,
                activeGroup,
                visibleGroups,
              ),
              bgColor: Colors.red.withValues(alpha: 0.1),
            ),
          ],
          // Mobile: single 3-dot popup menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              size: 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 8,
            offset: const Offset(0, 44),
            onSelected: (val) {
              switch (val) {
                case 'switch':
                  _showMobileVerticalCommunitiesBottomSheet(
                    context,
                    visibleGroups,
                    activeGroup,
                    currentUser,
                    isDark,
                  );
                  break;
                case 'create':
                  _showCreateGroupDialog(context, currentUser);
                  break;
                case 'edit':
                  _showEditGroupDialog(context, activeGroup);
                  break;
                case 'members':
                  _showManageMembersDialog(context, activeGroup);
                  break;
                case 'delete':
                  _showDeleteGroupConfirmDialog(
                    context,
                    activeGroup,
                    visibleGroups,
                  );
                  break;
              }
            },
            itemBuilder: (ctx) => [
              if (!isWide)
                _popupItem(
                  'switch',
                  Icons.swap_horiz_rounded,
                  'Switch Community',
                  AppTheme.primary,
                  isDark,
                ),
              if (isAdmin) ...[
                if (!isWide) const PopupMenuDivider(height: 1),
                _popupItem(
                  'create',
                  Icons.group_add_rounded,
                  'New Community',
                  AppTheme.primary,
                  isDark,
                ),
                _popupItem(
                  'edit',
                  Icons.edit_rounded,
                  'Edit Group',
                  AppTheme.primary,
                  isDark,
                ),
                _popupItem(
                  'members',
                  Icons.people_rounded,
                  'Manage Members',
                  const Color(0xFF0EA5E9),
                  isDark,
                ),
                const PopupMenuDivider(height: 1),
                _popupItem(
                  'delete',
                  Icons.delete_outline_rounded,
                  'Delete Group',
                  Colors.red,
                  isDark,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminIconBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
    Color? bgColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bgColor ?? color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
    String val,
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return PopupMenuItem<String>(
      value: val,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: val == 'delete'
                  ? Colors.red
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileVerticalCommunitiesBottomSheet(
    BuildContext context,
    List<CommunityGroupModel> visibleGroups,
    CommunityGroupModel activeGroup,
    UserModel currentUser,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.mark_chat_unread_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'All Communities',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const Spacer(),
                if (currentUser.role == UserRole.admin ||
                    currentUser.role == UserRole.hr) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.group_add_rounded,
                      color: AppTheme.primary,
                    ),
                    tooltip: 'New Community',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCreateGroupDialog(context, currentUser);
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<CommunityMessageModel>>(
                stream: FirestoreService().allCommunityMessagesStream,
                builder: (context, msgSnap) {
                  final allMessages =
                      msgSnap.data ??
                      FirestoreService().getAllCommunityMessages();

                  final Map<String, int> unreadCountMap = {};
                  for (final msg in allMessages) {
                    final isMyMsg =
                        msg.senderId == currentUser.userId ||
                        (currentUser.employeeId.isNotEmpty &&
                            msg.senderId == currentUser.employeeId);
                    if (isMyMsg) continue;
                    if (msg.groupId == activeGroup.groupId) continue;

                    final lastRead =
                        _lastReadTimestamps[msg.groupId] ?? _screenInitTime;
                    if (msg.sentAt.isAfter(lastRead)) {
                      unreadCountMap[msg.groupId] =
                          (unreadCountMap[msg.groupId] ?? 0) + 1;
                    }
                  }

                  return ListView.separated(
                    itemCount: visibleGroups.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final g = visibleGroups[idx];
                      final isSelected = g.groupId == activeGroup.groupId;
                      final unreadCount = unreadCountMap[g.groupId] ?? 0;

                      return ListTile(
                        leading: _buildGroupAvatar(g),
                        title: Text(
                          g.name,
                          style: GoogleFonts.outfit(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? AppTheme.primary
                                : (isDark
                                      ? Colors.white
                                      : AppTheme.textMainLight),
                          ),
                        ),
                        subtitle: Text(
                          g.description.isNotEmpty
                              ? g.description
                              : 'Work Community',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primary,
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedGroupId = g.groupId;
                            _lastReadTimestamps[g.groupId] = DateTime.now();
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreviewBar(bool isDark) {
    if (_replyingToMessage == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDarkAlt : const Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.borderDark : const Color(0xFFCBD5E1),
          ),
          left: const BorderSide(color: AppTheme.primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_replyingToMessage!.senderName}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingToMessage!.content.isNotEmpty
                      ? _replyingToMessage!.content
                      : (_replyingToMessage!.mediaUrl != null
                            ? '📷 Image attachment'
                            : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? Colors.grey.shade400
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
            onPressed: () => setState(() => _replyingToMessage = null),
          ),
        ],
      ),
    );
  }

  void _showEmojiReactionPicker(
    BuildContext context,
    CommunityMessageModel msg,
    UserModel currentUser,
  ) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏', '🎉', '💯', '🙏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.cardDark
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'React to message',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((emoji) {
                final myEmoji =
                    msg.reactions[currentUser.userId] ??
                    msg.reactions[currentUser.employeeId];
                final isSelected = myEmoji == emoji;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    FirestoreService().toggleMessageReaction(
                      messageId: msg.messageId,
                      userId: currentUser.userId,
                      emoji: emoji,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    CommunityMessageModel msg,
    bool isMe,
    bool isDark,
    UserModel currentUser,
  ) {
    Color roleColor;
    final roleUpper = msg.senderRole.toUpperCase();
    if (roleUpper.contains('ADMIN')) {
      roleColor = const Color(0xFF9333EA);
    } else if (roleUpper.contains('HR')) {
      roleColor = const Color(0xFF2563EB);
    } else if (roleUpper.contains('TL') || roleUpper.contains('MANAGER')) {
      roleColor = const Color(0xFFD97706);
    } else {
      roleColor = const Color(0xFF059669);
    }

    final timeStr = DateFormat('hh:mm a').format(msg.sentAt);

    final Map<String, List<String>> emojiUserMap = {};
    msg.reactions.forEach((userId, emoji) {
      emojiUserMap.putIfAbsent(emoji, () => []).add(userId);
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => _showEmojiReactionPicker(context, msg, currentUser),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              ClipOval(
                child: PhotoDisplayWidget(
                  photoUrl: msg.senderAvatar,
                  size: 32,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.senderName,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: roleColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              roleUpper,
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: roleColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF2563EB)
                          : (isDark
                                ? AppTheme.cardDark
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMe
                            ? const Radius.circular(18)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isMe
                              ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isMe
                            ? const Color(0xFF2563EB)
                            : (isDark
                                  ? AppTheme.borderDark
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quoted Reply Box if replying to another message
                        if (msg.replyToMessageId != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.black.withValues(alpha: 0.18)
                                  : (isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: isMe
                                      ? Colors.white70
                                      : AppTheme.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.replyToSenderName ?? 'Reply',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isMe
                                        ? Colors.white
                                        : AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  msg.replyToContent ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isMe
                                        ? Colors.white70
                                        : (isDark
                                              ? Colors.grey.shade300
                                              : const Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (msg.mediaUrl != null &&
                            msg.mediaUrl!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 260,
                              ),
                              child: SmartImageWidget(
                                path: msg.mediaUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (msg.content.isNotEmpty) const SizedBox(height: 8),
                        ],
                        if (msg.content.isNotEmpty)
                          SelectableText(
                            msg.content,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              height: 1.35,
                              color: isMe
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (msg.isEdited) ...[
                              Text(
                                '(edited) ',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontStyle: FontStyle.italic,
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : (isDark
                                            ? AppTheme.textMutedDark
                                            : const Color(0xFF94A3B8)),
                                ),
                              ),
                            ],
                            Text(
                              timeStr,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : (isDark
                                          ? AppTheme.textMutedDark
                                          : const Color(0xFF94A3B8)),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.done_all_rounded,
                                size: 13,
                                color: Colors.white70,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reactions & Actions Row
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (emojiUserMap.isNotEmpty) ...[
                        Wrap(
                          spacing: 4,
                          children: emojiUserMap.entries.map((e) {
                            final emoji = e.key;
                            final userIds = e.value;
                            final hasReacted =
                                userIds.contains(currentUser.userId) ||
                                (currentUser.employeeId.isNotEmpty &&
                                    userIds.contains(currentUser.employeeId));

                            return InkWell(
                              onTap: () {
                                FirestoreService().toggleMessageReaction(
                                  messageId: msg.messageId,
                                  userId: currentUser.userId,
                                  emoji: emoji,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: hasReacted
                                      ? AppTheme.primary.withValues(alpha: 0.15)
                                      : (isDark
                                            ? AppTheme.cardDark
                                            : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: hasReacted
                                        ? AppTheme.primary
                                        : (isDark
                                              ? AppTheme.borderDark
                                              : const Color(0xFFCBD5E1)),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$emoji ${userIds.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: hasReacted
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 6),
                      ],
                      InkWell(
                        onTap: () =>
                            _showEmojiReactionPicker(context, msg, currentUser),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Icon(
                            Icons.add_reaction_outlined,
                            size: 15,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => setState(() => _replyingToMessage = msg),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Icon(
                            Icons.reply_rounded,
                            size: 15,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      // Only the message sender can edit/delete their own message
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _showEditMessageDialog(context, msg),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () =>
                              _showDeleteMessageConfirmDialog(context, msg),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 15,
                              color: Colors.red.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(
    UserModel currentUser,
    CommunityGroupModel activeGroup,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickAttachment,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.cardDarkAlt
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.attach_file_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.borderDark
                        : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) =>
                      _sendMessage(currentUser, activeGroup.groupId),
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type work update or message...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.textMutedDark
                          : const Color(0xFF94A3B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSending
                    ? null
                    : () => _sendMessage(currentUser, activeGroup.groupId),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Admin / HR Modal: Create New Community Group
  void _showCreateGroupDialog(BuildContext context, UserModel adminUser) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final allUsers = FirestoreService().getAllUsers();
    final Set<String> selectedUserIds = allUsers.map((u) => u.userId).toSet();
    XFile? groupLogoFile;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.group_add_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Create Community Group',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Selection Header
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            try {
                              final XFile? file = await _picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                                imageQuality: 85,
                              );
                              if (file != null) {
                                setDlgState(() => groupLogoFile = file);
                              }
                            } catch (e) {
                              debugPrint('Error picking group logo: $e');
                            }
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF1D4ED8),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: groupLogoFile != null
                                    ? ClipOval(
                                        child: SmartImageWidget(
                                          path: groupLogoFile!.path,
                                          fit: BoxFit.cover,
                                          width: 72,
                                          height: 72,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.groups_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          groupLogoFile != null
                              ? 'Custom Group Logo Selected'
                              : 'Tap to Upload Group Logo',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Community Name *',
                      hintText: 'e.g. Mobile App Dev EB Squad',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Work communication & updates for project...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Group Members (Admin, HR, TL, Employees):',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.builder(
                      itemCount: allUsers.length,
                      itemBuilder: (context, idx) {
                        final u = allUsers[idx];
                        final isSelected = selectedUserIds.contains(u.userId);

                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          title: Text(
                            u.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          subtitle: Text(
                            '${u.role.name.toUpperCase()} • ${u.department}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: Colors.grey,
                            ),
                          ),
                          onChanged: (val) {
                            setDlgState(() {
                              if (val == true) {
                                selectedUserIds.add(u.userId);
                              } else {
                                selectedUserIds.remove(u.userId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Create Group'),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                String? groupLogoUrl;
                if (groupLogoFile != null) {
                  try {
                    final storage = StorageService();
                    groupLogoUrl = await storage.uploadProjectReportMedia(
                      reportId:
                          'group_${DateTime.now().millisecondsSinceEpoch}',
                      userId: adminUser.userId,
                      fileName:
                          'group_logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                      file: groupLogoFile!,
                    );
                  } catch (_) {
                    final bytes = await groupLogoFile!.readAsBytes();
                    groupLogoUrl =
                        'data:image/jpeg;base64,${base64Encode(bytes)}';
                  }
                }

                final newGroup = CommunityGroupModel(
                  groupId: 'comm_${const Uuid().v4()}',
                  name: name,
                  description: descController.text.trim(),
                  createdBy: adminUser.userId,
                  createdAt: DateTime.now(),
                  memberUserIds: selectedUserIds.toList(),
                  isOfficial: false,
                  groupLogoUrl: groupLogoUrl,
                );

                Navigator.pop(dlgCtx);
                await FirestoreService().createCommunityGroup(
                  newGroup,
                  adminUser,
                );
                setState(() => _selectedGroupId = newGroup.groupId);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Admin Modal: Manage Existing Group Members
  void _showManageMembersDialog(
    BuildContext context,
    CommunityGroupModel group,
  ) {
    final auth = context.read<AuthProvider>();
    final adminUser = auth.currentUser!;
    final allUsers = FirestoreService().getAllUsers();
    final Set<String> currentMemberIds = Set.from(group.memberUserIds);

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final filteredUsers = allUsers.where((u) {
            if (_searchUserQuery.isEmpty) return true;
            final q = _searchUserQuery.toLowerCase();
            return u.name.toLowerCase().contains(q) ||
                u.department.toLowerCase().contains(q) ||
                u.role.name.toLowerCase().contains(q);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Manage Members - ${group.name}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (val) =>
                        setDlgState(() => _searchUserQuery = val.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search member name, role, department...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, idx) {
                        final u = filteredUsers[idx];
                        final isMember =
                            currentMemberIds.contains(u.userId) ||
                            currentMemberIds.contains(u.employeeId);

                        return CheckboxListTile(
                          dense: true,
                          value: isMember,
                          title: Text(
                            u.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          subtitle: Text(
                            '${u.role.name.toUpperCase()} • ${u.department}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: Colors.grey,
                            ),
                          ),
                          onChanged: (val) {
                            setDlgState(() {
                              if (val == true) {
                                currentMemberIds.add(u.userId);
                                if (u.employeeId.isNotEmpty)
                                  currentMemberIds.add(u.employeeId);
                              } else {
                                currentMemberIds.remove(u.userId);
                                currentMemberIds.remove(u.employeeId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Members'),
                onPressed: () async {
                  Navigator.pop(dlgCtx);
                  await FirestoreService().updateCommunityGroupMembers(
                    group.groupId,
                    currentMemberIds.toList(),
                    adminUser,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Admin & HR Modal: Edit Community Group (Name, Description, Logo, Members)
  void _showEditGroupDialog(BuildContext context, CommunityGroupModel group) {
    final auth = context.read<AuthProvider>();
    final adminUser = auth.currentUser!;
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description);
    final allUsers = FirestoreService().getAllUsers();
    final Set<String> selectedUserIds = Set.from(group.memberUserIds);

    XFile? newLogoFile;
    String? existingLogoUrl = group.groupLogoUrl;
    String editSearchQuery = '';

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final filteredUsers = allUsers.where((u) {
            if (editSearchQuery.isEmpty) return true;
            final q = editSearchQuery.toLowerCase();
            return u.name.toLowerCase().contains(q) ||
                u.department.toLowerCase().contains(q) ||
                u.role.name.toLowerCase().contains(q);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.edit_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Community Group',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Logo Picker
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: newLogoFile != null
                                  ? FutureBuilder<Uint8List>(
                                      future: newLogoFile!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const CircularProgressIndicator();
                                      },
                                    )
                                  : (existingLogoUrl != null &&
                                        existingLogoUrl.isNotEmpty)
                                  ? PhotoDisplayWidget(
                                      photoUrl: existingLogoUrl,
                                      size: 72,
                                      borderRadius: 36,
                                    )
                                  : const Icon(
                                      Icons.groups_rounded,
                                      size: 36,
                                      color: AppTheme.primary,
                                    ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 70,
                              );
                              if (picked != null) {
                                setDlgState(() => newLogoFile = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name *',
                        prefixIcon: Icon(Icons.group, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Goal',
                        prefixIcon: Icon(Icons.description, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Group Members (${selectedUserIds.length} selected)',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      onChanged: (val) =>
                          setDlgState(() => editSearchQuery = val.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search members...',
                        prefixIcon: Icon(Icons.search, size: 16),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, idx) {
                          final u = filteredUsers[idx];
                          final isSelected =
                              selectedUserIds.contains(u.userId) ||
                              selectedUserIds.contains(u.employeeId);

                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            title: Text(
                              u.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                            subtitle: Text(
                              '${u.role.name.toUpperCase()} • ${u.department}',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: Colors.grey,
                              ),
                            ),
                            onChanged: (val) {
                              setDlgState(() {
                                if (val == true) {
                                  selectedUserIds.add(u.userId);
                                  if (u.employeeId.isNotEmpty)
                                    selectedUserIds.add(u.employeeId);
                                } else {
                                  selectedUserIds.remove(u.userId);
                                  selectedUserIds.remove(u.employeeId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Changes'),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  String? logoUrl = existingLogoUrl;
                  if (newLogoFile != null) {
                    try {
                      final storage = StorageService();
                      logoUrl = await storage.uploadProjectReportMedia(
                        reportId: 'group_${group.groupId}',
                        userId: adminUser.userId,
                        fileName:
                            'logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                        file: newLogoFile!,
                      );
                    } catch (_) {
                      final bytes = await newLogoFile!.readAsBytes();
                      logoUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                    }
                  }

                  final updatedGroup = group.copyWith(
                    name: name,
                    description: descController.text.trim(),
                    groupLogoUrl: logoUrl,
                    memberUserIds: selectedUserIds.toList(),
                  );

                  Navigator.pop(dlgCtx);
                  await FirestoreService().updateCommunityGroup(
                    updatedGroup,
                    adminUser,
                  );
                  setState(() {});
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Admin & HR Modal: Delete Community Group Confirmation
  void _showDeleteGroupConfirmDialog(
    BuildContext context,
    CommunityGroupModel group,
    List<CommunityGroupModel> visibleGroups,
  ) {
    if (group.groupId == 'general' || group.name.toLowerCase() == 'general') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The default "General Announcements" group cannot be deleted.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser!;

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete Community Group',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"?\n\nThis will remove the group for all members. This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete Group'),
            onPressed: () async {
              Navigator.pop(dlgCtx);

              final nextGroup = visibleGroups.firstWhere(
                (g) => g.groupId != group.groupId,
                orElse: () => visibleGroups.first,
              );

              final success = await FirestoreService().deleteCommunityGroup(
                group.groupId,
                currentUser,
              );
              if (success) {
                setState(() {
                  _selectedGroupId = nextGroup.groupId;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Group "${group.name}" deleted successfully.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditMessageDialog(BuildContext context, CommunityMessageModel msg) {
    final controller = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.edit_note_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Edit Message',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 4,
            minLines: 1,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Edit your message...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save'),
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty || newText == msg.content) {
                Navigator.pop(dlgCtx);
                return;
              }
              Navigator.pop(dlgCtx);
              await FirestoreService().editCommunityMessage(
                messageId: msg.messageId,
                newContent: newText,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteMessageConfirmDialog(
    BuildContext context,
    CommunityMessageModel msg,
  ) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_forever_rounded,
              color: Colors.red,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete Message',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await FirestoreService().deleteCommunityMessage(msg.messageId);
            },
          ),
        ],
      ),
    );
  }

}
