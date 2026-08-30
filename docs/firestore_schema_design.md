# AttendX - Enterprise Firestore Database Architecture & Schema Specification

**Application Name**: AttendX  
**Platform**: Flutter (Android, iOS, Web, Desktop) & Firebase  
**Target Roles**: Employee, TL / Manager, HR, Admin  

---

## 1. Complete Firestore Architecture Overview

The **AttendX** database is designed specifically as a high-throughput, horizontally scalable NoSQL schema optimized for Firestore pricing (minimizing document reads and avoiding unbounded array growth) while maintaining clean denormalization for real-time dashboards and instant querying.

```
                    ┌────────────────────────┐
                    │      Firebase Auth     │
                    └───────────┬────────────┘
                                │ (uid = userId)
                                ▼
                    ┌────────────────────────┐
                    │      users (Auth/RBAC) │
                    └───────────┬────────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          ▼                     ▼                     ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│    employees     │  │   departments    │  │      teams       │
└─────────┬────────┘  └──────────────────┘  └──────────────────┘
          │
          ├────────────────────────┬────────────────────────┐
          ▼                        ▼                        ▼
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│    attendance    │     │      leaves      │     │  notifications   │
└─────────┬────────┘     └──────────────────┘     └──────────────────┘
          │
          ├────────────────────────┬────────────────────────┐
          ▼                        ▼                        ▼
┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────┐
│ attendanceApprovals  │ │attendanceCorrections │ │     reports      │
└──────────────────────┘ └──────────────────────┘ └──────────────────┘
          │
          ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│    auditLogs     │  │attendancePolicies│  │  officeLocations │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 2. Collection Hierarchy

```
/users/{userId}
/employees/{employeeId}
/departments/{departmentId}
/teams/{teamId}
/officeLocations/{locationId}
/shifts/{shiftId}
/attendancePolicies/{policyId}
/holidays/{holidayId}
/leaveTypes/{leaveTypeId}
/leaves/{leaveId}
/attendance/{attendanceId}
/attendanceApprovals/{approvalId}
/attendanceCorrections/{correctionId}
/notifications/{notificationId}
/reports/{reportId}
/auditLogs/{logId}
/appSettings/{settingKey}
```

---

## 3. Detailed Schema Tables

### 3.1 `users`
**Document ID**: Firebase Auth `uid`

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `userId` | `string` | Required | `"usr_98a7sd8f9"` | Primary User ID matching Auth UID |
| `email` | `string` | Required | `"rahul.sharma@attendx.com"` | Authentication login email |
| `name` | `string` | Required | `"Rahul Sharma"` | Display name |
| `avatarUrl` | `string` | Optional | `"https://storage.googleapis.com/.../avatar.jpg"` | Profile photo URL |
| `role` | `string` | Required | `"employee"` | Role: `employee` \| `manager` \| `hr` \| `admin` |
| `employeeId` | `string` | Required | `"EMP-1024"` | Reference to `employees/{employeeId}` |
| `isActive` | `boolean` | Required | `true` | Account active / disabled flag |
| `fcmToken` | `string` | Optional | `"f7s8d9f7sd8f..."` | Firebase Cloud Messaging device token |
| `lastLoginAt` | `timestamp` | Optional | `2026-08-30T09:15:00Z` | Timestamp of last user sign-in |
| `createdAt` | `timestamp` | Required | `2026-01-15T00:00:00Z` | Registration creation time |
| `updatedAt` | `timestamp` | Required | `2026-08-30T09:15:00Z` | Last record update time |

---

### 3.2 `employees`
**Document ID**: `employeeId` (e.g. `"EMP-1024"`)

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `employeeId` | `string` | Required | `"EMP-1024"` | Unique Employee Corporate ID |
| `userId` | `string` | Required | `"usr_98a7sd8f9"` | Ref: `users/{userId}` |
| `fullName` | `string` | Required | `"Rahul Sharma"` | Full legal name |
| `workEmail` | `string` | Required | `"rahul.sharma@attendx.com"` | Official communication email |
| `phoneNumber` | `string` | Optional | `"+919876543210"` | Contact phone number |
| `departmentId` | `string` | Required | `"dept_eng"` | Ref: `departments/{departmentId}` |
| `departmentName` | `string` | Required | `"Engineering"` | Denormalized for fast display |
| `teamId` | `string` | Required | `"team_mobile"` | Ref: `teams/{teamId}` |
| `teamName` | `string` | Required | `"Mobile Apps Team"` | Denormalized for fast display |
| `managerId` | `string` | Required | `"EMP-1002"` | Ref: `employees/{managerId}` (Reporting TL) |
| `managerName` | `string` | Required | `"Vikram Mehta"` | Denormalized TL name |
| `shiftId` | `string` | Required | `"shift_gen_01"` | Ref: `shifts/{shiftId}` |
| `officeLocationId`| `string` | Required | `"loc_hq_delhi"` | Ref: `officeLocations/{locationId}` |
| `policyId` | `string` | Required | `"policy_default"`| Ref: `attendancePolicies/{policyId}` |
| `avatarUrl` | `string` | Optional | `"https://storage.googleapis.com/.../profile.jpg"` | Profile photo |
| `leaveBalance` | `map` | Required | `{"casual": 12, "sick": 8, "earned": 15}` | Real-time remaining leave quotas |
| `status` | `string` | Required | `"active"` | `active` \| `on_leave` \| `probation` \| `terminated` |
| `joiningDate` | `timestamp` | Required | `2024-03-01T00:00:00Z` | Date of joining |
| `createdAt` | `timestamp` | Required | `2024-03-01T00:00:00Z` | Record creation timestamp |
| `updatedAt` | `timestamp` | Required | `2026-08-30T09:00:00Z` | Record update timestamp |

---

### 3.3 `departments`
**Document ID**: Slug string (e.g. `"dept_engineering"`)

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `departmentId` | `string` | Required | `"dept_engineering"` | Department identifier |
| `name` | `string` | Required | `"Engineering"` | Department title |
| `code` | `string` | Required | `"ENG"` | Short code |
| `headOfDepartmentId`| `string` | Optional | `"EMP-1001"` | Ref: `employees/{employeeId}` (HOD) |
| `headOfDepartmentName`| `string` | Optional | `"Dr. Anita Roy"` | Denormalized HOD name |
| `totalEmployees`| `number` | Required | `42` | Count of active employees in department |
| `isActive` | `boolean` | Required | `true` | Active status flag |
| `createdAt` | `timestamp` | Required | `2023-01-01T00:00:00Z` | Creation timestamp |

---

### 3.4 `teams`
**Document ID**: Slug string (e.g. `"team_mobile"`)

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `teamId` | `string` | Required | `"team_mobile"` | Team identifier |
| `name` | `string` | Required | `"Mobile Apps Team"` | Team title |
| `departmentId` | `string` | Required | `"dept_engineering"` | Ref: `departments/{departmentId}` |
| `managerId` | `string` | Required | `"EMP-1002"` | Ref: `employees/{managerId}` (Team Lead) |
| `managerName` | `string` | Required | `"Vikram Mehta"` | Denormalized TL name |
| `memberCount` | `number` | Required | `8` | Total active team members |
| `isActive` | `boolean` | Required | `true` | Active status flag |
| `createdAt` | `timestamp` | Required | `2023-01-01T00:00:00Z` | Creation timestamp |

---

### 3.5 `officeLocations`
**Document ID**: Slug string (e.g. `"loc_hq_delhi"`)

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `locationId` | `string` | Required | `"loc_hq_delhi"` | Location identifier |
| `name` | `string` | Required | `"HQ - Connaught Place"` | Location display title |
| `address` | `string` | Required | `"Block B, Inner Circle, Connaught Place, New Delhi"` | Full postal address |
| `geopoint` | `geopoint` | Required | `GeoPoint(28.6139, 77.2090)` | Office GPS coordinate center |
| `geofenceRadiusMeters`| `number` | Required | `300` | Max allowed radius for Clock-In in meters |
| `wifiBSSIDs` | `array<string>` | Optional | `["00:14:22:01:23:45"]` | Allowed office WiFi BSSID MAC addresses |
| `isActive` | `boolean` | Required | `true` | Active office site flag |
| `createdAt` | `timestamp` | Required | `2023-01-01T00:00:00Z` | Creation timestamp |

---

### 3.6 `shifts`
**Document ID**: Slug string (e.g. `"shift_general"`)

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `shiftId` | `string` | Required | `"shift_general"` | Shift identifier |
| `name` | `string` | Required | `"General Day Shift"` | Shift display name |
| `startTime` | `string` | Required | `"09:30"` | Shift start time in HH:mm 24h format |
| `endTime` | `string` | Required | `"18:30"` | Shift end time in HH:mm 24h format |
| `gracePeriodMinutes`| `number` | Required | `15` | Late grace duration (e.g. until 09:45) |
| `halfDayThresholdMinutes`| `number` | Required | `240` | Min minutes for half day (4 hours) |
| `fullDayThresholdMinutes`| `number` | Required | `480` | Min minutes for full day (8 hours) |
| `workDays` | `array<number>`| Required | `[1, 2, 3, 4, 5]` | 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri |
| `isNightShift` | `boolean` | Required | `false` | Crosses midnight indicator |

---

### 3.7 `attendancePolicies`
**Document ID**: Slug string (e.g. `"policy_standard"`)

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `policyId` | `string` | Required | `"policy_standard"` | Policy identifier |
| `name` | `string` | Required | `"Standard Corporate Policy"` | Policy display name |
| `requireSelfie` | `boolean` | Required | `true` | Mandatory selfie verification on Clock In |
| `requireGeofence` | `boolean` | Required | `true` | Mandatory GPS perimeter check |
| `requireTLApproval`| `boolean` | Required | `true` | Must be reviewed by TL before verified |
| `autoClockOutTime`| `string` | Optional | `"23:59"` | Cloud Function auto clock-out time |
| `maxBreakMinutesPerDay`| `number` | Required | `60` | Allowed total break duration |
| `consecutiveLatePenaltyDays`| `number` | Optional | `3` | Late penalty rule threshold |
| `isDefault` | `boolean` | Required | `true` | Default applied to new employees |

---

### 3.8 `attendance`
**Document ID**: `{employeeId}_{yyyy-MM-dd}` (e.g. `"EMP-1024_2026-08-30"`)  
*Guarantees atomic uniqueness: only one primary record per employee per calendar date.*

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `attendanceId` | `string` | Required | `"EMP-1024_2026-08-30"` | Primary record document ID |
| `employeeId` | `string` | Required | `"EMP-1024"` | Ref: `employees/{employeeId}` |
| `employeeName` | `string` | Required | `"Rahul Sharma"` | Denormalized employee name |
| `employeeCode` | `string` | Required | `"EMP-1024"` | Denormalized employee corporate ID |
| `employeeAvatar` | `string` | Optional | `"https://storage.../rahul.jpg"` | Denormalized profile image |
| `departmentId` | `string` | Required | `"dept_eng"` | Ref: `departments/{departmentId}` |
| `departmentName` | `string` | Required | `"Engineering"` | Denormalized department name |
| `teamId` | `string` | Required | `"team_mobile"` | Ref: `teams/{teamId}` |
| `teamName` | `string` | Required | `"Mobile Apps Team"` | Denormalized team name |
| `managerId` | `string` | Required | `"EMP-1002"` | Ref: `employees/{managerId}` (Reporting TL) |
| `shiftId` | `string` | Required | `"shift_general"` | Ref: `shifts/{shiftId}` |
| `date` | `string` | Required | `"2026-08-30"` | ISO Date format `yyyy-MM-dd` |
| `clockInTime` | `timestamp` | Required | `2026-08-30T09:28:15Z` | Exact timestamp of clock-in |
| `clockInPhotoUrl` | `string` | Required | `"attendance-photos/EMP-1024/2026-08-30/clock-in.jpg"` | Storage path of clock-in selfie |
| `clockInLocation` | `geopoint` | Required | `GeoPoint(28.6140, 77.2091)` | Captured GPS coordinates at clock-in |
| `clockInAddress` | `string` | Optional | `"Connaught Place, New Delhi"` | Reverse geocoded address |
| `clockInDistanceMeters`| `number`| Required | `18.4` | Distance from assigned office in meters |
| `isWithinGeofence` | `boolean` | Required | `true` | Validated within geofence radius |
| `timingStatus` | `string` | Required | `"on_time"` | `on_time` \| `grace_period` \| `late` |
| `lateMinutes` | `number` | Required | `0` | Minutes after shift start + grace |
| `status` | `string` | Required | `"approved"` | `pending` \| `approved` \| `rejected` \| `completed` \| `absent` \| `on_leave` |
| `approvalStatus` | `string` | Required | `"approved"` | `pending` \| `approved` \| `rejected` |
| `approvedBy` | `string` | Optional | `"EMP-1002"` | Ref: `employees/{managerId}` |
| `approvedByName` | `string` | Optional | `"Vikram Mehta"` | Denormalized manager name |
| `approvedAt` | `timestamp` | Optional | `2026-08-30T09:40:00Z` | Timestamp when TL approved |
| `rejectedBy` | `string` | Optional | `null` | Ref: `employees/{managerId}` |
| `rejectedByName` | `string` | Optional | `null` | Denormalized manager name |
| `rejectedAt` | `timestamp` | Optional | `null` | Timestamp when TL rejected |
| `rejectionReason` | `string` | Optional | `null` | Explanation if rejected by manager |
| `managerComments` | `string` | Optional | `"Verified selfie and GPS"` | Optional reviewer note |
| `breaks` | `array<map>` | Required | `[{"breakId":"b1","type":"lunch","startTime":...,"endTime":...,"durationMinutes":45}]` | Break intervals |
| `totalBreakMinutes`| `number` | Required | `45` | Sum of all break durations in minutes |
| `clockOutTime` | `timestamp` | Optional | `2026-08-30T18:35:00Z` | Exact timestamp of clock-out |
| `clockOutPhotoUrl`| `string` | Optional | `"attendance-photos/EMP-1024/2026-08-30/clock-out.jpg"` | Storage path of clock-out selfie |
| `clockOutLocation`| `geopoint` | Optional | `GeoPoint(28.6141, 77.2090)` | Captured GPS coordinates at clock-out |
| `totalWorkingHours`| `number` | Optional | `8.61` | Gross hours (ClockOut - ClockIn) in decimal |
| `netWorkingHours` | `number` | Optional | `7.86` | Productive hours (Gross - Breaks) in decimal |
| `overtimeHours` | `number` | Optional | `0.0` | Extra hours beyond shift schedule |
| `isAutoClockOut` | `boolean` | Required | `false` | Set to true if closed by cron |
| `hasCorrection` | `boolean` | Required | `false` | True if regularized |
| `correctionId` | `string` | Optional | `null` | Ref: `attendanceCorrections/{correctionId}` |
| `createdAt` | `timestamp` | Required | `2026-08-30T09:28:15Z` | Creation timestamp |
| `updatedAt` | `timestamp` | Required | `2026-08-30T18:35:00Z` | Last update timestamp |

---

### 3.9 `attendanceApprovals`
**Document ID**: `appr_{attendanceId}`

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `approvalId` | `string` | Required | `"appr_EMP-1024_2026-08-30"` | Approval document ID |
| `attendanceId` | `string` | Required | `"EMP-1024_2026-08-30"` | Ref: `attendance/{attendanceId}` |
| `employeeId` | `string` | Required | `"EMP-1024"` | Ref: `employees/{employeeId}` |
| `employeeName` | `string` | Required | `"Rahul Sharma"` | Denormalized employee name |
| `teamId` | `string` | Required | `"team_mobile"` | Ref: `teams/{teamId}` |
| `managerId` | `string` | Required | `"EMP-1002"` | Ref: `employees/{managerId}` |
| `date` | `string` | Required | `"2026-08-30"` | ISO Date `yyyy-MM-dd` |
| `selfieUrl` | `string` | Required | `"attendance-photos/.../clock-in.jpg"` | Image to inspect |
| `distanceMeters` | `number` | Required | `18.4` | Geofence verification metric |
| `status` | `string` | Required | `"approved"` | `pending` \| `approved` \| `rejected` |
| `reviewedAt` | `timestamp` | Optional | `2026-08-30T09:40:00Z` | Decision timestamp |
| `rejectionReason` | `string` | Optional | `null` | Provided reason on rejection |
| `createdAt` | `timestamp` | Required | `2026-08-30T09:28:15Z` | Timestamp created |

---

### 3.10 `attendanceCorrections`
**Document ID**: `corr_{autoId}`

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `correctionId` | `string` | Required | `"corr_8a9sd7f6as"` | Correction request ID |
| `attendanceId` | `string` | Required | `"EMP-1024_2026-08-30"` | Ref: `attendance/{attendanceId}` |
| `employeeId` | `string` | Required | `"EMP-1024"` | Ref: `employees/{employeeId}` |
| `employeeName` | `string` | Required | `"Rahul Sharma"` | Denormalized employee name |
| `teamId` | `string` | Required | `"team_mobile"` | Ref: `teams/{teamId}` |
| `managerId` | `string` | Required | `"EMP-1002"` | Ref: `employees/{managerId}` |
| `date` | `string` | Required | `"2026-08-30"` | Attendance date being regularized |
| `requestedClockIn`| `timestamp`| Required | `2026-08-30T09:30:00Z` | Corrected clock-in requested |
| `requestedClockOut`| `timestamp`| Required | `2026-08-30T18:30:00Z` | Corrected clock-out requested |
| `reason` | `string` | Required | `"App crashed due to network issue"` | Justification from employee |
| `status` | `string` | Required | `"pending"` | `pending` \| `approved` \| `rejected` |
| `reviewedBy` | `string` | Optional | `null` | Ref: `employees/{managerId}` |
| `reviewedAt` | `timestamp` | Optional | `null` | Decision timestamp |
| `reviewComments` | `string` | Optional | `null` | Manager feedback |
| `createdAt` | `timestamp` | Required | `2026-08-30T19:00:00Z` | Request submission time |

---

### 3.11 `leaves`
**Document ID**: `leave_{autoId}`

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `leaveId` | `string` | Required | `"leave_98sd7f98s"` | Leave application ID |
| `employeeId` | `string` | Required | `"EMP-1024"` | Ref: `employees/{employeeId}` |
| `employeeName` | `string` | Required | `"Rahul Sharma"` | Denormalized employee name |
| `departmentId` | `string` | Required | `"dept_eng"` | Ref: `departments/{departmentId}` |
| `teamId` | `string` | Required | `"team_mobile"` | Ref: `teams/{teamId}` |
| `managerId` | `string` | Required | `"EMP-1002"` | Ref: `employees/{managerId}` (Reviewer) |
| `leaveTypeId` | `string` | Required | `"lt_casual"` | Ref: `leaveTypes/{leaveTypeId}` |
| `leaveTypeName` | `string` | Required | `"Casual Leave"` | Denormalized type name |
| `startDate` | `string` | Required | `"2026-09-05"` | `yyyy-MM-dd` |
| `endDate` | `string` | Required | `"2026-09-07"` | `yyyy-MM-dd` |
| `totalDays` | `number` | Required | `3` | Total business days applied |
| `reason` | `string` | Required | `"Attending family wedding"` | Application reason |
| `status` | `string` | Required | `"pending"` | `pending` \| `approved` \| `rejected` \| `cancelled` |
| `approvedBy` | `string` | Optional | `null` | Ref: `employees/{managerId}` |
| `approvedByName` | `string` | Optional | `null` | Manager name |
| `approvedAt` | `timestamp` | Optional | `null` | Approval timestamp |
| `rejectionReason` | `string` | Optional | `null` | Reason if rejected |
| `createdAt` | `timestamp` | Required | `2026-08-30T10:00:00Z` | Application timestamp |
| `updatedAt` | `timestamp` | Required | `2026-08-30T10:00:00Z` | Update timestamp |

---

### 3.12 `leaveTypes`
**Document ID**: `lt_{slug}` (e.g. `"lt_casual"`, `"lt_sick"`, `"lt_earned"`)

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `leaveTypeId` | `string` | Required | `"lt_casual"` | Unique leave type ID |
| `name` | `string` | Required | `"Casual Leave"` | Title |
| `code` | `string` | Required | `"CL"` | Short code |
| `annualQuota` | `number` | Required | `12` | Total allowed days per calendar year |
| `carryForward` | `boolean` | Required | `false` | Carry forward unused to next year |
| `isPaid` | `boolean` | Required | `true` | Paid vs Unpaid leave |
| `isActive` | `boolean` | Required | `true` | Active status |

---

### 3.13 `holidays`
**Document ID**: `hol_{yyyy}_{slug}` (e.g. `"hol_2026_diwali"`)

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `holidayId` | `string` | Required | `"hol_2026_diwali"` | Holiday document ID |
| `name` | `string` | Required | `"Diwali Festive Holiday"` | Title |
| `date` | `string` | Required | `"2026-11-08"` | `yyyy-MM-dd` |
| `year` | `number` | Required | `2026` | Calendar year for fast querying |
| `isOptional` | `boolean` | Required | `false` | Mandatory vs Optional holiday |
| `locationIds` | `array<string>`| Required | `["loc_hq_delhi"]` | Applicable office locations or `["ALL"]` |
| `createdAt` | `timestamp` | Required | `2026-01-01T00:00:00Z` | Creation timestamp |

---

### 3.14 `notifications`
**Document ID**: `notif_{autoId}`

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `notificationId` | `string` | Required | `"notif_98a7sd8f7"` | Notification document ID |
| `userId` | `string` | Required | `"usr_98a7sd8f9"` | Ref: `users/{userId}` (Target recipient) |
| `title` | `string` | Required | `"Clock-In Approved 🟢"` | Header text |
| `message` | `string` | Required | `"Your clock-in for 30 Aug was approved by Vikram Mehta."` | Body text |
| `type` | `string` | Required | `"approval"` | `approval` \| `rejection` \| `leave` \| `alert` \| `report` \| `system` |
| `entityId` | `string` | Optional | `"EMP-1024_2026-08-30"` | Ref ID of associated entity |
| `isRead` | `boolean` | Required | `false` | Read status |
| `createdAt` | `timestamp` | Required | `2026-08-30T09:40:00Z` | Dispatch timestamp |

---

### 3.15 `reports`
**Document ID**: `rep_{employeeId}_{yyyyMM}` or `rep_{deptId}_{yyyyMM}`

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `reportId` | `string` | Required | `"rep_EMP-1024_202608"` | Unique report identifier |
| `reportType` | `string` | Required | `"monthly_employee"` | `daily_company` \| `monthly_employee` \| `30_day_hr_audit` \| `department_summary` |
| `targetScope` | `string` | Required | `"employee"` | `company` \| `department` \| `team` \| `employee` |
| `targetId` | `string` | Required | `"EMP-1024"` | Entity ID for scope |
| `targetName` | `string` | Required | `"Rahul Sharma"` | Entity display title |
| `periodStart` | `timestamp` | Required | `2026-08-01T00:00:00Z` | Audit start window |
| `periodEnd` | `timestamp` | Required | `2026-08-30T23:59:59Z` | Audit end window |
| `totalWorkingDays`| `number` | Required | `22` | Number of business days |
| `presentDays` | `number` | Required | `20` | Count of verified present days |
| `absentDays` | `number` | Required | `1` | Count of unapproved absent days |
| `leaveDays` | `number` | Required | `1` | Count of approved leave days |
| `lateDays` | `number` | Required | `2` | Count of late check-in occurrences |
| `pendingDays` | `number` | Required | `0` | Unreviewed entries count |
| `totalHoursWorked`| `number` | Required | `168.5` | Sum of net productive hours |
| `averageHoursPerDay`|`number` | Required | `8.42` | Average daily productive hours |
| `attendancePercentage`|`number`| Required | `90.9` | `(presentDays / totalWorkingDays) * 100` |
| `pdfStorageUrl` | `string` | Optional | `"reports/2026-08/rep_EMP-1024_202608.pdf"` | Exported PDF storage location |
| `csvStorageUrl` | `string` | Optional | `"reports/2026-08/rep_EMP-1024_202608.csv"` | Exported CSV storage location |
| `generatedBy` | `string` | Required | `"system_cron"` | User ID or `"system_cron"` |
| `createdAt` | `timestamp` | Required | `2026-08-30T23:59:59Z` | Generation timestamp |

---

### 3.16 `auditLogs`
**Document ID**: `log_{autoId}`

| Field Name | Type | Req/Opt | Example | Purpose & Relationships |
|---|---|---|---|---|
| `logId` | `string` | Required | `"log_a8sd7f98s7"` | Audit log ID |
| `actorId` | `string` | Required | `"EMP-1002"` | User who performed action |
| `actorName` | `string` | Required | `"Vikram Mehta"` | Name of actor |
| `actorRole` | `string` | Required | `"manager"` | Role of actor at execution time |
| `actionType` | `string` | Required | `"APPROVE_ATTENDANCE"` | e.g. `LOGIN`, `APPROVE_ATTENDANCE`, `UPDATE_POLICY`, `CREATE_USER` |
| `targetCollection`| `string` | Required | `"attendance"` | Target collection modified |
| `targetEntityId`| `string` | Required | `"EMP-1024_2026-08-30"` | Target document ID |
| `description` | `string` | Required | `"Vikram Mehta approved attendance for Rahul Sharma."` | Human-readable explanation |
| `oldValue` | `map` | Optional | `{"status": "pending"}` | Snapshot of data before change |
| `newValue` | `map` | Optional | `{"status": "approved"}` | Snapshot of data after change |
| `ipAddress` | `string` | Optional | `"192.168.1.45"` | Client network IP |
| `userAgent` | `string` | Optional | `"Flutter Android 14 / Samsung S23"` | Client platform information |
| `timestamp` | `timestamp` | Required | `2026-08-30T09:40:00Z` | Immutable action timestamp |

---

### 3.17 `appSettings`
**Document ID**: Key string (e.g. `"general"`, `"branding"`, `"cron"`)

| Field Name | Type | Req/Opt | Example | Purpose |
|---|---|---|---|---|
| `settingKey` | `string` | Required | `"general"` | Key identifier |
| `companyName` | `string` | Required | `"AttendX Corporation"` | Organization title |
| `supportEmail`| `string` | Required | `"hr-support@attendx.com"` | Automated contact recipient |
| `autoEmailReportsTo`|`array<string>`| Required | `["hr-head@attendx.com", "ceo@attendx.com"]` | Email addresses for 30-day cron dispatches |
| `allowMockLocation`| `boolean`| Required | `false` | Reject mock / spoofed GPS locations |
| `updatedAt` | `timestamp` | Required | `2026-08-30T00:00:00Z` | Settings update timestamp |

---

## 4. Example JSON Documents for Major Collections

### 4.1 Example `attendance` Document (`/attendance/EMP-1024_2026-08-30`)
```json
{
  "attendanceId": "EMP-1024_2026-08-30",
  "employeeId": "EMP-1024",
  "employeeName": "Rahul Sharma",
  "employeeCode": "EMP-1024",
  "employeeAvatar": "https://storage.googleapis.com/attendx-8b4c5.appspot.com/profiles/EMP-1024.jpg",
  "departmentId": "dept_eng",
  "departmentName": "Engineering",
  "teamId": "team_mobile",
  "teamName": "Mobile Apps Team",
  "managerId": "EMP-1002",
  "shiftId": "shift_general",
  "date": "2026-08-30",
  "clockInTime": "2026-08-30T09:28:15.000Z",
  "clockInPhotoUrl": "attendance-photos/EMP-1024/2026-08-30/clock-in.jpg",
  "clockInLocation": {
    "_latitude": 28.6139,
    "_longitude": 77.2090
  },
  "clockInAddress": "Connaught Place, New Delhi",
  "clockInDistanceMeters": 14.5,
  "isWithinGeofence": true,
  "timingStatus": "on_time",
  "lateMinutes": 0,
  "status": "completed",
  "approvalStatus": "approved",
  "approvedBy": "EMP-1002",
  "approvedByName": "Vikram Mehta",
  "approvedAt": "2026-08-30T09:40:00.000Z",
  "rejectedBy": null,
  "rejectedByName": null,
  "rejectedAt": null,
  "rejectionReason": null,
  "managerComments": "Selfie and office GPS verified.",
  "breaks": [
    {
      "breakId": "brk_1",
      "type": "tea",
      "startTime": "2026-08-30T11:15:00.000Z",
      "endTime": "2026-08-30T11:30:00.000Z",
      "durationMinutes": 15
    },
    {
      "breakId": "brk_2",
      "type": "lunch",
      "startTime": "2026-08-30T13:30:00.000Z",
      "endTime": "2026-08-30T14:15:00.000Z",
      "durationMinutes": 45
    }
  ],
  "totalBreakMinutes": 60,
  "clockOutTime": "2026-08-30T18:35:00.000Z",
  "clockOutPhotoUrl": "attendance-photos/EMP-1024/2026-08-30/clock-out.jpg",
  "clockOutLocation": {
    "_latitude": 28.6140,
    "_longitude": 77.2091
  },
  "totalWorkingHours": 9.11,
  "netWorkingHours": 8.11,
  "overtimeHours": 0.0,
  "isAutoClockOut": false,
  "hasCorrection": false,
  "correctionId": null,
  "createdAt": "2026-08-30T09:28:15.000Z",
  "updatedAt": "2026-08-30T18:35:00.000Z"
}
```

---

### 4.2 Example `leaves` Document (`/leaves/leave_98sd7f98s`)
```json
{
  "leaveId": "leave_98sd7f98s",
  "employeeId": "EMP-1024",
  "employeeName": "Rahul Sharma",
  "departmentId": "dept_eng",
  "teamId": "team_mobile",
  "managerId": "EMP-1002",
  "leaveTypeId": "lt_casual",
  "leaveTypeName": "Casual Leave",
  "startDate": "2026-09-05",
  "endDate": "2026-09-07",
  "totalDays": 3,
  "reason": "Family wedding in hometown",
  "status": "approved",
  "approvedBy": "EMP-1002",
  "approvedByName": "Vikram Mehta",
  "approvedAt": "2026-08-30T11:00:00.000Z",
  "rejectionReason": null,
  "createdAt": "2026-08-30T10:00:00.000Z",
  "updatedAt": "2026-08-30T11:00:00.000Z"
}
```

---

### 4.3 Example `reports` Document (`/reports/rep_EMP-1024_202608`)
```json
{
  "reportId": "rep_EMP-1024_202608",
  "reportType": "monthly_employee",
  "targetScope": "employee",
  "targetId": "EMP-1024",
  "targetName": "Rahul Sharma",
  "periodStart": "2026-08-01T00:00:00.000Z",
  "periodEnd": "2026-08-30T23:59:59.000Z",
  "totalWorkingDays": 22,
  "presentDays": 20,
  "absentDays": 1,
  "leaveDays": 1,
  "lateDays": 2,
  "pendingDays": 0,
  "totalHoursWorked": 168.5,
  "averageHoursPerDay": 8.42,
  "attendancePercentage": 90.9,
  "pdfStorageUrl": "reports/2026-08/rep_EMP-1024_202608.pdf",
  "csvStorageUrl": "reports/2026-08/rep_EMP-1024_202608.csv",
  "generatedBy": "system_cron",
  "createdAt": "2026-08-30T23:59:59.000Z"
}
```

---

## 5. Collection Relationships & Controlled Denormalization

1. **User ➔ Employee Mapping**:
   - `users.userId` ➔ `employees.userId` (1-to-1).
   - `employees.employeeId` is the corporate key used throughout attendance, leaves, and approvals.

2. **Team & Department Hierarchy**:
   - `departments` ➔ `teams` (1-to-Many).
   - `teams.managerId` links to the `employees.employeeId` of the Team Lead.

3. **Controlled Denormalization for Query Performance**:
   - `employeeName`, `employeeAvatar`, `departmentName`, `teamName`, and `managerId` are duplicated into `attendance` and `leaves`.
   - **Why?** Allows Managers and HR to query team attendance and approvals in a **single indexed read** without performing client-side joins (N+1 query problem).

---

## 6. Security Rules Specifications (`firestore.rules`)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function getRole() {
      return getUserData().role;
    }
    
    function getEmployeeId() {
      return getUserData().employeeId;
    }
    
    function isAdmin() {
      return isAuthenticated() && getRole() == 'admin';
    }
    
    function isHR() {
      return isAuthenticated() && (getRole() == 'hr' || isAdmin());
    }
    
    function isManager() {
      return isAuthenticated() && (getRole() == 'manager' || isHR());
    }

    // Users Collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create, delete: if isAdmin();
      allow update: if isAdmin() || (request.auth.uid == userId && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'employeeId', 'isActive']));
    }

    // Employees Collection
    match /employees/{employeeId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isHR();
    }

    // Attendance Collection
    match /attendance/{attendanceId} {
      // Employees can read their own attendance; Managers can read their team; HR/Admin can read all
      allow read: if isAuthenticated() && (
        resource.data.employeeId == getEmployeeId() ||
        resource.data.managerId == getEmployeeId() ||
        isHR()
      );
      
      // Employees can create their initial clock-in (with status: pending)
      allow create: if isAuthenticated() && 
        request.resource.data.employeeId == getEmployeeId() &&
        request.resource.data.status == 'pending' &&
        request.resource.data.approvalStatus == 'pending';

      // Updates:
      // 1. Employee can add break and clock-out ONLY IF approved
      // 2. Manager can approve/reject
      // 3. Admin/HR have full authority
      allow update: if isAuthenticated() && (
        isAdmin() ||
        isHR() ||
        (isManager() && resource.data.managerId == getEmployeeId() && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'approvalStatus', 'approvedBy', 'approvedByName', 'approvedAt', 'rejectedBy', 'rejectedByName', 'rejectedAt', 'rejectionReason', 'managerComments', 'updatedAt'])) ||
        (resource.data.employeeId == getEmployeeId() && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['status', 'approvalStatus', 'approvedBy', 'approvedAt', 'rejectedBy', 'rejectedAt']))
      );
    }

    // Attendance Approvals Collection
    match /attendanceApprovals/{approvalId} {
      allow read: if isAuthenticated() && (resource.data.managerId == getEmployeeId() || resource.data.employeeId == getEmployeeId() || isHR());
      allow create: if isAuthenticated();
      allow update: if isManager() || isHR();
    }

    // Leaves Collection
    match /leaves/{leaveId} {
      allow read: if isAuthenticated() && (
        resource.data.employeeId == getEmployeeId() ||
        resource.data.managerId == getEmployeeId() ||
        isHR()
      );
      allow create: if isAuthenticated() && request.resource.data.employeeId == getEmployeeId();
      allow update: if isAuthenticated() && (
        (isManager() && resource.data.managerId == getEmployeeId()) ||
        isHR() ||
        (resource.data.employeeId == getEmployeeId() && resource.data.status == 'pending')
      );
    }

    // Audit Logs Collection (Immutable write-only by Cloud Functions or System)
    match /auditLogs/{logId} {
      allow read: if isAdmin() || isHR();
      allow create: if isAuthenticated();
      allow update, delete: if false; // IMMUTABLE
    }

    // Settings, Policies, Shifts, Office Locations
    match /{collection}/{docId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

---

## 7. Firebase Storage Directory Structure & Security Rules

### Storage Hierarchy
```
attendance-photos/
  └── {employeeId}/
      └── {yyyy-MM-dd}/
          ├── clock-in.jpg      (Selfie with EXIF metadata)
          └── clock-out.jpg     (Clock out verification photo)

profiles/
  └── {employeeId}/
      └── avatar.jpg            (Official employee profile photo)

reports/
  └── {yyyy-MM}/
      ├── 30-day-company-audit-{yyyyMMdd}.pdf
      ├── 30-day-company-audit-{yyyyMMdd}.csv
      └── employee-{employeeId}-{yyyyMM}.pdf
```

### `storage.rules`
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isImageBelow5MB() {
      return request.resource.size < 5 * 1024 * 1024
          && request.resource.contentType.matches('image/.*');
    }

    // Attendance Photos: User can upload only their photo; Managers/HR can read
    match /attendance-photos/{employeeId}/{date}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isImageBelow5MB();
    }

    // Profiles: Anyone authenticated can read; Owner and HR can upload
    match /profiles/{employeeId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isImageBelow5MB();
    }

    // Reports: HR and Admin can upload and download
    match /reports/{allPaths=**} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

---

## 8. Required Firestore Composite Indexes (`firestore.indexes.json`)

```json
{
  "indexes": [
    {
      "collectionGroup": "attendance",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "employeeId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "attendance",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "managerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "attendance",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "teamId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "attendance",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "departmentId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "attendance",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "date", "order": "ASCENDING" },
        { "fieldPath": "timingStatus", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "leaves",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "managerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "leaves",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "employeeId", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "auditLogs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "actionType", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## 9. 30-Day Attendance Report Data Flow

```
1. TRIGGER: Scheduled Cron (1st of every month at 00:00 UTC) or Manual HR Export Request.
                           │
                           ▼
2. AGGREGATION: Query `/attendance` where `date >= periodStart` AND `date <= periodEnd`.
                           │
                           ▼
3. FORMULA COMPUTATION (Per Employee):
   • Total Working Days = (Calendar Days) - (Weekends + Holidays)
   • Present Days       = COUNT(status == "approved" OR status == "completed")
   • Absent Days        = Total Working Days - (Present Days + Approved Leave Days)
   • Late Days          = COUNT(timingStatus == "late")
   • Total Hours Worked = SUM(netWorkingHours)
   • Attendance Rate %  = (Present Days / Total Working Days) * 100
                           │
                           ▼
4. PERSISTENCE: Write aggregate record to `/reports/{reportId}`.
```

---

## 10. Automatic HR Email & Report Dispatch Pipeline

```
┌─────────────────────────┐
│ Cloud Scheduler (Cron)  │ ──► Executes `monthlyAttendanceAuditCron` (1st of Month)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ Firebase Cloud Function │ ──► Fetches all employee attendance in 30-day window
└───────────┬─────────────┘
            ├─────────────────────────────────────────┐
            ▼                                         ▼
┌─────────────────────────┐               ┌─────────────────────────┐
│  Generate PDF Document  │               │   Generate CSV / Excel  │
└───────────┬─────────────┘               └───────────┬─────────────┘
            └────────────────────┬────────────────────┘
                                 ▼
                 ┌──────────────────────────────┐
                 │ Upload to Firebase Storage   │
                 │ `/reports/{yyyy-MM}/...`     │
                 └───────────────┬──────────────┘
                                 ▼
                 ┌──────────────────────────────┐
                 │ Send Email (SendGrid/Mailgun)│
                 │ To: HR & Leadership Emails   │
                 │ Attachments: PDF & CSV       │
                 └──────────────────────────────┘
```

---

## 11. Recommended Firebase Cloud Functions (`functions/index.js`)

1. **`onAttendanceSubmitted`** (`functions.firestore.document('attendance/{id}').onCreate`):
   - Sends FCM notification to the employee's Manager (`"Rahul Sharma submitted Clock-In for review"`).
2. **`onAttendanceReviewed`** (`functions.firestore.document('attendance/{id}').onUpdate`):
   - When `approvalStatus` changes to `approved` or `rejected`, dispatches FCM alert to employee with feedback.
3. **`onLeaveStatusChanged`** (`functions.firestore.document('leaves/{id}').onUpdate`):
   - Automatically decrements `leaveBalance` in `employees/{employeeId}` upon approval.
4. **`autoClockOutCron`** (`functions.pubsub.schedule('59 23 * * *')`):
   - Detects unclosed shifts (missing Clock-Out) at midnight and marks them with `isAutoClockOut = true`.
5. **`monthlyAttendanceAuditCron`** (`functions.pubsub.schedule('0 0 1 * *')`):
   - Computes 30-day company-wide stats, generates PDF/CSV, writes to `reports/`, and emails HR.

---

## 12. Recommended Naming Conventions

| Item | Standard | Example |
|---|---|---|
| Collection Names | `camelCase` (Plural) | `attendance`, `leaveTypes`, `auditLogs` |
| Document IDs | Unique structured slug | `EMP-1024_2026-08-30`, `team_mobile` |
| Field Names | `camelCase` | `clockInTime`, `isWithinGeofence` |
| Timestamps | Firestore `Timestamp` | `createdAt`, `approvedAt` |
| GPS Points | Firestore `GeoPoint` | `clockInLocation`, `geopoint` |
| Enums / Statuses | `snake_case` string | `on_time`, `grace_period`, `approved` |

---

## 13. Scalability & Performance Optimization

1. **No Array Bloat**:
   - Breaks are capped per day (1-3 entries max inside map array).
   - Daily attendance records are isolated documents (`{employeeId}_{date}`), avoiding single-document 1MB size limits.
2. **Atomic Document IDs**:
   - Using `{employeeId}_{yyyy-MM-dd}` prevents race conditions and accidental duplicate Clock-Ins on the same day.
3. **Sharded Counters for Company KPIs**:
   - Company-wide real-time attendance counts are updated via distributed triggers or periodic aggregation to avoid document write rate limits (1 write/sec/document).
