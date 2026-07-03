import 'package:flutter/material.dart';

const kPrimary = Color(0xFF2CB87A);
const kPrimaryDark = Color(0xFF176B4A);
const kPrimaryLight = Color(0xFF3DC97B);

class NexoraLogoIcon extends StatelessWidget {
  final double size;
  final bool isWhite;
  const NexoraLogoIcon({super.key, this.size = 70, this.isWhite = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NLogoPainter(isWhite: isWhite)),
    );
  }
}

class _NLogoPainter extends CustomPainter {
  final bool isWhite;
  const _NLogoPainter({this.isWhite = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = w * 0.21;

    void drawN(Color color) {
      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = color
        ..strokeWidth = t
        ..strokeCap = StrokeCap.butt
        ..style = PaintingStyle.stroke;
      canvas.drawRect(Rect.fromLTWH(0, 0, t, h), fill);
      canvas.drawRect(Rect.fromLTWH(w - t, 0, t, h), fill);
      canvas.drawLine(Offset(t / 2, 0), Offset(w - t / 2, h), stroke);
    }

    if (isWhite) {
      drawN(Colors.white);
      return;
    }

    final darkClip = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.63, 0)
      ..lineTo(w * 0.37, h)
      ..lineTo(0, h)
      ..close();
    canvas.save();
    canvas.clipPath(darkClip);
    drawN(kPrimaryDark);
    canvas.restore();

    final lightClip = Path()
      ..moveTo(w * 0.63, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w * 0.37, h)
      ..close();
    canvas.save();
    canvas.clipPath(lightClip);
    drawN(kPrimaryLight);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// White-on-white background painter for login/register
class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WavePainter(), size: Size.infinite);
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final blobPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..cubicTo(w, h * 0.09, w * 0.82, h * 0.24, w * 0.52, h * 0.30)
      ..cubicTo(w * 0.22, h * 0.36, w * 0.04, h * 0.22, 0, h * 0.12)
      ..close();
    canvas.drawPath(
      blobPath,
      Paint()
        ..color = const Color(0xFFF0FBF6)
        ..style = PaintingStyle.fill,
    );

    final arcCenter = Offset(w * 1.12, -h * 0.02);
    for (int i = 0; i < 9; i++) {
      final radius = w * (0.18 + i * 0.23);
      final opacity = 0.09 - i * 0.01;
      if (opacity <= 0) break;
      canvas.drawCircle(
        arcCenter,
        radius,
        Paint()
          ..color = Color.fromRGBO(44, 184, 122, opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Subtle wave decoration for green headers
class GreenHeaderDecoration extends StatelessWidget {
  const GreenHeaderDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GreenWavePainter(), size: Size.infinite);
  }
}

class _GreenWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.07)
      ..style = PaintingStyle.fill;

    final p1 = Path()
      ..moveTo(w * 0.45, 0)
      ..cubicTo(w * 1.15, 0, w * 1.05, h * 0.9, w * 0.55, h * 0.75)
      ..cubicTo(w * 0.2, h * 0.6, 0, h * 0.4, w * 0.45, 0)
      ..close();
    canvas.drawPath(p1, paint);

    final p2 = Path()
      ..moveTo(w * 0.7, 0)
      ..cubicTo(w * 1.1, 0, w * 1.0, h * 0.55, w * 0.78, h * 0.5)
      ..cubicTo(w * 0.6, h * 0.45, w * 0.55, h * 0.25, w * 0.7, 0)
      ..close();
    canvas.drawPath(p2, paint..color = const Color.fromRGBO(255, 255, 255, 0.05));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Shared status badge
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'Interview':
      return const Color(0xFFE57C00);
    case 'In Review':
      return const Color(0xFF4A90D9);
    case 'Received':
      return kPrimary;
    default:
      return Colors.grey;
  }
}

Color statusBg(String status) {
  switch (status) {
    case 'Interview':
      return const Color(0xFFFFF3E8);
    case 'In Review':
      return const Color(0xFFEBF3FF);
    case 'Received':
      return const Color(0xFFE8F8F0);
    default:
      return Colors.grey.shade100;
  }
}
