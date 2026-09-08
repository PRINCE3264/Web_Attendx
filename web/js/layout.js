/* ==========================================================================
   AttendX - Shared Layout Builder (layout.js)
   Dynamically generates sidebar, topbar, AI drawer, modals & toast container.
   Each page only needs its unique content; this file builds the shell.
   ========================================================================== */

const AttendXLayout = (function () {

  // Sidebar navigation items config
  const NAV_ITEMS = [
    { id: 'dashboard',        icon: 'fa-solid fa-border-all',        label: 'Clock & Today',          page: 'dashboard.html' },
    { id: 'attendance',       icon: 'fa-solid fa-calendar-days',     label: 'My Attendance',          page: 'attendance.html' },
    { id: 'break-tracker',    icon: 'fa-solid fa-mug-hot',           label: 'Break Tracker',          page: 'break-tracker.html' },
    { id: 'leaves',           icon: 'fa-solid fa-umbrella',          label: 'Leave Management',       page: 'leaves.html' },
    { id: 'daily-update',     icon: 'fa-solid fa-clipboard-check',   label: 'Daily Project Update',   page: 'daily-update.html' },
    { id: 'project-reports',  icon: 'fa-solid fa-folder-closed',     label: 'Project Work Reports',   page: 'project-reports.html' },
    { id: 'my-projects',      icon: 'fa-solid fa-folder-open',       label: 'My Projects',            page: 'my-projects.html' },
    { id: 'settings',         icon: 'fa-solid fa-gear',              label: 'System Settings',        page: 'settings.html' },
    { id: 'ai-chatbot',       icon: 'fa-solid fa-robot',             label: 'AI Chatbot',             page: 'ai-chatbot.html',  badge: 'AI' },
    { id: 'profile',          icon: 'fa-regular fa-user',            label: 'My Profile',             page: 'profile.html' },
  ];

  // Detect current page from URL
  function getCurrentPage() {
    const path = window.location.pathname;
    const filename = path.substring(path.lastIndexOf('/') + 1);
    return filename || 'dashboard.html';
  }

  // Build sidebar HTML
  function buildSidebar() {
    const currentPage = getCurrentPage();
    
    let navItemsHtml = '';
    NAV_ITEMS.forEach(item => {
      const isActive = (currentPage === item.page) ? ' active' : '';
      const badgeHtml = item.badge ? `<span class="ai-badge-pill">${item.badge}</span>` : '';
      navItemsHtml += `
        <li class="nav-item${isActive}">
          <a href="${item.page}">
            <i class="${item.icon}"></i>
            <span>${item.label}</span>
            ${badgeHtml}
          </a>
        </li>`;
    });

    // Get logged-in user info
    const user = (typeof AttendXAuth !== 'undefined') ? AttendXAuth.getCurrentUser() : null;
    const userName = user ? user.name.toUpperCase() : 'GUEST USER';
    const userRole = user ? user.role.toUpperCase() : 'EMPLOYEE';
    const userDept = user ? user.department : 'General';
    const userInitial = user ? user.name.charAt(0).toUpperCase() : 'G';

    return `
    <aside class="sidebar" id="app-sidebar">
      <div>
        <div class="sidebar-profile-header">
          <div class="company-badge-pill">Envision Beyond</div>
          <div class="profile-avatar-circle">${userInitial}</div>
          <div class="profile-user-name">${userName}</div>
          <div class="profile-user-sub">${userRole} • ${userDept}</div>
        </div>
        <ul class="nav-menu">
          ${navItemsHtml}
        </ul>
      </div>
      <div class="sidebar-logout-btn" id="btn-sidebar-logout">
        <i class="fa-solid fa-right-from-bracket"></i>
        <span>Logout</span>
      </div>
    </aside>`;
  }

  // Build topbar HTML
  function buildTopbar(pageTitle) {
    return `
    <header class="topbar">
      <div class="topbar-left">
        <button class="top-action-btn" id="btn-toggle-sidebar" title="Toggle Sidebar" style="margin-right: 1rem;">
          <i class="fa-solid fa-bars"></i>
        </button>
        <h2 class="page-header-title" id="page-title-text">${pageTitle}</h2>
        <div class="live-clock-badge" id="topbar-live-clock">
          <span class="pulse-dot"></span> Loading Clock...
        </div>
      </div>
      <div class="topbar-right">
        <div class="role-tabs">
          <button class="role-tab-btn active" data-role="employee">Employee</button>
          <button class="role-tab-btn" data-role="manager">Manager / TL</button>
          <button class="role-tab-btn" data-role="hr">HR Admin</button>
          <button class="role-tab-btn" data-role="admin">System Admin</button>
        </div>
        <button class="top-action-btn" id="btn-toggle-ai-assistant" title="AttendX AI Assistant">
          <i class="fa-solid fa-robot" style="color: var(--primary);"></i>
        </button>
        <button class="top-action-btn" id="btn-notifications" title="Notifications">
          <i class="fa-regular fa-bell"></i>
          <span class="notification-count">3</span>
        </button>
      </div>
    </header>`;
  }

  // Build modals HTML
  function buildModals() {
    return `
    <div class="modal-overlay" id="modal-camera-verification">
      <div class="modal-content">
        <div class="modal-header">
          <h3 class="modal-title"><i class="fa-solid fa-camera" style="color: var(--primary);"></i> Selfie & Location Verification</h3>
          <button class="modal-close-btn">&times;</button>
        </div>
        <div style="text-align: center; padding: 2rem; background: var(--bg-secondary); border-radius: var(--radius-md); margin-bottom: 1.5rem;">
          <i class="fa-solid fa-user-check" style="font-size: 3.5rem; color: var(--accent-emerald); margin-bottom: 0.75rem;"></i>
          <h4>Biometric Photo & Geofence Verified</h4>
          <p style="font-size: 0.85rem; color: var(--text-muted); margin-top: 0.25rem;">HQ Office</p>
        </div>
        <button class="btn btn-primary" id="btn-confirm-punch-in" style="width: 100%;">
          <i class="fa-solid fa-check-circle"></i> Confirm Punch In
        </button>
      </div>
    </div>
    <div class="modal-overlay" id="modal-apply-leave">
      <div class="modal-content">
        <div class="modal-header">
          <h3 class="modal-title"><i class="fa-solid fa-umbrella" style="color: var(--primary);"></i> Apply for Leave</h3>
          <button class="modal-close-btn">&times;</button>
        </div>
        <form id="form-apply-leave">
          <div class="form-group">
            <label>Leave Type</label>
            <select class="form-control" id="leave-type-select" required>
              <option value="Casual Leave">Casual Leave</option>
              <option value="Sick Leave">Sick Leave</option>
              <option value="Earned Leave">Earned Leave</option>
            </select>
          </div>
          <div style="display: flex; gap: 1rem;">
            <div class="form-group" style="flex: 1;"><label>Start Date</label><input type="date" class="form-control" id="leave-start-date" required></div>
            <div class="form-group" style="flex: 1;"><label>End Date</label><input type="date" class="form-control" id="leave-end-date" required></div>
          </div>
          <div class="form-group">
            <label>Reason</label>
            <textarea class="form-control" id="leave-reason-text" placeholder="Reason for leave..." required></textarea>
          </div>
          <button type="submit" class="btn btn-primary" style="width: 100%;">Submit Leave Application</button>
        </form>
      </div>
    </div>`;
  }

  // Build AI Assistant Drawer
  function buildAIDrawer() {
    return `
    <div class="ai-assistant-drawer" id="ai-assistant-drawer">
      <div class="ai-drawer-header">
        <div style="display: flex; align-items: center; gap: 0.5rem;">
          <i class="fa-solid fa-robot" style="font-size: 1.25rem; color: var(--primary);"></i>
          <div>
            <h4 style="font-size: 0.95rem;">AttendX AI Assistant</h4>
            <span style="font-size: 0.7rem; color: var(--accent-emerald);">● Firestore Connected</span>
          </div>
        </div>
        <button class="modal-close-btn" id="ai-drawer-close">&times;</button>
      </div>
      <div class="ai-chat-body" id="ai-chat-messages">
        <div class="chat-bubble bot">Hello Prince! I am your AttendX AI Assistant. How can I help today?</div>
      </div>
      <div class="ai-chat-input-area">
        <input type="text" class="form-control" id="ai-chat-input" placeholder="Ask AI assistant...">
        <button class="btn btn-primary" id="btn-send-ai-msg"><i class="fa-solid fa-paper-plane"></i></button>
      </div>
    </div>`;
  }

  /**
   * Initialize the full page layout.
   * @param {string} pageTitle - The title shown in the topbar
   */
  function init(pageTitle) {
    // Auth guard — redirect to login if not authenticated
    if (typeof AttendXAuth !== 'undefined') {
      if (!AttendXAuth.requireAuth()) return;
    }

    const $appContainer = $('#app-container');

    // Insert sidebar before main-wrapper
    $appContainer.prepend(buildSidebar());

    // Insert topbar at the start of main-wrapper
    $('.main-wrapper').prepend(buildTopbar(pageTitle));

    // Append modals, AI drawer, and toast container to body
    $('body').append(buildModals());
    $('body').append(buildAIDrawer());
    $('body').append('<div class="toast-container" id="toast-container"></div>');

    // Logout button handler
    $(document).on('click', '#btn-sidebar-logout', function () {
      if (typeof AttendXAuth !== 'undefined') {
        AttendXAuth.logout();
      } else {
        window.location.href = 'login.html';
      }
    });
  }

  return { init, NAV_ITEMS, getCurrentPage };
})();
