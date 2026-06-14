import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_item.dart';
import '../models/sale.dart';
import '../models/settings.dart';

class StorageService {
  static const _stockKey = 'stock_items';
  static const _salesKey = 'sales';
  static const _settingsKey = 'app_settings';

  // ── Stock ──────────────────────────────────────────────
  Future<List<StockItem>> loadStock() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_stockKey);
    if (json == null || json.isEmpty) return [];
    return StockItem.listFromJson(json);
  }

  Future<void> saveStock(List<StockItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stockKey, StockItem.listToJson(items));
  }

  // ── Sales ──────────────────────────────────────────────
  Future<List<Sale>> loadSales() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_salesKey);
    if (json == null || json.isEmpty) return [];
    return Sale.listFromJson(json);
  }

  Future<void> saveSales(List<Sale> sales) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_salesKey, Sale.listToJson(sales));
  }

  // ── Settings ───────────────────────────────────────────
  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_settingsKey);
    if (json == null || json.isEmpty) return AppSettings();
    return AppSettings.fromJsonString(json);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toJsonString());
  }
}
