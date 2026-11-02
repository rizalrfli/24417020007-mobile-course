import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_notify/data/push/notification_payload.dart';
import 'package:campus_notify/data/push/push_service.dart';
import 'package:campus_notify/data/push/push_debug_gateway.dart' show pushTokenProvider, createDebugMessage;
import 'package:campus_notify/presentation/auth/auth_controller.dart' show deviceRegistrarProvider;
import 'package:campus_notify/presentation/auth/auth_controller.dart';
import 'package:campus_notify/presentation/inbox/inbox_controller.dart';
import 'package:campus_notify/presentation/push/push_controller.dart';
import 'package:campus_notify/presentation/routes.dart';

class DebugPage extends ConsumerStatefulWidget {
  const DebugPage({super.key});

  @override
  ConsumerState<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends ConsumerState<DebugPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Mensimulasikan payload FCM tanpa menunggu server.
  ///
  /// Yang diuji adalah jalur yang sama dengan pesan sungguhan: parsing route,
  /// penampilan banner lokal, lalu navigasi saat banner diklik.
  Future<void> _simulateForeground() async {
    final route = Routes.announcement('3');
    final message = createDebugMessage(route);
    final item = inboxItemFromMessage(message);
    // Notifikasi uji masuk daftar seperti pesan sungguhan, sehingga badge dan
    // halaman daftar bisa diverifikasi tanpa menunggu server.
    await ref.read(inboxProvider.notifier).add(item);
    await showForegroundNotification(
      message,
      payload: encodeNotificationPayload(id: item.id, route: item.route),
      badgeCount: ref.read(unreadCountProvider),
    );
    ref.read(pushStatusProvider.notifier).note(
          PushDebugSource.foreground,
          'Banner lokal dikirim untuk $route',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(pushStatusProvider);
    final notifier = ref.read(pushStatusProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug push'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _StatusCard(status: status),
          const SizedBox(height: 24),
          Text('Aksi', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _ActionTile(
            title: 'Tampilkan banner uji',
            detail: 'Payload notification + data, route /pengumuman/3',
            enabled: !_busy,
            onTap: () => _run(_simulateForeground),
          ),
          _ActionTile(
            title: 'Kirim ulang token ke backend',
            detail: 'POST /devices dengan token saat ini',
            enabled: !_busy,
            onTap: () => _run(() async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final token = await ref.read(pushTokenProvider).getToken();
                if (token == null) {
                  notifier.backendFailed('Token belum tersedia');
                  return;
                }
                await ref.read(deviceRegistrarProvider).register(token);
                notifier.backendRegistered();
              } catch (error) {
                notifier.backendFailed(error.toString());
                messenger.showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            }),
          ),
          _ActionTile(
            title: status.topic == campusTopic
                ? 'Berhenti dari topik $campusTopic'
                : 'Berlangganan topik $campusTopic',
            detail: 'Topik dipakai untuk broadcast ke semua mahasiswa',
            enabled: !_busy,
            onTap: () => _run(() async {
              if (status.topic == campusTopic) {
                await unsubscribeCampusTopic();
                notifier.topic('');
              } else {
                await subscribeCampusTopic();
                notifier.topic(campusTopic);
              }
            }),
          ),
          const SizedBox(height: 24),
          Text('Log peristiwa', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (status.log.isEmpty)
            Text(
              'Belum ada peristiwa. Kirim notifikasi uji dari Firebase Console '
              'atau pakai aksi di atas.',
              style: theme.textTheme.bodyMedium,
            )
          else
            for (final entry in status.log.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        entry.time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(entry.detail, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 24),
          Text(
            'Token hanya ditampilkan 12 karakter pertama. Jangan pernah '
            'membagikan token penuh di screenshot atau log.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final PushStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permission = switch (status.permissionGranted) {
      true => 'Diberikan',
      false => 'Ditolak',
      null => 'Belum diminta',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(label: 'Izin notifikasi', value: permission),
          _Row(
            label: 'Token perangkat',
            value: status.tokenPrefix == null
                ? 'Belum tersedia'
                : '${status.tokenPrefix}...',
          ),
          _Row(
            label: 'Terkirim ke backend',
            value: status.registeredTokenPrefix == null
                ? 'Belum'
                : '${status.registeredTokenPrefix}...',
          ),
          _Row(label: 'Topik', value: status.topic ?? 'Tidak berlangganan'),
          _Row(
            label: 'Deep link terakhir',
            value: status.lastRoute == null
                ? 'Belum ada'
                : '${status.lastRoute} (${status.lastSource})',
          ),
          if (status.backendNote != null)
            _Row(label: 'Backend', value: status.backendNote!),
          if (status.isTokenPending)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Token perangkat berbeda dari yang terakhir dikirim. '
                'Kirim ulang agar backend tidak menyimpan token basi.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.detail,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 2),
            Text(detail, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
