import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_item.dart';
import '../services/app_state.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stock = state.stock;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FF),
      appBar: AppBar(
        title: const Text('My Stock',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        onPressed: () => _showItemDialog(context, state),
      ),
      body: stock.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No stock yet.\nTap + to add items.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: low
                          ? Colors.orange.shade100
                          : const Color(0xFF4A148C).withOpacity(0.1),
                      child: Icon(
                        Icons.checkroom,
                        color: low ? Colors.orange : const Color(0xFF4A148C),
                      ),
                    ),
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Cost: ${state.settings.currency}${fmt.format(item.costPrice)}'),
                        if (item.category != null)
                          Text('Category: ${item.category}',
                              style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.quantity} pcs',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: low ? Colors.orange : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        if (low)
                          const Text('Low!',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 11)),
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

  void _showItemDialog(BuildContext context, AppState state,
      {StockItem? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final costCtrl =
        TextEditingController(text: item?.costPrice.toString() ?? '');
    final qtyCtrl =
        TextEditingController(text: item?.quantity.toString() ?? '');
    final catCtrl = TextEditingController(text: item?.category ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Item' : 'Add Stock Item',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C)),
            ),
            const SizedBox(height: 16),
            _field(nameCtrl, 'Item Name (e.g. Ankara Blouse)', Icons.checkroom),
            const SizedBox(height: 12),
            _field(costCtrl, 'Cost Price (what you paid)', Icons.attach_money,
                isNum: true),
            const SizedBox(height: 12),
            _field(qtyCtrl, 'Quantity in stock', Icons.inventory,
                isNum: true, isInt: true),
            const SizedBox(height: 12),
            _field(catCtrl, 'Category (optional, e.g. Tops)', Icons.category),
            const SizedBox(height: 20),
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
                  final name = nameCtrl.text.trim();
                  final cost = double.tryParse(costCtrl.text) ?? 0;
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  if (name.isEmpty || cost <= 0 || qty < 0) return;

                  if (isEdit) {
                    item!.name = name;
                    item.costPrice = cost;
                    item.quantity = qty;
                    item.category =
                        catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim();
                    state.updateStockItem(item);
                  } else {
                    state.addStockItem(StockItem(
                      id: const Uuid().v4(),
                      name: name,
                      costPrice: cost,
                      quantity: qty,
                      category: catCtrl.text.trim().isEmpty
                          ? null
                          : catCtrl.text.trim(),
                    ));
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

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isNum = false,
    bool isInt = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum
          ? (isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true))
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4A148C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A148C)),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, StockItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Remove "${item.name}" from stock?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              state.deleteStockItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
