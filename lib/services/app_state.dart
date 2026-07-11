import 'package:flutter/foundation.dart';
import '../models/stock_item.dart';
import '../models/sale.dart';
import '../models/settings.dart';
import '../models/expense.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _local = StorageService();

  List<StockItem> _stock    = [];
  List<Sale>      _sales    = [];
  List<Expense>   _expenses = [];
  AppSettings     _settings = AppSettings();
  bool            _loaded   = false;

  List<StockItem> get stock    => List.unmodifiable(_stock);
  List<Sale>      get sales    => List.unmodifiable(_sales);
  List<Expense>   get expenses => List.unmodifiable(_expenses);
  AppSettings     get settings => _settings;
  bool            get loaded   => _loaded;

  Future<void> init() async {
    _loaded = false;
    notifyListeners();
    try {
      _stock    = await _firestore.loadStock();
      _sales    = await _firestore.loadSales();
      _expenses = await _firestore.loadExpenses();
      _settings = await _firestore.loadSettings();
    } catch (_) {
      _stock    = await _local.loadStock();
      _sales    = await _local.loadSales();
      _expenses = await _local.loadExpenses();
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
    _settings = AppSettings();
    _loaded   = false;
    notifyListeners();
  }

  void _checkLowStock() {
    NotificationService.checkLowStock(
      stock: _stock,
      threshold: _settings.lowStockThreshold,
    );
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

  // Net profit = sales profit - expenses (for a given period)
  double netProfitForPeriod(List<Sale> sales, List<Expense> expenses) {
    final profit  = sales.fold(0.0, (a, s) => a + s.totalProfit);
    final expTotal = expenses.fold(0.0, (a, e) => a + e.amount);
    return profit - expTotal;
  }
}