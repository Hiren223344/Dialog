import 'package:flutter/material.dart';

import 'screens/studio_home_screen.dart';
import 'theme/studio_theme.dart';
import 'widgets/juice_overlay_host.dart';

void main() {
  runApp(const StarStudioApp());
}

class StarStudioApp extends StatelessWidget {
  const StarStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Star Studio',
      debugShowCheckedModeBanner: false,
      theme: buildStudioTheme(),
      home: const JuiceOverlayHost(child: StudioHomeScreen()),
    );
  }
}
