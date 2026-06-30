import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/settings.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});
  @override State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = context.read<AppState>().settings.currency;
  }

  @override
  Widget build(BuildContext context) {
    final currencies = [
      {'symbol': '₦', 'name': 'Nigerian Naira'},
      {'symbol': 'GH₵', 'name': 'Ghanaian Cedi'},
      {'symbol': '\$', 'name': 'US Dollar'},
      {'symbol': '€', 'name': 'Euro'},
      {'symbol': '£', 'name': 'British Pound'},
      {'symbol': 'KSh', 'name': 'Kenyan Shilling'},
      {'symbol': 'R', 'name': 'South African Rand'},
      {'symbol': 'CFA', 'name': 'West African CFA'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Currency')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Choose your preferred currency symbol. This applies to all amounts shown in the app.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          ...currencies.map((c) {
            final sel = _currency == c['symbol'];
            return GestureDetector(
              onTap: () => setState(() => _currency = c['symbol']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.teal.withOpacity(0.08) : AppTheme.navyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? AppTheme.teal : const Color(0xFF1D3A4F), width: sel ? 1.5 : 0.5),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.teal.withOpacity(0.15) : AppTheme.navyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(c['symbol']!, style: TextStyle(color: sel ? AppTheme.teal : AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c['symbol']!, style: TextStyle(color: sel ? AppTheme.teal : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(c['name']!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ])),
                  if (sel) const Icon(Icons.check_circle, color: AppTheme.teal, size: 20),
                ]),
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final s = context.read<AppState>().settings;
                context.read<AppState>().updateSettings(AppSettings(
                  businessPercent: s.businessPercent,
                  personalPercent: s.personalPercent,
                  personalSavingsPercent: s.personalSavingsPercent,
                  personalUsePercent: s.personalUsePercent,
                  currency: _currency,
                ));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Currency saved')));
                Navigator.pop(context);
              },
              child: const Text('Save Currency'),
            ),
          ),
        ],
      ),
    );
  }
}