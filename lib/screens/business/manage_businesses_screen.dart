import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import 'create_business_screen.dart';

class ManageBusinessesScreen extends StatelessWidget {
  const ManageBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('My Businesses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBusinessScreen())),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('New Business', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Tap a business to switch to it.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          ...state.businesses.map((biz) {
            final isActive = biz.id == state.activeBizId;
            return GestureDetector(
              onTap: () async {
                if (!isActive) {
                  await state.switchBusiness(biz);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.teal.withOpacity(0.08) : AppTheme.navyCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppTheme.teal : const Color(0xFF0040DD),
                    width: isActive ? 1.5 : 0.5,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.teal.withOpacity(0.15) : AppTheme.navyLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(biz.type.emoji, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(biz.name, style: TextStyle(color: isActive ? AppTheme.teal : AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15))),
                      if (isActive) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Active', style: TextStyle(color: AppTheme.teal, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Text(biz.type.label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ])),
                  if (!isActive)
                    PopupMenuButton<String>(
                      color: AppTheme.navyCard,
                      icon: const Icon(Icons.more_vert, color: AppTheme.textMuted, size: 20),
                      onSelected: (val) async {
                        if (val == 'rename') _showRenameDialog(context, state, biz);
                        if (val == 'delete') _confirmDelete(context, state, biz);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'rename', child: Text('Rename', style: TextStyle(color: AppTheme.textPrimary))),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.danger))),
                      ],
                    ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, AppState state, Business biz) {
    final ctrl = TextEditingController(text: biz.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Business'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Business name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              state.updateBusiness(biz.copyWith(name: name));
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.teal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Business biz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Business?'),
        content: Text('All data for "${biz.name}" will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              state.deleteBusiness(biz.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}