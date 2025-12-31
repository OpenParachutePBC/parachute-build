import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parachute_build/core/theme/design_tokens.dart';

import 'steps/welcome_step.dart';
import 'steps/server_setup_step.dart';
import 'steps/ready_step.dart';

/// Multi-step onboarding flow for first-time users
///
/// Build flow: Welcome → Server Setup → Ready
class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  static const String _hasSeenOnboardingKey = 'has_seen_onboarding_v1';

  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _progressController;

  final List<OnboardingStepData> _steps = [
    OnboardingStepData(title: 'Welcome', icon: Icons.waving_hand),
    OnboardingStepData(title: 'Server', icon: Icons.cloud_outlined),
    OnboardingStepData(title: 'Ready', icon: Icons.rocket_launch),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: Motion.standard,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _progressController.forward(from: 0);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _progressController.forward(from: 0);
    }
  }

  void _skipToEnd() {
    setState(() => _currentStep = _steps.length - 1);
    _progressController.forward(from: 0);
  }

  Future<void> _completeOnboarding() async {
    await OnboardingFlow.markOnboardingComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? BrandColors.nightSurface : BrandColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(isDark),

            // Current step content
            Expanded(
              child: AnimatedSwitcher(
                duration: Motion.standard,
                switchInCurve: Motion.settling,
                switchOutCurve: Motion.settling,
                child: IndexedStack(
                  key: ValueKey(_currentStep),
                  index: _currentStep,
                  children: [
                    WelcomeStep(onNext: _nextStep, onSkip: _skipToEnd),
                    ServerSetupStep(
                      onNext: _nextStep,
                      onBack: _previousStep,
                      onSkip: _skipToEnd,
                    ),
                    ReadyStep(
                      onComplete: _completeOnboarding,
                      onBack: _previousStep,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.lg,
      ),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final step = _steps[index];
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          final activeColor = isDark
              ? BrandColors.nightForest
              : BrandColors.forest;
          final inactiveColor = isDark
              ? BrandColors.nightTextSecondary.withValues(alpha: 0.3)
              : BrandColors.stone;
          final completedColor = isDark
              ? BrandColors.nightForest.withValues(alpha: 0.7)
              : BrandColors.forest.withValues(alpha: 0.7);

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? activeColor
                              : isCompleted
                                  ? completedColor
                                  : inactiveColor,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : step.icon,
                          color: (isActive || isCompleted)
                              ? Colors.white
                              : (isDark
                                  ? BrandColors.nightTextSecondary
                                  : BrandColors.driftwood),
                          size: 20,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: TypographyTokens.labelSmall,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive
                              ? activeColor
                              : (isDark
                                  ? BrandColors.nightTextSecondary
                                  : BrandColors.driftwood),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < _steps.length - 1)
                  Container(
                    height: 2,
                    width: 24,
                    color: isCompleted
                        ? completedColor
                        : inactiveColor,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class OnboardingStepData {
  final String title;
  final IconData icon;

  OnboardingStepData({
    required this.title,
    required this.icon,
  });
}
