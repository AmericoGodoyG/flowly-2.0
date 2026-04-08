import 'package:flutter/material.dart';
import 'package:meu_app/src/app/flowly_theme.dart';

class FlowlyCard extends StatelessWidget {
  const FlowlyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: flowlyBorder),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
