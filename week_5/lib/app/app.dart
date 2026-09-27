import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class LyricWaveApp extends ConsumerWidget {
  const LyricWaveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GoogleFonts.config.allowRuntimeFetching = false;
    return MaterialApp.router(
      title: 'LyricWave',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
