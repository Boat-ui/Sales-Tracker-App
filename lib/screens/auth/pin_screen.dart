import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

class PinScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final bool isSetup;

  const PinScreen({super.key, required this.onUnlocked, this.isSetup = false});

  // PIN key is per user account using their UID
  static String _pinKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'bizsplit_pin_$uid';
  }

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey());
  }

  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey());
  }

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  String? _error;

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() { _pin += digit; _error = null; });
    if (_pin.length == 4) _handleComplete();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _handleComplete() async {
    await Future.delayed(const Duration(milliseconds: 150));

    if (widget.isSetup) {
      if (!_confirming) {
        setState(() { _confirmPin = _pin; _pin = ''; _confirming = true; });
      } else {
        if (_pin == _confirmPin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(PinScreen._pinKey(), _pin);
          if (mounted) widget.onUnlocked();
        } else {
          setState(() { _pin = ''; _confirmPin = ''; _confirming = false; _error = 'PINs did not match. Try again.'; });
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(PinScreen._pinKey());
      if (_pin == saved) {
        if (mounted) widget.onUnlocked();
      } else {
        setState(() { _pin = ''; _error = 'Incorrect PIN. Try again.'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSetup
        ? (_confirming ? 'Confirm your PIN' : 'Set a PIN')
        : 'Enter PIN';
    final subtitle = widget.isSetup
        ? (_confirming ? 'Enter your PIN again to confirm' : 'Choose a 4-digit PIN to secure the app')
        : 'Enter your 4-digit PIN to continue';

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTheme.navyCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
              ),
              child: const Icon(Icons.lock_outline, color: AppTheme.teal, size: 28),
            ),
            const SizedBox(height: 24),

            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? AppTheme.teal : AppTheme.navyCard,
                  border: Border.all(
                    color: i < _pin.length ? AppTheme.teal : const Color(0xFF1D3A4F),
                    width: 1.5,
                  ),
                ),
              )),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
            ],

            const SizedBox(height: 48),

            ...[
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫'],
            ].map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) => GestureDetector(
                  onTap: () {
                    if (key == '⌫') _onDelete();
                    else if (key.isNotEmpty) _onKey(key);
                  },
                  child: Container(
                    width: 72, height: 72,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: key.isEmpty ? Colors.transparent : AppTheme.navyCard,
                      shape: BoxShape.circle,
                      border: key.isEmpty ? null : Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
                    ),
                    child: Center(
                      child: key == '⌫'
                          ? const Icon(Icons.backspace_outlined, color: AppTheme.textSecondary, size: 22)
                          : Text(key, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w500)),
                    ),
                  ),
                )).toList(),
              ),
            )),
          ],
        ),
      ),
    );
  }
}