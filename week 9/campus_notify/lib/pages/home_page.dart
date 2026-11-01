import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';
import '../routes.dart';
import 'inbox_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final push = ref.watch(pushStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: 'Debug push',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => context.go(debugRoute),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _PushSummary(push: push),
          const SizedBox(height: 24),
          Text('Pengumuman', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              title: const Text('Jadwal kuliah berubah'),
              subtitle: const Text('Kelas Mobile pindah ke Ruang A2 jam 13.00'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(Routes.announcement('3')),
            ),
          ),
          const SizedBox(height: 24),
          Text('Cara menguji tiga app state', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '1. Foreground: buka Debug push, kirim banner uji, klik banner.\n'
            '2. Background: tekan Home, kirim campaign dari Firebase Console, '
            'klik banner sistem.\n'
            '3. Terminated: tutup aplikasi dari recent apps, kirim campaign, '
            'lalu klik banner.\n'
            'Ketiga jalur harus mendarat di /pengumuman/3.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PushSummary extends StatelessWidget {
  const _PushSummary({required this.push});

  final PushStatus push;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permission = switch (push.permissionGranted) {
      true => 'Izin notifikasi aktif',
      false => 'Izin notifikasi ditolak',
      null => 'Izin notifikasi belum diminta',
    };
    final token = push.tokenPrefix == null
        ? 'Token FCM belum tersedia di perangkat ini.'
        : 'Token ${push.tokenPrefix}... '
            '(${push.isTokenPending ? 'belum sinkron ke backend' : 'tersinkron ke backend'})';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(permission, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(token, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
