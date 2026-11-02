import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_notify/presentation/auth/auth_controller.dart';

/// Asal pesan untuk log debug di layar perangkat.
enum PushDebugSource { permission, token, refresh, topic, foreground, deepLink }

class PushDebugEntry {
  const PushDebugEntry(this.source, this.detail, {this.at});

  final PushDebugSource source;
  final String detail;
  final DateTime? at;

  String get time {
    final value = at ?? DateTime.now();
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    final ss = value.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

/// Status push terakhir yang terlihat di layar Debug.
///
/// Token disimpan terpotong: cukup untuk membandingkan token lama vs baru saat
/// demo, tidak cukup untuk dipakai orang lain.
class PushStatus {
  const PushStatus({
    this.permissionGranted,
    this.tokenPrefix,
    this.registeredTokenPrefix,
    this.topic,
    this.lastRoute,
    this.lastSource,
    this.lastSyncAt,
    this.backendNote,
    this.log = const [],
  });

  final bool? permissionGranted;

  /// Token perangkat saat ini, terpotong 12 karakter.
  final String? tokenPrefix;

  /// Token yang terakhir berhasil dikirim ke backend.
  final String? registeredTokenPrefix;
  final String? topic;
  final String? lastRoute;
  final String? lastSource;
  final DateTime? lastSyncAt;
  final String? backendNote;
  final List<PushDebugEntry> log;

  /// True bila token perangkat berbeda dari yang sudah terdaftar di backend,
  /// artinya backend masih menyimpan token basi.
  bool get isTokenPending =>
      tokenPrefix != null &&
      (registeredTokenPrefix == null || registeredTokenPrefix != tokenPrefix);

  PushStatus copyWith({
    bool? permissionGranted,
    String? tokenPrefix,
    String? registeredTokenPrefix,
    String? topic,
    String? lastRoute,
    String? lastSource,
    DateTime? lastSyncAt,
    String? backendNote,
    List<PushDebugEntry>? log,
  }) {
    return PushStatus(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      tokenPrefix: tokenPrefix ?? this.tokenPrefix,
      registeredTokenPrefix: registeredTokenPrefix ?? this.registeredTokenPrefix,
      topic: topic ?? this.topic,
      lastRoute: lastRoute ?? this.lastRoute,
      lastSource: lastSource ?? this.lastSource,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      backendNote: backendNote ?? this.backendNote,
      log: log ?? this.log,
    );
  }
}

class PushStatusNotifier extends Notifier<PushStatus> {
  static const _maxLog = 12;

  @override
  PushStatus build() => const PushStatus();

  void note(PushDebugSource source, String detail) {
    final entry = PushDebugEntry(source, detail);
    state = state.copyWith(log: [...state.log, entry].take(_maxLog).toList());
  }

  void permission(bool granted) {
    state = state.copyWith(permissionGranted: granted);
    note(
      PushDebugSource.permission,
      granted ? 'Izin diberikan' : 'Izin ditolak',
    );
  }

  /// [token] hanya dipakai untuk prefix 12 karakter, tidak pernah disimpan utuh.
  void token(String token, {required bool fromRefresh}) {
    final prefix = token.length <= 12 ? token : token.substring(0, 12);
    state = state.copyWith(tokenPrefix: prefix);
    note(
      fromRefresh ? PushDebugSource.refresh : PushDebugSource.token,
      '${fromRefresh ? 'Token baru' : 'Token perangkat'}: $prefix...',
    );
  }

  void backendRegistered() {
    state = state.copyWith(
      registeredTokenPrefix: state.tokenPrefix,
      lastSyncAt: DateTime.now(),
      backendNote: 'Tersimpan di backend',
    );
    note(PushDebugSource.token, 'POST /devices berhasil');
  }

  void backendFailed(String friendlyMessage) {
    state = state.copyWith(backendNote: friendlyMessage);
    note(PushDebugSource.token, 'POST /devices gagal: $friendlyMessage');
  }

  void topic(String name) {
    state = state.copyWith(topic: name);
    note(PushDebugSource.topic, 'Berlangganan topik $name');
  }

  void opened(String route, String source) {
    state = state.copyWith(lastRoute: route, lastSource: source);
    note(PushDebugSource.foreground, 'Buka $route ($source)');
  }
}

final pushStatusProvider =
    NotifierProvider<PushStatusNotifier, PushStatus>(PushStatusNotifier.new);

/// Rute tujuan yang belum sempat dibuka karena router belum siap atau pengguna
/// belum login. Dikosongkan setelah dipakai.
class PendingRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void hold(String route) => state = route;

  String? take() {
    final route = state;
    state = null;
    return route;
  }
}

final pendingRouteProvider =
    NotifierProvider<PendingRouteNotifier, String?>(PendingRouteNotifier.new);

/// `refreshListenable` untuk GoRouter supaya redirect dihitung ulang saat
/// status login berubah (login, logout, sesi kedaluwarsa).
final routerRefreshProvider = ChangeNotifierProvider<RouterRefresh>((ref) {
  final refresh = RouterRefresh();
  ref.listen(authStateProvider, (_, _) => refresh.notify());
  // `ChangeNotifierProvider` sudah membuang notifier ini sendiri saat provider
  // di-dispose. Menambahkan `ref.onDispose(refresh.dispose)` membuatnya dibuang
  // dua kali dan melempar "A RouterRefresh was used after being disposed."
  return refresh;
});

class RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Rute layar debug. Bukan target deep link, jadi tidak ikut di `Routes`.
const debugRoute = '/debug';
