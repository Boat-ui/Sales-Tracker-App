import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_state.dart';
import '../widgets/summary_card.dart';
import '../theme/app_theme.dart';
import '../models/sale.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
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
            ),

            const SizedBox(height: 16),

            // ── Tabs ─────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.navyCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppTheme.tealBorder, width: 0.5),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.teal,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Analytics'),
                ],
              ),
            ),

            const SizedBox(height: 4),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _OverviewTab(
                    todaySales: todaySales,
                    todaySummary: todaySummary,
                    allSummary: allSummary,
                    state: state,
                    f: f,
                  ),
                  _AnalyticsTab(state: state, currency: currency),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview Tab ─────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final List<Sale> todaySales;
  final Map<String, double> todaySummary;
  final Map<String, double> allSummary;
  final AppState state;
  final String Function(double) f;

  const _OverviewTab({
    required this.todaySales,
    required this.todaySummary,
    required this.allSummary,
    required this.state,
    required this.f,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Today's Summary", Icons.today_outlined),
          const SizedBox(height: 14),
          if (todaySales.isEmpty)
            _emptyBox("No sales recorded today yet")
          else
            Column(children: [
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
                decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cost of goods sold', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text(f(todaySummary['cost']!), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ]),

          const SizedBox(height: 28),
          _sectionTitle('All-Time Totals', Icons.bar_chart_outlined),
          const SizedBox(height: 14),
          _allTimeTile('Total Revenue', f(allSummary['revenue']!), AppTheme.revenue),
          _allTimeTile('Total Profit', f(allSummary['profit']!), AppTheme.profit),
          _allTimeTile('Business Saved', f(allSummary['business']!), AppTheme.biz),
          _allTimeTile('Total Savings', f(allSummary['savings']!), AppTheme.savings),

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
              child: Row(children: [
                const Icon(Icons.inventory_2_outlined, color: AppTheme.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(s.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('${s.quantity} left', style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
            )),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
    Icon(icon, color: AppTheme.teal, size: 16),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
  ]);

  Widget _emptyBox(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
    child: Column(children: [
      const Icon(Icons.receipt_long_outlined, color: AppTheme.textMuted, size: 36),
      const SizedBox(height: 10),
      Text(msg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
    ]),
  );

  Widget _allTimeTile(String label, String value, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
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

// ── Analytics Tab ─────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final AppState state;
  final String currency;

  const _AnalyticsTab({required this.state, required this.currency});

  List<FlSpot> _revenueSpots(List<Sale> sales) {
    final now = DateTime.now();
    final Map<int, double> byDay = {for (int i = 0; i < 30; i++) i: 0};
    for (final s in sales) {
      final diff = now.difference(s.date).inDays;
      if (diff >= 0 && diff < 30) byDay[29 - diff] = (byDay[29 - diff] ?? 0) + s.totalRevenue;
    }
    return byDay.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<FlSpot> _profitSpots(List<Sale> sales) {
    final now = DateTime.now();
    final Map<int, double> byDay = {for (int i = 0; i < 30; i++) i: 0};
    for (final s in sales) {
      final diff = now.difference(s.date).inDays;
      if (diff >= 0 && diff < 30) byDay[29 - diff] = (byDay[29 - diff] ?? 0) + s.totalProfit;
    }
    return byDay.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<MapEntry<String, double>> _topItems(List<Sale> sales) {
    final Map<String, double> totals = {};
    for (final s in sales) totals[s.itemName] = (totals[s.itemName] ?? 0) + s.totalRevenue;
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sales = state.sales;
    final fmt = NumberFormat('#,##0');
    final revenueSpots = _revenueSpots(sales);
    final profitSpots  = _profitSpots(sales);
    final topItems     = _topItems(sales);
    final maxY = revenueSpots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final hasData = sales.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Revenue & Profit Chart ──────────────────────
          _chartCard(
            title: 'Revenue & Profit — Last 30 Days',
            icon: Icons.show_chart,
            child: hasData
                ? SizedBox(
                    height: 200,
                    child: LineChart(LineChartData(
                      minY: 0,
                      maxY: maxY * 1.2 == 0 ? 100 : maxY * 1.2,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY == 0 ? 20 : maxY / 4,
                        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFF1D3A4F), strokeWidth: 0.5),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (v, _) => Text('$currency${fmt.format(v)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                        )),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          interval: 7,
                          getTitlesWidget: (v, _) {
                            final daysAgo = 29 - v.toInt();
                            if (daysAgo == 0) return const Text('Today', style: TextStyle(color: AppTheme.textMuted, fontSize: 9));
                            if (daysAgo % 7 == 0) return Text('${daysAgo}d', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9));
                            return const SizedBox();
                          },
                        )),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueSpots,
                          isCurved: true,
                          color: AppTheme.revenue,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppTheme.revenue.withOpacity(0.06)),
                        ),
                        LineChartBarData(
                          spots: profitSpots,
                          isCurved: true,
                          color: AppTheme.profit,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppTheme.profit.withOpacity(0.06)),
                        ),
                      ],
                    )),
                  )
                : _noDataBox('Record sales to see your revenue trend'),
          ),

          if (hasData) ...[
            const SizedBox(height: 10),
            Row(children: [
              _legend('Revenue', AppTheme.revenue),
              const SizedBox(width: 20),
              _legend('Profit', AppTheme.profit),
            ]),
          ],

          const SizedBox(height: 24),

          // ── Profit Split Donut ──────────────────────────
          _chartCard(
            title: 'Profit Split Breakdown',
            icon: Icons.pie_chart_outline,
            child: hasData
                ? SizedBox(
                    height: 200,
                    child: Row(children: [
                      Expanded(
                        child: PieChart(PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 48,
                          sections: [
                            PieChartSectionData(value: 50, color: AppTheme.biz, title: '50%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            PieChartSectionData(value: state.settings.personalSavingsPercent / 2, color: AppTheme.savings, title: '${(state.settings.personalSavingsPercent / 2).toInt()}%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            PieChartSectionData(value: state.settings.personalUsePercent / 2, color: AppTheme.danger, title: '${(state.settings.personalUsePercent / 2).toInt()}%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        )),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _pieLegend('Business', AppTheme.biz),
                          const SizedBox(height: 10),
                          _pieLegend('Savings', AppTheme.savings),
                          const SizedBox(height: 10),
                          _pieLegend('Personal Use', AppTheme.danger),
                        ],
                      ),
                    ]),
                  )
                : _noDataBox('Record sales to see your profit split'),
          ),

          const SizedBox(height: 24),

          // ── Top 5 Items ─────────────────────────────────
          _chartCard(
            title: 'Top Selling Items',
            icon: Icons.emoji_events_outlined,
            child: topItems.isEmpty
                ? _noDataBox('Record sales to see your best sellers')
                : Column(
                    children: topItems.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      final maxVal = topItems.first.value;
                      final pct = maxVal == 0 ? 0.0 : item.value / maxVal;
                      final colors = [AppTheme.teal, AppTheme.revenue, AppTheme.biz, AppTheme.savings, AppTheme.warning];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Container(
                                    width: 20, height: 20,
                                    decoration: BoxDecoration(color: colors[i].withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Center(child: Text('${i + 1}', style: TextStyle(color: colors[i], fontSize: 10, fontWeight: FontWeight.w700))),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(item.key, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                ]),
                                Text('$currency${fmt.format(item.value)}', style: TextStyle(color: colors[i], fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 5,
                                backgroundColor: const Color(0xFF1D3A4F),
                                valueColor: AlwaysStoppedAnimation(colors[i]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 24),

          // ── This month vs last month ────────────────────
          Builder(builder: (_) {
            final now = DateTime.now();
            final thisMonth = sales.where((s) => s.date.year == now.year && s.date.month == now.month).toList();
            final lastMonthDate = DateTime(now.year, now.month - 1);
            final lastMonth = sales.where((s) => s.date.year == lastMonthDate.year && s.date.month == lastMonthDate.month).toList();
            final thisRevenue = thisMonth.fold(0.0, (a, s) => a + s.totalRevenue);
            final lastRevenue = lastMonth.fold(0.0, (a, s) => a + s.totalRevenue);
            final diff = lastRevenue == 0 ? 0.0 : ((thisRevenue - lastRevenue) / lastRevenue * 100);
            final isUp = diff >= 0;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.calendar_month_outlined, color: AppTheme.teal, size: 20)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This Month', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('$currency${fmt.format(thisRevenue)} revenue', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${thisMonth.length} sales', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                )),
                if (lastRevenue > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: isUp ? AppTheme.profit.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, color: isUp ? AppTheme.profit : AppTheme.danger, size: 12),
                      const SizedBox(width: 3),
                      Text('${diff.abs().toStringAsFixed(1)}%', style: TextStyle(color: isUp ? AppTheme.profit : AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _chartCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppTheme.teal, size: 15),
            const SizedBox(width: 7),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(children: [
    Container(width: 16, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
  ]);

  Widget _pieLegend(String label, Color color) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
  ]);

  Widget _noDataBox(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(children: [
      const Icon(Icons.bar_chart, color: AppTheme.textMuted, size: 32),
      const SizedBox(height: 8),
      Text(msg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), textAlign: TextAlign.center),
    ]),
  );
}

class _MiniIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final bars = [[0.16, 0.26, 0.38], [0.34, 0.44, 0.65], [0.52, 0.60, 1.0], [0.70, 0.50, 0.85]];
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