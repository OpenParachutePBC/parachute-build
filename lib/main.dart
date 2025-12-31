import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'features/onboarding/screens/onboarding_flow.dart';
import 'features/projects/screens/project_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ParachuteBuildApp(),
    ),
  );
}

class ParachuteBuildApp extends StatefulWidget {
  const ParachuteBuildApp({super.key});

  @override
  State<ParachuteBuildApp> createState() => _ParachuteBuildAppState();
}

class _ParachuteBuildAppState extends State<ParachuteBuildApp> {
  bool _hasSeenOnboarding = false;
  bool _isCheckingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final hasSeenOnboarding = await OnboardingFlow.hasCompletedOnboarding();
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = hasSeenOnboarding;
        _isCheckingOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parachute Build',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _isCheckingOnboarding
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _hasSeenOnboarding
              ? const ProjectListScreen()
              : OnboardingFlow(
                  onComplete: () => setState(() => _hasSeenOnboarding = true),
                ),
    );
  }
}
