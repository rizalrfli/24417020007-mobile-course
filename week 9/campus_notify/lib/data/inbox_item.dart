import '../messaging/message_route.dart';

/// Satu notifikasi yang sudah pernah diterima perangkat.
///
/// Disimpan lokal supaya daftar notifikasi tetap ada setelah aplikasi ditutup.
/// Butir yang sudah dibaca dihapus dari daftar, jadi tidak ada field `readAt`:
/// keberadaan butir di daftar berarti belum dibaca.
class InboxItem {
  const InboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.receivedAt,
  });

  /// Id pesan FCM. Dipakai untuk mencegah notifikasi yang sama masuk dua kali
  /// saat background handler dan handler foreground sama-sama terpanggil.
  final String id;
  final String title;
  final String body;

  /// Rute tujuan yang sudah divalidasi [routeFromMessage].
  final String route;
  final DateTime receivedAt;

  /// Membentuk butir dari isi pesan FCM.
  ///
  /// [messageId] bisa null (payload tanpa id), sehingga dipakai `data['id']`
  /// atau gabungan judul dan rute sebagai kunci cadangan.
  factory InboxItem.fromMessage({
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

    return InboxItem(
      id: id,
      title: safeTitle,
      body: safeBody,
      route: route,
      receivedAt: receivedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'route': route,
        'received_at': receivedAt.toIso8601String(),
      };

  /// Mengembalikan null bila data tersimpan rusak, supaya satu entri cacat
  /// tidak menghapus seluruh isi kotak masuk.
  static InboxItem? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = _clean(raw['id']);
    final title = _clean(raw['title']);
    if (id == null || title == null) return null;

    final route = routeFromMessage({'route': raw['route']?.toString() ?? ''});
    final at = DateTime.tryParse(raw['received_at']?.toString() ?? '');
    return InboxItem(
      id: id,
      title: title,
      body: _clean(raw['body']) ?? '',
      route: route,
      receivedAt: at ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Label waktu ringkas untuk daftar: `HH:mm` hari ini, `dd/MM HH:mm` selain itu.
  String get timeLabel {
    final now = DateTime.now();
    final sameDay = receivedAt.year == now.year &&
        receivedAt.month == now.month &&
        receivedAt.day == now.day;
    final clock = '${_two(receivedAt.hour)}:${_two(receivedAt.minute)}';
    if (sameDay) return clock;
    return '${_two(receivedAt.day)}/${_two(receivedAt.month)} $clock';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

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
