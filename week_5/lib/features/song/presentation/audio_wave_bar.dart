import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

class AudioWaveform extends StatefulWidget {
  const AudioWaveform({
    super.key,
    required this.isPlaying,
    this.animate,
    this.height = 44,
  });

  final bool isPlaying;
  final bool? animate;
  final double height;

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _shouldAnimate {
    if (widget.animate != null) return widget.animate!;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    return widget.isPlaying;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (_shouldAnimate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isPlaying
          ? 'Animasi gelombang audio sedang berjalan'
          : 'Animasi gelombang audio nonaktif',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            height: widget.height,
            width: double.infinity,
            child: CustomPaint(
              painter: _WavePainter(
                progress: _controller.value,
                isPlaying: widget.isPlaying,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.isPlaying,
  });

  final double progress;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final width = size.width;

    // 1. Draw animated equalizer bars across width
    const barCount = 28;
    final barSpacing = width / (barCount + 1);
    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final x = barSpacing * (i + 1);
      final normalizedX = i / barCount;
      final wavePhase = normalizedX * 2 * math.pi;

      final dynamicPhase = isPlaying
          ? (progress * 2 * math.pi)
          : (math.pi / 4);

      final factor1 = math.sin(wavePhase * 2 + dynamicPhase);
      final factor2 = math.cos(wavePhase * 3 - dynamicPhase * 0.7);
      final envelope = math.sin(normalizedX * math.pi);

      final oscillation = isPlaying
          ? ((factor1 * 0.6 + factor2 * 0.4).abs() * envelope)
          : (0.15 * envelope);

      final barH = math.max(3.0, oscillation * (size.height * 0.75));

      barPaint.color = isPlaying
          ? Color.lerp(
              AppColors.primary,
              AppColors.active,
              (normalizedX + progress) % 1.0,
            )!.withValues(alpha: 0.45 + 0.35 * envelope)
          : AppColors.muted.withValues(alpha: 0.25);

      final barRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, midY),
          width: 3.0,
          height: barH,
        ),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(barRect, barPaint);
    }

    // 2. Draw flowing wave curve 1 (primary)
    final path1 = Path();
    final amp1 = isPlaying ? size.height * 0.32 : size.height * 0.08;
    final phase1 = isPlaying ? progress * 2 * math.pi : 0.0;

    path1.moveTo(0, midY);
    for (double x = 0; x <= width; x += 4) {
      final norm = x / width;
      final env = math.sin(norm * math.pi);
      final y = midY + math.sin(norm * 3 * math.pi + phase1) * amp1 * env;
      path1.lineTo(x, y);
    }

    final wavePaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = isPlaying
          ? AppColors.active.withValues(alpha: 0.9)
          : AppColors.muted.withValues(alpha: 0.4);

    canvas.drawPath(path1, wavePaint1);

    // 3. Draw secondary harmonic wave curve 2 (counter-flowing)
    final path2 = Path();
    final amp2 = isPlaying ? size.height * 0.22 : size.height * 0.05;
    final phase2 = isPlaying ? -progress * 2.4 * math.pi : math.pi / 2;

    path2.moveTo(0, midY);
    for (double x = 0; x <= width; x += 4) {
      final norm = x / width;
      final env = math.sin(norm * math.pi);
      final y = midY + math.sin(norm * 4 * math.pi + phase2) * amp2 * env;
      path2.lineTo(x, y);
    }

    final wavePaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = isPlaying
          ? AppColors.primary.withValues(alpha: 0.75)
          : AppColors.muted.withValues(alpha: 0.25);

    canvas.drawPath(path2, wavePaint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}
