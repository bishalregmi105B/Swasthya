import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.smart_toy,
      titleKey: 'aiSathi',
      subtitleKey: 'aiSathiSubtitle',
      color: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.local_hospital,
      titleKey: 'findDoctor',
      subtitleKey: 'bookAppointment',
      color: AppColors.success,
    ),
    _OnboardingPage(
      icon: Icons.notifications_active,
      titleKey: 'myMedicines',
      subtitleKey: 'refillReminder',
      color: AppColors.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _onGetStarted() {
    context.read<AuthProvider>().setOnboarded();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onGetStarted,
                    child: Text(l10n.skip),
                  ),
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                              ? AppColors.primary 
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            page.icon,
                            size: 80,
                            color: page.color,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _getLocalizedText(l10n, page.titleKey),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getLocalizedText(l10n, page.subtitleKey),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        child: Text(l10n.back),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _onGetStarted();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 
                            ? l10n.next 
                            : l10n.getStarted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedText(AppLocalizations l10n, String key) {
    switch (key) {
      case 'aiSathi': return l10n.aiSathi;
      case 'aiSathiSubtitle': return l10n.aiSathiSubtitle;
      case 'findDoctor': return l10n.findDoctor;
      case 'bookAppointment': return l10n.bookAppointment;
      case 'myMedicines': return l10n.myMedicines;
      case 'refillReminder': return l10n.refillReminder;
      default: return key;
    }
  }
}

class _OnboardingPage {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final Color color;

  _OnboardingPage({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.color,
  });
}
