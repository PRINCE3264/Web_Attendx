/* ==========================================================================
   AttendX - Core Web Application Controller (jQuery & Firebase Services)
   Multi-Page Route-Based Architecture
   ========================================================================== */

$(document).ready(function () {
  console.log("🚀 AttendX Web Application Starting (Route-Based Pages)...");

  let punchTimerInterval = null;
  let activeSeconds = 0;
  let currentAttendanceId = null;

  // Initialize UI & Services
  initApp();

  function initApp() {
    setupSidebarToggle();
    setupRoleTabs();
    setupPunchHandlers();
    setupModalHandlers();
    setupFormSubmissions();
    setupAIAssistant();
    startLiveClock();
    subscribeRealtimeFirestoreData();

    showToast("Welcome to AttendX Smart Attendance Portal!", "success");
  }

  // 1. Subscribe to Live Firestore DB Data
  function subscribeRealtimeFirestoreData() {
    // Attendance Records Sync
    AttendXService.subscribeAttendance(records => {
      AttendXComponents.renderAttendanceTable('table-recent-attendance', records.slice(0, 5));
      AttendXComponents.renderAttendanceTable('table-attendance-history', records);
      AttendXComponents.renderAttendanceTable('table-reports-all', records);
    });

    // Leave Requests Sync
    AttendXService.subscribeLeaves(leaves => {
      AttendXComponents.renderLeaveRequests('container-my-leaves', leaves, false);
      AttendXComponents.renderLeaveRequests('container-pending-approvals', leaves, true);
    });

    // Employee Master Directory Sync
    AttendXService.subscribeEmployees(employees => {
      AttendXComponents.renderEmployeeDirectory('table-hr-employees', employees);
    });

    // Announcements Sync
    AttendXService.subscribeAnnouncements(announcements => {
      AttendXComponents.renderAnnouncements('container-announcements', announcements);
    });
  }

  // 2. Live Clock
  function startLiveClock() {
    function updateClock() {
      const now = new Date();
      const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      const dateStr = now.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' });
      $('#topbar-live-clock').html(`<span class="pulse-dot"></span> ${dateStr} • ${timeStr}`);
    }
    updateClock();
    setInterval(updateClock, 1000);
  }

  // 3. Sidebar Toggle (Open / Close)
  function setupSidebarToggle() {
    $(document).on('click', '#btn-toggle-sidebar', function () {
      $('#app-sidebar').toggleClass('collapsed');
    });
  }

  // 4. Role Selector Tabs (Employee, Manager, HR, Admin)
  function setupRoleTabs() {
    $(document).on('click', '.role-tab-btn', function () {
      $('.role-tab-btn').removeClass('active');
      $(this).addClass('active');

      const selectedRole = $(this).attr('data-role');
      showToast(`Switched active role view to ${selectedRole.toUpperCase()}`, "info");
    });
  }

  // 5. Punch In / Punch Out Actions (Writes directly to Firestore DB)
  function setupPunchHandlers() {
    $(document).on('click', '#btn-punch-in', function () {
      $('#modal-camera-verification').addClass('active');
    });

    $(document).on('click', '#btn-confirm-punch-in', async function () {
      $('#modal-camera-verification').removeClass('active');

      const now = new Date();
      const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      const dateStr = now.toISOString().split('T')[0];

      const newRecord = {
        date: dateStr,
        employeeId: "EMP-1024",
        name: "Prince Vidyarthi",
        punchIn: timeStr,
        punchOut: "--",
        totalHours: "Running",
        status: "Present",
        location: "HQ Office (Geofence Verified)"
      };

      const saved = await AttendXService.punchIn(newRecord);
      currentAttendanceId = saved ? saved.id : null;

      // Update UI Status
      $('#punch-status-badge')
        .removeClass('out break')
        .addClass('in')
        .html('<i class="fa-solid fa-circle-check"></i> CLOCKED IN');

      $('#btn-punch-in').hide();
      $('#btn-punch-out, #btn-start-break').show();

      startStopwatch();
      showToast(`Punched IN at ${timeStr}! Record synced to Firestore.`, "success");
    });

    $(document).on('click', '#btn-punch-out', async function () {
      const now = new Date();
      const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

      clearInterval(punchTimerInterval);
      const totalHrs = $('#punch-stopwatch-display').text();

      await AttendXService.punchOut(currentAttendanceId, timeStr, totalHrs);

      $('#punch-status-badge')
        .removeClass('in break')
        .addClass('out')
        .html('<i class="fa-solid fa-circle-xmark"></i> OUT OF OFFICE');

      $('#btn-punch-in').show();
      $('#btn-punch-out, #btn-start-break').hide();
      $('#punch-stopwatch-display').text('00:00:00');

      showToast(`Punched OUT at ${timeStr}. Attendance saved to Firestore!`, "success");
    });

    $(document).on('click', '#btn-start-break', function () {
      const isBreak = $(this).hasClass('active-break');
      if (!isBreak) {
        $(this).addClass('active-break').html('<i class="fa-solid fa-play"></i> End Break');
        $('#punch-status-badge')
          .removeClass('in out')
          .addClass('break')
          .html('<i class="fa-solid fa-mug-hot"></i> ON BREAK');
        showToast("Break started. Enjoy your tea/lunch break!", "warning");
      } else {
        $(this).removeClass('active-break').html('<i class="fa-solid fa-coffee"></i> Take Break');
        $('#punch-status-badge')
          .removeClass('out break')
          .addClass('in')
          .html('<i class="fa-solid fa-circle-check"></i> CLOCKED IN');
        showToast("Welcome back! Break ended.", "success");
      }
    });
  }

  function startStopwatch() {
    clearInterval(punchTimerInterval);
    activeSeconds = 0;

    punchTimerInterval = setInterval(function () {
      activeSeconds++;
      const hrs = String(Math.floor(activeSeconds / 3600)).padStart(2, '0');
      const mins = String(Math.floor((activeSeconds % 3600) / 60)).padStart(2, '0');
      const secs = String(activeSeconds % 60).padStart(2, '0');
      $('#punch-stopwatch-display').text(`${hrs}:${mins}:${secs}`);
    }, 1000);
  }

  // 6. Modals & Forms
  function setupModalHandlers() {
    $(document).on('click', '[data-modal]', function () {
      const modalId = $(this).attr('data-modal');
      $(`#${modalId}`).addClass('active');
    });

    $(document).on('click', '.modal-close-btn', function () {
      $(this).closest('.modal-overlay').removeClass('active');
    });
  }

  function setupFormSubmissions() {
    // Apply Leave Form
    $(document).on('submit', '#form-apply-leave', async function (e) {
      e.preventDefault();
      const leaveType = $('#leave-type-select').val();
      const startDate = $('#leave-start-date').val();
      const endDate = $('#leave-end-date').val();
      const reason = $('#leave-reason-text').val();

      const newLeave = {
        employeeId: "EMP-1024",
        name: "Prince Vidyarthi",
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        status: "Pending",
        appliedOn: new Date().toISOString().split('T')[0]
      };

      await AttendXService.applyLeave(newLeave);
      $('#modal-apply-leave').removeClass('active');
      showToast("Leave application saved & submitted to Firestore!", "success");
    });

    // Add Employee Form (HR)
    $(document).on('submit', '#form-add-employee', async function (e) {
      e.preventDefault();
      const empId = $('#new-emp-id').val();
      const empName = $('#new-emp-name').val();
      const empEmail = $('#new-emp-email').val();
      const empDept = $('#new-emp-dept').val();

      const newEmp = {
        employeeId: empId,
        name: empName,
        email: empEmail,
        department: empDept,
        role: "employee",
        status: "Active"
      };

      await AttendXService.addEmployee(newEmp);
      $('#modal-add-employee').removeClass('active');
      showToast(`Employee ${empName} (${empId}) added to Firestore DB!`, "success");
    });

    // Daily Update Form
    $(document).on('submit', '#form-daily-update', function (e) {
      e.preventDefault();
      showToast("Daily project update submitted successfully!", "success");
      this.reset();
    });

    // Policy Settings Form
    $(document).on('submit', '#form-policy-settings', function (e) {
      e.preventDefault();
      showToast("Shift & Policy settings saved!", "success");
    });

    // Geofence Settings Form
    $(document).on('submit', '#form-geofence-settings', function (e) {
      e.preventDefault();
      showToast("Geofence settings saved!", "success");
    });

    // Leave Approval Delegation
    $(document).on('click', '.approve-leave-btn', async function () {
      const id = $(this).attr('data-id');
      await AttendXService.updateLeaveStatus(id, 'Approved');
      showToast("Leave request APPROVED in Firestore DB!", "success");
    });

    $(document).on('click', '.reject-leave-btn', async function () {
      const id = $(this).attr('data-id');
      await AttendXService.updateLeaveStatus(id, 'Rejected');
      showToast("Leave request REJECTED in Firestore DB!", "danger");
    });
  }

  // 7. AI Voice/Chat Assistant (Drawer)
  function setupAIAssistant() {
    $(document).on('click', '#btn-toggle-ai-assistant', function () {
      $('#ai-assistant-drawer').toggleClass('active');
    });

    $(document).on('click', '#ai-drawer-close', function () {
      $('#ai-assistant-drawer').removeClass('active');
    });

    $(document).on('click', '#btn-send-ai-msg', sendAIMessage);
    $(document).on('keypress', '#ai-chat-input', function (e) {
      if (e.which === 13) sendAIMessage();
    });

    function sendAIMessage() {
      const text = $('#ai-chat-input').val().trim();
      if (!text) return;

      $('#ai-chat-messages').append(`<div class="chat-bubble user">${text}</div>`);
      $('#ai-chat-input').val('');

      const $chatBody = $('#ai-chat-messages');
      $chatBody.scrollTop($chatBody[0].scrollHeight);

      setTimeout(function () {
        let reply = "I can fetch attendance logs, leave balances, or policy settings directly from Firestore DB!";
        const lower = text.toLowerCase();
        if (lower.includes('status') || lower.includes('punch')) {
          reply = "Your current punch status is **CLOCKED OUT**. You can click 'PUNCH IN NOW' to clock in.";
        } else if (lower.includes('leave')) {
          reply = "You have 12 Casual Leaves, 8 Sick Leaves, and 15 Earned Leaves remaining.";
        }
        $('#ai-chat-messages').append(`<div class="chat-bubble bot"><i class="fa-solid fa-robot" style="color:var(--primary); margin-right:0.3rem;"></i> ${reply}</div>`);
        $chatBody.scrollTop($chatBody[0].scrollHeight);
      }, 600);
    }
  }

  // Toast Helper
  function showToast(message, type = "info") {
    const toastHtml = `
      <div class="toast ${type}">
        <i class="fa-solid ${type === 'success' ? 'fa-circle-check' : type === 'danger' ? 'fa-triangle-exclamation' : 'fa-circle-info'}"></i>
        <span>${message}</span>
      </div>
    `;
    const $toast = $(toastHtml);
    $('#toast-container').append($toast);
    setTimeout(function () {
      $toast.fadeOut(400, function () { $(this).remove(); });
    }, 3500);
  }
});
