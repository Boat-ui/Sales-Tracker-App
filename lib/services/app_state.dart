import 'package:flutter/foundation.dart';
import '../models/stock_item.dart';
import '../models/sale.dart';
import '../models/settings.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _local = StorageService(); // kept as offline fallback

  List<StockItem> _stock = [];
  List<Sale> _sales = [];
  AppSettings _settings = AppSettings();
  bool _loaded = false;

  List<StockItem> get stock => _stock;
  List<Sale> get sales => _sales;
  AppSettings get settings => _settings;
  bool get loaded => _loaded;

  Future<void> init() async {
    try {
      // Load from Firestore (cloud)
      _stock    = await _firestore.loadStock();
      _sales    = await _firestore.loadSales();
      _settings = await _firestore.loadSettings();
    } catch (_) {
      // Fallback to local if offline
      _stock    = await _local.loadStock();
      _sales    = await _local.loadSales();
      _settings = await _local.loadSettings();
    }
    _loaded = true;
    notifyListeners();
  }

  // ── Stock ──────────────────────────────────────────────
  Future<void> addStockItem(StockItem item) async {
    _stock.add(item);
    notifyListeners();
    await _firestore.saveStockItem(item);
    await _local.saveStock(_stock); // local backup
  }

  Future<void> updateStockItem(StockItem updated) async {
    final idx = _stock.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _stock[idx] = updated;
      notifyListeners();
      await _firestore.saveStockItem(updated);
      await _local.saveStock(_stock);
    }
  }

  Future<void> deleteStockItem(String id) async {
    _stock.removeWhere((s) => s.id == id);
    notifyListeners();
    await _firestore.deleteStockItem(id);
    await _local.saveStock(_stock);
  }

  // ── Sales ──────────────────────────────────────────────
  Future<void> addSale(Sale sale) async {
    // Deduct stock
    final idx = _stock.indexWhere((s) => s.id == sale.stockItemId);
    if (idx != -1) {
      _stock[idx].quantity -= sale.quantitySold;
      await _firestore.saveStockItem(_stock[idx]);
    }
    _sales.add(sale);
    notifyListeners();
    await _firestore.saveSale(sale);
    await _local.saveSales(_sales);
    await _local.saveStock(_stock);
  }

  Future<void> deleteSale(String id) async {
    final sale = _sales.firstWhere((s) => s.id == id);
    // Restore stock
    final idx = _stock.indexWhere((s) => s.id == sale.stockItemId);
    if (idx != -1) {
      _stock[idx].quantity += sale.quantitySold;
      await _firestore.saveStockItem(_stock[idx]);
    }
    _sales.removeWhere((s) => s.id == id);
    notifyListeners();
    await _firestore.deleteSale(id);
    await _local.saveSales(_sales);
    await _local.saveStock(_stock);
  }

  // ── Settings ───────────────────────────────────────────
  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    notifyListeners();
    await _firestore.saveSettings(s);
    await _local.saveSettings(s);
  }

  // ── Computed ───────────────────────────────────────────
  List<Sale> salesForDate(DateTime date) => _sales
      .where((s) =>
          s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day)
      .toList();

  Map<String, double> summaryForSales(List<Sale> list) {
    double revenue = 0, cost = 0, profit = 0;
    for (final s in list) {
      revenue += s.totalRevenue;
      cost    += s.totalCost;
      profit  += s.totalProfit;
    }
    return {
      'revenue':     revenue,
      'cost':        cost,
      'profit':      profit,
      'business':    profit * 0.5,
      'personal':    profit * 0.5,
      'savings':     profit * 0.5 * (_settings.personalSavingsPercent / 100),
      'personalUse': profit * 0.5 * (_settings.personalUsePercent / 100),
    };
  }
}