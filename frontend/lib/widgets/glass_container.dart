import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double padding;
  final double borderRadius;
  final Color color;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = 16.0,
    this.borderRadius = 20.0,
    this.color = const Color(0x99FFFFFF), // High opacity white for visibility on light background
    this.blur = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white, // Clean white border
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
