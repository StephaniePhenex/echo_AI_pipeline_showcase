import 'dart:convert';

import 'package:flutter/foundation.dart';

void logEvent(String event, [Map<String, Object?> payload = const {}]) {
  final data = <String, Object?>{
    'type': 'event',
    'event': event,
    'ts': DateTime.now().toIso8601String(),
    ...payload,
  };
  debugPrint('[echo-log] ${jsonEncode(data)}');
}

void logError(
  String event,
  Object error,
  StackTrace stackTrace, {
  Map<String, Object?> payload = const {},
}) {
  final data = <String, Object?>{
    'type': 'error',
    'event': event,
    'ts': DateTime.now().toIso8601String(),
    'error': error.toString(),
    ...payload,
  };
  debugPrint('[echo-log] ${jsonEncode(data)}\n$stackTrace');
}
