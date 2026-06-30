import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/sale.dart';
import '../models/stock_item.dart';
import '../services/app_state.dart';
import '../widgets/summary_card.dart';
import '../theme/app_theme.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final daySales = state.salesForDate(_selectedDate);
    final summary  = state.summaryForSales(daySales);
    final fmt = NumberFormat('#,##0.00');
    final currency = state.settings.currency;
    String f(double v) => '$currency${fmt.format(v)}';
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: AppTheme.teal),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(primary: AppTheme.teal, surface: AppTheme.navyCard),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ],
      ),
      floatingActionButton: isToday
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Record Sale', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () => _showSaleDialog(context, state),
            )
          : null,
      body: Column(
        children: [
          // Date navigator
          Container(
            color: AppTheme.navyLight,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                  onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                ),
                Expanded(
                  child: Text(
                    isToday ? 'Today' : DateFormat('EEE, MMM d yyyy').format(_selectedDate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: isToday ? AppTheme.textMuted : AppTheme.textSecondary),
                  onPressed: isToday ? null : () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
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
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
                          child: const Icon(Icons.shopping_cart_outlined, size: 32, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Text(isToday ? 'No sales today yet' : 'No sales on this day', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        if (isToday) const Text('Tap Record Sale to add one', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      Row(children: [
                        Expanded(child: SummaryCard(label: 'Revenue', amount: f(summary['revenue']!), color: AppTheme.revenue, icon: Icons.attach_money)),
                        const SizedBox(width: 10),
                        Expanded(child: SummaryCard(label: 'Profit', amount: f(summary['profit']!), color: AppTheme.profit, icon: Icons.trending_up)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: SummaryCard(label: 'Business', amount: f(summary['business']!), color: AppTheme.biz, icon: Icons.business_center_outlined)),
                        const SizedBox(width: 10),
                        Expanded(child: SummaryCard(label: 'Savings', amount: f(summary['savings']!), color: AppTheme.savings, icon: Icons.savings_outlined)),
                      ]),
                      const SizedBox(height: 10),
                      SummaryCard(label: 'Personal Use', amount: f(summary['personalUse']!), color: AppTheme.danger, icon: Icons.shopping_bag_outlined),
                      const SizedBox(height: 20),
                      const Text('Sales List', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 12),
                      ...daySales.map((sale) => _saleTile(context, state, sale, fmt, currency)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _saleTile(BuildContext context, AppState state, Sale sale, NumberFormat fmt, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(sale.itemName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
              GestureDetector(
                onTap: () => _confirmDeleteSale(context, state, sale),
                child: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              _chip('Qty: ${sale.quantitySold}', AppTheme.textSecondary),
              _chip('Sold @ $currency${fmt.format(sale.sellingPrice)}', AppTheme.revenue),
              _chip('Cost: $currency${fmt.format(sale.costPrice)}', AppTheme.warning),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('Profit', '$currency${fmt.format(sale.totalProfit)}', AppTheme.profit),
              _miniStat('Business', '$currency${fmt.format(sale.businessShare)}', AppTheme.biz),
              _miniStat('Savings', '$currency${fmt.format(sale.personalSavings)}', AppTheme.savings),
              _miniStat('Personal', '$currency${fmt.format(sale.personalUse)}', AppTheme.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }

  void _showSaleDialog(BuildContext context, AppState state) {
    StockItem? selectedItem;
    final sellCtrl = TextEditingController();
    final qtyCtrl  = TextEditingController(text: '1');
    final fmt = NumberFormat('#,##0.00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.teal, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                const Text('Record a Sale', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 20),
              DropdownButtonFormField<StockItem>(
                dropdownColor: AppTheme.navyCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Select item', prefixIcon: Icon(Icons.checkroom_outlined)),
                value: selectedItem,
                items: state.stock.where((s) => s.quantity > 0).map((s) => DropdownMenuItem(
                  value: s,
                  child: Text('${s.name} (${s.quantity} left)', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                )).toList(),
                onChanged: (v) => setLocal(() => selectedItem = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Quantity sold', prefixIcon: Icon(Icons.production_quantity_limits_outlined)),
                onChanged: (_) => setLocal(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sellCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Selling price per item', prefixIcon: Icon(Icons.sell_outlined)),
                onChanged: (_) => setLocal(() {}),
              ),

              if (selectedItem != null && sellCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 14),
                Builder(builder: (_) {
                  final sell   = double.tryParse(sellCtrl.text) ?? 0;
                  final qty    = int.tryParse(qtyCtrl.text) ?? 1;
                  final profit = (sell - selectedItem!.costPrice) * qty;
                  final isPos  = profit >= 0;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isPos ? AppTheme.profit.withOpacity(0.07) : AppTheme.danger.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isPos ? AppTheme.profit.withOpacity(0.2) : AppTheme.danger.withOpacity(0.2), width: 0.5),
                    ),
                    child: Column(children: [
                      _previewRow('Profit', '${state.settings.currency}${fmt.format(profit)}', isPos ? AppTheme.profit : AppTheme.danger),
                      _previewRow('Business (${state.settings.businessPercent.toInt()}%)', '${state.settings.currency}${fmt.format(profit * state.settings.businessPercent / 100)}', AppTheme.biz),
                      _previewRow('Savings (${state.settings.personalSavingsPercent.toInt()}%)', '${state.settings.currency}${fmt.format(profit * state.settings.personalPercent / 100 * state.settings.personalSavingsPercent / 100)}', AppTheme.savings),
                      _previewRow('Personal Use (${state.settings.personalUsePercent.toInt()}%)', '${state.settings.currency}${fmt.format(profit * state.settings.personalPercent / 100 * state.settings.personalUsePercent / 100)}', AppTheme.danger),
                    ]),
                  );
                }),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedItem == null) return;
                    final sell = double.tryParse(sellCtrl.text) ?? 0;
                    final qty  = int.tryParse(qtyCtrl.text) ?? 1;
                    if (sell <= 0 || qty <= 0) return;
                    if (qty > selectedItem!.quantity) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Only ${selectedItem!.quantity} in stock!')));
                      return;
                    }
                    state.addSale(Sale(
                      id: const Uuid().v4(),
                      stockItemId: selectedItem!.id,
                      itemName: selectedItem!.name,
                      costPrice: selectedItem!.costPrice,
                      sellingPrice: sell,
                      quantitySold: qty,
                      personalSavingsPercent: state.settings.personalSavingsPercent,
                      personalUsePercent: state.settings.personalUsePercent,
                      businessPercent: state.settings.businessPercent,
                      personalPercent: state.settings.personalPercent,
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sale recorded ✓')),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  void _confirmDeleteSale(BuildContext context, AppState state, Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete sale?'),
        content: Text('Remove this sale of "${sale.itemName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () { state.deleteSale(sale.id); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
  }
}