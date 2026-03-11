import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}

const _pages = [
  _OnboardingPage(
    title: 'AI-Powered\nJob Applications',
    subtitle: 'Let GPT-4 tailor your resume to every job posting automatically.',
    icon: Icons.auto_awesome_rounded,
    iconColor: AppTheme.primary,
  ),
  _OnboardingPage(
    title: 'Create Your\nProfile Once',
    subtitle: 'Build a rich profile with your resume, skills, and preferences.',
    icon: Icons.person_rounded,
    iconColor: AppTheme.accent,
  ),
  _OnboardingPage(
    title: 'Apply in\nSeconds',
    subtitle: 'Watch your bot fill out forms in real-time while you relax.',
    icon: Icons.rocket_launch_rounded,
    iconColor: Color(0xFFFF7AA2),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Skip', style: theme.textTheme.bodyMedium),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingPageWidget(page: _pages[i]),
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppTheme.primary : AppTheme.darkBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // CTA buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  AppButton(
                    label: _currentPage == _pages.length - 1 ? 'Get Started' : 'Continue',
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/register');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: theme.textTheme.bodySmall),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 64, color: page.iconColor),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(),

          const SizedBox(height: 40),

          Text(
            page.title,
            style: theme.textTheme.displayMedium,
            textAlign: TextAlign.center,
          )
              .animate(delay: 200.ms)
              .slideY(begin: 0.3, end: 0, duration: 500.ms)
              .fadeIn(),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.darkTextSecondary,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 350.ms)
              .slideY(begin: 0.3, end: 0, duration: 500.ms)
              .fadeIn(),
        ],
      ),
    );
  }
}
