import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _auth      = AuthService();
  bool _loading    = false;
  bool _sent       = false;
  String? _error;

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) { setState(() => _error = 'Please enter your email.'); return; }
    setState(() { _loading = true; _error = null; });
    final err = await _auth.sendPasswordReset(email);
    if (mounted) setState(() { _loading = false; _error = err; _sent = err == null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reset password', style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text('Enter your email and we\'ll send a reset link', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 36),

              if (_sent) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.teal.withOpacity(0.3), width: 0.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.teal, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Reset link sent to ${_emailCtrl.text}', style: const TextStyle(color: AppTheme.teal, fontSize: 13))),
                  ]),
                ),
              ] else ...[
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.danger.withOpacity(0.3), width: 0.5)),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                  ),
                  const SizedBox(height: 20),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _send,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Send Reset Link'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }
}