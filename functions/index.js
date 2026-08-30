const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const Groq = require("groq-sdk");
const axios = require("axios");
const FormData = require("form-data");
const { v4: uuidv4 } = require("uuid");

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

// 2. Scheduled Cron Job / Late Employee Checker (Runs every morning at 10:00 AM)
exports.checkLateEmployees = functions.pubsub
  .schedule("0 10 * * 1-5") // Mon-Fri at 10:00 AM
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    
    // Get all employees
    const employeesSnapshot = await db.collection("users").where("role", "==", "employee").get();
    
    const batch = db.batch();
    
    for (const doc of employeesSnapshot.docs) {
      const employee = doc.data();
      
      // Check if attendance exists for today
      const attendanceSnapshot = await db.collection("attendance")
        .where("employeeId", "==", employee.userId)
        .where("date", "==", today)
        .get();
        
      if (attendanceSnapshot.empty) {
        // Employee hasn't clocked in yet! Create an alert for HR and their TL
        const notificationRef = db.collection("notifications").doc();
        batch.set(notificationRef, {
          notificationId: notificationRef.id,
          title: "Late Arrival Alert ⚠️",
          message: `${employee.name} (${employee.employeeId}) has not clocked in yet today.`,
          type: "alert",
          targetRole: "hr", // Notify HR
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
        });
        
        if (employee.managerId) {
           const tlNotificationRef = db.collection("notifications").doc();
           batch.set(tlNotificationRef, {
             notificationId: tlNotificationRef.id,
             title: "Team Member Late ⚠️",
             message: `${employee.name} has not clocked in by 10:00 AM.`,
             type: "alert",
             targetUserId: employee.managerId, // Notify their specific TL
             createdAt: admin.firestore.FieldValue.serverTimestamp(),
             isRead: false,
           });
        }
      }
    }
    
    await batch.commit();
    console.log("Late employee check completed.");
    return null;
  });

// 3. Scheduled Cron Job / 30-Day Attendance Calculation Function
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

    // Automatically send an email summary to HR
    try {
      const hrUsersSnapshot = await db.collection("users").where("role", "==", "hr").get();
      if (!hrUsersSnapshot.empty) {
        const hrEmails = hrUsersSnapshot.docs.map(doc => doc.data().email).filter(e => e);
        
        if (hrEmails.length > 0) {
          const transporter = nodemailer.createTransport({
            service: "gmail",
            auth: {
              user: functions.config().email?.user || "notifications@company.com",
              pass: functions.config().email?.pass || "app-specific-password",
            },
          });

          const mailOptions = {
            from: '"Smart Attendance Enterprise" <notifications@company.com>',
            to: hrEmails.join(","),
            subject: "Automated Monthly Attendance Report is Ready",
            html: `
              <h2>Monthly Attendance Report Generated</h2>
              <p>The automated 30-day attendance audit has been completed.</p>
              <p>Total Employee Reports Processed: ${employeesSnapshot.docs.length}</p>
              <p>Please log in to your HR Management Console to view insights and download the full PDF/CSV reports.</p>
            `,
          };

          await transporter.sendMail(mailOptions);
          console.log("Automated monthly email sent to HR team.");
        }
      }
    } catch (err) {
      console.error("Failed to send automated monthly email:", err);
    }

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

// AI Voice Assistant Setup
const GROQ_API_KEY = "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";
const ELEVENLABS_API_KEY = "sk_7ab84b72a5d1935d5bbe474f5abe2d4ecacf74693426bdc2";
const ELEVENLABS_VOICE_ID = "EXAVITQu4vr4xnSDxMaL";

const groq = new Groq({ apiKey: GROQ_API_KEY });

exports.askVoiceAssistant = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const { audioBase64 } = data;
  if (!audioBase64) {
    throw new functions.https.HttpsError("invalid-argument", "Audio data is required.");
  }

  try {
    // 1. Transcription (STT) via Groq
    const audioBuffer = Buffer.from(audioBase64, "base64");
    // We mock a file for the transcription API (Whisper expects multipart form-data)
    // Actually, groq-sdk supports creating file streams or we can use raw axios if it fails,
    // but the SDK handles buffers natively using custom file-like objects, or we can just send it.
    // For safety with groq-sdk, let's use a workaround for File interface in Node:
    
    // Convert buffer to Blob/File for Groq API
    const fetch = require('node-fetch'); // Use global fetch or node-fetch for Blob
    const { Blob } = require('buffer');
    
    // Instead of using the SDK's file parser which can be tricky with buffers in cloud functions, 
    // let's use a direct axios call to Groq's transcription endpoint using FormData
    const formData = new FormData();
    formData.append("file", audioBuffer, { filename: "audio.m4a", contentType: "audio/m4a" });
    formData.append("model", "whisper-large-v3");

    const sttResponse = await axios.post("https://api.groq.com/openai/v1/audio/transcriptions", formData, {
      headers: {
        ...formData.getHeaders(),
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
    });

    const userText = sttResponse.data.text;
    console.log("Transcribed text:", userText);

    // 2. Authorization and Data Gathering
    const uid = context.auth.uid;
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    
    const userData = userDoc.data();
    const role = userData.role;
    let systemContext = `You are a helpful HR and Attendance AI Assistant for AttendX Enterprise. Be brief and highly professional. Respond in a single short paragraph. Answer the user's question.`;

    if (role === "employee") {
      // Fetch only employee's data
      const attendance = await db.collection("attendance").where("employeeId", "==", uid).limit(10).get();
      const attendanceSummary = attendance.docs.map(d => `${d.data().date}: ${d.data().status}`).join(", ");
      systemContext += `\nYou are talking to an Employee named ${userData.name}. Their recent attendance is: ${attendanceSummary || "No records"}. Do not give them data about any other employee.`;
    } else if (role === "manager") {
      systemContext += `\nYou are talking to a Team Lead named ${userData.name}. They manage the ${userData.department} department. Answer questions regarding their team's attendance.`;
    } else if (role === "hr" || role === "admin") {
      const allAttendance = await db.collection("attendance").limit(50).get();
      const approvedCount = allAttendance.docs.filter(d => d.data().status === "approved").length;
      systemContext += `\nYou are talking to an ${role.toUpperCase()} named ${userData.name}. You have access to the entire company's data. Currently there are ${approvedCount} approved attendances in the recent records.`;
    }

    // 3. LLM Processing via Groq
    const chatCompletion = await groq.chat.completions.create({
      messages: [
        { role: "system", content: systemContext },
        { role: "user", content: userText },
      ],
      model: "llama-3.1-8b-instant",
    });

    const aiResponseText = chatCompletion.choices[0]?.message?.content || "I am unable to process that right now.";

    // 4. TTS via ElevenLabs
    const ttsResponse = await axios.post(
      `https://api.elevenlabs.io/v1/text-to-speech/${ELEVENLABS_VOICE_ID}?output_format=mp3_44100_128`,
      {
        text: aiResponseText,
        model_id: "eleven_flash_v2_5",
      },
      {
        headers: {
          "xi-api-key": ELEVENLABS_API_KEY,
          "Content-Type": "application/json",
        },
        responseType: "arraybuffer", // Important for audio
      }
    );

    const responseAudioBase64 = Buffer.from(ttsResponse.data).toString("base64");

    // 5. Store Conversation in Firestore
    await db.collection("ai_conversations").add({
      userId: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      messages: [
        { role: "user", text: userText },
        { role: "assistant", text: aiResponseText }
      ]
    });

    return {
      text: aiResponseText,
      transcription: userText,
      audioBase64: responseAudioBase64,
    };

  } catch (error) {
    console.error("AI Assistant Error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
