import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_notify/presentation/routes.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
        title: const Text('Pengumuman'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Jadwal kuliah berubah', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('ID pengumuman: $id', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Text(
            'Kelas Mobile pindah ke Ruang A2 jam 13.00.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Halaman ini adalah tujuan deep link dari notifikasi. '
              'Membukanya dari klik banner membuktikan data.route pada payload '
              'benar-benar dipakai, bukan hanya dicetak ke log.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
