import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/debt.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class DebtDetailScreen extends StatelessWidget {
  final String debtId;
  const DebtDetailScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final debt  = state.debts.firstWhere((d) => d.id == debtId);
    final fmt   = NumberFormat('#,##0.00');
    final currency = state.settings.currency;
    String f(double v) => '$currency${fmt.format(v)}';

    final statusColor = debt.status == DebtStatus.paid
        ? AppTheme.profit
        : debt.status == DebtStatus.partiallyPaid
            ? AppTheme.warning
            : AppTheme.danger;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: Text(debt.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            onPressed: () => _confirmDelete(context, state, debt),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Status card ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Balance Owed', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(f(debt.balance), style: TextStyle(color: statusColor, fontSize: 28, fontWeight: FontWeight.w700)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    debt.status == DebtStatus.paid ? '✓ Paid' : debt.status == DebtStatus.partiallyPaid ? 'Partial' : 'Unpaid',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: debt.totalAmount == 0 ? 0 : (debt.totalPaid / debt.totalAmount).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFF1D3A4F),
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Paid: ${f(debt.totalPaid)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text('Total: ${f(debt.totalAmount)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Details ────────────────────────────────────
          _detailCard([
            _row(Icons.person_outline, 'Customer', debt.customerName),
            if (debt.customerPhone != null) _row(Icons.phone_outlined, 'Phone', debt.customerPhone!),
            _row(Icons.calendar_today_outlined, 'Date', DateFormat('MMM d, yyyy').format(debt.date)),
            if (debt.stockItemName != null) _row(Icons.inventory_2_outlined, 'Item', '${debt.stockItemName} × ${debt.quantitySold}'),
            if (debt.note != null) _row(Icons.notes_outlined, 'Note', debt.note!),
          ]),

          const SizedBox(height: 20),

          // ── Payment history ────────────────────────────
          const Text('Payment History', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (debt.payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
              child: const Center(child: Text('No payments yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
            )
          else
            ...debt.payments.reversed.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.profit.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.payment, color: AppTheme.profit, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f(p.amount), style: const TextStyle(color: AppTheme.profit, fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(DateFormat('MMM d, yyyy').format(p.date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  if (p.note != null) Text(p.note!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ])),
              ]),
            )),

          const SizedBox(height: 20),

          // ── Record payment ─────────────────────────────
          if (debt.status != DebtStatus.paid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(context, state, debt),
                icon: const Icon(Icons.payment),
                label: const Text('Record Payment'),
              ),
            ),

          if (debt.status != DebtStatus.paid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  state.markDebtFullyPaid(debt.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked as fully paid ✓')),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, color: AppTheme.profit),
                label: const Text('Mark as Fully Paid', style: TextStyle(color: AppTheme.profit)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.profit),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _detailCard(List<Widget> rows) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
    child: Column(children: rows),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Icon(icon, color: AppTheme.teal, size: 16),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );

  void _showPaymentDialog(BuildContext context, AppState state, Debt debt) {
    final amtCtrl  = TextEditingController();
    final noteCtrl = TextEditingController();
    final currency = state.settings.currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Balance: $currency${NumberFormat('#,##0.00').format(debt.balance)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(labelText: 'Amount paid ($currency)', prefixIcon: const Icon(Icons.attach_money)),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes_outlined)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt <= 0) return;
              state.addDebtPayment(
                debt.id,
                DebtPayment(amount: amt, date: DateTime.now(), note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim()),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment recorded ✓')),
              );
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.teal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Debt debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete debt?'),
        content: Text('Remove debt for "${debt.customerName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              state.deleteDebt(debt.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}