import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/note_providers.dart';
import '../widgets/note_form_dialog.dart';

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByIdProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          noteAsync.whenOrNull(
            data: (note) => note == null
                ? null
                : IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final result = await showDialog<NoteFormResult>(
                        context: context,
                        builder: (_) => NoteFormDialog(initial: note),
                      );
                      if (result == null) return;
                      await ref
                          .read(noteActionsProvider)
                          .update(note.copyWith(title: result.title, body: result.body));
                      ref.invalidate(noteByIdProvider(id));
                    },
                  ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text('Gagal memuat catatan: $e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
        data: (note) {
          if (note == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.note_alt_outlined, size: 64),
                  const SizedBox(height: 12),
                  const Text('Catatan tidak ditemukan.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      note.dirty ? Icons.cloud_off : Icons.cloud_done,
                      color: note.dirty ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      note.dirty ? 'Belum tersinkron' : 'Tersinkron',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: note.dirty ? Colors.orange : Colors.green,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Diperbarui: ${note.updatedAt.toLocal().toString().substring(0, 16)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 32),
                Text(
                  note.body.isEmpty ? '(tanpa isi)' : note.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
