import 'package:flutter/material.dart';
import 'package:meu_app/src/app/flowly_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';

class FlowlyApp extends StatelessWidget {
  const FlowlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flowly',
      theme: flowlyTheme,
      routerConfig: flowlyRouter,
    );
  }
}
