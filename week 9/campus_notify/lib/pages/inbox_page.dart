import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/inbox_item.dart';
import '../providers/inbox_provider.dart';
import '../routes.dart';

/// Ikon lonceng dengan angka notifikasi belum dibaca.
///
/// Angka diambil dari [unreadCountProvider] yang juga menjadi sumber data
/// halaman daftar, sehingga angka dan isi daftar tidak pernah berbeda.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final tooltip = unread == 0
        ? 'Notifikasi'
        : '$unread notifikasi belum dibaca';

    return IconButton(
      tooltip: tooltip,
      onPressed: () => context.go(Routes.inbox),
      icon: Badge(
        // Nol berarti tidak ada notifikasi: badge disembunyikan, bukan
        // menampilkan angka 0 yang membuat pengguna mencari isi kosong.
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

/// Daftar notifikasi yang belum dibaca.
///
/// Mengetuk satu butir menandainya sebagai dibaca, sehingga butir hilang dari
/// daftar dan angka di lonceng ikut berkurang.
class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inbox = ref.watch(inboxProvider);
    final items = inbox.valueOrNull ?? const <InboxItem>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
        title: Text(
          items.isEmpty ? 'Notifikasi' : 'Notifikasi (${items.length})',
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Tandai semua dibaca',
              icon: const Icon(Icons.done_all),
              onPressed: () =>
                  ref.read(inboxProvider.notifier).clearAll(),
            ),
        ],
      ),
      body: switch (inbox) {
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncError(:final error) => _InboxError(error: error),
        _ when items.isEmpty => const _EmptyInbox(),
        _ => ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.campaign_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  item.timeLabel,
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () async {
                  // Dibaca lalu dibuka. Butir dihapus lebih dulu supaya badge
                  // langsung turun walau navigasi gagal.
                  await ref.read(inboxProvider.notifier).markRead(item.id);
                  if (!context.mounted) return;
                  context.go(item.route);
                },
              );
            },
          ),
      },
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada notifikasi baru',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Pengumuman yang masuk akan muncul di sini dan hilang setelah '
              'dibuka.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxError extends ConsumerWidget {
  const _InboxError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text('Gagal membaca daftar notifikasi: $error'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.read(inboxProvider.notifier).reload(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
