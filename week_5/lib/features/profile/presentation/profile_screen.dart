import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _saving = false;

  Future<void> _setSize(double size) async {
    setState(() => _saving = true);
    try {
      await ref.read(lyricsSizeProvider.notifier).setSize(size);
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil')),
    body: PageBody(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.surface,
            child: Icon(
              Icons.person_outline,
              size: 32,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Koleksi pribadimu',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tanpa akun. Favorit dan riwayat disimpan di perangkat ini.',
            textAlign: TextAlign.center,
          ),
          const SectionTitle('Koleksi'),
          _ProfileRow(
            title: 'Lagu favorit',
            icon: Icons.favorite_border,
            onTap: () => context.go('/favorites'),
          ),
          _ProfileRow(
            title: 'Riwayat lagu',
            icon: Icons.history,
            onTap: () => context.push('/history'),
          ),
          const SectionTitle('Preferensi membaca'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ukuran lirik',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                AsyncContent(
                  value: ref.watch(lyricsSizeProvider),
                  loadingLabel: 'Memuat preferensi',
                  onRetry: () => ref.invalidate(lyricsSizeProvider),
                  data: (size) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [22.0, 24.0, 28.0]
                            .map(
                              (value) => ChoiceChip(
                                label: Text('${value.toInt()} px'),
                                selected: size == value,
                                onSelected: _saving
                                    ? null
                                    : (_) => _setSize(value),
                                selectedColor: AppColors.darkBlue,
                                labelStyle: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ada waktu untuk\nsetiap kata.',
                        style: TextStyle(
                          fontSize: size,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Tentang'),
          _ProfileRow(
            title: 'Tentang LyricWave',
            icon: Icons.info_outline,
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                icon: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/logo/logo.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                title: const Text('LyricWave'),
                content: Text(
                  'Versi 1.0.0\n\nTemukan lagu, baca lirik, dan simpan favorit.\n\n'
                  '${ref.read(isDemoProvider) ? 'Katalog ini berisi lagu, artis, dan lirik contoh orisinal. ' : ''}'
                  'Aplikasi ini tidak memutar atau mengunduh audio.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
          _ProfileRow(
            title: 'Data di perangkat',
            icon: Icons.storage_outlined,
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Data di perangkat'),
                content: const Text(
                  'Favorit, 50 lagu terakhir yang dibuka, dan ukuran lirik '
                  'tersimpan di perangkat ini. Data ini tidak disinkronkan ke akun. '
                  'Hapus riwayat melalui halaman Riwayat. Menghapus data aplikasi juga '
                  'menghapus koleksi lokal.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
