import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';

class AICategoriesScreen extends StatelessWidget {
  const AICategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final categories = [
      _Category('physician', l10n.generalPhysician, Icons.medical_services, 'Cold, flu, fever, general health', Colors.blue),
      _Category('psychiatrist', l10n.mentalHealth, Icons.psychology, 'Anxiety, stress, depression', Colors.purple),
      _Category('dermatologist', l10n.dermatologist, Icons.face_retouching_natural, 'Rashes, acne, skin infections', Colors.pink),
      _Category('pediatrician', l10n.pediatrician, Icons.child_care, 'Infants, children, adolescents', Colors.amber),
      _Category('nutritionist', l10n.nutritionist, Icons.restaurant_menu, 'Diet plans, weight management', Colors.green),
      _Category('cardiologist', l10n.cardiologist, Icons.favorite, 'Blood pressure, heart health', Colors.red),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectSpecialist),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.typeSymptomsHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.aiDisclaimer,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return _buildCategoryCard(context, cat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, _Category cat) {
    return GestureDetector(
      onTap: () => context.push('/ai-chat/${cat.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat.icon, color: cat.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _Category {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final Color color;

  _Category(this.id, this.title, this.icon, this.description, this.color);
}
