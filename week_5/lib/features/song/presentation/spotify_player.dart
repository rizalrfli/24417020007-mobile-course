import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'song_audio_controller.dart';
import 'spotify_view_native.dart'
    if (dart.library.js_interop) 'spotify_view_web.dart';

class SpotifyPlayer extends ConsumerStatefulWidget {
  const SpotifyPlayer({super.key, required this.url});
  final String url;

  @override
  ConsumerState<SpotifyPlayer> createState() => _SpotifyPlayerState();
}

class _SpotifyPlayerState extends ConsumerState<SpotifyPlayer> {
  bool _opened = false;
  bool _busy = false;
  int _revision = 0;

  Future<void> _open() async {
    setState(() => _busy = true);
    await ref.read(songPlayerProvider).stop();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _opened = true;
      _revision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final supported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!supported) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Pemutar Spotify tersedia di browser, Android, dan iOS.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_opened)
            SizedBox(
              height: 152,
              width: double.infinity,
              child: SpotifyView(
                key: ValueKey(_revision),
                url: '${widget.url}?theme=0',
              ),
            ),
          TextButton(
            onPressed: _busy ? null : _open,
            child: Text(
              _busy
                  ? 'Memuat pemutar...'
                  : _opened
                  ? 'Muat ulang pemutar Spotify'
                  : 'Muat pemutar Spotify',
            ),
          ),
          const Text(
            'Tekan Play di pemutar Spotify. Pemutaran mungkin terbatas pada cuplikan.',
          ),
        ],
      ),
    );
  }
}
