import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_item.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stock = state.stock;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('My Stock'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showItemDialog(context, state),
              icon: const Icon(Icons.add, color: AppTheme.teal, size: 18),
              label: const Text('Add', style: TextStyle(color: AppTheme.teal, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: stock.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
                    child: const Icon(Icons.inventory_2_outlined, size: 32, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text('No stock yet', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Tap Add to add your first item', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: stock.length,
              itemBuilder: (ctx, i) {
                final item = stock[i];
                final fmt = NumberFormat('#,##0.00');
                final low = item.quantity <= 2;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.navyCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: low ? AppTheme.warning.withOpacity(0.3) : const Color(0xFF1D3A4F),
                      width: 0.5,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: low ? AppTheme.warning.withOpacity(0.12) : AppTheme.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.checkroom_outlined, color: low ? AppTheme.warning : AppTheme.teal, size: 20),
                    ),
                    title: Text(item.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Cost: ${state.settings.currency}${fmt.format(item.costPrice)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        if (item.category != null)
                          Text(item.category!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${item.quantity} pcs', style: TextStyle(color: low ? AppTheme.warning : AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                        if (low)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Low', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    onTap: () => _showItemDialog(context, state, item: item),
                    onLongPress: () => _confirmDelete(context, state, item),
                  ),
                );
              },
            ),
    );
  }

  void _showItemDialog(BuildContext context, AppState state, {StockItem? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final costCtrl = TextEditingController(text: item?.costPrice.toString() ?? '');
    final qtyCtrl  = TextEditingController(text: item?.quantity.toString() ?? '');
    final catCtrl  = TextEditingController(text: item?.category ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.teal, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(isEdit ? 'Edit Item' : 'Add Stock Item', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ]),
            const SizedBox(height: 20),
            _field(nameCtrl, 'Item name', Icons.checkroom_outlined),
            const SizedBox(height: 12),
            _field(costCtrl, 'Cost price', Icons.attach_money, isNum: true),
            const SizedBox(height: 12),
            _field(qtyCtrl, 'Quantity in stock', Icons.inventory_2_outlined, isNum: true, isInt: true),
            const SizedBox(height: 12),
            _field(catCtrl, 'Category (optional)', Icons.label_outline),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final cost = double.tryParse(costCtrl.text) ?? 0;
                  final qty  = int.tryParse(qtyCtrl.text) ?? 0;
                  if (name.isEmpty || cost <= 0 || qty < 0) return;
                  if (isEdit) {
                    item!.name = name; item.costPrice = cost; item.quantity = qty;
                    item.category = catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim();
                    state.updateStockItem(item);
                  } else {
                    state.addStockItem(StockItem(id: const Uuid().v4(), name: name, costPrice: cost, quantity: qty, category: catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim()));
                  }
                  Navigator.pop(ctx);
                },
                child: Text(isEdit ? 'Save Changes' : 'Add to Stock'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool isNum = false, bool isInt = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? (isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true)) : TextInputType.text,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, StockItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from stock?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () { state.deleteStockItem(item.id); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
  }
}