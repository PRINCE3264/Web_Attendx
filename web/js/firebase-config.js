/* ==========================================================================
   AttendX - Firebase & Firestore Service Layer
   Handles real-time Firestore database read/write operations
   ========================================================================== */

// Firebase Project Credentials matching lib/firebase_options.dart
const firebaseConfig = {
  apiKey: "AIzaSyAp4leezbbQpAXQYvF1_E6ZzE1ftKqErPA",
  authDomain: "attendx-8b4c5.firebaseapp.com",
  projectId: "attendx-8b4c5",
  storageBucket: "attendx-8b4c5.firebasestorage.app",
  messagingSenderId: "1053308876013",
  appId: "1:1053308876013:web:6da806687246c8ec52c8e4",
  measurementId: "G-M2FV0YME7F"
};

let db = null;
let auth = null;
let isFirebaseConnected = false;

// Initialize Firebase
try {
  if (typeof firebase !== 'undefined') {
    if (!firebase.apps.length) {
      firebase.initializeApp(firebaseConfig);
    }
    db = firebase.firestore();
    auth = firebase.auth();
    isFirebaseConnected = true;
    console.log("🔥 Connected to Firebase Firestore DB project: attendx-8b4c5");
  }
} catch (error) {
  console.warn("⚠️ Firebase connection warning:", error);
}

/* ==========================================================================
   Firestore CRUD & Real-Time Sync Service
   ========================================================================== */
const AttendXService = {
  // 1. Fetch / Sync Attendance Records
  subscribeAttendance: function (callback) {
    if (isFirebaseConnected && db) {
      db.collection('attendance')
        .orderBy('date', 'desc')
        .onSnapshot(
          snapshot => {
            const records = [];
            snapshot.forEach(doc => {
              records.push({ id: doc.id, ...doc.data() });
            });
            callback(records);
          },
          error => {
            console.warn("Firestore attendance read restriction, using local state:", error);
            callback(this.getLocalFallback('attendanceLogs'));
          }
        );
    } else {
      callback(this.getLocalFallback('attendanceLogs'));
    }
  },

  // Punch In Action (Create document in Firestore)
  punchIn: async function (record) {
    if (isFirebaseConnected && db) {
      try {
        const docRef = await db.collection('attendance').add({
          ...record,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        record.id = docRef.id;
        this.addAuditLog("PUNCH_IN", `Punch in recorded at ${record.location}`);
      } catch (err) {
        console.warn("Firestore punchIn write error, caching locally:", err);
      }
    }
    this.pushLocalFallback('attendanceLogs', record);
    return record;
  },

  // Punch Out Action (Update document in Firestore)
  punchOut: async function (docId, punchOutTime, totalHours) {
    if (isFirebaseConnected && db && docId) {
      try {
        await db.collection('attendance').doc(docId).update({
          punchOut: punchOutTime,
          totalHours: totalHours,
          status: 'Present',
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        this.addAuditLog("PUNCH_OUT", `Punch out recorded at ${punchOutTime}`);
      } catch (err) {
        console.warn("Firestore punchOut update error:", err);
      }
    }
  },

  // 2. Fetch / Apply Leaves
  subscribeLeaves: function (callback) {
    if (isFirebaseConnected && db) {
      db.collection('leaves')
        .onSnapshot(
          snapshot => {
            const leaves = [];
            snapshot.forEach(doc => {
              leaves.push({ id: doc.id, ...doc.data() });
            });
            callback(leaves);
          },
          error => {
            console.warn("Firestore leaves read warning:", error);
            callback(this.getLocalFallback('leaveRequests'));
          }
        );
    } else {
      callback(this.getLocalFallback('leaveRequests'));
    }
  },

  applyLeave: async function (leaveData) {
    if (isFirebaseConnected && db) {
      try {
        const docRef = await db.collection('leaves').add({
          ...leaveData,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        leaveData.id = docRef.id;
        this.addAuditLog("LEAVE_APPLY", `Leave applied for ${leaveData.leaveType}`);
      } catch (err) {
        console.warn("Firestore leave apply error:", err);
      }
    }
    this.pushLocalFallback('leaveRequests', leaveData);
    return leaveData;
  },

  updateLeaveStatus: async function (leaveId, status) {
    if (isFirebaseConnected && db && leaveId) {
      try {
        await db.collection('leaves').doc(leaveId).update({
          status: status,
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        this.addAuditLog("LEAVE_STATUS_UPDATE", `Leave status changed to ${status}`);
      } catch (err) {
        console.warn("Firestore leave status update error:", err);
      }
    }
    // Also update local fallback
    const leaves = this.getLocalFallback('leaveRequests');
    const updated = leaves.map(l => l.id === leaveId ? { ...l, status: status } : l);
    localStorage.setItem('attendx_leaveRequests', JSON.stringify(updated));
  },

  // 3. Employee Management
  subscribeEmployees: function (callback) {
    if (isFirebaseConnected && db) {
      db.collection('employees')
        .onSnapshot(
          snapshot => {
            const emps = [];
            snapshot.forEach(doc => {
              emps.push({ id: doc.id, ...doc.data() });
            });
            callback(emps);
          },
          error => {
            callback(this.getLocalFallback('employees'));
          }
        );
    } else {
      callback(this.getLocalFallback('employees'));
    }
  },

  addEmployee: async function (empData) {
    if (isFirebaseConnected && db) {
      try {
        await db.collection('employees').doc(empData.employeeId).set({
          ...empData,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        this.addAuditLog("EMPLOYEE_ADD", `Added new employee ${empData.name} (${empData.employeeId})`);
      } catch (err) {
        console.warn("Firestore add employee error:", err);
      }
    }
    this.pushLocalFallback('employees', empData);
  },

  // 4. Announcements & Audit Logs
  subscribeAnnouncements: function (callback) {
    if (isFirebaseConnected && db) {
      db.collection('announcements')
        .onSnapshot(
          snapshot => {
            const list = [];
            snapshot.forEach(doc => list.push({ id: doc.id, ...doc.data() }));
            callback(list);
          },
          () => callback(this.getLocalFallback('announcements'))
        );
    } else {
      callback(this.getLocalFallback('announcements'));
    }
  },

  addAuditLog: async function (action, details) {
    const log = {
      timestamp: new Date().toLocaleString(),
      user: "Rahul Sharma",
      action: action,
      details: details
    };
    if (isFirebaseConnected && db) {
      try {
        await db.collection('auditLogs').add({
          ...log,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
      } catch (e) { }
    }
    this.pushLocalFallback('auditLogs', log);
  },

  // Local fallback storage helpers
  getLocalFallback: function (key) {
    const defaultData = {
      attendanceLogs: [
        { id: "att_01", date: "2026-09-08", employeeId: "EMP-1024", name: "Rahul Sharma", punchIn: "09:15 AM", punchOut: "--", totalHours: "Running", status: "Present", location: "HQ Office" },
        { id: "att_02", date: "2026-09-07", employeeId: "EMP-1024", name: "Rahul Sharma", punchIn: "09:02 AM", punchOut: "06:15 PM", totalHours: "9h 13m", status: "Present", location: "HQ Office" },
        { id: "att_03", date: "2026-09-06", employeeId: "EMP-1024", name: "Rahul Sharma", punchIn: "09:45 AM", punchOut: "06:30 PM", totalHours: "8h 45m", status: "Late", location: "Remote" }
      ],
      leaveRequests: [
        { id: "lv_101", employeeId: "EMP-1024", name: "Rahul Sharma", leaveType: "Casual Leave", startDate: "2026-09-15", endDate: "2026-09-16", reason: "Family event", status: "Pending", appliedOn: "2026-09-07" },
        { id: "lv_102", employeeId: "EMP-1028", name: "Vikas Singh", leaveType: "Sick Leave", startDate: "2026-09-10", endDate: "2026-09-10", reason: "Medical appointment", status: "Approved", appliedOn: "2026-09-06" }
      ],
      employees: [
        { employeeId: "EMP-1024", name: "Rahul Sharma", role: "employee", email: "rahul.sharma@attendx.com", department: "Engineering", status: "Active" },
        { employeeId: "EMP-1025", name: "Priya Patel", role: "manager", email: "priya.patel@attendx.com", department: "Engineering", status: "Active" },
        { employeeId: "EMP-1026", name: "Amit Kumar", role: "hr", email: "amit.kumar@attendx.com", department: "Human Resources", status: "Active" },
        { employeeId: "EMP-1027", name: "Neha Verma", role: "admin", email: "neha.verma@attendx.com", department: "Operations", status: "Active" }
      ],
      announcements: [
        { id: "ann_01", title: "🎉 Quarter 3 Townhall & Policy Updates", content: "Join us this Friday at 4 PM for the Q3 All-Hands townhall.", targetRole: "All Roles", date: "Sep 07, 2026", author: "HR Department" }
      ],
      auditLogs: [
        { id: "log_01", timestamp: "2026-09-08 09:15:02", user: "Rahul Sharma", action: "PUNCH_IN", details: "Selfie verified at HQ Office (Geofence: OK)" }
      ]
    };
    try {
      const stored = localStorage.getItem('attendx_' + key);
      return stored ? JSON.parse(stored) : defaultData[key] || [];
    } catch (e) {
      return defaultData[key] || [];
    }
  },

  pushLocalFallback: function (key, item) {
    const list = this.getLocalFallback(key);
    list.unshift(item);
    try {
      localStorage.setItem('attendx_' + key, JSON.stringify(list));
    } catch (e) { }
  }
};

/* ==========================================================================
   Firebase Auth Service — Login, Register, Forgot Password, Logout
   ========================================================================== */
const AttendXAuth = {
  // Login with email/password, then fetch role from Firestore employees collection
  login: async function (email, password) {
    if (!isFirebaseConnected || !auth) {
      // Fallback: local mock login
      return this._mockLogin(email, password);
    }
    try {
      const userCredential = await auth.signInWithEmailAndPassword(email, password);
      const user = userCredential.user;

      // Fetch role from Firestore employees collection
      let role = 'employee';
      let name = user.displayName || email.split('@')[0];
      let department = 'General';

      try {
        const empQuery = await db.collection('employees').where('email', '==', email).limit(1).get();
        if (!empQuery.empty) {
          const empData = empQuery.docs[0].data();
          role = empData.role || 'employee';
          name = empData.name || name;
          department = empData.department || department;
        }
      } catch (e) {
        console.warn("Could not fetch employee role from Firestore, defaulting to employee:", e);
      }

      // Store session
      this._setSession(user.uid, email, name, role, department);
      return { success: true, role: role };
    } catch (error) {
      return { success: false, error: this._getErrorMessage(error.code) };
    }
  },

  // Register new user with Firebase Auth + create Firestore employee doc
  register: async function (name, email, password, department, role) {
    if (!isFirebaseConnected || !auth) {
      return this._mockRegister(name, email, role);
    }
    try {
      const userCredential = await auth.createUserWithEmailAndPassword(email, password);
      const user = userCredential.user;

      // Update display name
      await user.updateProfile({ displayName: name });

      // Create employee document in Firestore
      const empId = 'EMP-' + Math.floor(1000 + Math.random() * 9000);
      try {
        await db.collection('employees').doc(empId).set({
          employeeId: empId,
          uid: user.uid,
          name: name,
          email: email,
          department: department,
          role: role,
          status: 'Active',
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
      } catch (e) {
        console.warn("Could not create Firestore employee doc:", e);
      }

      // Sign out after registration so they can log in
      await auth.signOut();
      return { success: true };
    } catch (error) {
      return { success: false, error: this._getErrorMessage(error.code) };
    }
  },

  // Send password reset email
  resetPassword: async function (email) {
    if (!isFirebaseConnected || !auth) {
      return { success: true, message: 'Password reset email sent (mock mode).' };
    }
    try {
      await auth.sendPasswordResetEmail(email);
      return { success: true, message: 'Password reset email sent! Check your inbox.' };
    } catch (error) {
      return { success: false, error: this._getErrorMessage(error.code) };
    }
  },

  // Logout and redirect to login page
  logout: function () {
    if (isFirebaseConnected && auth) {
      auth.signOut().catch(function () { });
    }
    sessionStorage.removeItem('attendx_user');
    window.location.href = 'login.html';
  },

  // Get current logged-in user from session
  getCurrentUser: function () {
    try {
      const data = sessionStorage.getItem('attendx_user');
      return data ? JSON.parse(data) : null;
    } catch (e) {
      return null;
    }
  },

  // Auth guard — redirect to login if not authenticated
  requireAuth: function () {
    const user = this.getCurrentUser();
    const currentPage = window.location.pathname.split('/').pop();
    const authPages = ['login.html', 'register.html', 'forgot-password.html'];

    if (!user && !authPages.includes(currentPage)) {
      window.location.href = 'login.html';
      return false;
    }
    return true;
  },

  // Check if user is logged in (boolean)
  isLoggedIn: function () {
    return this.getCurrentUser() !== null;
  },

  // Store user session
  _setSession: function (uid, email, name, role, department) {
    const userData = {
      uid: uid,
      email: email,
      name: name,
      role: role,
      department: department,
      loginTime: new Date().toISOString()
    };
    sessionStorage.setItem('attendx_user', JSON.stringify(userData));
  },

  // Mock login for local/offline development
  _mockLogin: function (email, password) {
    const mockUsers = {
      'employee@attendx.com': { name: 'Prince Vidyarthi', role: 'employee', department: 'Engineering' },
      'manager@attendx.com': { name: 'Rajesh Kumar', role: 'manager', department: 'Engineering' },
      'hr@attendx.com': { name: 'Amit Kumar', role: 'hr', department: 'Human Resources' },
      'admin@attendx.com': { name: 'Neha Verma', role: 'admin', department: 'Operations' }
    };

    const user = mockUsers[email.toLowerCase()];
    if (user && password.length >= 6) {
      this._setSession('mock_' + Date.now(), email, user.name, user.role, user.department);
      return { success: true, role: user.role };
    }
    if (!user) {
      return { success: false, error: 'No account found with this email. Please register first.' };
    }
    return { success: false, error: 'Invalid password. Must be at least 6 characters.' };
  },

  // Mock register
  _mockRegister: function (name, email, role) {
    console.log("Mock registration:", name, email, role);
    return { success: true };
  },

  // Friendly error messages from Firebase error codes
  _getErrorMessage: function (code) {
    const messages = {
      'auth/user-not-found': 'No account found with this email. Please register first.',
      'auth/wrong-password': 'Incorrect password. Please try again.',
      'auth/invalid-email': 'Please enter a valid email address.',
      'auth/email-already-in-use': 'This email is already registered. Please login instead.',
      'auth/weak-password': 'Password must be at least 6 characters long.',
      'auth/too-many-requests': 'Too many attempts. Please try again later.',
      'auth/network-request-failed': 'Network error. Please check your connection.',
      'auth/invalid-credential': 'Invalid email or password. Please try again.'
    };
    return messages[code] || 'An unexpected error occurred. Please try again.';
  }
};
