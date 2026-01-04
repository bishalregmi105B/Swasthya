import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';

class DiseaseSurveillanceScreen extends StatefulWidget {
  const DiseaseSurveillanceScreen({super.key});

  @override
  State<DiseaseSurveillanceScreen> createState() =>
      _DiseaseSurveillanceScreenState();
}

class _DiseaseSurveillanceScreenState extends State<DiseaseSurveillanceScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _spreadLevel = {};
  List<dynamic> _outbreaks = [];
  List<dynamic> _regionalAlerts = [];
  Map<String, dynamic> _covidData = {};
  Map<String, dynamic> _covidComparison = {}; // Comparison data with neighbors
  Map<String, dynamic> _covidHistorical = {}; // Historical trends
  Map<String, dynamic> _vaccinationData = {}; // Vaccination coverage
  List<dynamic> _activeDiseaseAlerts = []; // All active disease alerts
  String _selectedCountry = 'Nepal';

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  void _initUserLocation() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      // Determine country from user's province/city
      _selectedCountry = _getCountryFromLocation(user.city, user.province);
    }
    _loadData();
  }

  String _getCountryFromLocation(String? city, String? province) {
    // For now, assume Nepal for all Nepal cities/provinces
    final nepalLocations = [
      'bagmati',
      'gandaki',
      'lumbini',
      'karnali',
      'sudurpashchim',
      'madhesh',
      'koshi',
      'kathmandu',
      'pokhara',
      'lalitpur',
      'bhaktapur',
      'biratnagar',
      'birgunj',
      'bharatpur'
    ];

    final loc = (city ?? province ?? '').toLowerCase();
    if (loc.isEmpty || nepalLocations.any((n) => loc.contains(n))) {
      return 'Nepal';
    }
    return 'Nepal'; // Default to Nepal
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Try to fetch from API, or use fallback data for demo
      try {
        final spreadData =
            await apiService.getDiseaseSpreadLevel(_selectedCountry);
        final outbreaksData = await apiService.getDiseaseOutbreaks();
        final alertsData = await apiService.getRegionalAlerts();
        final covidData = await apiService.getCovidData(_selectedCountry);

        // Get COVID comparison with neighboring countries
        final covidComparison =
            await apiService.getCovidComparison(_selectedCountry);

        // Get historical trends and vaccination data
        final historicalData =
            await apiService.getCovidHistorical(_selectedCountry);
        final vaccinationData =
            await apiService.getVaccinationData(_selectedCountry);

        // Get all active disease alerts
        final activeDiseaseAlerts =
            await apiService.getActiveDiseaseAlerts(_selectedCountry);

        setState(() {
          _spreadLevel = spreadData;
          _outbreaks = outbreaksData['realtime_from_who'] ??
              outbreaksData['outbreaks'] ??
              [];
          _regionalAlerts = alertsData['alerts'] ?? [];
          _covidData = covidData;
          _covidComparison = covidComparison;
          _covidHistorical = historicalData;
          _vaccinationData = vaccinationData;
          _activeDiseaseAlerts = activeDiseaseAlerts['active_alerts'] ?? [];
        });
      } catch (e) {
        // Use demo data when API not available
        setState(() {
          _spreadLevel = {
            'spread_level': 'low',
            'spread_color': 'green',
            'active_per_100k': 2.5,
            'trend': 'stable',
            'today_new': 12,
            'total_active': 856,
          };
          _outbreaks = [
            {
              'disease': 'Dengue',
              'location': 'Terai Region, Nepal',
              'severity': 'moderate',
              'title': 'Dengue Cases',
              'source': 'MoHP Nepal'
            },
            {
              'disease': 'Typhoid',
              'location': 'Kathmandu Valley',
              'severity': 'low',
              'title': 'Seasonal Typhoid',
              'source': 'EDCD'
            },
            {
              'disease': 'Influenza',
              'location': 'Hilly Regions',
              'severity': 'moderate',
              'title': 'Winter Flu Season',
              'source': 'MoHP Nepal'
            },
          ];
          _regionalAlerts = [
            {
              'disease': 'Influenza',
              'risk_level': 'moderate',
              'season': 'winter'
            },
            {
              'disease': 'Pneumonia',
              'risk_level': 'moderate',
              'season': 'winter'
            },
          ];
          _covidData = {
            'statistics': {
              'total_cases': 1003450,
              'today_cases': 12,
              'active_cases': 856,
              'recovered': 989234,
            }
          };
          _covidHistorical = {
            'trend': 'stable',
            'daily_breakdown': [
              {'date': '1/1/26', 'new_cases': 10},
              {'date': '1/2/26', 'new_cases': 8},
              {'date': '1/3/26', 'new_cases': 12},
              {'date': '1/4/26', 'new_cases': 15},
              {'date': '1/5/26', 'new_cases': 11},
              {'date': '1/6/26', 'new_cases': 9},
              {'date': '1/7/26', 'new_cases': 7},
            ],
          };
          _vaccinationData = {
            'latest': {
              'coverage_percentage': 85.0,
              'total_doses': 62000000,
              'population': 30000000,
            },
            'status': {
              'level': 'high',
              'color': 'green',
              'message': 'High vaccination coverage',
            },
          };
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openAIAnalysis() {
    final stats = _covidData['statistics'] ?? {};
    final spread = _spreadLevel;
    final vaccination = _vaccinationData['latest'] ?? {};
    final trend = _covidHistorical['trend'] ?? 'unknown';

    showLiveAICallBottomSheet(
      context: context,
      config: LiveAICallConfig(
        specialist: 'Epidemiologist & Public Health Expert',
        patientContext: '''Disease surveillance data for $_selectedCountry:

COVID-19 STATUS:
- Active Cases: ${stats['active_cases'] ?? 'N/A'}
- Total Cases: ${stats['total_cases'] ?? 'N/A'}
- Today's Cases: ${stats['today_cases'] ?? 'N/A'}
- Deaths: ${stats['deaths'] ?? 'N/A'}
- Recovered: ${stats['recovered'] ?? 'N/A'}

SPREAD LEVEL:
- Level: ${spread['spread_level'] ?? 'unknown'}
- Trend: $trend
- Active per 100k: ${spread['active_per_100k'] ?? 'N/A'}

VACCINATION:
- Coverage: ${vaccination['coverage_percentage'] ?? 'N/A'}%
- Total Doses: ${vaccination['total_doses'] ?? 'N/A'}

The user wants expert analysis on the disease situation and health recommendations.''',
        systemPrompt:
            '''You are an epidemiologist and public health expert. Analyze the disease surveillance data and provide:
1. Current disease situation assessment
2. Risk level for the population
3. Recommended precautions and protective measures
4. Advice for vulnerable groups (elderly, immunocompromised)
5. Travel and gathering recommendations if relevant''',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.diseaseSurveillance),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Health Analysis',
            onPressed: _openAIAnalysis,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.public),
            onSelected: (country) {
              setState(() => _selectedCountry = country);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Nepal', child: Text('🇳🇵 Nepal')),
              const PopupMenuItem(value: 'India', child: Text('🇮🇳 India')),
              const PopupMenuItem(
                  value: 'Bangladesh', child: Text('🇧🇩 Bangladesh')),
              const PopupMenuItem(
                  value: 'Pakistan', child: Text('🇵🇰 Pakistan')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpreadLevelCard(),
                    const SizedBox(height: 20),
                    _buildCovidStatsCard(),
                    const SizedBox(height: 20),
                    _buildVaccinationCard(), // Vaccination coverage
                    const SizedBox(height: 20),
                    _buildHistoricalTrendCard(), // Historical trends
                    const SizedBox(height: 20),
                    _buildRegionalComparisonCard(), // New comparison card
                    const SizedBox(height: 20),
                    _buildActiveDiseaseAlertsSection(), // All active diseases
                    const SizedBox(height: 20),
                    _buildOutbreaksSection(),
                    const SizedBox(height: 20),
                    _buildRegionalAlertsSection(),
                    const SizedBox(height: 20),
                    _buildPreventionSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSpreadLevelCard() {
    final level = _spreadLevel['spread_level'] ?? 'unknown';
    final trend = _spreadLevel['trend'] ?? 'stable';
    final activePer100k = _spreadLevel['active_per_100k'] ?? 0.0;

    Color levelColor;
    IconData levelIcon;
    String levelText;

    switch (level) {
      case 'critical':
        levelColor = Colors.red;
        levelIcon = Icons.warning_rounded;
        levelText = 'Critical';
        break;
      case 'high':
        levelColor = Colors.orange;
        levelIcon = Icons.error_outline;
        levelText = 'High Risk';
        break;
      case 'moderate':
        levelColor = Colors.amber;
        levelIcon = Icons.info_outline;
        levelText = 'Moderate';
        break;
      default:
        levelColor = Colors.green;
        levelIcon = Icons.check_circle_outline;
        levelText = 'Low Risk';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [levelColor.withOpacity(0.8), levelColor.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(levelIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_selectedCountry Health Status',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      levelText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend == 'increasing'
                          ? Icons.trending_up
                          : trend == 'decreasing'
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend.toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Active/100K', activePer100k.toStringAsFixed(1),
                    Icons.people_outline),
                Container(
                    height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                _buildStatItem('New Today', '${_spreadLevel['today_new'] ?? 0}',
                    Icons.add_circle_outline),
                Container(
                    height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                _buildStatItem(
                    'Total Active',
                    '${_spreadLevel['total_active'] ?? 0}',
                    Icons.coronavirus_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCovidStatsCard() {
    final stats = _covidData['statistics'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.coronavirus, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'COVID-19 Statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildCovidStatTile('Total Cases',
                      _formatNumber(stats['total_cases'] ?? 0), Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildCovidStatTile('Active',
                      _formatNumber(stats['active_cases'] ?? 0), Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildCovidStatTile(
                      'Today', '+${stats['today_cases'] ?? 0}', Colors.amber)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildCovidStatTile('Recovered',
                      _formatNumber(stats['recovered'] ?? 0), Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationCard() {
    final latest = _vaccinationData['latest'] as Map<String, dynamic>?;
    final status = _vaccinationData['status'] as Map<String, dynamic>?;

    if (latest == null) return const SizedBox.shrink();

    final coverage = latest['coverage_percentage'] ?? 0.0;
    final totalDoses = latest['total_doses'] ?? 0;
    final statusColor = status?['color'] ?? 'gray';

    Color getColor(String colorName) {
      switch (colorName) {
        case 'green':
          return Colors.green;
        case 'yellow':
          return Colors.orange;
        case 'orange':
          return Colors.deepOrange;
        case 'red':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade600, Colors.teal.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vaccines, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Vaccination Coverage',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getColor(statusColor).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status?['level']?.toString().toUpperCase() ?? 'N/A',
                  style: TextStyle(
                      color: getColor(statusColor),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (coverage as num).toDouble() / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(getColor(statusColor)),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${coverage.toStringAsFixed(1)}% coverage',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${_formatNumber(totalDoses as int)} doses',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalTrendCard() {
    final trend = _covidHistorical['trend'] ?? 'unknown';
    final dailyBreakdown =
        _covidHistorical['daily_breakdown'] as List<dynamic>? ?? [];

    if (dailyBreakdown.isEmpty) return const SizedBox.shrink();

    IconData getTrendIcon() {
      switch (trend) {
        case 'increasing':
          return Icons.trending_up;
        case 'decreasing':
          return Icons.trending_down;
        default:
          return Icons.trending_flat;
      }
    }

    Color getTrendColor() {
      switch (trend) {
        case 'increasing':
          return Colors.red;
        case 'decreasing':
          return Colors.green;
        default:
          return Colors.orange;
      }
    }

    // Get max for scaling chart bars
    final maxCases = dailyBreakdown.fold<int>(1,
        (max, d) => (d['new_cases'] ?? 0) > max ? (d['new_cases'] ?? 0) : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: getTrendColor(), size: 22),
              const SizedBox(width: 10),
              const Text('COVID Trend (14 days)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getTrendColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(getTrendIcon(), size: 14, color: getTrendColor()),
                    const SizedBox(width: 4),
                    Text(trend.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            color: getTrendColor(),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mini bar chart
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyBreakdown.take(14).map((d) {
                final cases = (d['new_cases'] ?? 0) as int;
                final height = maxCases > 0 ? (cases / maxCases) * 50 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: height + 4,
                      decoration: BoxDecoration(
                        color: getTrendColor().withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('14 days ago',
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
              Text('Today',
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDiseaseAlertsSection() {
    if (_activeDiseaseAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text(
              'Active Disease Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_activeDiseaseAlerts).map((alert) {
          final disease = alert['disease']?.toString() ?? 'Unknown';
          final severity = alert['severity']?.toString() ?? 'low';
          final message = alert['message']?.toString() ?? '';
          final icon = alert['icon']?.toString() ?? '🦠';
          final status = alert['status']?.toString() ?? 'active';

          Color cardColor;
          switch (severity) {
            case 'high':
              cardColor = Colors.red;
              break;
            case 'moderate':
              cardColor = Colors.orange;
              break;
            default:
              cardColor = Colors.green;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => context
                  .push('/disease-detail/${Uri.encodeComponent(disease)}'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cardColor.withOpacity(0.15),
                      cardColor.withOpacity(0.05)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                disease,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cardColor),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRegionalComparisonCard() {
    final comparison = _covidComparison['comparison'] as Map<String, dynamic>?;
    final neighbors = _covidComparison['neighbors'] as List<dynamic>? ?? [];

    if (comparison == null && neighbors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade600, Colors.indigo.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Regional COVID Comparison',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Verdict chip
          if (comparison != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                comparison['comparison_verdict'] ?? 'Similar to region',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Analysis text
            Text(
              comparison['analysis'] ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Neighbor comparison cards
          if (neighbors.isNotEmpty) ...[
            Text(
              'Neighboring Countries',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 85,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: neighbors.length,
                itemBuilder: (context, index) {
                  final neighbor = neighbors[index] as Map<String, dynamic>;
                  final stats =
                      neighbor['statistics'] as Map<String, dynamic>? ?? {};
                  return Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (neighbor['flag'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Image.network(
                                  neighbor['flag'],
                                  width: 18,
                                  height: 12,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.flag,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                neighbor['country'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Active: ${_formatNumber((stats['active_cases'] ?? 0) as int)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                        Text(
                          '${_formatNumber((stats['cases_per_million'] ?? 0) as int)}/M',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCovidStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.6))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildOutbreaksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Active Outbreaks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_outbreaks.length} Active',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.6)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: _outbreaks.isEmpty
              ? Center(
                  child: Text(
                    'No active outbreaks',
                    style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.5)),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _outbreaks.length,
                  itemBuilder: (context, index) {
                    final outbreak = _outbreaks[index];
                    return _buildOutbreakCard(outbreak);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOutbreakCard(Map<String, dynamic> outbreak) {
    final severity = outbreak['severity'] ?? 'moderate';
    final diseaseName = outbreak['disease'] ?? 'Unknown';
    final Color color = severity == 'critical'
        ? Colors.red
        : severity == 'high'
            ? Colors.orange
            : Colors.amber;

    return GestureDetector(
      onTap: () =>
          context.push('/disease-detail/${Uri.encodeComponent(diseaseName)}'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.coronavirus, color: color, size: 20),
                const Spacer(),
                if (severity == 'critical')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CRITICAL',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      severity.toString().toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              outbreak['disease'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    outbreak['location'] ?? 'Global',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Source: ${outbreak['source'] ?? 'WHO'}',
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_active,
                color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Seasonal Disease Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_regionalAlerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'No active seasonal alerts for your region',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ],
            ),
          )
        else
          ...List.generate(_regionalAlerts.length, (index) {
            final alert = _regionalAlerts[index];
            return _buildAlertTile(alert);
          }),
      ],
    );
  }

  Widget _buildAlertTile(Map<String, dynamic> alert) {
    final riskLevel = alert['risk_level'] ?? 'moderate';
    final color = riskLevel == 'high'
        ? Colors.red
        : riskLevel == 'moderate'
            ? Colors.orange
            : Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              alert['disease'] == 'Influenza'
                  ? Icons.air
                  : alert['disease'] == 'Pneumonia'
                      ? Icons.sick
                      : Icons.coronavirus,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['disease'] ?? 'Disease',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Season: ${alert['season'] ?? 'Year-round'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              riskLevel.toString().toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreventionSection() {
    final tips = [
      {
        'icon': Icons.masks,
        'tip': 'Wear mask in crowded places',
        'color': Colors.blue
      },
      {
        'icon': Icons.wash,
        'tip': 'Wash hands frequently',
        'color': Colors.teal
      },
      {'icon': Icons.water_drop, 'tip': 'Stay hydrated', 'color': Colors.cyan},
      {'icon': Icons.vaccines, 'tip': 'Get vaccinated', 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.shield, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              'Prevention Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tips
              .map((tip) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (tip['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: (tip['color'] as Color).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tip['icon'] as IconData,
                            color: tip['color'] as Color, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          tip['tip'] as String,
                          style: TextStyle(
                              fontSize: 12,
                              color: tip['color'] as Color,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
