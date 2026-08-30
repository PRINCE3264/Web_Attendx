const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

// 1. Trigger FCM Notification on Attendance Approval or Rejection
exports.onAttendanceStatusChanged = functions.firestore
  .document("attendance/{attendanceId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if status changed
    if (beforeData.status === afterData.status) {
      return null;
    }

    const employeeId = afterData.employeeId;
    const userDoc = await db.collection("users").doc(employeeId).get();

    if (!userDoc.exists) return null;
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    let title = "";
    let body = "";

    if (afterData.status === "approved") {
      title = "Attendance Approved! 🎉";
      body = `Your clock-in for ${afterData.date} was approved by ${afterData.approvedByName || "Manager"}.`;
    } else if (afterData.status === "rejected") {
      title = "Attendance Rejected ⚠️";
      body = `Your clock-in was rejected. Reason: ${afterData.rejectionReason || "Verification failed"}.`;
    } else {
      return null;
    }

    // Send FCM push notification
    if (fcmToken) {
      const payload = {
        notification: { title, body },
        data: {
          attendanceId: context.params.attendanceId,
          status: afterData.status,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      try {
        await admin.messaging().sendToDevice(fcmToken, payload);
        console.log(`Notification sent to employee ${employeeId}`);
      } catch (err) {
        console.error("Error sending FCM notification:", err);
      }
    }

    return null;
  });

// 2. Scheduled Cron Job / 30-Day Attendance Calculation Function
exports.calculate30DayAttendanceCron = functions.pubsub
  .schedule("0 0 1 * *") // Runs 1st day of every month at midnight
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    const now = new Date();
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(now.getDate() - 30);

    const employeesSnapshot = await db.collection("users").where("role", "==", "employee").get();

    const batch = db.batch();

    for (const doc of employeesSnapshot.docs) {
      const employee = doc.data();
      const attendanceSnapshot = await db
        .collection("attendance")
        .where("employeeId", "==", employee.userId)
        .where("createdAt", ">=", thirtyDaysAgo)
        .get();

      let presentDays = 0;
      let totalWorkMinutes = 0;

      attendanceSnapshot.forEach((attDoc) => {
        const att = attDoc.data();
        if (att.status === "approved" || att.status === "completed") {
          presentDays++;
          totalWorkMinutes += att.totalWorkMinutes || 480;
        }
      });

      const totalWorkingDays = 22;
      const absentDays = Math.max(0, totalWorkingDays - presentDays);
      const attendancePercentage = Number(((presentDays / totalWorkingDays) * 100).toFixed(1));

      const reportRef = db.collection("reports").doc();
      batch.set(reportRef, {
        reportId: reportRef.id,
        employeeId: employee.userId,
        employeeName: employee.name,
        employeeCode: employee.employeeId,
        department: employee.department,
        periodStart: thirtyDaysAgo.toISOString().split("T")[0],
        periodEnd: now.toISOString().split("T")[0],
        totalWorkingDays,
        presentDays,
        absentDays,
        attendancePercentage,
        totalHoursWorked: Number((totalWorkMinutes / 60).toFixed(1)),
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log("30-Day automated attendance report calculation completed.");
    return null;
  });

// 3. Callable Automated Email Dispatch Function
exports.sendHrReportEmail = functions.https.onCall(async (data, context) => {
  const { recipientEmail, reportSummary } = data;

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: functions.config().email?.user || "notifications@company.com",
      pass: functions.config().email?.pass || "app-specific-password",
    },
  });

  const mailOptions = {
    from: '"Smart Attendance Enterprise" <notifications@company.com>',
    to: recipientEmail,
    subject: "Monthly 30-Day Attendance & Audit Report",
    html: `
      <h2>Smart Attendance 30-Day Audit Summary</h2>
      <p>${reportSummary}</p>
      <p>Please check your HR Management Console to download full PDF and CSV exports.</p>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true, message: "Email sent successfully" };
  } catch (error) {
    console.error("Email send failed:", error);
    throw new functions.https.HttpsError("internal", "Failed to send email");
  }
});
