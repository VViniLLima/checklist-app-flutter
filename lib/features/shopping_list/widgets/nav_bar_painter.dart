import 'package:flutter/material.dart';

class NavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    const double margin = 16.0;
    const double borderRadius = 36.0;
    const double bumpRadius = 40.0;
    const double bumpHeight = 15.0;

    final rect = Rect.fromLTWH(
      margin,
      bumpHeight,
      size.width - (margin * 2),
      size.height - bumpHeight - 12, // vertical margin
    );

    final path = Path();
    final centerX = size.width / 2;
    
    // Top-left corner
    path.moveTo(rect.left + borderRadius, rect.top);
    
    // Smooth transition to bump
    double bumpStartX = centerX - bumpRadius - 10;
    double bumpEndX = centerX + bumpRadius + 10;
    
    path.lineTo(bumpStartX, rect.top);
    
    // The bump (convex notch)
    path.cubicTo(
      centerX - bumpRadius + 5, rect.top,
      centerX - bumpRadius, rect.top - bumpHeight,
      centerX, rect.top - bumpHeight,
    );
    path.cubicTo(
      centerX + bumpRadius, rect.top - bumpHeight,
      centerX + bumpRadius - 5, rect.top,
      bumpEndX, rect.top,
    );
    
    // Top-right corner
    path.lineTo(rect.right - borderRadius, rect.top);
    path.arcToPoint(
      Offset(rect.right, rect.top + borderRadius),
      radius: const Radius.circular(borderRadius),
    );
    
    // Bottom-right corner
    path.lineTo(rect.right, rect.bottom - borderRadius);
    path.arcToPoint(
      Offset(rect.right - borderRadius, rect.bottom),
      radius: const Radius.circular(borderRadius),
    );
    
    // Bottom-left corner
    path.lineTo(rect.left + borderRadius, rect.bottom);
    path.arcToPoint(
      Offset(rect.left, rect.bottom - borderRadius),
      radius: const Radius.circular(borderRadius),
    );
    
    // Back to top-left
    path.lineTo(rect.left, rect.top + borderRadius);
    path.arcToPoint(
      Offset(rect.left + borderRadius, rect.top),
      radius: const Radius.circular(borderRadius),
    );

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
