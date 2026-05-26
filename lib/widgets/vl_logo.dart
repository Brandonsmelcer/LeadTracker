import 'package:flutter/material.dart';

class VLLogo extends StatelessWidget {
  final double size;
  final Color color;

  const VLLogo({super.key, this.size = 80, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _VLLogoPainter(color: color)),
    );
  }
}

class _VLLogoPainter extends CustomPainter {
  final Color color;
  _VLLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Left vertical bar of V
    final vBar = Path()
      ..moveTo(w * 0.05, h * 0.02)
      ..lineTo(w * 0.15, h * 0.02)
      ..lineTo(w * 0.15, h * 0.72)
      ..lineTo(w * 0.05, h * 0.72)
      ..close();
    canvas.drawPath(vBar, paint);

    // Upper diagonal stripe (V right stroke going down-right)
    final diag1 = Path()
      ..moveTo(w * 0.15, h * 0.02)
      ..lineTo(w * 0.28, h * 0.02)
      ..lineTo(w * 0.95, h * 0.55)
      ..lineTo(w * 0.82, h * 0.55)
      ..close();
    canvas.drawPath(diag1, paint);

    // Lower diagonal stripe (L diagonal going down-right)
    final diag2 = Path()
      ..moveTo(w * 0.15, h * 0.38)
      ..lineTo(w * 0.28, h * 0.38)
      ..lineTo(w * 0.95, h * 0.88)
      ..lineTo(w * 0.82, h * 0.88)
      ..close();
    canvas.drawPath(diag2, paint);

    // Bottom horizontal bar of L
    final lBar = Path()
      ..moveTo(w * 0.55, h * 0.88)
      ..lineTo(w * 0.95, h * 0.88)
      ..lineTo(w * 0.95, h * 0.98)
      ..lineTo(w * 0.55, h * 0.98)
      ..close();
    canvas.drawPath(lBar, paint);
  }

  @override
  bool shouldRepaint(covariant _VLLogoPainter old) => old.color != color;
}
