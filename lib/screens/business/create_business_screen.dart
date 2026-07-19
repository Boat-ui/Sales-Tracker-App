import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class CreateBusinessScreen extends StatefulWidget {
  const CreateBusinessScreen({super.key});
  @override State<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<CreateBusinessScreen> {
  final _nameCtrl = TextEditingController();
  BusinessType _type = BusinessType.retail;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('New Business')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Business Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'e.g. Mama Akosua Stores', prefixIcon: Icon(Icons.business_outlined)),
          ),

          const SizedBox(height: 28),
          const Text('Business Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),

          ...BusinessType.values.map((type) {
            final sel = _type == type;
            return GestureDetector(
              onTap: () => setState(() => _type = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.teal.withOpacity(0.08) : AppTheme.navyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? AppTheme.teal : const Color(0xFF0040DD), width: sel ? 1.5 : 0.5),
                ),
                child: Row(children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(type.label, style: TextStyle(color: sel ? AppTheme.teal : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(type.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                  ])),
                  if (sel) const Icon(Icons.check_circle, color: AppTheme.teal, size: 20),
                ]),
              ),
            );
          }),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Business'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a business name.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().createBusiness(name: name, type: _type);
      if (mounted) {
        Navigator.pop(context); // pop create screen
        Navigator.pop(context); // pop manage screen back to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name created and activated')),
        );
      }
    } catch (e) {
      setState(() { _loading = false; _error = 'Failed to create business. Try again.'; });
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }
}