import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stock_item.dart';
import '../models/sale.dart';
import '../models/settings.dart';
import '../models/expense.dart';
import '../models/debt.dart';
import '../models/business.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final StorageService   _local     = StorageService();

  List<Business>  _businesses = [];
  Business?       _activeBusiness;
  List<StockItem> _stock    = [];
  List<Sale>      _sales    = [];
  List<Expense>   _expenses = [];
  List<Debt>      _debts    = [];
  AppSettings     _settings = AppSettings();
  bool            _loaded   = false;

  List<Business>  get businesses      => List.unmodifiable(_businesses);
  Business?       get activeBusiness  => _activeBusiness;
  String?         get activeBizId     => _activeBusiness?.id;
  BusinessType    get businessType    => _activeBusiness?.type ?? BusinessType.retail;
  List<StockItem> get stock           => List.unmodifiable(_stock);
  List<Sale>      get sales           => List.unmodifiable(_sales);
  List<Expense>   get expenses        => List.unmodifiable(_expenses);
  List<Debt>      get debts           => List.unmodifiable(_debts);
  AppSettings     get settings        => _settings;
  bool            get loaded          => _loaded;
  bool            get hasBusinesses   => _businesses.isNotEmpty;

  // ── Init ───────────────────────────────────────────────
  Future<void> init() async {
    _loaded = false;
    notifyListeners();

    try {
      // Load all businesses for this user
      _businesses = await _firestore.loadBusinesses();

      if (_businesses.isEmpty) {
        // First login — create default business
        final uid  = FirebaseAuth.instance.currentUser!.uid;
        final name = FirebaseAuth.instance.currentUser?.displayName ?? 'My Business';
        final biz  = Business(
          id: const Uuid().v4(),
          name: '$name\'s Business',
          type: BusinessType.retail,
          ownerId: uid,
          createdAt: DateTime.now(),
          members: {uid: 'owner'},
        );
        await _firestore.saveBusiness(biz);
        await _firestore.setActiveBizId(biz.id);
        _businesses = [biz];
        _activeBusiness = biz;
      } else {
        // Restore last active business
        final savedId = await _firestore.getActiveBizId();
        _activeBusiness = _businesses.firstWhere(
          (b) => b.id == savedId,
          orElse: () => _businesses.first,
        );
      }

      await _loadBizData(_activeBusiness!.id);
    } catch (e) {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _loadBizData(String bizId) async {
    try {
      _stock    = await _firestore.loadStock(bizId);
      _sales    = await _firestore.loadSales(bizId);
      _expenses = await _firestore.loadExpenses(bizId);
      _debts    = await _firestore.loadDebts(bizId);
      _settings = await _firestore.loadSettings(bizId);
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

  // ── Switch business ────────────────────────────────────
  Future<void> switchBusiness(Business biz) async {
    if (_activeBusiness?.id == biz.id) return;
    _loaded = false;
    _activeBusiness = biz;
    notifyListeners();
    await _firestore.setActiveBizId(biz.id);
    await _loadBizData(biz.id);
  }

  // ── Create business ────────────────────────────────────
  Future<Business> createBusiness({required String name, required BusinessType type}) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final biz = Business(
      id: const Uuid().v4(),
      name: name,
      type: type,
      ownerId: uid,
      createdAt: DateTime.now(),
      members: {uid: 'owner'},
    );
    await _firestore.saveBusiness(biz);
    _businesses = [..._businesses, biz];
    notifyListeners();
    await switchBusiness(biz);
    return biz;
  }

  // ── Update business ────────────────────────────────────
  Future<void> updateBusiness(Business updated) async {
    await _firestore.saveBusiness(updated);
    _businesses = [for (final b in _businesses) if (b.id == updated.id) updated else b];
    if (_activeBusiness?.id == updated.id) _activeBusiness = updated;
    notifyListeners();
  }

  // ── Delete business ────────────────────────────────────
  Future<void> deleteBusiness(String bizId) async {
    await _firestore.deleteBusiness(bizId);
    _businesses = _businesses.where((b) => b.id != bizId).toList();
    if (_activeBusiness?.id == bizId) {
      if (_businesses.isNotEmpty) {
        await switchBusiness(_businesses.first);
      } else {
        _activeBusiness = null;
        _stock = []; _sales = []; _expenses = []; _debts = [];
        _settings = AppSettings();
        _loaded = true;
      }
    }
    notifyListeners();
  }

  void reset() {
    _businesses     = [];
    _activeBusiness = null;
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

  String get _bizId => _activeBusiness?.id ?? '';

  // ── Stock ──────────────────────────────────────────────
  Future<void> addStockItem(StockItem item) async {
    _stock = [..._stock, item];
    notifyListeners();
    await _firestore.saveStockItem(_bizId, item);
    await _local.saveStock(_stock);
  }

  Future<void> updateStockItem(StockItem updated) async {
    _stock = [for (final s in _stock) if (s.id == updated.id) updated else s];
    notifyListeners();
    await _firestore.saveStockItem(_bizId, updated);
    await _local.saveStock(_stock);
    _checkLowStock();
  }

  Future<void> deleteStockItem(String id) async {
    _stock = _stock.where((s) => s.id != id).toList();
    notifyListeners();
    await _firestore.deleteStockItem(_bizId, id);
    await _local.saveStock(_stock);
  }

  // ── Sales ──────────────────────────────────────────────
  Future<void> addSale(Sale sale) async {
    final idx = _stock.indexWhere((s) => s.id == sale.stockItemId);
    if (idx != -1) {
      final old = _stock[idx];
      final updated = StockItem(id: old.id, name: old.name, costPrice: old.costPrice, quantity: old.quantity - sale.quantitySold, category: old.category, dateAdded: old.dateAdded);
      _stock = [for (final s in _stock) if (s.id == updated.id) updated else s];
      await _firestore.saveStockItem(_bizId, updated);
    }
    _sales = [..._sales, sale];
    notifyListeners();
    await _firestore.saveSale(_bizId, sale);
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
      await _firestore.saveStockItem(_bizId, restored);
    }
    _sales = _sales.where((s) => s.id != id).toList();
    notifyListeners();
    await _firestore.deleteSale(_bizId, id);
    await _local.saveSales(_sales);
    await _local.saveStock(_stock);
  }

  // ── Expenses ───────────────────────────────────────────
  Future<void> addExpense(Expense expense) async {
    _expenses = [..._expenses, expense];
    notifyListeners();
    await _firestore.saveExpense(_bizId, expense);
    await _local.saveExpenses(_expenses);
  }

  Future<void> deleteExpense(String id) async {
    _expenses = _expenses.where((e) => e.id != id).toList();
    notifyListeners();
    await _firestore.deleteExpense(_bizId, id);
    await _local.saveExpenses(_expenses);
  }

  // ── Debts ──────────────────────────────────────────────
  Future<void> addDebt(Debt debt) async {
    _debts = [..._debts, debt];
    notifyListeners();
    await _firestore.saveDebt(_bizId, debt);
    await _local.saveDebts(_debts);
  }

  Future<void> addDebtPayment(String debtId, DebtPayment payment) async {
    _debts = [for (final d in _debts) if (d.id == debtId) d.withPayment(payment) else d];
    notifyListeners();
    final updated = _debts.firstWhere((d) => d.id == debtId);
    await _firestore.saveDebt(_bizId, updated);
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
    await _firestore.deleteDebt(_bizId, id);
    await _local.saveDebts(_debts);
  }

  // ── Settings ───────────────────────────────────────────
  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    notifyListeners();
    await _firestore.saveSettings(_bizId, s);
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