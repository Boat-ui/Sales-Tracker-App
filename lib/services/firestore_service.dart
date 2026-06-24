import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stock_item.dart';
import '../models/sale.dart';
import '../models/settings.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Collection refs ────────────────────────────────────
  CollectionReference get _stock =>
      _db.collection('users').doc(_uid).collection('stock');

  CollectionReference get _sales =>
      _db.collection('users').doc(_uid).collection('sales');

  DocumentReference get _settingsDoc =>
      _db.collection('users').doc(_uid).collection('meta').doc('settings');

  // ── Stock ──────────────────────────────────────────────
  Future<List<StockItem>> loadStock() async {
    final snap = await _stock.get();
    return snap.docs.map((d) => StockItem.fromMap(d.data() as Map<String, dynamic>)).toList();
  }

  Future<void> saveStockItem(StockItem item) async {
    await _stock.doc(item.id).set(item.toMap());
  }

  Future<void> deleteStockItem(String id) async {
    await _stock.doc(id).delete();
  }

  // ── Sales ──────────────────────────────────────────────
  Future<List<Sale>> loadSales() async {
    final snap = await _sales.orderBy('date', descending: true).get();
    return snap.docs.map((d) => Sale.fromMap(d.data() as Map<String, dynamic>)).toList();
  }

  Future<void> saveSale(Sale sale) async {
    await _sales.doc(sale.id).set(sale.toMap());
  }

  Future<void> deleteSale(String id) async {
    await _sales.doc(id).delete();
  }

  // ── Settings ───────────────────────────────────────────
  Future<AppSettings> loadSettings() async {
    final doc = await _settingsDoc.get();
    if (!doc.exists) return AppSettings();
    return AppSettings.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings s) async {
    await _settingsDoc.set(s.toMap());
  }
}