/* ==========================================================================
   AttendX - Dynamic UI Components & Renderers (Chart.js, Tables, Modals)
   ========================================================================== */

const AttendXComponents = {
  // 1. Attendance Overview Charts (Chart.js)
  charts: {},

  initAttendanceChart: function (canvasId) {
    const ctx = document.getElementById(canvasId);
    if (!ctx) return;

    if (this.charts[canvasId]) {
      this.charts[canvasId].destroy();
    }

    this.charts[canvasId] = new Chart(ctx, {
      type: 'line',
      data: {
        labels: ['Mon (Sep 02)', 'Tue (Sep 03)', 'Wed (Sep 04)', 'Thu (Sep 05)', 'Fri (Sep 06)', 'Mon (Sep 08)'],
        datasets: [
          {
            label: 'On-Time Present',
            data: [42, 45, 44, 46, 43, 47],
            borderColor: '#10b981',
            backgroundColor: 'rgba(16, 185, 129, 0.1)',
            fill: true,
            tension: 0.4,
            borderWidth: 3
          },
          {
            label: 'Late Arrival',
            data: [5, 3, 6, 2, 4, 3],
            borderColor: '#f59e0b',
            backgroundColor: 'rgba(245, 158, 11, 0.1)',
            fill: true,
            tension: 0.4,
            borderWidth: 2
          },
          {
            label: 'Absent / On Leave',
            data: [3, 2, 0, 2, 3, 1],
            borderColor: '#f43f5e',
            backgroundColor: 'rgba(244, 63, 94, 0.1)',
            fill: true,
            tension: 0.4,
            borderWidth: 2
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: { color: '#9ca3af', font: { family: 'Inter' } }
          }
        },
        scales: {
          x: { ticks: { color: '#9ca3af' }, grid: { color: 'rgba(255, 255, 255, 0.05)' } },
          y: { ticks: { color: '#9ca3af' }, grid: { color: 'rgba(255, 255, 255, 0.05)' } }
        }
      }
    });
  },

  initDepartmentChart: function (canvasId) {
    const ctx = document.getElementById(canvasId);
    if (!ctx) return;

    if (this.charts[canvasId]) {
      this.charts[canvasId].destroy();
    }

    this.charts[canvasId] = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Engineering', 'Design', 'Marketing', 'Human Resources', 'Operations'],
        datasets: [{
          data: [25, 8, 10, 5, 12],
          backgroundColor: ['#6366f1', '#ec4899', '#f59e0b', '#10b981', '#8b5cf6'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { color: '#9ca3af' } }
        }
      }
    });
  },

  // 2. Render Attendance Logs Table
  renderAttendanceTable: function (containerId, logs) {
    const $container = $(`#${containerId}`);
    if (!$container.length) return;

    if (!logs || logs.length === 0) {
      $container.html(`<tr><td colspan="7" class="text-center text-muted">No attendance logs available.</td></tr>`);
      return;
    }

    let html = '';
    logs.forEach(log => {
      let statusClass = 'badge-success';
      if (log.status === 'Late') statusClass = 'badge-warning';
      if (log.status === 'Absent') statusClass = 'badge-danger';
      if (log.status === 'On Break') statusClass = 'badge-info';

      html += `
        <tr>
          <td><strong>${log.date}</strong></td>
          <td>
            <div style="font-weight: 600;">${log.name}</div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">${log.employeeId}</div>
          </td>
          <td><i class="fa-regular fa-clock" style="color: var(--accent-emerald);"></i> ${log.punchIn}</td>
          <td><i class="fa-regular fa-clock" style="color: var(--accent-rose);"></i> ${log.punchOut}</td>
          <td><span style="font-family: monospace;">${log.totalHours}</span></td>
          <td><span class="badge ${statusClass}">${log.status}</span></td>
          <td><i class="fa-solid fa-location-dot" style="color: var(--primary);"></i> ${log.location}</td>
        </tr>
      `;
    });

    $container.html(html);
  },

  // 3. Render Employees Directory Table
  renderEmployeeDirectory: function (containerId, employees) {
    const $container = $(`#${containerId}`);
    if (!$container.length) return;

    let html = '';
    employees.forEach(emp => {
      html += `
        <tr>
          <td><strong>${emp.employeeId}</strong></td>
          <td>
            <div style="font-weight: 600;">${emp.name}</div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">${emp.email}</div>
          </td>
          <td><span class="badge badge-purple">${emp.department}</span></td>
          <td><span class="badge badge-info" style="text-transform: capitalize;">${emp.role}</span></td>
          <td><span class="badge badge-success">${emp.status}</span></td>
          <td>
            <button class="btn btn-outline btn-sm edit-emp-btn" data-id="${emp.employeeId}">
              <i class="fa-solid fa-pen"></i> Edit
            </button>
          </td>
        </tr>
      `;
    });

    $container.html(html);
  },

  // 4. Render Leave Requests Cards / Approvals
  renderLeaveRequests: function (containerId, leaves, isApprovalMode = false) {
    const $container = $(`#${containerId}`);
    if (!$container.length) return;

    if (!leaves || leaves.length === 0) {
      $container.html(`<div class="text-center text-muted p-4">No leave applications found.</div>`);
      return;
    }

    let html = '';
    leaves.forEach(lv => {
      let statusBadge = 'badge-warning';
      if (lv.status === 'Approved') statusBadge = 'badge-success';
      if (lv.status === 'Rejected') statusBadge = 'badge-danger';

      html += `
        <div class="glass-card" style="margin-bottom: 1rem; border-left: 4px solid var(--primary);">
          <div class="card-header-flex">
            <div>
              <h4 style="font-size: 1rem; margin-bottom: 0.2rem;">${lv.leaveType}</h4>
              <span style="font-size: 0.8rem; color: var(--text-muted);">${lv.name} (${lv.employeeId}) • Applied on ${lv.appliedOn}</span>
            </div>
            <span class="badge ${statusBadge}">${lv.status}</span>
          </div>
          <div style="margin: 0.75rem 0; font-size: 0.88rem; color: var(--text-main);">
            <i class="fa-regular fa-calendar-days" style="color: var(--primary); margin-right: 0.4rem;"></i>
            <strong>${lv.startDate}</strong> to <strong>${lv.endDate}</strong>
          </div>
          <p style="font-size: 0.85rem; color: var(--text-muted); background: rgba(0,0,0,0.2); padding: 0.6rem; border-radius: var(--radius-sm);">
            "${lv.reason}"
          </p>
          ${isApprovalMode && lv.status === 'Pending' ? `
            <div style="display: flex; gap: 0.5rem; margin-top: 1rem;">
              <button class="btn btn-success btn-sm approve-leave-btn" data-id="${lv.id}">
                <i class="fa-solid fa-check"></i> Approve
              </button>
              <button class="btn btn-danger btn-sm reject-leave-btn" data-id="${lv.id}">
                <i class="fa-solid fa-xmark"></i> Reject
              </button>
            </div>
          ` : ''}
        </div>
      `;
    });

    $container.html(html);
  },

  // 5. Render Announcements Banners
  renderAnnouncements: function (containerId, announcements) {
    const $container = $(`#${containerId}`);
    if (!$container.length) return;

    let html = '';
    announcements.forEach(ann => {
      html += `
        <div class="glass-card" style="margin-bottom: 1rem; background: linear-gradient(135deg, rgba(99, 102, 241, 0.08) 0%, rgba(255,255,255,0.02) 100%);">
          <div class="card-header-flex">
            <h4 style="font-size: 1rem; color: var(--primary);"><i class="fa-solid fa-bullhorn"></i> ${ann.title}</h4>
            <span class="badge badge-info">${ann.targetRole}</span>
          </div>
          <p style="font-size: 0.88rem; color: var(--text-main); margin: 0.5rem 0;">${ann.content}</p>
          <div style="font-size: 0.75rem; color: var(--text-muted); display: flex; justify-content: space-between;">
            <span>By ${ann.author}</span>
            <span>${ann.date}</span>
          </div>
        </div>
      `;
    });

    $container.html(html);
  },

  // 6. Render Audit Logs Table
  renderAuditLogs: function (containerId, logs) {
    const $container = $(`#${containerId}`);
    if (!$container.length) return;

    let html = '';
    logs.forEach(log => {
      html += `
        <tr>
          <td><span style="font-family: monospace; font-size: 0.8rem;">${log.timestamp}</span></td>
          <td><strong>${log.user}</strong></td>
          <td><span class="badge badge-purple">${log.action}</span></td>
          <td style="color: var(--text-muted);">${log.details}</td>
        </tr>
      `;
    });

    $container.html(html);
  }
};
