import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/expense.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fmt = NumberFormat('#,##0.00');
    final currency = state.settings.currency;
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    final dayExpenses = state.expensesForDate(_selectedDate);
    final totalToday = dayExpenses.fold(0.0, (a, e) => a + e.amount);
    final totalAll = state.expenses.fold(0.0, (a, e) => a + e.amount);

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Expenses'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpense(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ── Date navigator ────────────────────────────
          Container(
            color: AppTheme.navyLight,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Row(children: [
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
            ]),
          ),

          // ── Summary strip ─────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppTheme.navyCard,
            child: Row(children: [
              _strip('Today', '$currency${fmt.format(totalToday)}', AppTheme.danger),
              _stripDivider(),
              _strip('All-Time', '$currency${fmt.format(totalAll)}', AppTheme.warning),
              _stripDivider(),
              _strip('Entries', '${dayExpenses.length}', AppTheme.textSecondary),
            ]),
          ),

          Expanded(
            child: dayExpenses.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 72, height: 72, decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)), child: const Icon(Icons.receipt_outlined, size: 32, color: AppTheme.textMuted)),
                      const SizedBox(height: 16),
                      Text(isToday ? 'No expenses today' : 'No expenses on this day', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      if (isToday) const Text('Tap + to record an expense', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: dayExpenses.length,
                    itemBuilder: (ctx, i) {
                      final exp = dayExpenses[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.navyCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Center(child: Text(exp.category.emoji, style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(exp.description, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 3),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(exp.category.label, style: const TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                              if (exp.note != null) ...[
                                const SizedBox(width: 6),
                                Expanded(child: Text(exp.note!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
                              ],
                            ]),
                          ])),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('$currency${fmt.format(exp.amount)}', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _confirmDelete(context, state, exp),
                              child: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 18),
                            ),
                          ]),
                        ]),
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
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
    ]),
  );

  Widget _stripDivider() => Container(width: 0.5, height: 28, color: const Color(0xFF1D3A4F));

  void _showAddExpense(BuildContext context, AppState state) {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    ExpenseCategory selectedCat = ExpenseCategory.other;

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
                Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                const Text('Add Expense', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 20),

              // Category picker
              const Text('Category', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ExpenseCategory.values.map((cat) {
                    final sel = selectedCat == cat;
                    return GestureDetector(
                      onTap: () => setLocal(() => selectedCat = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.danger.withOpacity(0.12) : AppTheme.navyLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? AppTheme.danger : const Color(0xFF1D3A4F), width: sel ? 1.5 : 0.5),
                        ),
                        child: Text('${cat.emoji} ${cat.label}', style: TextStyle(color: sel ? AppTheme.danger : AppTheme.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.edit_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(labelText: 'Amount (${state.settings.currency})', prefixIcon: const Icon(Icons.attach_money)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes_outlined)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                  onPressed: () {
                    final desc = descCtrl.text.trim();
                    final amt = double.tryParse(amtCtrl.text) ?? 0;
                    if (desc.isEmpty || amt <= 0) return;
                    state.addExpense(Expense(
                      id: const Uuid().v4(),
                      description: desc,
                      amount: amt,
                      category: selectedCat,
                      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expense recorded')),
                    );
                  },
                  child: const Text('Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Expense exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${exp.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () { state.deleteExpense(exp.id); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
  }
}