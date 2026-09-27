import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class SpotifyView extends StatelessWidget {
  const SpotifyView({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final frame = element as web.HTMLIFrameElement;
      frame
        ..src = url
        ..title = 'Spotify: honeybee - Olivia Rodrigo'
        ..allow =
            'autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture'
        ..allowFullscreen = true;
      frame.style
        ..width = '100%'
        ..height = '100%'
        ..border = '0'
        ..borderRadius = '12px';
    },
  );
}
