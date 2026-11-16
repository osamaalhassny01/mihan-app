class DateHelper {
  /// Parse a date string from backend (e.g. "2026-11-16 10:44:39" or ISO-8601)
  static DateTime? parse(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final str = raw.toString().trim();
    if (str.isEmpty || str == '-' || str == 'null') return null;

    try {
      // Standard ISO-8601 or DateTime.parse compatible
      return DateTime.parse(str.replaceFirst(' ', 'T'));
    } catch (_) {
      try {
        final parts = str.split(' ');
        if (parts.isNotEmpty) {
          final dateParts = parts[0].split('-');
          if (dateParts.length == 3) {
            final y = int.parse(dateParts[0]);
            final m = int.parse(dateParts[1]);
            final d = int.parse(dateParts[2]);
            int h = 0, min = 0, s = 0;
            if (parts.length > 1) {
              final timeParts = parts[1].split(':');
              if (timeParts.isNotEmpty) h = int.parse(timeParts[0]);
              if (timeParts.length > 1) min = int.parse(timeParts[1]);
              if (timeParts.length > 2) s = int.parse(timeParts[2].split('.')[0]);
            }
            return DateTime(y, m, d, h, min, s);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Format as date + time with Arabic AM/PM (e.g. 2026/11/16 • 10:44 ص)
  static String formatDateTime(dynamic raw) {
    final dt = parse(raw);
    if (dt == null) return raw?.toString() ?? '-';

    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');

    final hour24 = dt.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'م' : 'ص';

    return '$y/$m/$d • $hour12:$minute $ampm';
  }

  /// Format as date only (e.g. 2026/11/16)
  static String formatDate(dynamic raw) {
    final dt = parse(raw);
    if (dt == null) return raw?.toString() ?? '-';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  /// Format as time only with Arabic AM/PM (e.g. 10:44 ص)
  static String formatTime(dynamic raw) {
    if (raw == null) return '-';
    final str = raw.toString().trim();
    if (str.isEmpty || str == '-') return '-';

    // If string is already just "HH:mm:ss" or "HH:mm"
    if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(str)) {
      final parts = str.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? parts[1] : '00';
      final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      final ampm = h >= 12 ? 'م' : 'ص';
      return '$hour12:$m $ampm';
    }

    final dt = parse(raw);
    if (dt == null) return str;

    final hour24 = dt.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'م' : 'ص';

    return '$hour12:$minute $ampm';
  }

  /// Format customer scheduled visit (date + time)
  static String formatSchedule(String? date, String? time) {
    if ((date == null || date.isEmpty) && (time == null || time.isEmpty)) {
      return 'زيارة فورية / بأقرب وقت';
    }
    if (date != null && date.isNotEmpty && (time == null || time.isEmpty)) {
      return formatDate(date);
    }
    if ((date == null || date.isEmpty) && time != null && time.isNotEmpty) {
      return formatTime(time);
    }
    return '${formatDate(date)} • ${formatTime(time)}';
  }

  /// Relative human-friendly time (e.g. "منذ 5 دقائق • 10:44 ص")
  static String formatRelative(dynamic raw) {
    final dt = parse(raw);
    if (dt == null) return raw?.toString() ?? '-';

    final now = DateTime.now();
    final diff = now.difference(dt);

    final hour24 = dt.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'م' : 'ص';
    final timeStr = '$hour12:$minute $ampm';

    if (diff.isNegative) {
      // Future date
      return '${formatDate(dt)} • $timeStr';
    }

    if (diff.inSeconds < 60) {
      return 'الآن • $timeStr';
    }
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      if (mins == 1) return 'منذ دقيقة • $timeStr';
      if (mins == 2) return 'منذ دقيقتين • $timeStr';
      if (mins >= 3 && mins <= 10) return 'منذ $mins دقائق • $timeStr';
      return 'منذ $mins دقيقة • $timeStr';
    }
    if (diff.inHours < 24 && dt.day == now.day) {
      final hours = diff.inHours;
      if (hours == 1) return 'منذ ساعة • $timeStr';
      if (hours == 2) return 'منذ ساعتين • $timeStr';
      if (hours >= 3 && hours <= 10) return 'منذ $hours ساعات • $timeStr';
      return 'منذ $hours ساعة • $timeStr';
    }
    if (diff.inDays == 1 || (diff.inHours < 48 && dt.day == now.subtract(const Duration(days: 1)).day)) {
      return 'أمس • $timeStr';
    }

    return '${formatDate(dt)} • $timeStr';
  }
}
