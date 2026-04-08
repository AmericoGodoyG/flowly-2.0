import 'package:flutter/material.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final Color? backgroundColor;
  final double borderRadius;
  final double elevation;

  const AnimatedCard({
    required this.child,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 200),
    this.backgroundColor,
    this.borderRadius = 12,
    this.elevation = 2,
    super.key,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          color: widget.backgroundColor,
          elevation: widget.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const FadeInAnimation({
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeIn,
    super.key,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }
}

class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final SlideDirection direction;
  final Curve curve;

  const SlideInAnimation({
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.direction = SlideDirection.up,
    this.curve = Curves.easeOut,
    super.key,
  });

  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

enum SlideDirection { up, down, left, right }

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    final begin = _getBeginOffset(widget.direction);
    _offset = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  Offset _getBeginOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.up:
        return const Offset(0, 0.2);
      case SlideDirection.down:
        return const Offset(0, -0.2);
      case SlideDirection.left:
        return const Offset(0.2, 0);
      case SlideDirection.right:
        return const Offset(-0.2, 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }
}

class BounceAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const BounceAnimation({
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    super.key,
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }
}
