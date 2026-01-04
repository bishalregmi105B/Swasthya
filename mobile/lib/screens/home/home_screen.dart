import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';
import '../../services/offline_cache_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _appointments = [];
  List<dynamic> _healthAlerts = [];
  bool _isLoading = true;

  // Personalized health tips
  List<dynamic> _healthTips = [];
  bool _loadingTips = false;
  final PageController _tipsPageController = PageController();
  int _currentTipIndex = 0;

  // Weather & health alerts slider
  List<dynamic> _weatherAlerts = [];
  bool _loadingWeatherAlerts = false;
  final PageController _weatherAlertsController = PageController();
  int _currentWeatherAlertIndex = 0;

  // Cached futures to prevent infinite rebuilds
  Future<Map<String, dynamic>>? _weatherDataFuture;
  Future<Map<String, dynamic>>? _simulationsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadHealthTips(); // Load tips async - doesn't block home screen
    _loadWeatherAlerts(); // Load weather/health alerts async
    _simulationsFuture =
        apiService.getFeaturedSimulations(); // Cache simulations future
  }

  @override
  void dispose() {
    _tipsPageController.dispose();
    _weatherAlertsController.dispose();
    super.dispose();
  }

  /// Load personalized health tips asynchronously
  Future<void> _loadHealthTips() async {
    if (!mounted) return;
    setState(() => _loadingTips = true);

    try {
      // Get language from locale provider
      final localeProvider = context.read<LocaleProvider>();
      final language = localeProvider.isEnglish ? 'en' : 'ne';

      final result = await apiService.getPersonalizedHealthTips(
        language: language,
        count: 5,
      );

      if (mounted && result['tips'] != null) {
        setState(() {
          _healthTips = result['tips'];
          _loadingTips = false;
        });

        // Auto-scroll timer
        _startAutoScroll();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTips = false);
      }
    }
  }

  /// Load weather and health alerts asynchronously
  Future<void> _loadWeatherAlerts() async {
    if (!mounted) return;
    setState(() => _loadingWeatherAlerts = true);

    try {
      final localeProvider = context.read<LocaleProvider>();
      final language = localeProvider.isEnglish ? 'en' : 'ne';

      final result = await apiService.getWeatherHealthAlerts(
        language: language,
        count: 5,
      );

      if (mounted && result['alerts'] != null) {
        setState(() {
          _weatherAlerts = result['alerts'];
          _loadingWeatherAlerts = false;
        });

        // Auto-scroll timer for weather alerts
        _startWeatherAlertsAutoScroll();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingWeatherAlerts = false);
      }
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _healthTips.isNotEmpty) {
        final nextIndex = (_currentTipIndex + 1) % _healthTips.length;
        _tipsPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  void _startWeatherAlertsAutoScroll() {
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _weatherAlerts.isNotEmpty) {
        final nextIndex =
            (_currentWeatherAlertIndex + 1) % _weatherAlerts.length;
        _weatherAlertsController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startWeatherAlertsAutoScroll();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final alertsData = await apiService.getHealthAlerts();
      final appointmentsData = await apiService.getAppointments();

      // Cache alerts for offline use
      await OfflineCacheService.cacheAlerts(List<Map<String, dynamic>>.from(
          (alertsData['alerts'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))));

      setState(() {
        _healthAlerts = alertsData['alerts'] ?? [];
        _appointments = appointmentsData['appointments'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to cached data
      final cachedAlerts = OfflineCacheService.getCachedAlerts();
      setState(() {
        _healthAlerts = cachedAlerts ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadData();
            _loadHealthTips();
            _loadWeatherAlerts();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, l10n, user),
                _buildHealthTipsSlider(context), // Personalized health tips
                _buildWeatherAlertsSlider(context), // Weather & pandemic alerts
                _buildAISathiCard(context, l10n),
                _buildQuickActionsSection(context, l10n),
                _buildDiseaseWatchWidget(context, l10n),
                _buildWeatherClimateWidget(context, l10n),
                _buildSimulationsWidget(context, l10n),
                _buildHealthAlertsSection(context, l10n),
                _buildPreventionTipsSection(context, l10n),
                _buildHospitalPerformanceSection(context, l10n),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AppLocalizations l10n, dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              user?.fullName.isNotEmpty == true
                  ? user!.fullName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.welcome} 👋',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6),
                  ),
                ),
                Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  /// Build personalized health tips slider
  Widget _buildHealthTipsSlider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show shimmer loading placeholder
    if (_loadingTips && _healthTips.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading personalized tips...'),
            ],
          ),
        ),
      );
    }

    // No tips to show
    if (_healthTips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      height: 120, // Increased from 100 to fix overflow
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _tipsPageController,
              onPageChanged: (index) {
                setState(() => _currentTipIndex = index);
              },
              itemCount: _healthTips.length,
              itemBuilder: (context, index) {
                final tip = _healthTips[index];
                final color = _parseHexColor(tip['color'] ?? '#4CAF50');

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.9),
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTipIcon(tip['icon']),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tip['title'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tip['content'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_healthTips.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentTipIndex == index ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentTipIndex == index
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getTipIcon(String? iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'medication':
        return Icons.medication;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'psychology':
        return Icons.psychology;
      case 'air':
        return Icons.air;
      case 'favorite':
        return Icons.favorite;
      case 'shield':
        return Icons.shield;
      case 'bedtime':
        return Icons.bedtime;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.lightbulb;
    }
  }

  /// Build weather and health alerts slider
  Widget _buildWeatherAlertsSlider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show shimmer loading placeholder
    if (_loadingWeatherAlerts && _weatherAlerts.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 100,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.orange.shade900.withOpacity(0.3)
              : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200.withOpacity(0.5)),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.orange),
              ),
              SizedBox(width: 12),
              Text('Loading health alerts...',
                  style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      );
    }

    if (_weatherAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 120, // Increased from 100 to fix overflow
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _weatherAlertsController,
              onPageChanged: (index) {
                setState(() => _currentWeatherAlertIndex = index);
              },
              itemCount: _weatherAlerts.length,
              itemBuilder: (context, index) {
                final alert = _weatherAlerts[index];
                final color = _parseHexColor(alert['color'] ?? '#FF9800');

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.9),
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getAlertIcon(alert['icon']),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                if (alert['type'] == 'outbreak')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('ALERT',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                Expanded(
                                  child: Text(
                                    alert['title'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert['content'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_weatherAlerts.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentWeatherAlertIndex == index ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentWeatherAlertIndex == index
                      ? Colors.orange
                      : Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getAlertIcon(String? iconName) {
    switch (iconName) {
      case 'thermostat':
        return Icons.thermostat;
      case 'air':
        return Icons.air;
      case 'coronavirus':
        return Icons.coronavirus;
      case 'masks':
        return Icons.masks;
      case 'sanitizer':
        return Icons.sanitizer;
      case 'home':
        return Icons.home;
      case 'warning':
        return Icons.warning_amber;
      case 'shield':
        return Icons.shield;
      case 'water_drop':
        return Icons.water_drop;
      case 'medical_services':
        return Icons.medical_services;
      default:
        return Icons.health_and_safety;
    }
  }

  Widget _buildAISathiCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated greeting row
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.1),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.pinkAccent, size: 32),
                    ),
                  );
                },
                onEnd: () {
                  // Animation will restart due to rebuilds
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.howAreYouFeeling} 💭',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.talkToAIDoctor,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              // Call button - opens bottom sheet modal
              Expanded(
                child: _buildHealthActionButton(
                  icon: Icons.phone_in_talk,
                  label: l10n.callAIDoctor,
                  color: Colors.greenAccent,
                  onTap: () {
                    showLiveAICallBottomSheet(
                      context: context,
                      config: const LiveAICallConfig(
                        specialist: 'physician',
                        patientContext:
                            'User is asking about their general health from home screen',
                      ),
                      title: l10n.aiHealthConsultation,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Chat button - goes to categories
              Expanded(
                child: _buildHealthActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: l10n.chatWithAI,
                  color: Colors.white,
                  onTap: () => context.push('/chats'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Scan image button
          _buildHealthActionButton(
            icon: Icons.document_scanner,
            label: '📸 ${l10n.scanHealthImage}',
            color: Colors.amberAccent,
            onTap: () => context.push('/ai-scan'),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: fullWidth ? 14 : 12,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: fullWidth ? 14 : 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
      BuildContext context, AppLocalizations l10n) {
    final actions = [
      _QuickAction(
          l10n.findDoctor, Icons.person_search, AppColors.primary, '/bookings'),
      _QuickAction(
          l10n.myMedicines, Icons.medication, Colors.orange, '/reminders'),
      _QuickAction(
          l10n.diseases, Icons.medical_information, Colors.blue, '/diseases'),
      _QuickAction(
          l10n.drugInfo, Icons.medication_liquid, Colors.purple, '/drugs'),
      _QuickAction(l10n.aiHealthScan, Icons.document_scanner, Colors.indigo,
          '/health-analyzers'),
      _QuickAction(
          l10n.ayurvedicDoctors, Icons.eco, Colors.green, '/ayurvedic-doctors'),
      _QuickAction(
          l10n.healthCalculators, Icons.calculate, Colors.teal, '/calculators'),
      _QuickAction(
          l10n.emergencyServices, Icons.emergency, Colors.pink, '/emergency'),
      _QuickAction(
          l10n.bloodBanks, Icons.bloodtype, Colors.red, '/blood-banks'),
      _QuickAction(
          l10n.nearbyFacilities, Icons.local_hospital, Colors.cyan, '/nearby'),
      _QuickAction(
          l10n.chatHistory, Icons.history, Colors.deepOrange, '/ai-history'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(l10n.quickActions,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return GestureDetector(
                onTap: () => context.push(action.route),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: action.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(action.icon, color: action.color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(action.title,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 2),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointments(
      BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Appointments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              TextButton(
                  onPressed: () => context.push('/appointments'),
                  child: Text(l10n.seeAll)),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _appointments.take(3).length,
            itemBuilder: (context, index) {
              final apt = _appointments[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: const Icon(Icons.person,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(apt['doctor']?['name'] ?? 'Doctor',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(apt['doctor']?['specialization'] ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.6))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(apt['appointment_date'] ?? '',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(apt['appointment_time'] ?? '',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: apt['type'] == 'video'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        apt['type'] == 'video'
                            ? '📹 Video Call'
                            : apt['type'] == 'chat'
                                ? '💬 Chat'
                                : '🏥 In-Person',
                        style: TextStyle(
                            fontSize: 11,
                            color: apt['type'] == 'video'
                                ? Colors.blue
                                : Colors.green,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHealthAlertsSection(
      BuildContext context, AppLocalizations l10n) {
    final alert = _healthAlerts.isNotEmpty ? _healthAlerts.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.healthAlerts,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              TextButton(
                  onPressed: () => context.push('/health-alerts'),
                  child: Text(l10n.seeAll)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.warning_amber,
                    color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert?['disease_name'] ?? 'Health Alert',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      alert?['description'] ??
                          'Stay informed about health alerts in your area.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.6)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreventionTipsSection(
      BuildContext context, AppLocalizations l10n) {
    final tips = [
      {
        'title': 'Stay Hydrated',
        'icon': Icons.water_drop,
        'color': Colors.blue
      },
      {
        'title': 'Exercise Daily',
        'icon': Icons.directions_run,
        'color': Colors.green
      },
      {'title': 'Sleep 8 Hours', 'icon': Icons.bedtime, 'color': Colors.purple},
      {
        'title': 'Eat Healthy',
        'icon': Icons.restaurant,
        'color': Colors.orange
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prevention Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              TextButton(
                  onPressed: () => context.push('/prevention'),
                  child: Text(l10n.seeAll)),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: (tip['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tip['icon'] as IconData,
                        color: tip['color'] as Color, size: 32),
                    const SizedBox(height: 8),
                    Text(tip['title'] as String,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalPerformanceSection(
      BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Hospitals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              TextButton(
                  onPressed: () => context.push('/hospitals'),
                  child: Text(l10n.seeAll)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_hospital,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Grande International Hospital',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Row(
                            children: [
                              Icon(Icons.verified,
                                  size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text('AI Score: 9.2',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const Text(' 4.8', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseWatchWidget(BuildContext context, AppLocalizations l10n) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([
        apiService.getDiseaseSpreadLevel('Nepal'),
        apiService.getVaccinationData('Nepal'),
        apiService.getActiveDiseaseAlerts('Nepal'),
      ]).then((results) => [
            results[0],
            results[1],
            results[2],
          ]),
      builder: (context, snapshot) {
        // Default values while loading or on error
        String spreadLevel = 'low';
        String trend = 'stable';
        double activePer100k = 0.0;
        double vaccinationCoverage = 85.0;
        MaterialColor cardColor = Colors.green;
        IconData trendIcon = Icons.trending_flat;
        List<dynamic> activeAlerts = [];

        if (snapshot.hasData && snapshot.data != null) {
          final spreadData = snapshot.data![0];
          final vaccData = snapshot.data![1];
          final alertsData = snapshot.data![2];

          spreadLevel = spreadData['spread_level']?.toString() ?? 'low';
          trend = spreadData['trend']?.toString() ?? 'stable';
          activePer100k =
              (spreadData['active_per_100k'] as num?)?.toDouble() ?? 0.0;
          vaccinationCoverage =
              (vaccData['latest']?['coverage_percentage'] as num?)
                      ?.toDouble() ??
                  85.0;
          activeAlerts = alertsData['active_alerts'] as List<dynamic>? ?? [];

          // Set card color based on spread level
          switch (spreadLevel) {
            case 'minimal':
              cardColor = Colors.green;
              break;
            case 'low':
              cardColor = Colors.lightGreen;
              break;
            case 'moderate':
              cardColor = Colors.orange;
              break;
            case 'high':
              cardColor = Colors.deepOrange;
              break;
            case 'critical':
              cardColor = Colors.red;
              break;
            default:
              cardColor = Colors.green;
          }

          // Set trend icon
          switch (trend) {
            case 'increasing':
              trendIcon = Icons.trending_up;
              break;
            case 'decreasing':
              trendIcon = Icons.trending_down;
              break;
            default:
              trendIcon = Icons.trending_flat;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.coronavirus, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Disease Watch',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/disease-surveillance'),
                    child: Text(l10n.seeAll),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/disease-surveillance'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor.shade600, cardColor.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                              spreadLevel == 'low' || spreadLevel == 'minimal'
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: Colors.white,
                              size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nepal Health Status',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('${spreadLevel.toUpperCase()} RISK',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(trendIcon,
                                            color: Colors.white, size: 12),
                                        const SizedBox(width: 4),
                                        Text(trend.toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${activePer100k.toStringAsFixed(1)} cases/100k',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Vaccination progress bar
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.vaccines,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Vaccination Coverage',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11)),
                                    Text(
                                        '${vaccinationCoverage.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: vaccinationCoverage / 100,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.2),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Active Disease Alerts
                    if (activeAlerts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              activeAlerts.length > 3 ? 3 : activeAlerts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final alert =
                                activeAlerts[index] as Map<String, dynamic>;
                            final severity =
                                alert['severity']?.toString() ?? 'low';
                            final diseaseName =
                                alert['disease']?.toString() ?? 'Unknown';
                            Color alertColor = Colors.white.withOpacity(0.2);
                            if (severity == 'high')
                              alertColor = Colors.red.withOpacity(0.4);
                            else if (severity == 'moderate')
                              alertColor = Colors.orange.withOpacity(0.4);
                            return GestureDetector(
                              onTap: () => context.push(
                                  '/disease-detail/${Uri.encodeComponent(diseaseName)}'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: alertColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(alert['icon']?.toString() ?? '⚠️',
                                        style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      diseaseName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherClimateWidget(
      BuildContext context, AppLocalizations l10n) {
    // Get user's city from auth provider
    final user = context
        .read<AuthProvider>()
        .user; // Use read, not watch to prevent rebuilds
    final userLocation = user?.city?.toLowerCase() ?? 'nepal';

    // Initialize cached future if not already done
    _weatherDataFuture ??= apiService.getCombinedHealthData(userLocation);

    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        // Handle error - don't show widget
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data;
        final weather = data?['weather'] as Map<String, dynamic>?;
        final weatherCurrent = weather?['current'] as Map<String, dynamic>?;
        final airQuality = data?['air_quality'] as Map<String, dynamic>?;
        final aqCurrent = airQuality?['current'] as Map<String, dynamic>?;

        final temp = weatherCurrent?['temperature'] ?? 0;
        final description =
            weatherCurrent?['weather_description'] ?? 'Loading...';
        final aqi = aqCurrent?['aqi'] ?? 0;
        final humidity = weatherCurrent?['humidity'] ?? 0;

        Color aqiColor = Colors.green;
        String aqiLabel = 'Good';
        if (aqi > 50) {
          aqiColor = Colors.yellow.shade700;
          aqiLabel = 'Moderate';
        }
        if (aqi > 100) {
          aqiColor = Colors.orange;
          aqiLabel = 'Unhealthy';
        }
        if (aqi > 150) {
          aqiColor = Colors.red;
          aqiLabel = 'Very Unhealthy';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wb_cloudy, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Weather & Air Quality',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/weather-climate'),
                    child: Text(l10n.seeAll),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/weather-climate'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.cyan.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Temperature
                    Column(
                      children: [
                        const Icon(Icons.thermostat,
                            color: Colors.white, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          '${temp.toStringAsFixed(0)}°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          description,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Divider
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(width: 20),
                    // AQI & Humidity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: aqiColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'AQI $aqi',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                aqiLabel,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.water_drop,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '$humidity%',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.wb_sunny,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'UV ${(aqCurrent?['uv_index'] ?? 0).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimulationsWidget(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.school, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Emergency Training',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/simulations'),
                child: Text(l10n.seeAll),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: FutureBuilder<Map<String, dynamic>>(
            future:
                _simulationsFuture, // Use cached future instead of calling API directly
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2));
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.grey.shade400, size: 32),
                      const SizedBox(height: 8),
                      Text('Could not load',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                );
              }

              final simulations = snapshot.data!['simulations'] as List? ?? [];

              if (simulations.isEmpty) {
                return Center(
                  child: Text('No simulations available',
                      style: TextStyle(color: Colors.grey.shade500)),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: simulations.length,
                itemBuilder: (context, index) {
                  final sim = simulations[index];
                  final slug = sim['slug'] ?? 'adult-cpr';
                  final color = _parseSimColor(sim['color'] ?? '#136dec');
                  final icon = _getSimIcon(sim['icon']);

                  return GestureDetector(
                    onTap: () => context.push('/simulation/$slug'),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color, size: 32),
                          const SizedBox(height: 8),
                          Text(sim['title'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _parseSimColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getSimIcon(dynamic name) {
    const icons = {
      'favorite': Icons.favorite,
      'emergency': Icons.emergency,
      'healing': Icons.healing,
      'local_fire_department': Icons.local_fire_department,
      'child_care': Icons.child_care,
      'psychology': Icons.psychology,
      'local_hospital': Icons.local_hospital,
    };
    return icons[name] ?? Icons.school;
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  _QuickAction(this.title, this.icon, this.color, this.route);
}
