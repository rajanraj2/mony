import 'package:flutter/material.dart';

class MonyLogo extends StatelessWidget {
  final double size;
  final bool hasSquircleBackground;
  final bool showText;
  final double? fontSize;

  const MonyLogo({
    super.key,
    this.size = 36,
    this.hasSquircleBackground = true,
    this.showText = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MonyLogoPainter(hasSquircleBackground: hasSquircleBackground),
      ),
    );

    if (!showText) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00F5A0), Color(0xFF06B6D4), Color(0xFF38BDF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Mony',
            style: TextStyle(
              fontSize: fontSize ?? (size * 0.75),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonyLogoPainter extends CustomPainter {
  final bool hasSquircleBackground;

  _MonyLogoPainter({required this.hasSquircleBackground});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Draw Squircle Base Plate if enabled
    if (hasSquircleBackground) {
      final rrect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 512, 512),
        const Radius.circular(128),
      );

      final bgPaint = Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.8,
          colors: [Color(0xFF0E1726), Color(0xFF04060A)],
        ).createShader(const Rect.fromLTWH(0, 0, 512, 512));
      canvas.drawRRect(rrect, bgPaint);

      // Border Highlight
      final borderPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x8010B981),
            Color(0x1AFFFFFF),
            Color(0x6606B6D4),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 512, 512))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRRect(rrect.deflate(1.5), borderPaint);

      // Ambient Core Glow
      final glowPaint = Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0x4D00F5A0),
            Color(0x1A00D09C),
            Color(0x0000D09C),
          ],
          radius: 0.6,
        ).createShader(const Rect.fromLTWH(81, 70, 350, 350));
      canvas.drawCircle(const Offset(256, 245), 175, glowPaint);
    }

    // 2. Left Wing Stemma
    final leftPath = Path()
      ..moveTo(124, 372)
      ..lineTo(124, 220)
      ..cubicTo(124, 204, 134, 190, 149, 184)
      ..lineTo(204, 162)
      ..lineTo(204, 316)
      ..cubicTo(204, 332, 194, 346, 179, 352)
      ..close();

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topCenter,
        colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF00F5A0)],
      ).createShader(const Rect.fromLTWH(124, 162, 80, 210));
    canvas.drawPath(leftPath, leftPaint);

    // 3. Right Return Stemma
    final rightPath = Path()
      ..moveTo(388, 372)
      ..lineTo(388, 220)
      ..cubicTo(388, 204, 378, 190, 363, 184)
      ..lineTo(308, 162)
      ..lineTo(308, 316)
      ..cubicTo(308, 332, 318, 346, 333, 352)
      ..close();

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF0F766E), Color(0xFF06B6D4), Color(0xFF00E5FF)],
      ).createShader(const Rect.fromLTWH(308, 162, 80, 210));
    canvas.drawPath(rightPath, rightPaint);

    // 4. Center Folded Growth Arrow
    final centerPath = Path()
      ..moveTo(179, 240)
      ..lineTo(242, 144)
      ..cubicTo(250, 132, 262, 132, 270, 144)
      ..lineTo(333, 240)
      ..lineTo(282, 260)
      ..lineTo(256, 220)
      ..lineTo(230, 260)
      ..close();

    final centerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF047857), Color(0xFF00D09C), Color(0xFF38BDF8)],
      ).createShader(const Rect.fromLTWH(179, 132, 154, 128));
    canvas.drawPath(centerPath, centerPaint);

    // 5. Intersecting Mobius Core Segment
    final mobiusPath = Path()
      ..moveTo(204, 274)
      ..lineTo(256, 210)
      ..lineTo(308, 274)
      ..lineTo(280, 348)
      ..cubicTo(268, 356, 244, 356, 232, 348)
      ..close();

    final mobiusPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      ).createShader(const Rect.fromLTWH(204, 210, 104, 146));
    canvas.drawPath(mobiusPath, mobiusPaint);

    // 6. Overlapping Ribbon Diamond: Apex Finisher
    final capPath = Path()
      ..moveTo(256, 136)
      ..lineTo(304, 208)
      ..lineTo(256, 230)
      ..lineTo(208, 208)
      ..close();

    final capPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xB3FFFFFF), Color(0x1AFFFFFF)],
      ).createShader(const Rect.fromLTWH(208, 136, 96, 94));
    canvas.drawPath(capPath, capPaint);

    // 7. Glass Core Accent: AI Growth Node
    final nodePath = Path()
      ..moveTo(256, 178)
      ..lineTo(278, 212)
      ..lineTo(256, 226)
      ..lineTo(234, 212)
      ..close();

    final nodePaint = Paint()..color = const Color(0xE6FFFFFF);
    canvas.drawPath(nodePath, nodePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MonyLogoPainter oldDelegate) =>
      oldDelegate.hasSquircleBackground != hasSquircleBackground;
}
