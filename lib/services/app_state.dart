import 'package:flutter/foundation.dart';
import '../models/stock_item.dart';
import '../models/sale.dart';
import '../models/settings.dart';
import 'storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<StockItem> _stock = [];
  List<Sale> _sales = [];
  AppSettings _settings = AppSettings();
  bool _loaded = false;

  List<StockItem> get stock => _stock;
  List<Sale> get sales => _sales;
  AppSettings get settings => _settings;
  bool get loaded => _loaded;

  Future<void> init() async {
    _stock = await _storage.loadStock();
    _sales = await _storage.loadSales();
    _settings = await _storage.loadSettings();
    _loaded = true;
    notifyListeners();
  }

  // ── Stock ──────────────────────────────────────────────
  Future<void> addStockItem(StockItem item) async {
    _stock.add(item);
    await _storage.saveStock(_stock);
    notifyListeners();
  }

  Future<void> updateStockItem(StockItem updated) async {
    final idx = _stock.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _stock[idx] = updated;
      await _storage.saveStock(_stock);
      notifyListeners();
    }
  }

  Future<void> deleteStockItem(String id) async {
    _stock.removeWhere((s) => s.id == id);
    await _storage.saveStock(_stock);
    notifyListeners();
  }

  // ── Sales ──────────────────────────────────────────────
  Future<void> addSale(Sale sale) async {
    // deduct from stock
    final idx = _stock.indexWhere((s) => s.id == sale.stockItemId);
    if (idx != -1) {
      _stock[idx].quantity -= sale.quantitySold;
      await _storage.saveStock(_stock);
    }
    _sales.add(sale);
    await _storage.saveSales(_sales);
    notifyListeners();
  }

  Future<void> deleteSale(String id) async {
    final sale = _sales.firstWhere((s) => s.id == id);
    // restore stock
    final idx = _stock.indexWhere((s) => s.id == sale.stockItemId);
    if (idx != -1) {
      _stock[idx].quantity += sale.quantitySold;
      await _storage.saveStock(_stock);
    }
    _sales.removeWhere((s) => s.id == id);
    await _storage.saveSales(_sales);
    notifyListeners();
  }

  // ── Settings ───────────────────────────────────────────
  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    await _storage.saveSettings(s);
    notifyListeners();
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
      cost += s.totalCost;
      profit += s.totalProfit;
    }
    return {
      'revenue': revenue,
      'cost': cost,
      'profit': profit,
      'business': profit * 0.5,
      'personal': profit * 0.5,
      'savings': profit * 0.5 * (_settings.personalSavingsPercent / 100),
      'personalUse': profit * 0.5 * (_settings.personalUsePercent / 100),
    };
  }
}
