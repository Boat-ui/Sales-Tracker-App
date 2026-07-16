import 'package:flutter/foundation.dart';
import '../models/stock_item.dart';
import '../models/sale.dart';
import '../models/settings.dart';
import '../models/expense.dart';
import '../models/debt.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final StorageService   _local     = StorageService();

  List<StockItem> _stock    = [];
  List<Sale>      _sales    = [];
  List<Expense>   _expenses = [];
  List<Debt>      _debts    = [];
  AppSettings     _settings = AppSettings();
  bool            _loaded   = false;

  List<StockItem> get stock    => List.unmodifiable(_stock);
  List<Sale>      get sales    => List.unmodifiable(_sales);
  List<Expense>   get expenses => List.unmodifiable(_expenses);
  List<Debt>      get debts    => List.unmodifiable(_debts);
  AppSettings     get settings => _settings;
  bool            get loaded   => _loaded;

  Future<void> init() async {
    _loaded = false;
    notifyListeners();
    try {
      _stock    = await _firestore.loadStock();
      _sales    = await _firestore.loadSales();
      _expenses = await _firestore.loadExpenses();
      _debts    = await _firestore.loadDebts();
      _settings = await _firestore.loadSettings();
    } catch (_) {
      _stock    = await _local.loadStock();
      _sales    = await _local.loadSales();
      _expenses = await _local.loadExpenses();
      _debts    = await _local.loadDebts();
      _settings = await _local.loadSettings();
    }
    _loaded = true;
    notifyListeners();
    _checkLowStock();
  }

  void reset() {
    _stock    = [];
    _sales    = [];
    _expenses = [];
    _debts    = [];
    _settings = AppSettings();
    _loaded   = false;
    notifyListeners();
  }

  void _checkLowStock() {
    NotificationService.checkLowStock(stock: _stock, threshold: _settings.lowStockThreshold);
  }

  // ── Stock ──────────────────────────────────────────────
  Future<void> addStockItem(StockItem item) async {
    _stock = [..._stock, item];
    notifyListeners();
    await _firestore.saveStockItem(item);
    await _local.saveStock(_stock);
  }

  Future<void> updateStockItem(StockItem updated) async {
    _stock = [for (final s in _stock) if (s.id == updated.id) updated else s];
    notifyListeners();
    await _firestore.saveStockItem(updated);
    await _local.saveStock(_stock);
    _checkLowStock();
  }

  Future<void> deleteStockItem(String id) async {
    _stock = _stock.where((s) => s.id != id).toList();
    notifyListeners();
    await _firestore.deleteStockItem(id);
    await _local.saveStock(_stock);
  }

  // ── Sales ──────────────────────────────────────────────
  Future<void> addSale(Sale sale) async {
    final idx = _stock.indexWhere((s) => s.id == sale.stockItemId);
    if (idx != -1) {
      final old = _stock[idx];
      final updated = StockItem(id: old.id, name: old.name, costPrice: old.costPrice, quantity: old.quantity - sale.quantitySold, category: old.category, dateAdded: old.dateAdded);
      _stock = [for (final s in _stock) if (s.id == updated.id) updated else s];
      await _firestore.saveStockItem(updated);
    }
    _sales = [..._sales, sale];
    notifyListeners();
    await _firestore.saveSale(sale);
    await _local.saveSales(_sales);
    await _local.saveStock(_stock);
    _checkLowStock();
  }

  Future<void> deleteSale(String id) async {
    final sale = _sales.firstWhere((s) => s.id == id);
    final idx  = _stock.indexWhere((s) => s.id == sale.stockItemId);
    if (idx != -1) {
      final old = _stock[idx];
      final restored = StockItem(id: old.id, name: old.name, costPrice: old.costPrice, quantity: old.quantity + sale.quantitySold, category: old.category, dateAdded: old.dateAdded);
      _stock = [for (final s in _stock) if (s.id == restored.id) restored else s];
      await _firestore.saveStockItem(restored);
    }
    _sales = _sales.where((s) => s.id != id).toList();
    notifyListeners();
    await _firestore.deleteSale(id);
    await _local.saveSales(_sales);
    await _local.saveStock(_stock);
  }

  // ── Expenses ───────────────────────────────────────────
  Future<void> addExpense(Expense expense) async {
    _expenses = [..._expenses, expense];
    notifyListeners();
    await _firestore.saveExpense(expense);
    await _local.saveExpenses(_expenses);
  }

  Future<void> deleteExpense(String id) async {
    _expenses = _expenses.where((e) => e.id != id).toList();
    notifyListeners();
    await _firestore.deleteExpense(id);
    await _local.saveExpenses(_expenses);
  }

  // ── Debts ──────────────────────────────────────────────
  Future<void> addDebt(Debt debt) async {
    _debts = [..._debts, debt];
    notifyListeners();
    await _firestore.saveDebt(debt);
    await _local.saveDebts(_debts);
  }

  Future<void> addDebtPayment(String debtId, DebtPayment payment) async {
    _debts = [
      for (final d in _debts)
        if (d.id == debtId) d.withPayment(payment) else d
    ];
    notifyListeners();
    final updated = _debts.firstWhere((d) => d.id == debtId);
    await _firestore.saveDebt(updated);
    await _local.saveDebts(_debts);
  }

  Future<void> markDebtFullyPaid(String debtId) async {
    final debt = _debts.firstWhere((d) => d.id == debtId);
    final remaining = debt.balance;
    if (remaining <= 0) return;
    await addDebtPayment(debtId, DebtPayment(amount: remaining, date: DateTime.now(), note: 'Marked as fully paid'));
  }

  Future<void> deleteDebt(String id) async {
    _debts = _debts.where((d) => d.id != id).toList();
    notifyListeners();
    await _firestore.deleteDebt(id);
    await _local.saveDebts(_debts);
  }

  // ── Settings ───────────────────────────────────────────
  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    notifyListeners();
    await _firestore.saveSettings(s);
    await _local.saveSettings(s);
  }

  // ── Computed ───────────────────────────────────────────
  List<Sale> salesForDate(DateTime date) => _sales.where((s) =>
      s.date.year == date.year && s.date.month == date.month && s.date.day == date.day).toList();

  List<Expense> expensesForDate(DateTime date) => _expenses.where((e) =>
      e.date.year == date.year && e.date.month == date.month && e.date.day == date.day).toList();

  Map<String, double> summaryForSales(List<Sale> list) {
    double revenue = 0, cost = 0, profit = 0;
    for (final s in list) { revenue += s.totalRevenue; cost += s.totalCost; profit += s.totalProfit; }
    final bizShare      = profit * (_settings.businessPercent / 100);
    final personalShare = profit * (_settings.personalPercent / 100);
    return {
      'revenue':     revenue,
      'cost':        cost,
      'profit':      profit,
      'business':    bizShare,
      'personal':    personalShare,
      'savings':     personalShare * (_settings.personalSavingsPercent / 100),
      'personalUse': personalShare * (_settings.personalUsePercent / 100),
    };
  }

  double netProfitForPeriod(List<Sale> sales, List<Expense> expenses) {
    final profit   = sales.fold(0.0, (a, s) => a + s.totalProfit);
    final expTotal = expenses.fold(0.0, (a, e) => a + e.amount);
    return profit - expTotal;
  }
}