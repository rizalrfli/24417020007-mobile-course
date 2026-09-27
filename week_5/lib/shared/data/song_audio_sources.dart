import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const songSpotifyEmbeds = <String, String>{};

const songAudioAssets = <String, String>{
  'everything-u-are': 'assets/audio/everything-u-are.mp3',
  'nina': 'assets/audio/Feast - Nina (Official Lyric Video).mp3',
  'akad': 'assets/audio/akad.mp3',
  'peradaban': 'assets/audio/peradaban.mp3',
  'honeybee':
      'assets/audio/Olivia Rodrigo - honeybee (Full Official Audio) [HQ].mp3',
};

final songAudioSourceProvider = FutureProvider.family<String?, String>((
  ref,
  id,
) async {
  final path = songAudioAssets[id];
  if (path == null) return null;
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest.listAssets().contains(path) ? path : null;
});
