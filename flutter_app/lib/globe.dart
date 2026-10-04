import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Round button with a small living Earth: blue oceans, green land, turning
/// slowly around its axis. Used as the language switch.
class SpinningGlobe extends StatefulWidget {
  const SpinningGlobe({super.key, this.size = 44});

  final double size;

  @override
  State<SpinningGlobe> createState() => _SpinningGlobeState();
}

class _SpinningGlobeState extends State<SpinningGlobe> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();
  ui.Image? _earth;

  @override
  void initState() {
    super.initState();
    _loadEarth().then((ui.Image image) {
      if (mounted) setState(() => _earth = image);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    return Container(
      width: s,
      height: s,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x592A6FC4), blurRadius: 9, offset: Offset(0, 3)),
        ],
      ),
      child: AnimatedBuilder(
        animation: _spin,
        builder: (BuildContext context, Widget? _) {
          return CustomPaint(
            size: Size(s - 4, s - 4),
            painter: _EarthPainter(_earth, _spin.value),
          );
        },
      ),
    );
  }
}

Future<ui.Image>? _earthFuture;

Future<ui.Image> _loadEarth() {
  return _earthFuture ??= () async {
    final ui.Codec codec = await ui.instantiateImageCodec(base64Decode(_earthPng));
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }();
}

/// Paints the world map onto a ball, row by row, so that it looks like a
/// real globe; [phase] (0..1) is how far the Earth has turned.
class _EarthPainter extends CustomPainter {
  _EarthPainter(this.image, this.phase);

  final ui.Image? image;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final double d = size.shortestSide;
    final double r = d / 2;
    final Offset c = Offset(r, r);
    final Rect ball = Rect.fromCircle(center: c, radius: r);

    canvas.save();
    canvas.clipPath(Path()..addOval(ball));
    canvas.drawRect(ball, Paint()..color = const Color(0xFF1F78D1));

    final ui.Image? map = image;
    if (map != null) {
      final double iw = map.width.toDouble();
      final double ih = map.height.toDouble();
      final double window = iw / 2;
      final double sx = ((1 - phase) * iw) % iw;
      final Paint p = Paint()..filterQuality = FilterQuality.low;
      const int rows = 56;
      final double rowH = d / rows;
      final double srcH = ih / rows;
      for (int i = 0; i < rows; i++) {
        final double yc = (i + 0.5) / rows * 2 - 1;
        final double half = r * math.sqrt(1 - yc * yc);
        if (half < 0.3) continue;
        final double lat = math.asin(-yc);
        double top = (0.5 - lat / math.pi) * ih - srcH / 2;
        if (top < 0) top = 0;
        if (top > ih - srcH) top = ih - srcH;
        final double left = r - half;
        final double width = half * 2;
        final double y = i * rowH;
        final double first = math.min(window, iw - sx);
        final double firstW = width * first / window;
        canvas.drawImageRect(
          map,
          Rect.fromLTWH(sx, top, first, srcH),
          Rect.fromLTWH(left, y, firstW + 0.5, rowH + 0.6),
          p,
        );
        if (first < window) {
          canvas.drawImageRect(
            map,
            Rect.fromLTWH(0, top, window - first, srcH),
            Rect.fromLTWH(left + firstW, y, width - firstW, rowH + 0.6),
            p,
          );
        }
      }
    }

    // Light from the upper left, shadow on the lower right: makes it a ball.
    canvas.drawRect(
      ball,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.45),
          radius: 1.05,
          colors: <Color>[Color(0x55FFFFFF), Color(0x00FFFFFF), Color(0x7A041833)],
          stops: <double>[0, 0.5, 1],
        ).createShader(ball),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EarthPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.image != image;
}

/// Small world map (PNG, 256x128) kept inside the code so the app needs no
/// extra image file.
const String _earthPng = ''
    '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'
    'rkJggg==';
