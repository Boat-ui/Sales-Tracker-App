import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _savingsPct;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().settings;
    _savingsPct = s.personalSavingsPercent;
    _currency = s.currency;
  }

  @override
  Widget build(BuildContext context) {
    final double usePct = 100 - _savingsPct;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FF),
      appBar: AppBar(
        title:
            const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionHeader('Currency'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: ['₦', 'GH₵', '\$', '€', '£']
                .map((c) => ChoiceChip(
                      label: Text(c,
                          style: TextStyle(
                              color: _currency == c
                                  ? Colors.white
                                  : const Color(0xFF4A148C),
                              fontWeight: FontWeight.bold)),
                      selected: _currency == c,
                      selectedColor: const Color(0xFF4A148C),
                      onSelected: (_) => setState(() => _currency = c),
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),
          _sectionHeader('Profit Split'),
          const SizedBox(height: 4),
          const Text(
            'Your profit is already split 50% Business / 50% Personal.\nBelow, set how to split your personal share:',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _splitVisual(_savingsPct, usePct),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Savings: ${_savingsPct.toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
              Text('Personal Use: ${usePct.toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
            ],
          ),
          Slider(
            value: _savingsPct,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: const Color(0xFF00695C),
            inactiveColor: const Color(0xFFC62828),
            onChanged: (v) => setState(() => _savingsPct = v),
          ),
          const SizedBox(height: 28),
          _sectionHeader('How the splits work'),
          const SizedBox(height: 12),
          _explainCard(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A148C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<AppState>().updateSettings(AppSettings(
                      personalSavingsPercent: _savingsPct,
                      personalUsePercent: usePct,
                      currency: _currency,
                    ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Settings saved ✅'),
                      backgroundColor: Color(0xFF2E7D32)),
                );
              },
              child: const Text('Save Settings',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A148C)));
  }

  Widget _splitVisual(double savPct, double usePct) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Expanded(
            flex: savPct.toInt(),
            child: Container(
              height: 40,
              color: const Color(0xFF00695C),
              child: Center(
                child: Text(
                  'Savings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: savPct < 20 ? 9 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: usePct.toInt(),
            child: Container(
              height: 40,
              color: const Color(0xFFC62828),
              child: Center(
                child: Text(
                  'Personal Use',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: usePct < 20 ? 9 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _explainCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A148C).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4A148C).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _step('1', 'Selling Price − Cost Price = Profit',
              const Color(0xFF2E7D32)),
          const Divider(height: 20),
          _step('2', '50% of Profit → Business (for restocking etc.)',
              const Color(0xFF6A1B9A)),
          _step('3', '50% of Profit → Personal', const Color(0xFFE65100)),
          const Divider(height: 20),
          _step('4', 'Personal × Savings % → Your savings 🏦',
              const Color(0xFF00695C)),
          _step('5', 'Personal × Use % → Spend freely 🛍️',
              const Color(0xFFC62828)),
        ],
      ),
    );
  }

  Widget _step(String num, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(num,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: color.withOpacity(0.9), fontSize: 13))),
        ],
      ),
    );
  }
}
