import 'package:flutter/material.dart';

// Define custom colors for consistency with Clean Lanka branding
const Color primaryGreen = Color(0xFF4CAF50); // From #4CAF50
const Color secondaryBlue = Color(0xFF3F51B5); // From #3F51B5
const Color accentYellow = Color(0xFFFFC107); // From #FFC107
const Color lightIndigo = Color(0xFFE8EAF6); // A lighter indigo for backgrounds
const Color darkGray = Color(0xFF424242); // For dark mode text/elements

// Clean Lanka Logo Widget (Simplified for CustomPaint)
class CleanLankaLogo extends StatelessWidget {
  final double width;
  final double height;

  const CleanLankaLogo({super.key, this.width = 200, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CleanLankaLogoPainter(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, // Align text to bottom
          children: [
            Text(
              'Clean',
              style: TextStyle(
                fontSize: height * 0.25, // Responsive font size
                fontWeight: FontWeight.w800,
                color: primaryGreen,
                height: 1, // Adjust line height for tight spacing
              ),
            ),
            Text(
              'Lanka',
              style: TextStyle(
                fontSize: height * 0.20, // Responsive font size
                fontWeight: FontWeight.w600,
                color: secondaryBlue,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanLankaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / 250; // Original SVG width was 250
    final double scaleY = size.height / 180; // Original SVG height was 180

    // Paint for the green wave
    final Paint greenPaint = Paint()
      ..color = primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * (scaleX + scaleY) / 2 // Scale stroke width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Paint for the blue wave
    final Paint bluePaint = Paint()
      ..color = secondaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * (scaleX + scaleY) / 2 // Scale stroke width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Paint for the accent yellow spark
    final Paint accentPaint = Paint()
      ..color = accentYellow
      ..style = PaintingStyle.fill; // Fill for the polygon

    final Paint accentStrokePaint = Paint()
      ..color = accentYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (scaleX + scaleY) / 2 // Scale stroke width
      ..strokeCap = StrokeCap.round;

    // Paint for the blue droplets
    final Paint dropletPaint = Paint()
      ..color = secondaryBlue
      ..style = PaintingStyle.fill;

    // Green Wave Path
    final Path greenWavePath = Path()
      ..moveTo(30 * scaleX, 100 * scaleY)
      ..cubicTo(50 * scaleX, 80 * scaleY, 80 * scaleX, 70 * scaleY, 125 * scaleX, 70 * scaleY)
      ..cubicTo(170 * scaleX, 70 * scaleY, 200 * scaleX, 80 * scaleY, 220 * scaleX, 100 * scaleY);
    canvas.drawPath(greenWavePath, greenPaint);

    // Blue Wave Path
    final Path blueWavePath = Path()
      ..moveTo(35 * scaleX, 115 * scaleY)
      ..cubicTo(55 * scaleX, 95 * scaleY, 85 * scaleX, 85 * scaleY, 125 * scaleX, 85 * scaleY)
      ..cubicTo(165 * scaleX, 85 * scaleY, 195 * scaleX, 95 * scaleY, 215 * scaleX, 115 * scaleY);
    canvas.drawPath(blueWavePath, bluePaint);

    // Accent Yellow Spark (Polygon)
    final Path sparkPolygon = Path()
      ..moveTo(125 * scaleX, 60 * scaleY)
      ..lineTo(120 * scaleX, 50 * scaleY)
      ..lineTo(130 * scaleX, 50 * scaleY)
      ..close();
    canvas.drawPath(sparkPolygon, accentPaint);

    // Accent Yellow Spark (Line)
    canvas.drawLine(
      Offset(125 * scaleX, 60 * scaleY),
      Offset(125 * scaleX, 45 * scaleY),
      accentStrokePaint,
    );

    // Blue Droplets
    canvas.drawCircle(Offset(20 * scaleX, 95 * scaleY), 4 * (scaleX + scaleY) / 2, dropletPaint);
    canvas.drawCircle(Offset(230 * scaleX, 95 * scaleY), 4 * (scaleX + scaleY) / 2, dropletPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
