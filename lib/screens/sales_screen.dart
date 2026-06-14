import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/sale.dart';
import '../models/stock_item.dart';
import '../services/app_state.dart';
import '../widgets/summary_card.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final daySales = state.salesForDate(_selectedDate);
    final summary = state.summaryForSales(daySales);
    final fmt = NumberFormat('#,##0.00');
    final currency = state.settings.currency;
    String f(double v) => '$currency${fmt.format(v)}';
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FF),
      appBar: AppBar(
        title: const Text('Sales', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ],
      ),
      floatingActionButton: isToday
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF4A148C),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Record Sale'),
              onPressed: () => _showSaleDialog(context, state),
            )
          : null,
      body: Column(
        children: [
          // Date header
          Container(
            color: const Color(0xFF4A148C),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white70),
                  onPressed: () => setState(() => _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1))),
                ),
                Expanded(
                  child: Text(
                    isToday
                        ? "Today"
                        : DateFormat('EEE, MMM d yyyy').format(_selectedDate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right,
                      color: isToday ? Colors.white24 : Colors.white70),
                  onPressed: isToday
                      ? null
                      : () => setState(() =>
                          _selectedDate = _selectedDate.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),

          Expanded(
            child: daySales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          isToday
                              ? 'No sales today yet.\nTap + to record a sale.'
                              : 'No sales on this day.',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Summary cards
                      Row(
                        children: [
                          Expanded(
                              child: SummaryCard(
                            label: 'Revenue',
                            amount: f(summary['revenue']!),
                            color: const Color(0xFF1565C0),
                            icon: Icons.attach_money,
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              child: SummaryCard(
                            label: 'Profit',
                            amount: f(summary['profit']!),
                            color: const Color(0xFF2E7D32),
                            icon: Icons.trending_up,
                          )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: SummaryCard(
                            label: 'Business 💼',
                            amount: f(summary['business']!),
                            color: const Color(0xFF6A1B9A),
                            icon: Icons.business_center,
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              child: SummaryCard(
                            label: 'Savings 🏦',
                            amount: f(summary['savings']!),
                            color: const Color(0xFF00695C),
                            icon: Icons.savings,
                          )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SummaryCard(
                        label: 'Personal Use 🛍️',
                        amount: f(summary['personalUse']!),
                        color: const Color(0xFFC62828),
                        icon: Icons.shopping_bag,
                      ),
                      const SizedBox(height: 20),
                      const Text('Sales List',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF4A148C))),
                      const SizedBox(height: 10),
                      ...daySales.map((sale) => _saleTile(context, state, sale, fmt, currency)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _saleTile(BuildContext context, AppState state, Sale sale,
      NumberFormat fmt, String currency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(sale.itemName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteSale(context, state, sale),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                )
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip('Qty: ${sale.quantitySold}', Colors.grey),
                const SizedBox(width: 6),
                _chip(
                    'Sold @ $currency${fmt.format(sale.sellingPrice)}', Colors.blue),
                const SizedBox(width: 6),
                _chip(
                    'Cost: $currency${fmt.format(sale.costPrice)}', Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(
                    'Profit', '$currency${fmt.format(sale.totalProfit)}', Colors.green),
                _miniStat('Business',
                    '$currency${fmt.format(sale.businessShare)}', Colors.purple),
                _miniStat('Savings',
                    '$currency${fmt.format(sale.personalSavings)}', Colors.teal),
                _miniStat('Personal Use',
                    '$currency${fmt.format(sale.personalUse)}', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  void _showSaleDialog(BuildContext context, AppState state) {
    StockItem? selectedItem;
    final sellCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final fmt = NumberFormat('#,##0.00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
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
              const Text(
                'Record a Sale',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C)),
              ),
              const SizedBox(height: 16),

              // Item picker
              DropdownButtonFormField<StockItem>(
                decoration: InputDecoration(
                  labelText: 'Select Item',
                  prefixIcon: const Icon(Icons.checkroom,
                      color: Color(0xFF4A148C)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF4A148C)),
                  ),
                ),
                value: selectedItem,
                items: state.stock
                    .where((s) => s.quantity > 0)
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                              '${s.name} (${s.quantity} left) — ${state.settings.currency}${fmt.format(s.costPrice)} cost'),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => selectedItem = v),
              ),
              const SizedBox(height: 12),

              // Qty
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity Sold',
                  prefixIcon: const Icon(Icons.production_quantity_limits,
                      color: Color(0xFF4A148C)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF4A148C)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Selling price
              TextField(
                controller: sellCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Selling Price (per item)',
                  prefixIcon: const Icon(Icons.sell, color: Color(0xFF4A148C)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF4A148C)),
                  ),
                ),
              ),

              // Live preview
              if (selectedItem != null && sellCtrl.text.isNotEmpty)
                Builder(builder: (_) {
                  final sell = double.tryParse(sellCtrl.text) ?? 0;
                  final qty = int.tryParse(qtyCtrl.text) ?? 1;
                  final profit = (sell - selectedItem!.costPrice) * qty;
                  return Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: profit >= 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _previewRow('Profit',
                            '${state.settings.currency}${fmt.format(profit)}',
                            profit >= 0 ? Colors.green : Colors.red),
                        _previewRow('Business (50%)',
                            '${state.settings.currency}${fmt.format(profit * 0.5)}',
                            Colors.purple),
                        _previewRow(
                            'Savings (${state.settings.personalSavingsPercent.toInt()}%)',
                            '${state.settings.currency}${fmt.format(profit * 0.5 * state.settings.personalSavingsPercent / 100)}',
                            Colors.teal),
                        _previewRow(
                            'Personal Use (${state.settings.personalUsePercent.toInt()}%)',
                            '${state.settings.currency}${fmt.format(profit * 0.5 * state.settings.personalUsePercent / 100)}',
                            Colors.red),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),
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
                    if (selectedItem == null) return;
                    final sell = double.tryParse(sellCtrl.text) ?? 0;
                    final qty = int.tryParse(qtyCtrl.text) ?? 1;
                    if (sell <= 0 || qty <= 0) return;
                    if (qty > selectedItem!.quantity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Only ${selectedItem!.quantity} in stock!')),
                      );
                      return;
                    }
                    state.addSale(Sale(
                      id: const Uuid().v4(),
                      stockItemId: selectedItem!.id,
                      itemName: selectedItem!.name,
                      costPrice: selectedItem!.costPrice,
                      sellingPrice: sell,
                      quantitySold: qty,
                      personalSavingsPercent:
                          state.settings.personalSavingsPercent,
                      personalUsePercent: state.settings.personalUsePercent,
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sale recorded! ✅'),
                          backgroundColor: Color(0xFF2E7D32)),
                    );
                  },
                  child: const Text('Save Sale'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmDeleteSale(BuildContext context, AppState state, Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sale?'),
        content: Text('Remove this sale of "${sale.itemName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              state.deleteSale(sale.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
