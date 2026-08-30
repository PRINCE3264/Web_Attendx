# AttendX – Attendance Management App

AttendX is a role-based attendance management application built with Flutter and Firebase.

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging (FCM)

## User Roles

### Employee

Employee can:

- Login
- Clock In
- Capture attendance photo
- View approval status
- Clock Out after approval
- View own attendance history

Employee can only access their own attendance records.

### TL

TL can:

- Login
- View assigned team attendance
- View pending attendance requests
- Verify employee clock-in photo
- Approve attendance
- Reject attendance
- View team attendance history

TL can only access employees assigned to their team.

### Admin

Admin has full access to:

- Employees
- TLs
- All attendance records
- Pending approvals
- Approved/rejected attendance
- Daily attendance
- Monthly attendance
- Reports
- User management

## Attendance Flow

```text
Employee Login
      ↓
Clock In
      ↓
Camera Capture
      ↓
Upload Photo
      ↓
Create Attendance
      ↓
TL Approval
      ↓
Approved
      ↓
Clock Out
      ↓
Attendance Completed
