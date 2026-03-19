import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';

class CityBackground extends StatelessWidget {
  const CityBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.bgPrimary, AppTheme.bgSecondary],
              ),
            ),
          ),
        ),
        const Positioned(
          top: -140,
          right: -100,
          child: _GlowOrb(size: 360, color: AppTheme.accentGlow),
        ),
        const Positioned(
          bottom: -150,
          left: -120,
          child: _GlowOrb(size: 320, color: Color(0x143B82F6)),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _GridPainter()),
          ),
        ),
        child,
      ],
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.glassLight,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionEyebrow extends StatelessWidget {
  const SectionEyebrow({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: AppTheme.accent,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 56.0;
    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
