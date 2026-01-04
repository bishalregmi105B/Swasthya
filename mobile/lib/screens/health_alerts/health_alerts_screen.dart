import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

class HealthAlertsScreen extends StatefulWidget {
  const HealthAlertsScreen({super.key});

  @override
  State<HealthAlertsScreen> createState() => _HealthAlertsScreenState();
}

class _HealthAlertsScreenState extends State<HealthAlertsScreen> {
  List<dynamic> _alerts = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final alertsData = await apiService.getHealthAlerts();
      final summaryData = await apiService.getHealthAlertsSummary();

      final alerts = alertsData['alerts'] ?? [];

      // Cache for offline use
      await OfflineCacheService.cacheAlerts(List<Map<String, dynamic>>.from(
          alerts.map((e) => Map<String, dynamic>.from(e))));

      setState(() {
        _alerts = alerts;
        _summary = summaryData;
        _isLoading = false;
      });
    } catch (e) {
      // Try loading from cache on error
      final cachedAlerts = OfflineCacheService.getCachedAlerts();
      if (cachedAlerts != null && cachedAlerts.isNotEmpty) {
        setState(() {
          _alerts = cachedAlerts;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthAlerts),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
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
                    // AI Summary Card
                    _buildAISummary(context, l10n),

                    const SizedBox(height: 24),

                    // Critical Alerts
                    Text(l10n.criticalAlerts,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: _alerts.isEmpty
                          ? Center(
                              child: Text('No active alerts',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.5))))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _alerts
                                  .where((a) =>
                                      a['severity'] == 'critical' ||
                                      a['severity'] == 'high')
                                  .take(5)
                                  .length,
                              itemBuilder: (context, index) {
                                final alert = _alerts
                                    .where((a) =>
                                        a['severity'] == 'critical' ||
                                        a['severity'] == 'high')
                                    .toList()[index];
                                return _buildAlertCard(context, alert);
                              },
                            ),
                    ),

                    const SizedBox(height: 24),

                    // All Alerts List
                    Text(l10n.trendingNearYou,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ..._alerts
                        .map((alert) => _buildAlertListItem(context, alert)),

                    if (_alerts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: Colors.green.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text('No health alerts in your area',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.5))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAISummary(BuildContext context, AppLocalizations l10n) {
    final riskLevel = _summary?['risk_level'] ?? 'moderate';
    final Color gradientStart;
    final Color gradientEnd;

    switch (riskLevel) {
      case 'critical':
        gradientStart = const Color(0xFFDC2626);
        gradientEnd = const Color(0xFFF97316);
        break;
      case 'high':
        gradientStart = const Color(0xFFEA580C);
        gradientEnd = const Color(0xFFF59E0B);
        break;
      case 'low':
        gradientStart = const Color(0xFF16A34A);
        gradientEnd = const Color(0xFF22C55E);
        break;
      default:
        gradientStart = const Color(0xFFF59E0B);
        gradientEnd = const Color(0xFFFBBF24);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskLevel == 'critical'
                      ? 'High Risk'
                      : riskLevel == 'high'
                          ? l10n.moderateRisk
                          : 'Low Risk',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _summary?['summary'] ??
                      'Stay informed about health conditions in your area.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, dynamic alert) {
    final severity = alert['severity'] ?? 'moderate';
    final Color color = severity == 'critical'
        ? Colors.red
        : severity == 'high'
            ? Colors.orange
            : Colors.amber;

    IconData icon;
    switch (alert['icon']) {
      case 'air':
        icon = Icons.air;
        break;
      case 'sun':
        icon = Icons.thermostat;
        break;
      case 'virus':
        icon = Icons.coronavirus;
        break;
      case 'thermometer':
        icon = Icons.thermostat;
        break;
      default:
        icon = Icons.warning;
    }

    return Container(
      width: 150,
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              if (severity == 'critical')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                ),
            ],
          ),
          const Spacer(),
          Text(
            alert['disease_name'] ?? 'Alert',
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            alert['affected_city'] ?? '',
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertListItem(BuildContext context, dynamic alert) {
    final trend = alert['trend'] ?? 'stable';
    final trendPct = alert['trend_percentage'] ?? 0;
    final isUp = trend == 'increasing';
    final severity = alert['severity'] ?? 'moderate';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: severity == 'critical'
            ? Border.all(color: Colors.red.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(alert['disease_name'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (severity == 'critical') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text('Critical',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert['affected_city'] ?? ''} • ${alert['cases_count'] ?? 0} cases',
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
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isUp ? Colors.red : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isUp ? Icons.trending_up : Icons.trending_down,
                        size: 14, color: isUp ? Colors.red : Colors.green),
                    const SizedBox(width: 4),
                    Text('${isUp ? '+' : ''}${trendPct.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 12,
                            color: isUp ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          if (alert['prevention_tips'] != null) ...[
            const SizedBox(height: 8),
            Text(
              alert['prevention_tips'],
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
