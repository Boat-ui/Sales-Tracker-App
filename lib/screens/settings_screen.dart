import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../screens/auth/pin_screen.dart';
import '../screens/settings/currency_screen.dart';
import '../screens/settings/split_screen.dart';
import '../screens/settings/security_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName ?? '').isNotEmpty
        ? user!.displayName!
        : user?.email?.split('@').first ?? 'Business Owner';

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Account card ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.navyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'B',
                    style: const TextStyle(color: AppTheme.teal, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              )),
            ]),
          ),

          const SizedBox(height: 28),
          _sectionLabel('Business'),
          const SizedBox(height: 12),

          _menuTile(
            context,
            icon: Icons.currency_exchange_outlined,
            label: 'Currency',
            subtitle: 'Set your preferred currency symbol',
            color: AppTheme.revenue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencyScreen())),
          ),
          const SizedBox(height: 10),
          _menuTile(
            context,
            icon: Icons.pie_chart_outline,
            label: 'Profit Split',
            subtitle: 'Configure how profit is divided',
            color: AppTheme.biz,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SplitScreen())),
          ),
          const SizedBox(height: 10),
          _menuTile(
            context,
            icon: Icons.description_outlined,
            label: 'Reports',
            subtitle: 'Export sales reports as PDF',
            color: AppTheme.revenue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),

          const SizedBox(height: 28),
          _sectionLabel('Security'),
          const SizedBox(height: 12),

          _menuTile(
            context,
            icon: Icons.security_outlined,
            label: 'Security',
            subtitle: 'Change PIN or sign out',
            color: AppTheme.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
          ),

          const SizedBox(height: 28),
          _sectionLabel('App'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.navyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
            ),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.textMuted.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 18)),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BizSplit', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Version 1.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ])),
            ]),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) => Text(title,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5));

  Widget _menuTile(BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
        ),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
        ]),
      ),
    );
  }
}