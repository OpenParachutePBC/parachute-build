import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/projects/screens/project_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ParachuteBuildApp()));
}

class ParachuteBuildApp extends StatelessWidget {
  const ParachuteBuildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parachute Build',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ProjectListScreen(),
    );
  }
}
