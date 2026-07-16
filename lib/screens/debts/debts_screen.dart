import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/debt.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import 'debt_detail_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override State<DebtsScreen> createState() => _DebtsScreenState();
}

enum _Filter { all, unpaid, partial, paid }

class _DebtsScreenState extends State<DebtsScreen> {
  _Filter _filter = _Filter.unpaid;

  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final fmt    = NumberFormat('#,##0.00');
    final currency = state.settings.currency;
    String f(double v) => '$currency${fmt.format(v)}';

    final allDebts = state.debts;
    final filtered = allDebts.where((d) {
      switch (_filter) {
        case _Filter.all:     return true;
        case _Filter.unpaid:  return d.status == DebtStatus.unpaid;
        case _Filter.partial: return d.status == DebtStatus.partiallyPaid;
        case _Filter.paid:    return d.status == DebtStatus.paid;
      }
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final totalOutstanding = allDebts.where((d) => d.status != DebtStatus.paid).fold(0.0, (a, d) => a + d.balance);
    final totalCollected   = allDebts.fold(0.0, (a, d) => a + d.totalPaid);

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Debt Ledger')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebt(context, state),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Debt', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ── Summary strip ─────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            color: AppTheme.navyCard,
            child: Row(children: [
              _strip('Outstanding', f(totalOutstanding), AppTheme.danger),
              _divider(),
              _strip('Collected', f(totalCollected), AppTheme.profit),
              _divider(),
              _strip('Total Debts', '${allDebts.length}', AppTheme.textSecondary),
            ]),
          ),

          // ── Filter chips ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppTheme.navy,
            child: Row(children: [
              _chip('Unpaid', _Filter.unpaid, AppTheme.danger),
              const SizedBox(width: 8),
              _chip('Partial', _Filter.partial, AppTheme.warning),
              const SizedBox(width: 8),
              _chip('Paid', _Filter.paid, AppTheme.profit),
              const SizedBox(width: 8),
              _chip('All', _Filter.all, AppTheme.textSecondary),
            ]),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 72, height: 72, decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)), child: const Icon(Icons.people_outline, size: 32, color: AppTheme.textMuted)),
                      const SizedBox(height: 16),
                      Text(_filter == _Filter.unpaid ? 'No unpaid debts' : 'No debts here', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('Tap + to record a debt', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final debt = filtered[i];
                      final statusColor = debt.status == DebtStatus.paid
                          ? AppTheme.profit
                          : debt.status == DebtStatus.partiallyPaid
                              ? AppTheme.warning
                              : AppTheme.danger;
                      final statusLabel = debt.status == DebtStatus.paid
                          ? 'Paid'
                          : debt.status == DebtStatus.partiallyPaid
                              ? 'Partial'
                              : 'Unpaid';

                      return GestureDetector(
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => DebtDetailScreen(debtId: debt.id))),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.navyCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Center(child: Text(debt.customerName[0].toUpperCase(), style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.w700))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(debt.customerName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                if (debt.customerPhone != null)
                                  Text(debt.customerPhone!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(f(debt.balance), style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 15)),
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            ]),

                            if (debt.status != DebtStatus.paid) ...[
                              const SizedBox(height: 12),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: debt.totalAmount == 0 ? 0 : (debt.totalPaid / debt.totalAmount).clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor: const Color(0xFF1D3A4F),
                                  valueColor: AlwaysStoppedAnimation(statusColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('Paid: ${f(debt.totalPaid)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                Text('Total: ${f(debt.totalAmount)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              ]),
                            ],

                            if (debt.stockItemName != null) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.inventory_2_outlined, size: 12, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text('${debt.stockItemName} × ${debt.quantitySold}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              ]),
                            ],

                            const SizedBox(height: 6),
                            Text(DateFormat('MMM d, yyyy').format(debt.date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _strip(String label, String value, Color color) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
    ]),
  );

  Widget _divider() => Container(width: 0.5, height: 28, color: const Color(0xFF1D3A4F));

  Widget _chip(String label, _Filter filter, Color color) {
    final sel = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.12) : AppTheme.navyCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? color : const Color(0xFF1D3A4F), width: sel ? 1.5 : 0.5),
        ),
        child: Text(label, style: TextStyle(color: sel ? color : AppTheme.textMuted, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  void _showAddDebt(BuildContext context, AppState state) {
    final nameCtrl  = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amtCtrl   = TextEditingController();
    final noteCtrl  = TextEditingController();
    bool linkedToStock = false;
    dynamic selectedItem;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  const Text('Record Debt', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ]),
                const SizedBox(height: 20),

                // Link to stock toggle
                GestureDetector(
                  onTap: () => setLocal(() { linkedToStock = !linkedToStock; selectedItem = null; amtCtrl.clear(); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: linkedToStock ? AppTheme.teal.withOpacity(0.08) : AppTheme.navyLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: linkedToStock ? AppTheme.teal : const Color(0xFF1D3A4F), width: linkedToStock ? 1.5 : 0.5),
                    ),
                    child: Row(children: [
                      Icon(linkedToStock ? Icons.check_box : Icons.check_box_outline_blank, color: linkedToStock ? AppTheme.teal : AppTheme.textMuted, size: 20),
                      const SizedBox(width: 10),
                      const Text('Link to a stock item', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    ]),
                  ),
                ),

                if (linkedToStock) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<dynamic>(
                    dropdownColor: AppTheme.navyCard,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Select item', prefixIcon: Icon(Icons.inventory_2_outlined)),
                    value: selectedItem,
                    items: state.stock.map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.quantity} left)', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)))).toList(),
                    onChanged: (v) => setLocal(() {
                      selectedItem = v;
                      amtCtrl.text = v?.costPrice.toString() ?? '';
                    }),
                  ),
                ],

                const SizedBox(height: 12),
                TextField(controller: nameCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Customer name', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Phone number (optional)', prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 12),
                TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textPrimary), decoration: InputDecoration(labelText: 'Amount owed (${state.settings.currency})', prefixIcon: const Icon(Icons.attach_money))),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes_outlined))),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final amt  = double.tryParse(amtCtrl.text) ?? 0;
                      if (name.isEmpty || amt <= 0) return;
                      state.addDebt(Debt(
                        id: const Uuid().v4(),
                        customerName: name,
                        customerPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                        totalAmount: amt,
                        payments: [],
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                        stockItemId: linkedToStock ? selectedItem?.id : null,
                        stockItemName: linkedToStock ? selectedItem?.name : null,
                        quantitySold: linkedToStock ? 1 : null,
                      ));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debt recorded')),
                      );
                    },
                    child: const Text('Save Debt'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}