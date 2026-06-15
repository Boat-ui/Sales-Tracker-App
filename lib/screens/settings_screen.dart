import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _savingsPct;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().settings;
    _savingsPct = s.personalSavingsPercent;
    _currency   = s.currency;
  }

  @override
  Widget build(BuildContext context) {
    final usePct = 100 - _savingsPct;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionLabel('Currency'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['₦', 'GH₵', '\$', '€', '£'].map((c) {
              final sel = _currency == c;
              return GestureDetector(
                onTap: () => setState(() => _currency = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52, height: 48,
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.teal.withOpacity(0.15) : AppTheme.navyCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppTheme.teal : const Color(0xFF1D3A4F), width: sel ? 1.5 : 0.5),
                  ),
                  child: Center(
                    child: Text(c, style: TextStyle(color: sel ? AppTheme.teal : AppTheme.textSecondary, fontSize: 18, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),
          _sectionLabel('Profit Split'),
          const SizedBox(height: 6),
          const Text('Drag to set how your personal 50% is split between savings and spending.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),

          // Split bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: _savingsPct.toInt().clamp(1, 99),
                  child: Container(
                    height: 44,
                    color: AppTheme.savings,
                    child: Center(child: Text('Savings', style: TextStyle(color: AppTheme.navy, fontSize: _savingsPct < 20 ? 9 : 13, fontWeight: FontWeight.w700))),
                  ),
                ),
                Expanded(
                  flex: usePct.toInt().clamp(1, 99),
                  child: Container(
                    height: 44,
                    color: AppTheme.spend,
                    child: Center(child: Text('Spending', style: TextStyle(color: AppTheme.navy, fontSize: usePct < 20 ? 9 : 13, fontWeight: FontWeight.w700))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pctBadge('Savings', '${_savingsPct.toInt()}%', AppTheme.savings),
              _pctBadge('Spending', '${usePct.toInt()}%', AppTheme.spend),
            ],
          ),
          Slider(
            value: _savingsPct,
            min: 0, max: 100, divisions: 20,
            onChanged: (v) => setState(() => _savingsPct = v),
          ),

          const SizedBox(height: 28),
          _sectionLabel('How splits work'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.navyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
            ),
            child: Column(
              children: [
                _step('Selling price − Cost price', 'Profit', AppTheme.profit),
                _divider(),
                _step('50% of Profit', 'Business fund', AppTheme.biz),
                _step('50% of Profit', 'Personal share', AppTheme.spend),
                _divider(),
                _step('Personal × ${_savingsPct.toInt()}%', 'Your savings', AppTheme.savings),
                _step('Personal × ${usePct.toInt()}%', 'Free to spend', AppTheme.danger),
              ],
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<AppState>().updateSettings(AppSettings(
                  personalSavingsPercent: _savingsPct,
                  personalUsePercent: usePct,
                  currency: _currency,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved')),
                );
              },
              child: const Text('Save Settings'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600));
  }

  Widget _pctBadge(String label, String pct, Color color) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      Text(pct, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1),
  );

  Widget _step(String from, String to, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(from, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          const Icon(Icons.arrow_forward, color: AppTheme.textMuted, size: 14),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(to, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}