import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';

class PreventionHubScreen extends StatelessWidget {
  const PreventionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.prevention)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade800, Colors.teal.shade600],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20, top: -20,
                    child: Icon(Icons.water_drop, size: 150, color: Colors.white.withOpacity(0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(l10n.dailyInsight, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const Spacer(),
                        const Text('Boost Your Immunity',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('Drinking 3L of water daily can significantly improve your body\'s natural defense.',
                          style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            _buildCategoryChips(),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.dailyGoals, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            
            _buildGoalItem(context, l10n.drinkWater, '2000ml', Icons.water_drop, Colors.blue, true),
            _buildGoalItem(context, l10n.takeVitamins, '1 Tablet (1000 IU)', Icons.medication, Colors.orange, false),
            _buildGoalItem(context, l10n.sleepEarly, '10:30 PM', Icons.bedtime, Colors.indigo, false),
            
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('AI Recommended', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            
            _buildRecommendationCard(context, 'Seasonal Flu Prevention', 'Learn how to protect yourself this season', Icons.ac_unit, Colors.cyan),
            _buildRecommendationCard(context, 'Hand Hygiene Guide', '5 steps to proper handwashing', Icons.clean_hands, Colors.green),
            _buildRecommendationCard(context, 'Stress Management', 'Daily techniques for mental wellness', Icons.self_improvement, Colors.purple),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.smart_toy),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['For You', 'Viral', 'Hygiene', 'Nutrition', 'Mental'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((c) => Container(
          margin: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(c),
            selected: c == 'For You',
            onSelected: (v) {},
            selectedColor: AppColors.primary.withOpacity(0.2),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, String title, String target, IconData icon, Color color, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: isCompleted ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                )),
                Text(target, style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                )),
              ],
            ),
          ),
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: isCompleted ? Colors.green : Colors.grey, width: 2),
            ),
            child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
