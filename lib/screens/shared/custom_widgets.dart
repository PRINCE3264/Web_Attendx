import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';

class StatusBadge extends StatelessWidget {
  final AttendanceStatus status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String text;

    switch (status) {
      case AttendanceStatus.approved:
        bg = AppTheme.successSoft;
        fg = AppTheme.success;
        icon = Icons.check_circle_outline;
        text = 'Approved';
        break;
      case AttendanceStatus.pending:
        bg = AppTheme.warningSoft;
        fg = AppTheme.warning;
        icon = Icons.schedule;
        text = 'Pending TL Review';
        break;
      case AttendanceStatus.rejected:
        bg = AppTheme.dangerSoft;
        fg = AppTheme.danger;
        icon = Icons.highlight_off;
        text = 'Rejected';
        break;
      case AttendanceStatus.completed:
        bg = AppTheme.infoSoft;
        fg = AppTheme.info;
        icon = Icons.task_alt;
        text = 'Completed';
        break;
    }

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: fg.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (subtitle != null)
                  Flexible(
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DigitalLiveClock extends StatefulWidget {
  const DigitalLiveClock({super.key});

  @override
  State<DigitalLiveClock> createState() => _DigitalLiveClockState();
}

class _DigitalLiveClockState extends State<DigitalLiveClock> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm:ss').format(_now);
    final amPm = DateFormat('a').format(_now);
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(_now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Watermark Icon in matching translucent color
          Positioned(
            right: -8,
            bottom: -16,
            child: Icon(
              Icons.access_time_rounded,
              size: 95,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),

          // Main Content Row
          Row(
            children: [
              // Attractive Left Glassmorphism Icon Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Time & Date Display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.outfit(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              amPm,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 13),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PhotoDisplayWidget — glitch-free avatar / profile picture.
// Uses gaplessPlayback + StatefulWidget to prevent re-loading on provider rebuilds.
// ─────────────────────────────────────────────────────────────────────────────
class PhotoDisplayWidget extends StatefulWidget {
  final String? photoUrl;
  final double size;
  final double borderRadius;
  final BoxFit fit;

  const PhotoDisplayWidget({
    super.key,
    required this.photoUrl,
    this.size = 60,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  State<PhotoDisplayWidget> createState() => _PhotoDisplayWidgetState();
}

class _PhotoDisplayWidgetState extends State<PhotoDisplayWidget> {
  Widget _fallback() => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Icon(Icons.person, size: widget.size * 0.5, color: Colors.grey.shade500),
      );

  Widget _loading() => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.35,
            height: widget.size * 0.35,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final url = widget.photoUrl;
    if (url == null || url.isEmpty) return _fallback();

    // Base64 data-URI
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Image.memory(bytes,
              width: widget.size, height: widget.size,
              fit: widget.fit, gaplessPlayback: true,
              errorBuilder: (ctx, err, st) => _fallback()),
        );
      } catch (_) {
        return Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(widget.borderRadius)),
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    }

    // Network / Blob URL
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('blob:')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.network(url,
            width: widget.size, height: widget.size,
            fit: widget.fit, gaplessPlayback: true,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _loading(),
            errorBuilder: (ctx, err, st) => _fallback()),
      );
    }

    // Local file (non-web)
    if (!kIsWeb) {
      try {
        final file = File(url);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Image.file(file,
                width: widget.size, height: widget.size,
                fit: widget.fit, gaplessPlayback: true,
                errorBuilder: (ctx, err, st) => _fallback()),
          );
        }
      } catch (_) {}
    }

    return _fallback();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SmartImageWidget — glitch-free content image (screenshots, work photos, etc.)
// Supports nullable width/height for flexible layouts.
// Drop-in replacement for all _buildSmartImage() helper methods.
// ─────────────────────────────────────────────────────────────────────────────
class SmartImageWidget extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double borderRadius;

  const SmartImageWidget({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = 0,
  });

  @override
  State<SmartImageWidget> createState() => _SmartImageWidgetState();
}

class _SmartImageWidgetState extends State<SmartImageWidget> {
  Widget _fallback(IconData icon) => Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade300,
        child: Icon(icon, color: Colors.grey),
      );

  Widget _loading() => Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade200,
        child: const Center(
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final path = widget.path;

    if (path.isEmpty) return _fallback(Icons.image);

    // Base64 data-URI
    if (path.startsWith('data:image')) {
      try {
        final bytes = base64Decode(path.split(',').last);
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Image.memory(bytes,
              width: widget.width, height: widget.height,
              fit: widget.fit, gaplessPlayback: true,
              errorBuilder: (ctx, err, st) => _fallback(Icons.broken_image)),
        );
      } catch (_) {}
    }

    // Network URL (http / https / blob)
    final lower = path.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('blob:')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.network(path,
            width: widget.width, height: widget.height,
            fit: widget.fit, gaplessPlayback: true,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _loading(),
            errorBuilder: (ctx, err, st) => _fallback(Icons.broken_image)),
      );
    }

    // Local file (non-web)
    if (!kIsWeb) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Image.file(file,
                width: widget.width, height: widget.height,
                fit: widget.fit, gaplessPlayback: true,
                errorBuilder: (ctx, err, st) => _fallback(Icons.broken_image)),
          );
        }
      } catch (_) {}
    }

    return _fallback(Icons.image);
  }
}

/// Responsive Modal helper that renders a centered Dialog on Web/Desktop (>= 600px)
/// and a Bottom Sheet on Mobile (< 600px), preventing layout overflows outside the app frame.
Future<T?> showAppResponsiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 640,
  double maxHeightRatio = 0.88,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isDesktop = screenWidth >= 600;

  if (isDesktop) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: screenHeight * maxHeightRatio,
            ),
            child: Material(
              color: isDark ? AppTheme.bgDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: builder(dialogContext),
            ),
          ),
        );
      },
    );
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: isDark ? AppTheme.bgDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    constraints: BoxConstraints(
      maxWidth: maxWidth,
      maxHeight: MediaQuery.of(context).size.height * maxHeightRatio,
    ),
    builder: builder,
  );
}

