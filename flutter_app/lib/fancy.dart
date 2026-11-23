import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'data.dart';
import 'widgets.dart';

// ---------------------------------------------------------------- texts

const Map<String, Map<String, String>> _fx = <String, Map<String, String>>{
  'nl': <String, String>{
    'tabCustomers': 'Melders',
    'tabTeam': 'Team',
    'teamTitle': 'Teamchat schoonmakers',
    'teamHint': 'Alleen schoonmakers zien dit. Spreek af wie welke klus doet of geef een klus door.',
    'teamEmpty': 'Nog geen berichten. Begin het gesprek!',
    'teamSetup': 'De teamchat wordt nog ingeschakeld. Probeer het later opnieuw.',
    'teamPh': 'Bericht aan het team…',
  },
  'en': <String, String>{
    'tabCustomers': 'Reporters',
    'tabTeam': 'Team',
    'teamTitle': 'Cleaners team chat',
    'teamHint': 'Only cleaners can see this. Agree who takes which job or hand a job over.',
    'teamEmpty': 'No messages yet. Start the conversation!',
    'teamSetup': 'The team chat is being switched on. Please try again later.',
    'teamPh': 'Message to the team…',
  },
  'ru': <String, String>{
    'tabCustomers': 'Заказчики',
    'tabTeam': 'Команда',
    'teamTitle': 'Чат исполнителей',
    'teamHint': 'Видят только исполнители. Договоритесь, кто берёт заказ, или передайте его другому.',
    'teamEmpty': 'Сообщений пока нет. Напишите первым!',
    'teamSetup': 'Командный чат ещё включается. Попробуйте позже.',
    'teamPh': 'Сообщение команде…',
  },
  'ar': <String, String>{
    'tabCustomers': 'المبلّغون',
    'tabTeam': 'الفريق',
    'teamTitle': 'دردشة فريق التنظيف',
    'teamHint': 'يراها عمال التنظيف فقط. اتفقوا على من يأخذ المهمة أو سلّموها لزميل.',
    'teamEmpty': 'لا توجد رسائل بعد. ابدأ المحادثة!',
    'teamSetup': 'يتم تفعيل دردشة الفريق. حاول لاحقاً.',
    'teamPh': 'رسالة إلى الفريق…',
  },
};

String fx(String key) => _fx[I18n.lang.value]?[key] ?? _fx['en']?[key] ?? key;

// ---------------------------------------------------------------- 3D icons

enum Icon3DKind { wallet, notebook, chat, person, house, camera, broom }

/// Colourful, shaded icons that look like small 3D objects.
class Icon3D extends StatelessWidget {
  const Icon3D(this.kind, {super.key, this.size = 28, this.dim = false});

  final Icon3DKind kind;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final Widget icon = kind == Icon3DKind.broom
        ? SweepingBroom(size: size, animate: !dim)
        : CustomPaint(size: Size.square(size), painter: _Icon3DPainter(kind));
    if (!dim) return icon;
    return Opacity(opacity: 0.5, child: icon);
  }
}

Shader _lin(Rect r, List<Color> c, {Alignment b = Alignment.topLeft, Alignment e = Alignment.bottomRight}) =>
    LinearGradient(begin: b, end: e, colors: c).createShader(r);

void _shadow(Canvas canvas, Rect r, double s) {
  canvas.drawOval(
    Rect.fromCenter(center: Offset(r.center.dx, r.bottom + s * 0.02), width: r.width * 0.9, height: s * 0.12),
    Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04),
  );
}

void _gloss(Canvas canvas, RRect r) {
  final Rect top = Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.5);
  canvas.save();
  canvas.clipRRect(r);
  canvas.drawRect(
    top,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0x66FFFFFF), Color(0x00FFFFFF)],
      ).createShader(top),
  );
  canvas.restore();
}

class _Icon3DPainter extends CustomPainter {
  _Icon3DPainter(this.kind);

  final Icon3DKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    switch (kind) {
      case Icon3DKind.wallet:
        _wallet(canvas, s);
      case Icon3DKind.notebook:
        _notebook(canvas, s);
      case Icon3DKind.chat:
        _chat(canvas, s);
      case Icon3DKind.person:
        _person(canvas, s);
      case Icon3DKind.house:
        _house(canvas, s);
      case Icon3DKind.camera:
        _camera(canvas, s);
      case Icon3DKind.broom:
        break;
    }
  }

  void _wallet(Canvas canvas, double s) {
    final Rect body = Rect.fromLTWH(s * 0.06, s * 0.32, s * 0.88, s * 0.58);
    _shadow(canvas, body, s);
    // Banknotes sticking out of the top.
    for (int i = 0; i < 3; i++) {
      final Rect note = Rect.fromLTWH(s * (0.14 + i * 0.06), s * (0.12 + i * 0.05), s * 0.6, s * 0.36);
      canvas.save();
      canvas.translate(note.center.dx, note.center.dy);
      canvas.rotate(-0.22 + i * 0.16);
      canvas.translate(-note.center.dx, -note.center.dy);
      final RRect n = RRect.fromRectAndRadius(note, Radius.circular(s * 0.04));
      canvas.drawRRect(n, Paint()..shader = _lin(note, const <Color>[Color(0xFF8EE6A0), Color(0xFF2E9E57)]));
      canvas.drawRRect(
        n.deflate(s * 0.04),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.018
          ..color = const Color(0x88FFFFFF),
      );
      canvas.drawCircle(note.center, s * 0.07, Paint()..color = const Color(0x66FFFFFF));
      canvas.restore();
    }
    // Leather body.
    final RRect b = RRect.fromRectAndRadius(body, Radius.circular(s * 0.12));
    canvas.drawRRect(b, Paint()..shader = _lin(body, const <Color>[Color(0xFFB0703A), Color(0xFF7A4520), Color(0xFF5A2F14)]));
    // Stitching.
    final Paint stitch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.016
      ..color = const Color(0x99FFD9A8);
    final Path dash = Path()..addRRect(b.deflate(s * 0.05));
    for (final ui in dash.computeMetrics()) {
      for (double d = 0; d < ui.length; d += s * 0.07) {
        canvas.drawPath(ui.extractPath(d, d + s * 0.035), stitch);
      }
    }
    _gloss(canvas, b);
    // Strap with a golden button.
    final Rect strap = Rect.fromLTWH(s * 0.56, s * 0.46, s * 0.4, s * 0.26);
    final RRect st = RRect.fromRectAndRadius(strap, Radius.circular(s * 0.1));
    canvas.drawRRect(st, Paint()..shader = _lin(strap, const <Color>[Color(0xFF9A5A2C), Color(0xFF5E3216)]));
    final Offset btn = Offset(s * 0.8, strap.center.dy);
    canvas.drawCircle(
      btn,
      s * 0.07,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: <Color>[Color(0xFFFFF4B0), Color(0xFFF2B818), Color(0xFFB07A00)],
        ).createShader(Rect.fromCircle(center: btn, radius: s * 0.07)),
    );
    // A coin in front.
    final Offset coin = Offset(s * 0.22, s * 0.8);
    final Rect cr = Rect.fromCircle(center: coin, radius: s * 0.13);
    canvas.drawCircle(coin, s * 0.13, Paint()..color = const Color(0xFFA06C00));
    canvas.drawCircle(
      coin.translate(0, -s * 0.02),
      s * 0.13,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: <Color>[Color(0xFFFFF6C2), Color(0xFFFFC928), Color(0xFFD99A00)],
        ).createShader(cr),
    );
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '€',
        style: TextStyle(fontSize: s * 0.17, fontWeight: FontWeight.w900, color: const Color(0xFFA06C00)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, coin.translate(-tp.width / 2, -tp.height / 2 - s * 0.02));
  }

  void _notebook(Canvas canvas, double s) {
    final Rect cover = Rect.fromLTWH(s * 0.18, s * 0.08, s * 0.68, s * 0.84);
    _shadow(canvas, cover, s);
    // Pages (visible at the side).
    final Rect pages = cover.translate(s * 0.05, s * 0.02);
    canvas.drawRRect(RRect.fromRectAndRadius(pages, Radius.circular(s * 0.08)), Paint()..color = const Color(0xFFF4EEE4));
    final RRect c = RRect.fromRectAndRadius(cover, Radius.circular(s * 0.08));
    canvas.drawRRect(c, Paint()..shader = _lin(cover, const <Color>[Color(0xFF6FB6FF), Color(0xFF2E7FD9), Color(0xFF1D5CA8)]));
    // Label.
    final Rect label = Rect.fromLTWH(s * 0.34, s * 0.24, s * 0.42, s * 0.24);
    canvas.drawRRect(RRect.fromRectAndRadius(label, Radius.circular(s * 0.04)), Paint()..color = const Color(0xFFFFFFFF));
    final Paint line = Paint()
      ..color = const Color(0xFF9DB8D9)
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * 0.4, s * 0.32), Offset(s * 0.7, s * 0.32), line);
    canvas.drawLine(Offset(s * 0.4, s * 0.4), Offset(s * 0.62, s * 0.4), line);
    // Check mark.
    final Path check = Path()
      ..moveTo(s * 0.4, s * 0.66)
      ..lineTo(s * 0.5, s * 0.75)
      ..lineTo(s * 0.7, s * 0.56);
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF7CF0A0),
    );
    _gloss(canvas, c);
    // Spiral rings.
    for (int i = 0; i < 5; i++) {
      final double y = s * (0.18 + i * 0.15);
      final Rect ring = Rect.fromCenter(center: Offset(s * 0.19, y), width: s * 0.16, height: s * 0.07);
      canvas.drawRRect(
        RRect.fromRectAndRadius(ring, Radius.circular(s * 0.04)),
        Paint()..shader = _lin(ring, const <Color>[Color(0xFFFFFFFF), Color(0xFF9AA4B0)], b: Alignment.topCenter, e: Alignment.bottomCenter),
      );
    }
    // Orange bookmark ribbon.
    final Path ribbon = Path()
      ..moveTo(s * 0.68, s * 0.08)
      ..lineTo(s * 0.78, s * 0.08)
      ..lineTo(s * 0.78, s * 0.98)
      ..lineTo(s * 0.73, s * 0.92)
      ..lineTo(s * 0.68, s * 0.98)
      ..close();
    canvas.drawPath(ribbon, Paint()..shader = _lin(cover, const <Color>[Color(0xFFFFA45C), Color(0xFFE85A0C)]));
  }

  void _chat(Canvas canvas, double s) {
    // Back bubble (blue).
    final Rect back = Rect.fromLTWH(s * 0.36, s * 0.1, s * 0.58, s * 0.46);
    final RRect bb = RRect.fromRectAndRadius(back, Radius.circular(s * 0.2));
    _shadow(canvas, Rect.fromLTWH(s * 0.06, s * 0.3, s * 0.88, s * 0.6), s);
    canvas.drawRRect(bb, Paint()..shader = _lin(back, const <Color>[Color(0xFF8CC8FF), Color(0xFF2E7FD9)]));
    final Path backTail = Path()
      ..moveTo(s * 0.78, s * 0.5)
      ..lineTo(s * 0.9, s * 0.64)
      ..lineTo(s * 0.66, s * 0.54)
      ..close();
    canvas.drawPath(backTail, Paint()..color = const Color(0xFF2E7FD9));
    _gloss(canvas, bb);
    // Front bubble (orange).
    final Rect front = Rect.fromLTWH(s * 0.06, s * 0.3, s * 0.62, s * 0.48);
    final RRect fb = RRect.fromRectAndRadius(front, Radius.circular(s * 0.22));
    final Path frontTail = Path()
      ..moveTo(s * 0.18, s * 0.7)
      ..lineTo(s * 0.1, s * 0.92)
      ..lineTo(s * 0.34, s * 0.76)
      ..close();
    canvas.drawPath(frontTail, Paint()..color = const Color(0xFFE85A0C));
    canvas.drawRRect(fb, Paint()..shader = _lin(front, const <Color>[Color(0xFFFFB574), Color(0xFFFF6A1A), Color(0xFFE0500A)]));
    _gloss(canvas, fb);
    for (int i = 0; i < 3; i++) {
      final Offset d = Offset(s * (0.22 + i * 0.15), front.center.dy);
      canvas.drawCircle(
        d,
        s * 0.05,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.4),
            colors: <Color>[Color(0xFFFFFFFF), Color(0xFFFFE3CF)],
          ).createShader(Rect.fromCircle(center: d, radius: s * 0.05)),
      );
    }
  }

  void _person(Canvas canvas, double s) {
    final Rect bodyR = Rect.fromLTWH(s * 0.14, s * 0.52, s * 0.72, s * 0.44);
    _shadow(canvas, bodyR, s);
    // Shoulders in the orange company jacket.
    final Path body = Path()
      ..moveTo(bodyR.left, bodyR.bottom)
      ..quadraticBezierTo(bodyR.left, bodyR.top, bodyR.center.dx, bodyR.top)
      ..quadraticBezierTo(bodyR.right, bodyR.top, bodyR.right, bodyR.bottom)
      ..close();
    canvas.drawPath(body, Paint()..shader = _lin(bodyR, const <Color>[Color(0xFFFFB574), Color(0xFFFF6A1A), Color(0xFFC24A06)]));
    // Reflective stripe.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      Rect.fromLTWH(bodyR.left, bodyR.top + bodyR.height * 0.48, bodyR.width, s * 0.07),
      Paint()..color = const Color(0xCCFFF6D0),
    );
    canvas.restore();
    // Head.
    final Offset head = Offset(s * 0.5, s * 0.32);
    final Rect hr = Rect.fromCircle(center: head, radius: s * 0.2);
    canvas.drawCircle(
      head,
      s * 0.2,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: <Color>[Color(0xFFFFE6CC), Color(0xFFF2B98A), Color(0xFFC98656)],
        ).createShader(hr),
    );
    // Hair / cap.
    final Path cap = Path()
      ..addArc(Rect.fromCircle(center: head, radius: s * 0.205), math.pi * 1.05, math.pi * 0.9)
      ..close();
    canvas.drawPath(cap, Paint()..shader = _lin(hr, const <Color>[Color(0xFF5A4636), Color(0xFF2A1E16)]));
  }

  void _house(Canvas canvas, double s) {
    final Rect walls = Rect.fromLTWH(s * 0.18, s * 0.44, s * 0.64, s * 0.48);
    _shadow(canvas, walls, s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(walls, Radius.circular(s * 0.04)),
      Paint()..shader = _lin(walls, const <Color>[Color(0xFFFFF6EA), Color(0xFFF1D9BE)]),
    );
    // Side wall for depth.
    final Path side = Path()
      ..moveTo(walls.right, walls.top)
      ..lineTo(walls.right + s * 0.08, walls.top - s * 0.04)
      ..lineTo(walls.right + s * 0.08, walls.bottom - s * 0.04)
      ..lineTo(walls.right, walls.bottom)
      ..close();
    canvas.drawPath(side, Paint()..color = const Color(0xFFD9B993));
    // Roof.
    final Path roof = Path()
      ..moveTo(s * 0.08, s * 0.48)
      ..lineTo(s * 0.5, s * 0.1)
      ..lineTo(s * 0.92, s * 0.44)
      ..lineTo(s * 0.86, s * 0.5)
      ..lineTo(s * 0.5, s * 0.2)
      ..lineTo(s * 0.14, s * 0.54)
      ..close();
    canvas.drawPath(roof, Paint()..shader = _lin(Rect.fromLTWH(0, 0, s, s * 0.55), const <Color>[Color(0xFFFF8A4C), Color(0xFFD9432B)]));
    // Door.
    final Rect door = Rect.fromLTWH(s * 0.42, s * 0.62, s * 0.18, s * 0.3);
    canvas.drawRRect(
      RRect.fromRectAndCorners(door, topLeft: Radius.circular(s * 0.09), topRight: Radius.circular(s * 0.09)),
      Paint()..shader = _lin(door, const <Color>[Color(0xFFB0703A), Color(0xFF6A3A18)]),
    );
    canvas.drawCircle(Offset(s * 0.56, s * 0.78), s * 0.018, Paint()..color = const Color(0xFFFFD34D));
    // Window with light.
    final Rect win = Rect.fromLTWH(s * 0.24, s * 0.58, s * 0.13, s * 0.13);
    canvas.drawRRect(
      RRect.fromRectAndRadius(win, Radius.circular(s * 0.02)),
      Paint()..shader = _lin(win, const <Color>[Color(0xFFBFE3FF), Color(0xFF5AA8F0)]),
    );
    // Chimney.
    canvas.drawRect(Rect.fromLTWH(s * 0.66, s * 0.18, s * 0.08, s * 0.14), Paint()..color = const Color(0xFFB0352A));
  }

  void _camera(Canvas canvas, double s) {
    final Rect body = Rect.fromLTWH(s * 0.06, s * 0.28, s * 0.88, s * 0.6);
    _shadow(canvas, body, s);
    final RRect b = RRect.fromRectAndRadius(body, Radius.circular(s * 0.14));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.32, s * 0.16, s * 0.36, s * 0.2), Radius.circular(s * 0.06)),
      Paint()..color = const Color(0xFF3A3A44),
    );
    canvas.drawRRect(b, Paint()..shader = _lin(body, const <Color>[Color(0xFF6A6A78), Color(0xFF2A2A33)]));
    _gloss(canvas, b);
    final Offset lens = Offset(s * 0.5, s * 0.58);
    canvas.drawCircle(lens, s * 0.22, Paint()..color = const Color(0xFFDDDDE4));
    canvas.drawCircle(
      lens,
      s * 0.17,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: <Color>[Color(0xFF7FC4FF), Color(0xFF1D4F8C), Color(0xFF0A1A30)],
        ).createShader(Rect.fromCircle(center: lens, radius: s * 0.17)),
    );
    canvas.drawCircle(lens.translate(-s * 0.06, -s * 0.06), s * 0.04, Paint()..color = const Color(0xCCFFFFFF));
    canvas.drawCircle(Offset(s * 0.8, s * 0.38), s * 0.04, Paint()..color = const Color(0xFFFF6A1A));
  }

  @override
  bool shouldRepaint(covariant _Icon3DPainter oldDelegate) => oldDelegate.kind != kind;
}

// ---------------------------------------------------------------- broom

/// A living broom: it sweeps back and forth and kicks up a little dust.
class SweepingBroom extends StatefulWidget {
  const SweepingBroom({super.key, this.size = 28, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<SweepingBroom> createState() => _SweepingBroomState();
}

class _SweepingBroomState extends State<SweepingBroom> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant SweepingBroom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _BroomPainter(_c.value),
        ),
      ),
    );
  }
}

class _BroomPainter extends CustomPainter {
  _BroomPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double swing = math.sin(t * 2 * math.pi);
    // Floor shadow follows the bristles.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * (0.5 + swing * 0.12), s * 0.95), width: s * 0.6, height: s * 0.08),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
    );
    // Dust puffs on the side the broom moves to.
    for (int i = 0; i < 3; i++) {
      final double p = (t * 2 + i / 3) % 1;
      final double dir = swing >= 0 ? 1 : -1;
      final Offset c = Offset(s * (0.5 + dir * (0.28 + p * 0.18)), s * (0.9 - p * 0.18));
      canvas.drawCircle(
        c,
        s * (0.03 + p * 0.05),
        Paint()..color = Color.fromRGBO(190, 170, 140, (1 - p) * 0.55),
      );
    }
    canvas.save();
    // Pivot near the top of the handle, like a hand holding it.
    canvas.translate(s * 0.5, s * 0.06);
    canvas.rotate(swing * 0.32);
    canvas.translate(-s * 0.5, -s * 0.06);
    // Wooden handle.
    final Rect handle = Rect.fromLTWH(s * 0.46, s * 0.02, s * 0.08, s * 0.58);
    canvas.drawRRect(
      RRect.fromRectAndRadius(handle, Radius.circular(s * 0.04)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFE2B07A), Color(0xFFB0703A), Color(0xFF7A4520)],
        ).createShader(handle),
    );
    // Straw bristles.
    final Path straw = Path()
      ..moveTo(s * 0.4, s * 0.6)
      ..lineTo(s * 0.6, s * 0.6)
      ..quadraticBezierTo(s * 0.84, s * 0.78, s * 0.8, s * 0.94)
      ..lineTo(s * 0.2, s * 0.94)
      ..quadraticBezierTo(s * 0.16, s * 0.78, s * 0.4, s * 0.6)
      ..close();
    final Rect sr = Rect.fromLTWH(s * 0.16, s * 0.6, s * 0.68, s * 0.34);
    canvas.drawPath(straw, Paint()..shader = _lin(sr, const <Color>[Color(0xFFFFE08A), Color(0xFFF2B818), Color(0xFFC98A00)]));
    final Paint fibre = Paint()
      ..color = const Color(0x66A06C00)
      ..strokeWidth = s * 0.012;
    for (int i = 0; i < 9; i++) {
      final double x = s * (0.26 + i * 0.06);
      canvas.drawLine(Offset(s * 0.5 + (x - s * 0.5) * 0.4, s * 0.64), Offset(x, s * 0.93), fibre);
    }
    // Red binding band.
    final Rect band = Rect.fromLTWH(s * 0.37, s * 0.58, s * 0.26, s * 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, Radius.circular(s * 0.03)),
      Paint()..shader = _lin(band, const <Color>[Color(0xFFFF8A4C), Color(0xFFD9432B)], b: Alignment.topCenter, e: Alignment.bottomCenter),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BroomPainter oldDelegate) => oldDelegate.t != t;
}

// ---------------------------------------------------------------- team chat

/// Chat room only for cleaners: they can agree who takes which job or hand a
/// job over. Reporters never see it. Messages are kept in the database, so
/// the company can check them when something looks suspicious.
class TeamChatView extends StatefulWidget {
  const TeamChatView({super.key, required this.myId, required this.myName});

  final String myId;
  final String myName;

  @override
  State<TeamChatView> createState() => _TeamChatViewState();
}

class _TeamChatViewState extends State<TeamChatView> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  bool _broken = false;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<Map<String, dynamic>> data = await db
          .from('team_messages')
          .select()
          .order('created_at', ascending: true)
          .limit(300);
      if (!mounted) return;
      final bool grew = data.length != _messages.length;
      setState(() {
        _messages = data;
        _broken = false;
      });
      if (grew) _toBottom();
    } catch (_) {
      if (mounted && !_broken) setState(() => _broken = true);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty) return;
    final Map<String, dynamic> row = <String, dynamic>{
      'id': uid(),
      'sender_id': widget.myId,
      'sender_name': widget.myName,
      'text': text,
      'created_at': nowMs(),
    };
    _input.clear();
    setState(() => _messages = <Map<String, dynamic>>[..._messages, row]);
    _toBottom();
    try {
      await db.from('team_messages').insert(row);
    } catch (_) {
      if (mounted) setState(() => _broken = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: C.blueSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              const SweepingBroom(size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(fx('teamTitle'), style: const TextStyle(fontWeight: FontWeight.w700, color: C.ink)),
                    const SizedBox(height: 2),
                    Text(fx('teamHint'), style: const TextStyle(fontSize: 12, color: C.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_broken)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(fx('teamSetup'), style: const TextStyle(fontSize: 12.5, color: C.danger)),
          ),
        Expanded(
          child: _messages.isEmpty
              ? Center(child: Text(fx('teamEmpty'), style: metaStyle))
              : ListView.builder(
                  controller: _scroll,
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext ctx, int i) {
                    final Map<String, dynamic> m = _messages[i];
                    final bool mine = (m['sender_id'] ?? '').toString() == widget.myId;
                    final String name = (m['sender_name'] ?? '').toString();
                    return Align(
                      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                        decoration: BoxDecoration(
                          gradient: mine
                              ? const LinearGradient(colors: <Color>[Color(0xFFFF8A3D), Color(0xFFE85A0C)])
                              : null,
                          color: mine ? null : C.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: mine ? null : Border.all(color: C.border),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (!mine && name.isNotEmpty)
                              Text(
                                name,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.blue),
                              ),
                            Text(
                              (m['text'] ?? '').toString(),
                              style: TextStyle(fontSize: 14, height: 1.35, color: mine ? Colors.white : C.ink),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _input,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: smInput(fx('teamPh')),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: C.accent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _send,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// For cleaners: switch between the chats with reporters and the team chat.
class ExecutorChats extends StatefulWidget {
  const ExecutorChats({super.key, required this.customers, required this.myId, required this.myName});

  final Widget customers;
  final String myId;
  final String myName;

  @override
  State<ExecutorChats> createState() => _ExecutorChatsState();
}

class _ExecutorChatsState extends State<ExecutorChats> {
  bool _team = false;

  Widget _tab(String label, bool selected, VoidCallback onTap, Widget icon) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? C.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const <BoxShadow>[BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: selected ? C.accentDark : C.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: C.accentSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: <Widget>[
              _tab(fx('tabCustomers'), !_team, () => setState(() => _team = false),
                  const Icon3D(Icon3DKind.chat, size: 20)),
              _tab(fx('tabTeam'), _team, () => setState(() => _team = true),
                  Icon3D(Icon3DKind.broom, size: 20, dim: !_team)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _team ? TeamChatView(myId: widget.myId, myName: widget.myName) : widget.customers,
        ),
      ],
    );
  }
}
