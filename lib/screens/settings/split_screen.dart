import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/settings.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});
  @override State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  late double _bizPct;
  late double _savingsPct;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().settings;
    _bizPct     = s.businessPercent;
    _savingsPct = s.personalSavingsPercent;
  }

  double get _personalPct => 100 - _bizPct;
  double get _usePct => 100 - _savingsPct;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Profit Split')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Business vs Personal ───────────────────────
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _cardTitle('Business vs Personal', Icons.pie_chart_outline, AppTheme.biz),
            const SizedBox(height: 6),
            const Text('How your total profit is divided between your business fund and personal income.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5)),
            const SizedBox(height: 20),
            _splitBar(_bizPct.toInt(), _personalPct.toInt(), 'Business', 'Personal', AppTheme.biz, AppTheme.spend),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _pctBadge('Business', '${_bizPct.toInt()}%', AppTheme.biz),
              _pctBadge('Personal', '${_personalPct.toInt()}%', AppTheme.spend),
            ]),
            Slider(
              value: _bizPct,
              min: 0, max: 100, divisions: 20,
              activeColor: AppTheme.biz,
              inactiveColor: AppTheme.spend,
              onChanged: (v) => setState(() => _bizPct = v),
            ),
          ])),

          const SizedBox(height: 16),

          // ── Savings vs Spending ────────────────────────
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _cardTitle('Savings vs Spending', Icons.savings_outlined, AppTheme.savings),
            const SizedBox(height: 6),
            const Text('How your personal share is split between savings and free spending money.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5)),
            const SizedBox(height: 20),
            _splitBar(_savingsPct.toInt(), _usePct.toInt(), 'Savings', 'Spending', AppTheme.savings, AppTheme.spend),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _pctBadge('Savings', '${_savingsPct.toInt()}%', AppTheme.savings),
              _pctBadge('Spending', '${_usePct.toInt()}%', AppTheme.spend),
            ]),
            Slider(
              value: _savingsPct,
              min: 0, max: 100, divisions: 20,
              activeColor: AppTheme.savings,
              inactiveColor: AppTheme.spend,
              onChanged: (v) => setState(() => _savingsPct = v),
            ),
          ])),

          const SizedBox(height: 16),

          // ── Live preview ───────────────────────────────
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _cardTitle('How it works', Icons.info_outline, AppTheme.teal),
            const SizedBox(height: 16),
            _step('Selling price − Cost price', 'Profit', AppTheme.profit),
            _divider(),
            _step('${_bizPct.toInt()}% of Profit', 'Business fund', AppTheme.biz),
            _step('${_personalPct.toInt()}% of Profit', 'Personal share', AppTheme.spend),
            _divider(),
            _step('Personal × ${_savingsPct.toInt()}%', 'Your savings', AppTheme.savings),
            _step('Personal × ${_usePct.toInt()}%', 'Free to spend', AppTheme.danger),
          ])),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final s = context.read<AppState>().settings;
                context.read<AppState>().updateSettings(AppSettings(
                  businessPercent: _bizPct,
                  personalPercent: _personalPct,
                  personalSavingsPercent: _savingsPct,
                  personalUsePercent: _usePct,
                  currency: s.currency,
                ));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Split saved')));
                Navigator.pop(context);
              },
              child: const Text('Save Split'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
    child: child,
  );

  Widget _cardTitle(String title, IconData icon, Color color) => Row(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
  ]);

  Widget _splitBar(int left, int right, String leftLabel, String rightLabel, Color lc, Color rc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Row(children: [
        Expanded(flex: left.clamp(1, 99), child: Container(height: 44, color: lc, child: Center(child: Text(leftLabel, style: TextStyle(color: AppTheme.navy, fontSize: left < 20 ? 9 : 13, fontWeight: FontWeight.w700))))),
        Expanded(flex: right.clamp(1, 99), child: Container(height: 44, color: rc, child: Center(child: Text(rightLabel, style: TextStyle(color: AppTheme.navy, fontSize: right < 20 ? 9 : 13, fontWeight: FontWeight.w700))))),
      ]),
    );
  }

  Widget _pctBadge(String label, String pct, Color color) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text('$label ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    Text(pct, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
  ]);

  Widget _divider() => const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1));

  Widget _step(String from, String to, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Expanded(child: Text(from, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
      const Icon(Icons.arrow_forward, color: AppTheme.textMuted, size: 14),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(to, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}