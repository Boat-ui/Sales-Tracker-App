import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/summary_card.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.navyCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
                    ),
                    child: CustomPaint(painter: _MiniIconPainter()),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                          children: [
                            TextSpan(text: 'Biz', style: TextStyle(color: AppTheme.textPrimary)),
                            TextSpan(text: 'Split', style: TextStyle(color: AppTheme.teal)),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('EEE, MMM d yyyy').format(DateTime.now()),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Today ────────────────────────────────────
              _sectionTitle("Today's Summary", Icons.today_outlined),
              const SizedBox(height: 14),
              if (todaySales.isEmpty)
                _emptyBox("No sales recorded today yet")
              else
                Column(
                  children: [
                    Row(children: [
                      Expanded(child: SummaryCard(label: 'Revenue', amount: f(todaySummary['revenue']!), color: AppTheme.revenue, icon: Icons.attach_money)),
                      const SizedBox(width: 10),
                      Expanded(child: SummaryCard(label: 'Profit', amount: f(todaySummary['profit']!), color: AppTheme.profit, icon: Icons.trending_up)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: SummaryCard(label: 'Business', amount: f(todaySummary['business']!), color: AppTheme.biz, icon: Icons.business_center_outlined, subtitle: '50% of profit')),
                      const SizedBox(width: 10),
                      Expanded(child: SummaryCard(label: 'Personal', amount: f(todaySummary['personal']!), color: AppTheme.spend, icon: Icons.person_outline, subtitle: '50% of profit')),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: SummaryCard(label: 'Savings', amount: f(todaySummary['savings']!), color: AppTheme.savings, icon: Icons.savings_outlined, subtitle: '${state.settings.personalSavingsPercent.toInt()}% of personal')),
                      const SizedBox(width: 10),
                      Expanded(child: SummaryCard(label: 'Personal Use', amount: f(todaySummary['personalUse']!), color: AppTheme.danger, icon: Icons.shopping_bag_outlined, subtitle: '${state.settings.personalUsePercent.toInt()}% of personal')),
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppTheme.navyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cost of goods sold', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          Text(f(todaySummary['cost']!), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 28),

              // ── All-Time ──────────────────────────────────
              _sectionTitle('All-Time Totals', Icons.bar_chart_outlined),
              const SizedBox(height: 14),
              _allTimeTile('Total Revenue', f(allSummary['revenue']!), AppTheme.revenue),
              _allTimeTile('Total Profit', f(allSummary['profit']!), AppTheme.profit),
              _allTimeTile('Business Saved', f(allSummary['business']!), AppTheme.biz),
              _allTimeTile('Total Savings', f(allSummary['savings']!), AppTheme.savings),

              // ── Low Stock ─────────────────────────────────
              if (state.stock.any((s) => s.quantity <= 2)) ...[
                const SizedBox(height: 28),
                _sectionTitle('Low Stock Alert', Icons.warning_amber_outlined),
                const SizedBox(height: 14),
                ...state.stock.where((s) => s.quantity <= 2).map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.25), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppTheme.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${s.quantity} left', style: TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600)),
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
        Icon(icon, color: AppTheme.teal, size: 16),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }

  Widget _emptyBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: AppTheme.textMuted, size: 36),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _allTimeTile(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}

class _MiniIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final bars = [
      [0.16, 0.26, 0.38], [0.34, 0.44, 0.65], [0.52, 0.60, 1.0], [0.70, 0.50, 0.85],
    ];
    const bottom = 0.82; const bw = 0.13;
    final p = Paint()..style = PaintingStyle.fill;
    for (final b in bars) {
      p.color = const Color(0xFF1D9E75).withOpacity(b[2]);
      final bh = h * b[1];
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*b[0], h*bottom-bh, w*bw, bh), Radius.circular(w*0.04)), p);
    }
    final lp = Paint()..color = const Color(0xFF5DCAA5)..strokeWidth = w*0.05..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final pts = bars.map((b) => Offset(w*b[0]+w*bw/2, h*bottom-h*b[1])).toList();
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
    canvas.drawPath(path, lp);
  }
  @override bool shouldRepaint(_) => false;
}