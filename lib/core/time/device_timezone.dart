import 'dart:developer';

import 'package:flutter_timezone/flutter_timezone.dart';

/// IANA time zone of the device (e.g. "America/Bogota"), or null if it cannot
/// be read. The backend uses it to follow daylight saving time changes.
Future<String?> deviceTimezone() async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (e) {
    log('Failed to read the device time zone: $e');
    return null;
  }
}
