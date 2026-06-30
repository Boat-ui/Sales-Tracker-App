import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/pin_screen.dart';
import '../../theme/app_theme.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  Future<void> _changePin(BuildContext context) async {
    await PinScreen.clearPin();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          isSetup: true,
          onUnlocked: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated successfully')),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your data. Your PIN will be remembered for next time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().logout();
    // AuthGate (top-level StreamBuilder in main.dart) detects the sign-out
    // event automatically and swaps the entire screen to LoginScreen.
    // No manual navigation needed here.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _tile(
            icon: Icons.pin_outlined,
            label: 'Change PIN',
            subtitle: 'Set a new 4-digit PIN for this account',
            color: AppTheme.teal,
            onTap: () => _changePin(context),
          ),
          const SizedBox(height: 10),
          _tile(
            icon: Icons.logout,
            label: 'Sign Out',
            subtitle: 'Sign out and return to the login screen',
            color: AppTheme.danger,
            onTap: () => _signOut(context),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.teal.withOpacity(0.2), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppTheme.teal, size: 16),
              const SizedBox(width: 10),
              const Expanded(child: Text('Your PIN is saved per account. Signing into a different account will ask for that account\'s own PIN.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tile({required IconData icon, required String label, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2), width: 0.5)),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 18),
        ]),
      ),
    );
  }
}