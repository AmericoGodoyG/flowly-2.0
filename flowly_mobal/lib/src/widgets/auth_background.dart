import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF0D0C13),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF120F1E),
                  Color(0xFF181426),
                  Color(0xFF0D0C13),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -90,
          left: -90,
          child: _GlowBlob(
            size: 280,
            colors: <Color>[Color(0x66FF3366), Color(0x00000000)],
          ),
        ),
        Positioned(
          top: 110,
          right: -60,
          child: _GlowBlob(
            size: 240,
            colors: <Color>[Color(0x667E57C2), Color(0x00000000)],
          ),
        ),
        Positioned(
          bottom: -120,
          left: 30,
          child: _GlowBlob(
            size: 300,
            colors: <Color>[Color(0x6638D5E5), Color(0x00000000)],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.08,
              child: SvgPicture.asset(
                'assets/images/fundo.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: 0.04),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
