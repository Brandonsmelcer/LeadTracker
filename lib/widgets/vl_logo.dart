import 'package:flutter/material.dart';

class VLLogo extends StatelessWidget {
  final double size;

  const VLLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => CustomPaint(
          painter: _VLLogoPainter(),
          size: Size(size, size),
        ),
      ),
    );
  }
}

class _VLLogoPainter extends CustomPainter {
  static const _silver = Color(0xFFD0D0D8);
  static const _silverLight = Color(0xFFE8E8ED);
  static const _green = Color(0xFF00783C);
  static const _greenLight = Color(0xFF00A050);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final m = w * 0.08;
    final dw = w - 2 * m;
    final dh = dw;

    // Left vertical bar (silver)
    canvas.drawPath(
      Path()
        ..moveTo(m + dw * 0.03, m)
        ..lineTo(m + dw * 0.15, m)
        ..lineTo(m + dw * 0.15, m + dh * 0.72)
        ..lineTo(m + dw * 0.03, m + dh * 0.72)
        ..close(),
      Paint()..color = _silverLight,
    );

    // Upper diagonal (silver)
    canvas.drawPath(
      Path()
        ..moveTo(m + dw * 0.15, m)
        ..lineTo(m + dw * 0.30, m)
        ..lineTo(m + dw * 0.95, m + dh * 0.55)
        ..lineTo(m + dw * 0.80, m + dh * 0.55)
        ..close(),
      Paint()..color = _silver,
    );

    // Lower diagonal (green)
    canvas.drawPath(
      Path()
        ..moveTo(m + dw * 0.15, m + dh * 0.35)
        ..lineTo(m + dw * 0.30, m + dh * 0.35)
        ..lineTo(m + dw * 0.95, m + dh * 0.88)
        ..lineTo(m + dw * 0.80, m + dh * 0.88)
        ..close(),
      Paint()..color = _green,
    );

    // Bottom bar (green)
    canvas.drawPath(
      Path()
        ..moveTo(m + dw * 0.52, m + dh * 0.88)
        ..lineTo(m + dw * 0.95, m + dh * 0.88)
        ..lineTo(m + dw * 0.95, m + dh * 0.99)
        ..lineTo(m + dw * 0.52, m + dh * 0.99)
        ..close(),
      Paint()..color = _greenLight,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
