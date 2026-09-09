import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/leave_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class LeaveEmailTemplateService {
  /// Generate full branded HTML Email Template matching Screenshot 2026-09-09 120242.png
  static String generateLeaveEmailHtml({
    required LeaveRequestModel leave,
    required UserModel employee,
    required String actionType, // 'applied', 'approved', 'rejected'
    String? reviewerName,
    String? rejectionReason,
  }) {
    final df = DateFormat('dd MMM yyyy');
    final startDateStr = df.format(leave.startDate);
    final endDateStr = df.format(leave.endDate);

    String statusText;
    String statusBg;
    String statusColor;
    String statusIcon;
    String headline;
    String actionMessage;

    if (actionType == 'approved') {
      statusText = 'Approved';
      statusBg = '#DCFCE7';
      statusColor = '#16A34A';
      statusIcon = '✔';
      headline = 'Your leave application has been successfully approved.';
      actionMessage = 'We\'re glad to have you with us! Wishing you a great time ahead!';
    } else if (actionType == 'rejected') {
      statusText = 'Rejected';
      statusBg = '#FEE2E2';
      statusColor = '#DC2626';
      statusIcon = '✖';
      headline = 'Your leave application has been reviewed and rejected.';
      actionMessage = rejectionReason != null && rejectionReason.isNotEmpty
          ? 'Reason for rejection: $rejectionReason'
          : 'Please get in touch with your manager or HR for further details.';
    } else {
      statusText = 'Pending Approval';
      statusBg = '#FEF3C7';
      statusColor = '#D97706';
      statusIcon = '⏳';
      headline = 'Your leave application has been submitted successfully.';
      actionMessage = 'Your request has been routed to your Team Lead & HR for review.';
    }

    final String reviewerInfo = reviewerName ?? (leave.reviewerName ?? 'HR Team');
    final String msgContent = leave.reason.isNotEmpty ? leave.reason : actionMessage;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Leave Application - Envision Beyond</title>
</head>
<body style="margin: 0; padding: 0; background-color: #F1F5F9; font-family: 'Segoe UI', Arial, sans-serif;">
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #F1F5F9; padding: 30px 10px;">
    <tr>
      <td align="center">
        <!-- Main Email Container -->
        <table width="600" border="0" cellspacing="0" cellpadding="0" style="background-color: #FFFFFF; border-radius: 20px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.08);">
          
          <!-- Header Banner -->
          <tr>
            <td style="background: linear-gradient(135deg, #1E3A8A 0%, #2563EB 50%, #3B82F6 100%); padding: 25px 30px; text-align: left;">
              <table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>
                    <h2 style="color: #FFFFFF; margin: 0; font-size: 22px; font-weight: 800; letter-spacing: -0.5px;">envision<span style="color: #EF4444;">beyond</span></h2>
                    <p style="color: #93C5FD; margin: 4px 0 0 0; font-size: 10px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">PEOPLE | TECHNOLOGY | A BETTER TOMORROW</p>
                  </td>
                  <td align="right" style="vertical-align: top;">
                    <span style="color: #FFFFFF; font-size: 11px; font-weight: 600;">www.envisionbeyond.com</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Body Content -->
          <tr>
            <td style="padding: 35px 35px 25px 35px;">
              <h2 style="color: #0F172A; margin: 0 0 10px 0; font-size: 24px; font-weight: 800;">Hello ${employee.name.split(' ')[0]},</h2>
              <p style="color: #475569; margin: 0 0 8px 0; font-size: 15px; line-height: 1.5;">$headline</p>
              <p style="color: #64748B; margin: 0 0 20px 0; font-size: 13.5px;">$actionMessage</p>

              <!-- Application Details Card -->
              <table width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 14px; margin-bottom: 25px; border-collapse: separate; border-spacing: 0; overflow: hidden;">
                <tr style="background-color: #F1F5F9;">
                  <td colspan="2" style="padding: 12px 18px; border-bottom: 1px solid #E2E8F0;">
                    <span style="color: #1E293B; font-weight: 700; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">Application Details</span>
                  </td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px; border-bottom: 1px solid #F1F5F9; width: 35%;">Application ID</td>
                  <td style="padding: 10px 18px; color: #0F172A; font-weight: 600; font-size: 13px; border-bottom: 1px solid #F1F5F9;">${leave.leaveId.toUpperCase()}</td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px; border-bottom: 1px solid #F1F5F9;">Employee Name</td>
                  <td style="padding: 10px 18px; color: #0F172A; font-weight: 600; font-size: 13px; border-bottom: 1px solid #F1F5F9;">${employee.name}</td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px; border-bottom: 1px solid #F1F5F9;">Department</td>
                  <td style="padding: 10px 18px; color: #0F172A; font-weight: 600; font-size: 13px; border-bottom: 1px solid #F1F5F9;">${employee.department}</td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px; border-bottom: 1px solid #F1F5F9;">Leave Type</td>
                  <td style="padding: 10px 18px; color: #0F172A; font-weight: 600; font-size: 13px; border-bottom: 1px solid #F1F5F9;">${leave.leaveType.label}</td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px; border-bottom: 1px solid #F1F5F9;">From Date</td>
                  <td style="padding: 10px 18px; color: #0F172A; font-weight: 600; font-size: 13px; border-bottom: 1px solid #F1F5F9;">$startDateStr</td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px; border-bottom: 1px solid #F1F5F9;">To Date</td>
                  <td style="padding: 10px 18px; color: #0F172A; font-weight: 600; font-size: 13px; border-bottom: 1px solid #F1F5F9;">$endDateStr</td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px; border-bottom: 1px solid #F1F5F9;">Total Days</td>
                  <td style="padding: 10px 18px; color: #0F172A; font-weight: 600; font-size: 13px; border-bottom: 1px solid #F1F5F9;">${leave.totalDays} Days</td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px; border-bottom: 1px solid #F1F5F9;">Status</td>
                  <td style="padding: 10px 18px; border-bottom: 1px solid #F1F5F9;">
                    <span style="background-color: $statusBg; color: $statusColor; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 700;">$statusIcon $statusText</span>
                  </td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px; border-bottom: 1px solid #F1F5F9;">Reviewed By</td>
                  <td style="padding: 10px 18px; color: #0F172A; font-weight: 600; font-size: 13px; border-bottom: 1px solid #F1F5F9;">$reviewerInfo</td>
                </tr>
                <tr>
                  <td style="padding: 10px 18px; color: #64748B; font-size: 13px;">Reason / Message</td>
                  <td style="padding: 10px 18px; color: #334155; font-size: 12.5px;">$msgContent</td>
                </tr>
              </table>

              <!-- Feature Pillars -->
              <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 25px;">
                <tr>
                  <td width="33%" align="center" style="background-color: #EFF6FF; border-radius: 12px; padding: 12px 8px;">
                    <span style="font-size: 13px; font-weight: 700; color: #1E40AF; display: block;">📅 Manage</span>
                    <span style="font-size: 11px; color: #3B82F6;">Your Applications</span>
                  </td>
                  <td width="2%"></td>
                  <td width="33%" align="center" style="background-color: #F0FDF4; border-radius: 12px; padding: 12px 8px;">
                    <span style="font-size: 13px; font-weight: 700; color: #166534; display: block;">📑 Track</span>
                    <span style="font-size: 11px; color: #22C55E;">Request Status</span>
                  </td>
                  <td width="2%"></td>
                  <td width="33%" align="center" style="background-color: #FAF5FF; border-radius: 12px; padding: 12px 8px;">
                    <span style="font-size: 13px; font-weight: 700; color: #6B21A8; display: block;">🎧 Get Support</span>
                    <span style="font-size: 11px; color: #A855F7;">We're here to help</span>
                  </td>
                </tr>
              </table>

              <p style="color: #64748B; font-size: 12.5px; margin: 0 0 15px 0;">If you have any questions, feel free to reach out to the HR team.</p>
              
              <p style="color: #1E293B; font-size: 13px; margin: 0; font-weight: 700;">Regards,<br>Envision Beyond India Private Limited</p>
              <p style="color: #94A3B8; font-size: 11px; margin: 4px 0 0 0;">People | Technology | A Better Tomorrow</p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #0F172A; padding: 20px 30px; text-align: center; color: #94A3B8; font-size: 11px;">
              <p style="margin: 0 0 6px 0; color: #F8FAFC; font-weight: 600;">Envision Beyond India Private Limited • Bangalore, India</p>
              <p style="margin: 0; color: #64748B;">Email: hr@envisionbeyond.com • Web: www.envisionbeyond.com</p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  /// Plain Text summary for email body launch
  static String generateLeaveEmailPlainText({
    required LeaveRequestModel leave,
    required UserModel employee,
    required String actionType,
    String? reviewerName,
    String? rejectionReason,
  }) {
    final df = DateFormat('dd MMM yyyy');
    final startDateStr = df.format(leave.startDate);
    final endDateStr = df.format(leave.endDate);

    String statusText = actionType == 'approved'
        ? 'APPROVED'
        : (actionType == 'rejected' ? 'REJECTED' : 'PENDING APPROVAL');

    final String reviewerInfo = reviewerName ?? (leave.reviewerName ?? 'HR Team');

    final buf = StringBuffer();
    buf.writeln('Hello ${employee.name.split(' ')[0]},');
    buf.writeln('');
    buf.writeln('Your leave application has been $statusText.');
    buf.writeln('');
    buf.writeln('APPLICATION DETAILS:');
    buf.writeln('• Application ID: ${leave.leaveId.toUpperCase()}');
    buf.writeln('• Employee Name: ${employee.name}');
    buf.writeln('• Department: ${employee.department}');
    buf.writeln('• Leave Type: ${leave.leaveType.label}');
    buf.writeln('• Duration: $startDateStr to $endDateStr (${leave.totalDays} Days)');
    buf.writeln('• Status: $statusText');
    buf.writeln('• Action By: $reviewerInfo');
    if (rejectionReason != null && rejectionReason.isNotEmpty) {
      buf.writeln('• Rejection Reason: $rejectionReason');
    }
    buf.writeln('• Employee Reason: ${leave.reason}');
    buf.writeln('');
    buf.writeln('If you have any questions, feel free to reach out to the HR team.');
    buf.writeln('');
    buf.writeln('Regards,');
    buf.writeln('Envision Beyond India Private Limited');
    buf.writeln('People | Technology | A Better Tomorrow');

    return buf.toString();
  }

  /// Dispatch email via mailto: or url_launcher to employee and HR/TL
  static Future<bool> sendLeaveStatusEmail({
    required LeaveRequestModel leave,
    required UserModel employee,
    required String actionType, // 'applied', 'approved', 'rejected'
    String? reviewerName,
    String? rejectionReason,
  }) async {
    bool launched = false;
    try {
      final List<String> recipients = [];
      final profileEmail = employee.email.trim();
      if (profileEmail.isNotEmpty) {
        recipients.add(profileEmail);
      }
      // Add HR fallback if needed
      if (!recipients.contains('hr@envisionbeyond.com')) {
        recipients.add('hr@envisionbeyond.com');
      }

      final statusSubject = actionType == 'approved'
          ? 'Leave Approved 🎉 - ${leave.leaveType.label}'
          : (actionType == 'rejected'
              ? 'Leave Request Update ⚠️ - ${leave.leaveType.label}'
              : 'New Leave Application Submitted 🌴 - ${employee.name}');

      final subject = '[Envision Beyond] $statusSubject (${employee.name})';
      final body = generateLeaveEmailPlainText(
        leave: leave,
        employee: employee,
        actionType: actionType,
        reviewerName: reviewerName,
        rejectionReason: rejectionReason,
      );

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipients.join(','),
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      if (await canLaunchUrl(emailUri)) {
        launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        launched = await launchUrl(emailUri);
      }
    } catch (e) {
      debugPrint('Leave email launcher error: $e');
    }

    NotificationService().sendNotification(
      title: actionType == 'approved'
          ? 'Leave Approval Email Sent ✉️'
          : (actionType == 'rejected' ? 'Leave Rejection Email Sent ✉️' : 'Leave Email Dispatched ✉️'),
      message: 'Branded email template notification dispatched for ${employee.name}.',
      type: actionType == 'approved' ? 'approval' : 'info',
    );

    return launched;
  }
}
