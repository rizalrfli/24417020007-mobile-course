import 'package:campus_notify/domain/inbox/inbox_item.dart';
import 'package:campus_notify/domain/push/message_route.dart';

class InboxItemModel extends InboxItem {
  const InboxItemModel({
    required super.id,
    required super.title,
    required super.body,
    required super.route,
    required super.receivedAt,
  });

  factory InboxItemModel.fromMessage({
    required String? messageId,
    required String? title,
    required String? body,
    required Map<String, dynamic> data,
    DateTime? receivedAt,
  }) {
    final route = routeFromMessage(data);
    final safeTitle = _clean(title) ?? _clean(data['title']) ?? 'Pengumuman';
    final safeBody = _clean(body) ?? _clean(data['body']) ?? '';
    final id = _firstNonEmpty([
          messageId,
          data['id']?.toString(),
          data['message_id']?.toString(),
        ]) ??
        'local-${route.hashCode}-${safeTitle.hashCode}';

    return InboxItemModel(
      id: id,
      title: safeTitle,
      body: safeBody,
      route: route,
      receivedAt: receivedAt ?? DateTime.now(),
    );
  }

  factory InboxItemModel.fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('Format inbox tidak valid.');
    final id = _clean(raw['id']);
    final title = _clean(raw['title']);
    if (id == null || title == null) {
      throw const FormatException('Data inbox tidak lengkap.');
    }

    return InboxItemModel(
      id: id,
      title: title,
      body: _clean(raw['body']) ?? '',
      route: routeFromMessage({'route': raw['route']?.toString() ?? ''}),
      receivedAt: DateTime.tryParse(raw['received_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory InboxItemModel.fromEntity(InboxItem item) => InboxItemModel(
        id: item.id,
        title: item.title,
        body: item.body,
        route: item.route,
        receivedAt: item.receivedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'route': route,
        'received_at': receivedAt.toIso8601String(),
      };

  InboxItem toEntity() => InboxItem(
        id: id,
        title: title,
        body: body,
        route: route,
        receivedAt: receivedAt,
      );

  static String? _clean(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final clean = _clean(value);
      if (clean != null) return clean;
    }
    return null;
  }
}
