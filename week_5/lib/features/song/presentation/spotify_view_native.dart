import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SpotifyView extends StatefulWidget {
  const SpotifyView({super.key, required this.url});
  final String url;

  @override
  State<SpotifyView> createState() => _SpotifyViewState();
}

class _SpotifyViewState extends State<SpotifyView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _load();
  }

  Future<void> _load() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => _failed = true);
            }
          },
        ),
      );
      await _controller.loadRequest(Uri.parse(widget.url));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text('Spotify gagal dimuat. Periksa koneksi lalu muat ulang.'),
      );
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
