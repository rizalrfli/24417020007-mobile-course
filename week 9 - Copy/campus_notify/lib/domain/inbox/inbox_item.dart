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

}
