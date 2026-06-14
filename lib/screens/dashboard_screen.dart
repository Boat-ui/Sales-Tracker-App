import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = state.settings.currency;
    final todaySales = state.salesForDate(DateTime.now());
    final todaySummary = state.summaryForSales(todaySales);
    final allSummary = state.summaryForSales(state.sales);
    final fmt = NumberFormat('#,##0.00');

    String f(double v) => '$currency${fmt.format(v)}';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '📊',
                    style: TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BizSplit ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A148C),
                        ),
                      ),
                      Text(
                        DateFormat('EEE, MMM d yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Today ─────────────────────────────────────────
              _sectionTitle("Today's Summary", Icons.today),
              const SizedBox(height: 12),
              if (todaySales.isEmpty)
                _emptyBox("No sales recorded today yet")
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            label: 'Revenue',
                            amount: f(todaySummary['revenue']!),
                            color: const Color(0xFF1565C0),
                            icon: Icons.attach_money,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            label: 'Profit',
                            amount: f(todaySummary['profit']!),
                            color: const Color(0xFF2E7D32),
                            icon: Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            label: 'Business 💼',
                            amount: f(todaySummary['business']!),
                            color: const Color(0xFF6A1B9A),
                            icon: Icons.business_center,
                            subtitle: '50% of profit',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            label: 'Personal 👤',
                            amount: f(todaySummary['personal']!),
                            color: const Color(0xFFE65100),
                            icon: Icons.person,
                            subtitle: '50% of profit',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            label: 'Savings 🏦',
                            amount: f(todaySummary['savings']!),
                            color: const Color(0xFF00695C),
                            icon: Icons.savings,
                            subtitle:
                                '${state.settings.personalSavingsPercent.toInt()}% of personal',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            label: 'Personal Use 🛍️',
                            amount: f(todaySummary['personalUse']!),
                            color: const Color(0xFFC62828),
                            icon: Icons.shopping_bag,
                            subtitle:
                                '${state.settings.personalUsePercent.toInt()}% of personal',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cost of goods sold',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          Text(
                            f(todaySummary['cost']!),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 28),

              // ── All Time ─────────────────────────────────────
              _sectionTitle('All-Time Totals', Icons.bar_chart),
              const SizedBox(height: 12),
              _allTimeTile('Total Revenue', f(allSummary['revenue']!),
                  const Color(0xFF1565C0)),
              _allTimeTile('Total Profit', f(allSummary['profit']!),
                  const Color(0xFF2E7D32)),
              _allTimeTile('Business Saved', f(allSummary['business']!),
                  const Color(0xFF6A1B9A)),
              _allTimeTile(
                  'Total Savings', f(allSummary['savings']!), const Color(0xFF00695C)),

              const SizedBox(height: 28),

              // ── Stock Alert ────────────────────────────────────
              if (state.stock.any((s) => s.quantity <= 2)) ...[
                _sectionTitle('⚠️ Low Stock Alert', Icons.warning_amber),
                const SizedBox(height: 8),
                ...state.stock
                    .where((s) => s.quantity <= 2)
                    .map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2,
                                  color: Colors.orange, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(s.name)),
                              Text(
                                '${s.quantity} left',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4A148C), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF4A148C),
          ),
        ),
      ],
    );
  }

  Widget _emptyBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, color: Colors.grey, size: 40),
          const SizedBox(height: 8),
          Text(msg,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _allTimeTile(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color.withOpacity(0.8))),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
