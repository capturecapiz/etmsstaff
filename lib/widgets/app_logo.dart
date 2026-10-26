import 'package:flutter/material.dart';

/// Shared PTCAO ETMS Staff app mark (the calendar + clock + building
/// logo), used on the login screen, the dashboard header and as the
/// source image for the Android launcher icon. Falls back to a generic
/// Material icon if the asset is ever missing, so a packaging mistake
/// never crashes the screen that shows it.
class AppLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const AppLogo({super.key, this.size = 72, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.task_alt_rounded,
        size: size,
        color: const Color(0xFF3B82F6),
      ),
    );
  }
}
