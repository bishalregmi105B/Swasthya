import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final calculators = [
      _Calculator('BMI Calculator', 'Body Mass Index - Weight health indicator',
          Icons.monitor_weight, Colors.blue, 'bmi'),
      _Calculator(
          'Ideal Body Weight',
          'Robinson Formula - Target weight by height',
          Icons.accessibility_new,
          Colors.green,
          'ibw'),
      _Calculator('Heart Rate Zones', 'Karvonen Method - Training zones',
          Icons.favorite, Colors.red, 'heart'),
      _Calculator('Body Fat %', 'Navy Method - Estimate body composition',
          Icons.percent, Colors.orange, 'bodyfat'),
      _Calculator('Calorie Needs', 'Mifflin-St Jeor - Daily calorie intake',
          Icons.local_fire_department, Colors.deepOrange, 'calories'),
      _Calculator('Water Intake', 'Daily hydration needs by weight',
          Icons.water_drop, Colors.cyan, 'water'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.healthCalculators)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: calculators.length,
        itemBuilder: (context, index) {
          final calc = calculators[index];
          return GestureDetector(
            onTap: () => _showCalculator(context, calc),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                      color: calc.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(calc.icon, color: calc.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(calc.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(calc.subtitle,
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.3)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCalculator(BuildContext context, _Calculator calc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        switch (calc.type) {
          case 'bmi':
            return _BMICalculator(color: calc.color);
          case 'ibw':
            return _IBWCalculator(color: calc.color);
          case 'heart':
            return _HeartRateCalculator(color: calc.color);
          case 'bodyfat':
            return _BodyFatCalculator(color: calc.color);
          case 'calories':
            return _CalorieCalculator(color: calc.color);
          case 'water':
            return _WaterIntakeCalculator(color: calc.color);
          default:
            return _BMICalculator(color: calc.color);
        }
      },
    );
  }
}

class _Calculator {
  final String title, subtitle, type;
  final IconData icon;
  final Color color;
  _Calculator(this.title, this.subtitle, this.icon, this.color, this.type);
}

// ===== BMI CALCULATOR =====
class _BMICalculator extends StatefulWidget {
  final Color color;
  const _BMICalculator({required this.color});

  @override
  State<_BMICalculator> createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<_BMICalculator> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  double? _result;
  String? _category;
  Map<String, dynamic>? _details;
  bool _isLoading = false;

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    if (weight == null || height == null || height == 0) return;

    final bmi = weight / ((height / 100) * (height / 100));

    String category;
    String healthRisk;
    String recommendation;
    double minHealthy, maxHealthy;

    minHealthy = 18.5 * (height / 100) * (height / 100);
    maxHealthy = 24.9 * (height / 100) * (height / 100);

    if (bmi < 16) {
      category = 'Severely Underweight';
      healthRisk = 'High risk of malnutrition';
      recommendation =
          'Seek medical advice. Consider nutrient-rich foods and supplements.';
    } else if (bmi < 18.5) {
      category = 'Underweight';
      healthRisk = 'Risk of nutritional deficiency';
      recommendation =
          'Increase calorie intake with healthy foods. Consider strength training.';
    } else if (bmi < 25) {
      category = 'Normal Weight';
      healthRisk = 'Low health risk';
      recommendation =
          'Maintain your healthy lifestyle! Regular exercise and balanced diet.';
    } else if (bmi < 30) {
      category = 'Overweight';
      healthRisk = 'Increased risk of heart disease, diabetes';
      recommendation =
          'Reduce calorie intake, increase physical activity. Target 150 min/week exercise.';
    } else if (bmi < 35) {
      category = 'Obese Class I';
      healthRisk = 'High risk of cardiovascular disease';
      recommendation =
          'Consult a doctor. Aim for 5-10% weight loss over 6 months.';
    } else if (bmi < 40) {
      category = 'Obese Class II';
      healthRisk = 'Very high risk of health complications';
      recommendation =
          'Medical supervision recommended. Consider structured weight loss program.';
    } else {
      category = 'Obese Class III';
      healthRisk = 'Extremely high risk';
      recommendation =
          'Seek medical intervention. May require supervised treatment.';
    }

    setState(() {
      _result = bmi;
      _category = category;
      _details = {
        'healthRisk': healthRisk,
        'recommendation': recommendation,
        'minHealthy': minHealthy.toStringAsFixed(1),
        'maxHealthy': maxHealthy.toStringAsFixed(1),
        'weightToLose':
            bmi > 25 ? (weight - maxHealthy).toStringAsFixed(1) : null,
        'weightToGain':
            bmi < 18.5 ? (minHealthy - weight).toStringAsFixed(1) : null,
      };
    });
  }

  Color _getCategoryColor() {
    if (_result == null) return widget.color;
    if (_result! < 18.5) return Colors.blue;
    if (_result! < 25) return Colors.green;
    if (_result! < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 20,
          right: 20,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.monitor_weight, color: widget.color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BMI Calculator',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Body Mass Index',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              prefixIcon: Icon(Icons.fitness_center),
              hintText: 'e.g., 70',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              prefixIcon: Icon(Icons.height),
              hintText: 'e.g., 175',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56)),
            child: const Text('Calculate BMI'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getCategoryColor().withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(_result!.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: _getCategoryColor())),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                        color: _getCategoryColor(),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(_category!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard('⚠️ Health Risk', _details!['healthRisk']),
            _buildInfoCard('💡 Recommendation', _details!['recommendation']),
            _buildInfoCard('📊 Healthy Weight Range',
                '${_details!['minHealthy']} - ${_details!['maxHealthy']} kg'),
            if (_details!['weightToLose'] != null)
              _buildInfoCard('🎯 Weight to Lose',
                  '${_details!['weightToLose']} kg to reach healthy BMI'),
            if (_details!['weightToGain'] != null)
              _buildInfoCard('🎯 Weight to Gain',
                  '${_details!['weightToGain']} kg to reach healthy BMI'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7))),
        ],
      ),
    );
  }
}

// ===== IBW CALCULATOR =====
class _IBWCalculator extends StatefulWidget {
  final Color color;
  const _IBWCalculator({required this.color});

  @override
  State<_IBWCalculator> createState() => _IBWCalculatorState();
}

class _IBWCalculatorState extends State<_IBWCalculator> {
  final _heightController = TextEditingController();
  String _gender = 'male';
  Map<String, double>? _results;

  void _calculate() {
    final height = double.tryParse(_heightController.text);
    if (height == null || height == 0) return;

    final heightInches = height / 2.54;
    final baseHeight = 60.0;

    // Multiple formulas for comparison
    double robinson, miller, devine, hamwi;

    if (_gender == 'male') {
      robinson = 52 + 1.9 * (heightInches - baseHeight);
      miller = 56.2 + 1.41 * (heightInches - baseHeight);
      devine = 50 + 2.3 * (heightInches - baseHeight);
      hamwi = 48.0 + 2.7 * (heightInches - baseHeight);
    } else {
      robinson = 49 + 1.7 * (heightInches - baseHeight);
      miller = 53.1 + 1.36 * (heightInches - baseHeight);
      devine = 45.5 + 2.3 * (heightInches - baseHeight);
      hamwi = 45.5 + 2.2 * (heightInches - baseHeight);
    }

    setState(() {
      _results = {
        'robinson': robinson.clamp(40.0, 200.0),
        'miller': miller.clamp(40.0, 200.0),
        'devine': devine.clamp(40.0, 200.0),
        'hamwi': hamwi.clamp(40.0, 200.0),
        'average':
            ((robinson + miller + devine + hamwi) / 4).clamp(40.0, 200.0),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 20,
          right: 20,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.accessibility_new, color: widget.color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ideal Body Weight',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Multiple formulas comparison',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              prefixIcon: Icon(Icons.height),
              hintText: 'e.g., 175',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = 'male'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gender == 'male'
                          ? widget.color.withOpacity(0.1)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _gender == 'male'
                              ? widget.color
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.male,
                            color:
                                _gender == 'male' ? widget.color : Colors.grey,
                            size: 32),
                        const SizedBox(height: 4),
                        Text('Male',
                            style: TextStyle(
                                fontWeight: _gender == 'male'
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = 'female'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gender == 'female'
                          ? widget.color.withOpacity(0.1)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _gender == 'female'
                              ? widget.color
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.female,
                            color: _gender == 'female'
                                ? widget.color
                                : Colors.grey,
                            size: 32),
                        const SizedBox(height: 4),
                        Text('Female',
                            style: TextStyle(
                                fontWeight: _gender == 'female'
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56)),
            child: const Text('Calculate'),
          ),
          if (_results != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Recommended Weight',
                      style: TextStyle(fontSize: 14)),
                  Text('${_results!['average']!.toStringAsFixed(1)} kg',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: widget.color)),
                  const Text('(Average of 4 formulas)',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildFormulaRow('Robinson Formula', _results!['robinson']!,
                'Most commonly used'),
            _buildFormulaRow(
                'Miller Formula', _results!['miller']!, 'More recent research'),
            _buildFormulaRow(
                'Devine Formula', _results!['devine']!, 'Used in drug dosing'),
            _buildFormulaRow(
                'Hamwi Formula', _results!['hamwi']!, 'Nutrition baseline'),
          ],
        ],
      ),
    );
  }

  Widget _buildFormulaRow(String name, double value, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(desc,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text('${value.toStringAsFixed(1)} kg',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                  fontSize: 16)),
        ],
      ),
    );
  }
}

// ===== HEART RATE CALCULATOR =====
class _HeartRateCalculator extends StatefulWidget {
  final Color color;
  const _HeartRateCalculator({required this.color});

  @override
  State<_HeartRateCalculator> createState() => _HeartRateCalculatorState();
}

class _HeartRateCalculatorState extends State<_HeartRateCalculator> {
  final _ageController = TextEditingController();
  final _restingHRController = TextEditingController();
  Map<String, dynamic>? _zones;

  void _calculate() {
    final age = int.tryParse(_ageController.text);
    final restingHR = int.tryParse(_restingHRController.text) ?? 70;
    if (age == null) return;

    final maxHR = 220 - age;
    final hrReserve = maxHR - restingHR;

    setState(() {
      _zones = {
        'maxHR': maxHR,
        'restingHR': restingHR,
        'zones': [
          {
            'name': 'Zone 1 - Recovery',
            'intensity': '50-60%',
            'min': (restingHR + hrReserve * 0.5).round(),
            'max': (restingHR + hrReserve * 0.6).round(),
            'color': Colors.grey,
            'desc': 'Light activity, warm-up/cool-down'
          },
          {
            'name': 'Zone 2 - Fat Burn',
            'intensity': '60-70%',
            'min': (restingHR + hrReserve * 0.6).round(),
            'max': (restingHR + hrReserve * 0.7).round(),
            'color': Colors.blue,
            'desc': 'Aerobic endurance, fat burning'
          },
          {
            'name': 'Zone 3 - Cardio',
            'intensity': '70-80%',
            'min': (restingHR + hrReserve * 0.7).round(),
            'max': (restingHR + hrReserve * 0.8).round(),
            'color': Colors.green,
            'desc': 'Cardiovascular fitness'
          },
          {
            'name': 'Zone 4 - Threshold',
            'intensity': '80-90%',
            'min': (restingHR + hrReserve * 0.8).round(),
            'max': (restingHR + hrReserve * 0.9).round(),
            'color': Colors.orange,
            'desc': 'Lactate threshold training'
          },
          {
            'name': 'Zone 5 - Max',
            'intensity': '90-100%',
            'min': (restingHR + hrReserve * 0.9).round(),
            'max': maxHR,
            'color': Colors.red,
            'desc': 'Maximum effort, sprints'
          },
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 20,
          right: 20,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.favorite, color: widget.color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heart Rate Zones',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Karvonen Method',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age (years)',
              prefixIcon: Icon(Icons.cake),
              hintText: 'e.g., 30',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _restingHRController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Resting Heart Rate (bpm) - Optional',
              prefixIcon: Icon(Icons.monitor_heart),
              hintText: 'e.g., 65 (default: 70)',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56)),
            child: const Text('Calculate Zones'),
          ),
          if (_zones != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Max HR', style: TextStyle(fontSize: 12)),
                      Text('${_zones!['maxHR']}',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: widget.color)),
                      const Text('bpm',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey.withOpacity(0.2)),
                  Column(
                    children: [
                      const Text('Resting HR', style: TextStyle(fontSize: 12)),
                      Text('${_zones!['restingHR']}',
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w700)),
                      const Text('bpm',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...(_zones!['zones'] as List).map((zone) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (zone['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: (zone['color'] as Color).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                            color: zone['color'],
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(zone['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(zone['desc'],
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${zone['min']}-${zone['max']}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: zone['color'],
                                  fontSize: 16)),
                          Text(zone['intensity'],
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ===== BODY FAT CALCULATOR =====
class _BodyFatCalculator extends StatefulWidget {
  final Color color;
  const _BodyFatCalculator({required this.color});

  @override
  State<_BodyFatCalculator> createState() => _BodyFatCalculatorState();
}

class _BodyFatCalculatorState extends State<_BodyFatCalculator> {
  final _waistController = TextEditingController();
  final _neckController = TextEditingController();
  final _heightController = TextEditingController();
  final _hipController = TextEditingController();
  String _gender = 'male';
  double? _result;
  String? _category;

  void _calculate() {
    final waist = double.tryParse(_waistController.text);
    final neck = double.tryParse(_neckController.text);
    final height = double.tryParse(_heightController.text);
    final hip = double.tryParse(_hipController.text);

    if (waist == null || neck == null || height == null) return;
    if (_gender == 'female' && hip == null) return;

    double bodyFat;
    if (_gender == 'male') {
      // Navy Method for men
      bodyFat = 495 /
              (1.0324 -
                  0.19077 * _log10(waist - neck) +
                  0.15456 * _log10(height)) -
          450;
    } else {
      // Navy Method for women
      bodyFat = 495 /
              (1.29579 -
                  0.35004 * _log10(waist + hip! - neck) +
                  0.22100 * _log10(height)) -
          450;
    }

    String category;
    if (_gender == 'male') {
      if (bodyFat < 6)
        category = 'Essential Fat';
      else if (bodyFat < 14)
        category = 'Athletes';
      else if (bodyFat < 18)
        category = 'Fitness';
      else if (bodyFat < 25)
        category = 'Average';
      else
        category = 'Obese';
    } else {
      if (bodyFat < 14)
        category = 'Essential Fat';
      else if (bodyFat < 21)
        category = 'Athletes';
      else if (bodyFat < 25)
        category = 'Fitness';
      else if (bodyFat < 32)
        category = 'Average';
      else
        category = 'Obese';
    }

    setState(() {
      _result = bodyFat.clamp(3.0, 50.0);
      _category = category;
    });
  }

  double _log10(double x) =>
      0.4342944819 * (x > 0 ? x : 1).toString().length.toDouble() +
      0.4342944819 * (x / 10.0).clamp(0.1, 10.0);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 20,
          right: 20,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.percent, color: widget.color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Body Fat %',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Navy Method',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = 'male'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _gender == 'male'
                          ? widget.color.withOpacity(0.1)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _gender == 'male'
                              ? widget.color
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.male,
                            color:
                                _gender == 'male' ? widget.color : Colors.grey),
                        const SizedBox(width: 8),
                        Text('Male',
                            style: TextStyle(
                                fontWeight: _gender == 'male'
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = 'female'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _gender == 'female'
                          ? widget.color.withOpacity(0.1)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _gender == 'female'
                              ? widget.color
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.female,
                            color: _gender == 'female'
                                ? widget.color
                                : Colors.grey),
                        const SizedBox(width: 8),
                        Text('Female',
                            style: TextStyle(
                                fontWeight: _gender == 'female'
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Height (cm)', prefixIcon: Icon(Icons.height)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _waistController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Waist circumference (cm)',
                prefixIcon: Icon(Icons.straighten)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _neckController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Neck circumference (cm)',
                prefixIcon: Icon(Icons.straighten)),
          ),
          if (_gender == 'female') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _hipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Hip circumference (cm)',
                  prefixIcon: Icon(Icons.straighten)),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56)),
            child: const Text('Calculate'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('${_result!.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: widget.color)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(_category!,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===== CALORIE CALCULATOR =====
class _CalorieCalculator extends StatefulWidget {
  final Color color;
  const _CalorieCalculator({required this.color});

  @override
  State<_CalorieCalculator> createState() => _CalorieCalculatorState();
}

class _CalorieCalculatorState extends State<_CalorieCalculator> {
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _gender = 'male';
  String _activity = 'moderate';
  Map<String, int>? _results;

  void _calculate() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    if (age == null || weight == null || height == null) return;

    // Mifflin-St Jeor Equation
    double bmr;
    if (_gender == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'veryActive': 1.9,
    };

    final tdee = (bmr * multipliers[_activity]!).round();

    setState(() {
      _results = {
        'bmr': bmr.round(),
        'maintenance': tdee,
        'mildLoss': (tdee - 250).round(),
        'weightLoss': (tdee - 500).round(),
        'mildGain': (tdee + 250).round(),
        'weightGain': (tdee + 500).round(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 20,
          right: 20,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.local_fire_department, color: widget.color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calorie Calculator',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Mifflin-St Jeor Equation',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _genderButton('male', Icons.male)),
              const SizedBox(width: 12),
              Expanded(child: _genderButton('female', Icons.female)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Age (years)', prefixIcon: Icon(Icons.cake))),
          const SizedBox(height: 12),
          TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.fitness_center))),
          const SizedBox(height: 12),
          TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Height (cm)', prefixIcon: Icon(Icons.height))),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _activity,
            decoration: const InputDecoration(
                labelText: 'Activity Level',
                prefixIcon: Icon(Icons.directions_run)),
            items: const [
              DropdownMenuItem(
                  value: 'sedentary',
                  child: Text('Sedentary (little/no exercise)')),
              DropdownMenuItem(
                  value: 'light', child: Text('Light (1-3 days/week)')),
              DropdownMenuItem(
                  value: 'moderate', child: Text('Moderate (3-5 days/week)')),
              DropdownMenuItem(
                  value: 'active', child: Text('Active (6-7 days/week)')),
              DropdownMenuItem(
                  value: 'veryActive',
                  child: Text('Very Active (physical job)')),
            ],
            onChanged: (v) => setState(() => _activity = v!),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56)),
            child: const Text('Calculate'),
          ),
          if (_results != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Text('Daily Calories to Maintain Weight',
                      style: TextStyle(fontSize: 14)),
                  Text('${_results!['maintenance']}',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: widget.color)),
                  const Text('kcal/day', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _calorieCard(
                        'BMR', _results!['bmr']!, 'At rest', Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                    child: _calorieCard('Lose 0.25kg/wk',
                        _results!['mildLoss']!, '-250 cal', Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _calorieCard('Lose 0.5kg/wk',
                        _results!['weightLoss']!, '-500 cal', Colors.green)),
                const SizedBox(width: 8),
                Expanded(
                    child: _calorieCard('Gain 0.5kg/wk',
                        _results!['weightGain']!, '+500 cal', Colors.orange)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _genderButton(String g, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => _gender = g),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _gender == g
              ? widget.color.withOpacity(0.1)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _gender == g ? widget.color : Colors.transparent,
              width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _gender == g ? widget.color : Colors.grey),
            const SizedBox(width: 8),
            Text(g == 'male' ? 'Male' : 'Female',
                style: TextStyle(
                    fontWeight:
                        _gender == g ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _calorieCard(String title, int value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          Text('$value',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ===== WATER INTAKE CALCULATOR =====
class _WaterIntakeCalculator extends StatefulWidget {
  final Color color;
  const _WaterIntakeCalculator({required this.color});

  @override
  State<_WaterIntakeCalculator> createState() => _WaterIntakeCalculatorState();
}

class _WaterIntakeCalculatorState extends State<_WaterIntakeCalculator> {
  final _weightController = TextEditingController();
  String _activity = 'moderate';
  Map<String, dynamic>? _results;

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;

    // Base: 35ml per kg
    double baseWater = weight * 35;

    final multipliers = {
      'sedentary': 1.0,
      'light': 1.1,
      'moderate': 1.2,
      'active': 1.4,
      'veryActive': 1.6,
    };

    final totalMl = (baseWater * multipliers[_activity]!).round();

    setState(() {
      _results = {
        'liters': (totalMl / 1000).toStringAsFixed(1),
        'ml': totalMl,
        'glasses': (totalMl / 250).round(),
        'bottles': (totalMl / 500).toStringAsFixed(1),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 20,
          right: 20,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.water_drop, color: widget.color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Water Intake',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Daily hydration needs',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.fitness_center)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _activity,
            decoration: const InputDecoration(
                labelText: 'Activity Level',
                prefixIcon: Icon(Icons.directions_run)),
            items: const [
              DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
              DropdownMenuItem(value: 'light', child: Text('Light activity')),
              DropdownMenuItem(
                  value: 'moderate', child: Text('Moderate activity')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(
                  value: 'veryActive',
                  child: Text('Very active / Hot climate')),
            ],
            onChanged: (v) => setState(() => _activity = v!),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56)),
            child: const Text('Calculate'),
          ),
          if (_results != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Icon(Icons.water_drop, color: widget.color, size: 40),
                  const SizedBox(height: 8),
                  Text('${_results!['liters']} L',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: widget.color)),
                  const Text('Daily water intake',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _infoCard(
                        '🥛', '${_results!['glasses']}', 'Glasses (250ml)')),
                const SizedBox(width: 8),
                Expanded(
                    child: _infoCard(
                        '🍶', '${_results!['bottles']}', 'Bottles (500ml)')),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Increase intake during exercise, hot weather, or if you consume caffeine/alcohol.',
                          style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: widget.color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
