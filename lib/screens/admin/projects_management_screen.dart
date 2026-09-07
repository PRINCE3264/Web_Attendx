import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/hr_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

class ProjectsManagementScreen extends StatefulWidget {
  final bool isEmbedded;

  const ProjectsManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<ProjectsManagementScreen> createState() =>
      _ProjectsManagementScreenState();
}

class _ProjectsManagementScreenState extends State<ProjectsManagementScreen> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedDeptFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hrProvider = Provider.of<HrProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isAdmin = currentUser?.role == UserRole.admin;

    final allProjects = hrProvider.projects;

    // Filter projects
    final filteredProjects = allProjects.where((proj) {
      // Role-based visibility
      if (currentUser != null && (currentUser.role == UserRole.employee || currentUser.role == UserRole.manager)) {
        final isAssigned =
            proj.projectId == currentUser.assignedProjectId ||
            (currentUser.assignedProjectName != null &&
                currentUser.assignedProjectName!.isNotEmpty &&
                proj.projectName.toLowerCase() == currentUser.assignedProjectName!.toLowerCase()) ||
            proj.assignedEmployeeIds.contains(currentUser.userId) ||
            proj.assignedEmployeeIds.contains(currentUser.employeeId) ||
            proj.assignedLeadId == currentUser.userId ||
            proj.assignedLeadId == currentUser.employeeId;
        if (!isAssigned) return false;
      }

      final leadName = proj.assignedLeadName ?? '';
      final matchesSearch =
          proj.projectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          proj.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          leadName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          proj.department.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatusFilter == 'All' ||
          proj.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      final matchesDept =
          _selectedDeptFilter == 'All' ||
          proj.department.toLowerCase() == _selectedDeptFilter.toLowerCase();

      return matchesSearch && matchesStatus && matchesDept;
    }).toList();

    // Calculate stats
    final totalCount = filteredProjects.length;
    final activeCount = filteredProjects
        .where((p) => p.status == 'active')
        .length;
    final completedCount = filteredProjects
        .where((p) => p.status == 'completed')
        .length;
    final onHoldCount = filteredProjects
        .where((p) => p.status == 'on_hold' || p.status == 'planning')
        .length;

    // Available departments
    final departments = <String>{
      'All',
      ...allProjects.map((p) => p.department),
    };
    if (!departments.contains(_selectedDeptFilter)) {
      _selectedDeptFilter = 'All';
    }

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title & subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin
                          ? 'Project Master Directory'
                          : (currentUser?.role == UserRole.manager
                                ? 'My Managed Projects'
                                : 'My Assigned Projects'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAdmin
                          ? 'Manage company projects, leads, target schedules, and team assignments.'
                          : (currentUser?.role == UserRole.employee
                                ? 'View your assigned projects, team leads, and schedules.'
                                : 'Browse active company projects, team leads, schedules, and departments.'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                ElevatedButton.icon(
                  onPressed: () =>
                      _openProjectBottomSheet(context, hrProvider, currentUser),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('New Project'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (currentUser?.role == UserRole.manager ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (currentUser?.role == UserRole.manager ? Colors.green : Colors.blue).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentUser?.role == UserRole.manager
                            ? Icons.group_add_rounded
                            : Icons.lock_outline_rounded,
                        size: 14,
                        color: currentUser?.role == UserRole.manager ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentUser?.role == UserRole.manager
                            ? 'TL · Team Assign Enabled'
                            : currentUser?.role == UserRole.hr
                            ? 'HR · View Only'
                            : 'Employee · View Only',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: currentUser?.role == UserRole.manager ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Read-Only / TL Info Banner
          if (!isAdmin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: (currentUser?.role == UserRole.manager ? Colors.green : Colors.blue).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (currentUser?.role == UserRole.manager ? Colors.green : Colors.blue).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    currentUser?.role == UserRole.manager
                        ? Icons.group_add_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: currentUser?.role == UserRole.manager ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentUser?.role == UserRole.manager
                          ? 'As Team Lead (TL), click "Assign Team" on any project card to assign or update team member allocations.'
                          : 'You have read-only access to the Project Directory. Contact Admin to make changes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: currentUser?.role == UserRole.manager
                            ? (isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32))
                            : (isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0)),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // KPI Stats Cards
          Builder(
            builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              return GridView.count(
                crossAxisCount: isMobile ? 2 : 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: isMobile ? 1.4 : 1.7,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    context,
                    title: 'Total Projects',
                    value: '$totalCount',
                    icon: Icons.folder_special_rounded,
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Active Running',
                    value: '$activeCount',
                    icon: Icons.bolt_rounded,
                    color: Colors.green,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Completed',
                    value: '$completedCount',
                    icon: Icons.check_circle_rounded,
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    context,
                    title: 'On Hold / Planning',
                    value: '$onHoldCount',
                    icon: Icons.pause_circle_rounded,
                    color: const Color(0xFFFF8F00),
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Search & Filter controls bar
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFEEEEEE),
              ),
            ),
            color: isDark ? const Color(0xFF212121) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar (Row 1 - Full Width)
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText:
                          'Search by title, description, lead, department...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFFE0E0E0),
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF303030) : const Color(0xFFFAFAFA),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Department Dropdown Filter (Row 2 - Full Width)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white24 : const Color(0xFFE0E0E0),
                      ),
                      color: isDark ? const Color(0xFF303030) : const Color(0xFFFAFAFA),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDeptFilter,
                        isExpanded: true,
                        icon: const Icon(Icons.filter_list_rounded, size: 20),
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDeptFilter = val);
                          }
                        },
                        items: departments.map((dept) {
                          return DropdownMenuItem<String>(
                            value: dept,
                            child: Text(
                              dept == 'All'
                                  ? 'Filter by Department: All Depts'
                                  : 'Department: $dept',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Status Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip('All', 'All Status', isDark),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          'active',
                          'Active',
                          isDark,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          'completed',
                          'Completed',
                          isDark,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          'on_hold',
                          'On Hold',
                          isDark,
                          color: const Color(0xFFFF8F00),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          'planning',
                          'Planning',
                          isDark,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Projects List / Grid
          if (filteredProjects.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? const Color(0xFF212121) : const Color(0xFFFAFAFA),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off_rounded,
                    size: 64,
                    color: isDark ? const Color(0xFF757575) : const Color(0xFFBDBDBD),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Projects Found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty || _selectedStatusFilter != 'All'
                        ? 'Try adjusting your search query or status filter.'
                        : 'Click "New Project" to add the first company project.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            )
          else
            Builder(
              builder: (context) {
                final isWide = MediaQuery.of(context).size.width > 850;
                if (isWide) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 240,
                        ),
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      return _buildProjectCard(
                        context,
                        filteredProjects[index],
                        hrProvider,
                        currentUser,
                        isDark,
                      );
                    },
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredProjects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildProjectCard(
                      context,
                      filteredProjects[index],
                      hrProvider,
                      currentUser,
                      isDark,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Project Management')),
      body: body,
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212121) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String key,
    String label,
    bool isDark, {
    Color? color,
  }) {
    final isSelected = _selectedStatusFilter == key;
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF424242)),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      selectedColor: activeColor,
      backgroundColor: isDark ? const Color(0xFF303030) : const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? activeColor
              : (isDark ? Colors.white12 : const Color(0xFFE0E0E0)),
        ),
      ),
      onSelected: (_) {
        setState(() => _selectedStatusFilter = key);
      },
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    ProjectModel project,
    HrProvider hrProvider,
    UserModel? currentUser,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    Color statusColor;
    String statusLabel;
    switch (project.status) {
      case 'completed':
        statusColor = Colors.blue;
        statusLabel = 'Completed';
        break;
      case 'on_hold':
        statusColor = const Color(0xFFFF8F00);
        statusLabel = 'On Hold';
        break;
      case 'planning':
        statusColor = const Color(0xFF0EA5E9);
        statusLabel = 'Planning';
        break;
      case 'active':
      default:
        statusColor = Colors.green;
        statusLabel = 'Active';
        break;
    }

    // Reports submitted for this project
    final projectReports = hrProvider.getReportsForProject(project.projectName);

    final startDateStr = DateFormat('MMM dd, yyyy').format(project.startDate);
    final targetDateStr = project.targetDate != null
        ? DateFormat('MMM dd, yyyy').format(project.targetDate!)
        : 'Ongoing';

    final leadName = project.assignedLeadName ?? 'Unassigned';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212121) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Title + Status + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            project.projectName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.department,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons: Edit & Delete (Admin only)
              if (currentUser?.role == UserRole.admin) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Project',
                  onPressed: () => _openProjectBottomSheet(
                    context,
                    hrProvider,
                    currentUser,
                    existingProject: project,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  tooltip: 'Delete Project',
                  onPressed: () => _confirmDeleteProject(
                    context,
                    hrProvider,
                    project,
                    currentUser,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            project.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 16),

          // Details row: Lead, Dates, Reports, Members
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lead Info
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            leadName.isNotEmpty ? leadName[0].toUpperCase() : 'L',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            leadName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF424242),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date Range
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$startDateStr - $targetDateStr',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Report Badge Count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF424242) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_rounded,
                          size: 12,
                          color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF616161),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${projectReports.length} Reports',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Assigned Members chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_rounded,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.assignedEmployeeIds.length} Members',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Assign Team Members Button for TL & Admin
                  if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.manager)
                    InkWell(
                      onTap: () => _openAssignMembersSheet(
                        context,
                        hrProvider,
                        currentUser,
                        project,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Assign Team',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Open Create/Edit Project BottomSheet Modal
  void _openProjectBottomSheet(
    BuildContext context,
    HrProvider hrProvider,
    UserModel? currentUser, {
    ProjectModel? existingProject,
  }) {
    final isEditing = existingProject != null;
    final nameController = TextEditingController(
      text: existingProject?.projectName ?? '',
    );
    final descController = TextEditingController(
      text: existingProject?.description ?? '',
    );
    final deptController = TextEditingController(
      text: existingProject?.department ?? 'Engineering',
    );

    String selectedStatus = existingProject?.status ?? 'active';
    String selectedLeadId = existingProject?.assignedLeadId ?? '';
    String selectedLeadName = existingProject?.assignedLeadName ?? '';

    DateTime startDate = existingProject?.startDate ?? DateTime.now();
    DateTime? targetDate =
        existingProject?.targetDate ??
        DateTime.now().add(const Duration(days: 90));

    // Get list of potential project leads (Managers/TLs/Admins)
    final allUsers = hrProvider.filteredEmployees;
    if (selectedLeadId.isEmpty && allUsers.isNotEmpty) {
      selectedLeadId = allUsers.first.userId;
      selectedLeadName = allUsers.first.name;
    }

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF212121) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF616161)
                                  : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          isEditing
                              ? 'Edit Project Details'
                              : 'Create New Project',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Project Name Input
                        TextFormField(
                          controller: nameController,
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Project name is required'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Project Name *',
                            hintText: 'e.g. Attendance AI Engine v2',
                            prefixIcon: const Icon(Icons.folder_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description Input
                        TextFormField(
                          controller: descController,
                          maxLines: 3,
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Description is required'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Project Description *',
                            hintText: 'Describe key milestones, goals, and tech stack...',
                            prefixIcon: const Icon(Icons.description_outlined),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Department & Status row
                        Row(
                          children: [
                            // Department
                            Expanded(
                              child: TextFormField(
                                controller: deptController,
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'Department required'
                                    : null,
                                decoration: InputDecoration(
                                  labelText: 'Department *',
                                  hintText: 'e.g. Engineering',
                                  prefixIcon: const Icon(Icons.domain_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Status Dropdown
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: selectedStatus,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  prefixIcon: const Icon(Icons.flag_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Active', overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text('Completed', overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'on_hold',
                                    child: Text('On Hold', overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'planning',
                                    child: Text('Planning', overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedStatus = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Assigned Project Lead Dropdown
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue:
                              selectedLeadId.isNotEmpty &&
                                  allUsers.any(
                                    (u) => u.userId == selectedLeadId,
                                  )
                              ? selectedLeadId
                              : (allUsers.isNotEmpty
                                    ? allUsers.first.userId
                                    : null),
                          decoration: InputDecoration(
                            labelText: 'Assigned Project Lead / Manager',
                            prefixIcon: const Icon(Icons.person_pin_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: allUsers.map((u) {
                            return DropdownMenuItem<String>(
                              value: u.userId,
                              child: Text(
                                '${u.name} (${u.role.name.toUpperCase()})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final leadUser = allUsers.firstWhere(
                                (u) => u.userId == val,
                              );
                              setModalState(() {
                                selectedLeadId = leadUser.userId;
                                selectedLeadName = leadUser.name;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date Pickers Row
                        Row(
                          children: [
                            // Start Date
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setModalState(() => startDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Start Date',
                                    prefixIcon: const Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    DateFormat('yyyy-MM-dd').format(startDate),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Target Date
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        targetDate ??
                                        DateTime.now().add(
                                          const Duration(days: 90),
                                        ),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setModalState(() => targetDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Target Date',
                                    prefixIcon: const Icon(
                                      Icons.event_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    targetDate != null
                                        ? DateFormat('yyyy-MM-dd')
                                              .format(targetDate!)
                                        : 'Select Date',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final projId = isEditing
                                  ? existingProject.projectId
                                  : 'proj_${DateTime.now().millisecondsSinceEpoch}';

                              final newProj = ProjectModel(
                                projectId: projId,
                                projectName: nameController.text.trim(),
                                description: descController.text.trim(),
                                department: deptController.text.trim(),
                                status: selectedStatus,
                                startDate: startDate,
                                targetDate: targetDate,
                                assignedLeadId: selectedLeadId,
                                assignedLeadName: selectedLeadName,
                                assignedEmployeeIds: existingProject?.assignedEmployeeIds ?? [],
                                createdAt:
                                    existingProject?.createdAt ??
                                    DateTime.now(),
                              );

                              if (currentUser != null) {
                                if (isEditing) {
                                  await hrProvider.updateProject(
                                    newProj,
                                    currentUser,
                                  );
                                } else {
                                  await hrProvider.createProject(
                                    newProj,
                                    currentUser,
                                  );
                                }
                              }

                              if (context.mounted) {
                                Navigator.pop(bottomSheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Project "${newProj.projectName}" updated successfully!'
                                          : 'Project "${newProj.projectName}" created successfully!',
                                    ),
                                    backgroundColor: const Color(0xFF388E3C),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Save Changes' : 'Create Project',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Delete project prompt
  void _confirmDeleteProject(
    BuildContext context,
    HrProvider hrProvider,
    ProjectModel project,
    UserModel? currentUser,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Project'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete project "${project.projectName}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (currentUser != null) {
                  await hrProvider.deleteProject(
                    project.projectId,
                    currentUser,
                  );
                }
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Project "${project.projectName}" deleted.',
                      ),
                      backgroundColor: const Color(0xFFD32F2F),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _openAssignMembersSheet(
    BuildContext context,
    HrProvider hrProvider,
    UserModel? currentUser,
    ProjectModel project,
  ) {
    final allUsers = hrProvider.allEmployees;
    final isTL = currentUser?.role == UserRole.manager;

    List<UserModel> candidates;
    if (isTL && currentUser != null) {
      final teamMembers = allUsers.where((e) {
        final assignedByManagerId =
            e.managerId == currentUser.userId ||
            (currentUser.employeeId.isNotEmpty && e.managerId == currentUser.employeeId) ||
            (currentUser.name.isNotEmpty && e.managerId == currentUser.name) ||
            (currentUser.email.isNotEmpty && e.managerId == currentUser.email);
        final assignedByManagerName =
            e.managerName != null &&
            e.managerName!.isNotEmpty &&
            e.managerName!.trim().toLowerCase() == currentUser.name.trim().toLowerCase();
        final sameTeam = e.teamId.isNotEmpty && e.teamId == currentUser.teamId;
        return assignedByManagerId || assignedByManagerName || sameTeam;
      }).toList();

      if (teamMembers.isNotEmpty) {
        candidates = teamMembers;
      } else {
        candidates = allUsers.where((e) => e.role == UserRole.employee).toList();
      }
    } else {
      candidates = allUsers.where((e) => e.role == UserRole.employee || e.role == UserRole.manager).toList();
    }

    final Set<String> selectedEmployeeIds = Set<String>.from(project.assignedEmployeeIds);
    String memberSearch = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            final isDark = theme.brightness == Brightness.dark;

            final filteredCandidates = candidates.where((c) {
              final q = memberSearch.toLowerCase().trim();
              if (q.isEmpty) return true;
              return c.name.toLowerCase().contains(q) ||
                  c.employeeId.toLowerCase().contains(q) ||
                  c.department.toLowerCase().contains(q);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF212121) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF616161)
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.group_add_rounded,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assign Team Members',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Project: ${project.projectName} (${selectedEmployeeIds.length} Assigned)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      onChanged: (val) => setModalState(() => memberSearch = val),
                      decoration: InputDecoration(
                        hintText: 'Search team member by name or ID...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: filteredCandidates.isEmpty
                          ? Center(
                              child: Text(
                                'No matching team members found.',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredCandidates.length,
                              itemBuilder: (ctx, idx) {
                                final emp = filteredCandidates[idx];
                                final isAssigned = selectedEmployeeIds.contains(emp.userId) ||
                                    (emp.employeeId.isNotEmpty && selectedEmployeeIds.contains(emp.employeeId));

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isAssigned
                                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                        : (isDark ? const Color(0xFF303030) : const Color(0xFFFAFAFA)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isAssigned
                                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                                          : (isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    value: isAssigned,
                                    activeColor: theme.colorScheme.primary,
                                    title: Text(
                                      emp.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: ${emp.employeeId} • ${emp.department} • Assigned: ${emp.assignedProjectName ?? 'Unassigned'}',
                                      style: const TextStyle(fontSize: 11.5),
                                    ),
                                    secondary: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                      child: Text(
                                        emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setModalState(() {
                                        if (val == true) {
                                          selectedEmployeeIds.add(emp.userId);
                                          if (emp.employeeId.isNotEmpty) {
                                            selectedEmployeeIds.add(emp.employeeId);
                                          }
                                        } else {
                                          selectedEmployeeIds.remove(emp.userId);
                                          selectedEmployeeIds.remove(emp.employeeId);
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final updatedProject = project.copyWith(
                            assignedEmployeeIds: selectedEmployeeIds.toList(),
                          );

                          if (currentUser != null) {
                            await hrProvider.updateProject(updatedProject, currentUser);

                            for (final empId in selectedEmployeeIds) {
                              await hrProvider.assignProjectToEmployee(empId, project.projectName);
                            }
                          }

                          if (context.mounted) {
                            Navigator.pop(bottomSheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Team member assignments updated for "${project.projectName}"!',
                                ),
                                backgroundColor: const Color(0xFF388E3C),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          'SAVE TEAM ASSIGNMENTS (${selectedEmployeeIds.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }
}
