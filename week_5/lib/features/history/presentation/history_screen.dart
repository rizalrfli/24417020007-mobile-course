import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _clearing = false;

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus riwayat lagu?'),
        content: const Text(
          'Daftar terakhir dilihat akan dikosongkan. Favorit tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus riwayat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    try {
      await ref.read(libraryActionsProvider.notifier).clearHistory();
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        actions: [
          if (history.valueOrNull?.isNotEmpty ?? false)
            IconButton(
              tooltip: 'Hapus riwayat',
              onPressed: _clearing ? null : _clear,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: PageBody(
        child: history.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingSkeleton(),
          ),
          error: (error, _) => ListView(
            children: [
              ErrorState(
                error: error,
                onRetry: () => ref.invalidate(historyProvider),
              ),
            ],
          ),
          data: (songs) => songs.isEmpty
              ? ListView(
                  children: [
                    EmptyState(
                      title: 'Riwayat masih kosong',
                      message: 'Buka lagu untuk mulai menyimpan riwayat.',
                      icon: Icons.history,
                      action: 'Cari lagu',
                      onAction: () => context.go('/search'),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: songs.length + 1,
                  itemBuilder: (context, index) => index == 0
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            '50 lagu terakhir, dari yang paling baru.',
                          ),
                        )
                      : SongTile(song: songs[index - 1]),
                ),
        ),
      ),
    );
  }
}
