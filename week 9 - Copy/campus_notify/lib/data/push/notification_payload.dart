import 'dart:convert';

import 'package:campus_notify/domain/push/message_route.dart';
import 'package:campus_notify/presentation/routes.dart';

String encodeNotificationPayload({required String id, required String route}) =>
    jsonEncode({'id': id, 'route': route});

({String? id, String route}) decodeNotificationPayload(String payload) {
  final raw = payload.trim();
  if (raw.isEmpty) return (id: null, route: Routes.home);
  if (raw.startsWith('{')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final route = routeFromMessage({'route': decoded['route']?.toString() ?? ''});
        final id = decoded['id']?.toString();
        return (id: (id == null || id.isEmpty) ? null : id, route: route);
      }
    } on FormatException {
      // Preserve compatibility with older raw route payloads.
    }
  }
  return (id: null, route: routeFromMessage({'route': raw}));
}
