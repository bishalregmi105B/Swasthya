import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final cartItems = [
      _CartItem('Paracetamol 500mg', 'Pain Relief', 50.0, 2),
      _CartItem('Vitamin C 1000mg', 'Supplements', 120.0, 1),
    ];

    final subtotal =
        cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    const deliveryFee = 50.0;
    final total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cart)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...cartItems.map((item) => _buildCartItem(context, item, l10n)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.subtotal),
                          Text('Rs. ${subtotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.deliveryFee),
                          Text('Rs. ${deliveryFee.toStringAsFixed(0)}'),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.total,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('Rs. ${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.deliveryAddress,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('Kalimati, Kathmandu',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.6))),
                          ],
                        ),
                      ),
                      TextButton(onPressed: () {}, child: Text(l10n.change)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.uploadPrescription)),
                      OutlinedButton(
                          onPressed: () {}, child: Text(l10n.upload)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56)),
                child: Text(l10n.placeOrder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
      BuildContext context, _CartItem item, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(item.category,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text('Rs. ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {}),
              Text('${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(icon: const Icon(Icons.add_circle), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartItem {
  final String name, category;
  final double price;
  final int quantity;
  _CartItem(this.name, this.category, this.price, this.quantity);
}
