import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stock_item.dart';
import '../models/sale.dart';
import '../models/settings.dart';
import '../models/expense.dart';
import '../models/debt.dart';
import '../models/business.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Business-scoped collection refs ───────────────────
  // All data now lives under users/{uid}/businesses/{bizId}/...
  CollectionReference _stock(String bizId) =>
      _db.collection('users').doc(_uid).collection('businesses').doc(bizId).collection('stock');

  CollectionReference _sales(String bizId) =>
      _db.collection('users').doc(_uid).collection('businesses').doc(bizId).collection('sales');

  CollectionReference _expenses(String bizId) =>
      _db.collection('users').doc(_uid).collection('businesses').doc(bizId).collection('expenses');

  CollectionReference _debts(String bizId) =>
      _db.collection('users').doc(_uid).collection('businesses').doc(bizId).collection('debts');

  DocumentReference _settingsDoc(String bizId) =>
      _db.collection('users').doc(_uid).collection('businesses').doc(bizId).collection('meta').doc('settings');

  // ── Businesses ─────────────────────────────────────────
  CollectionReference get _businesses =>
      _db.collection('users').doc(_uid).collection('businesses');

  DocumentReference get _profileDoc =>
      _db.collection('users').doc(_uid);

  Future<List<Business>> loadBusinesses() async {
    final snap = await _businesses.orderBy('createdAt').get();
    return snap.docs.map((d) => Business.fromMap(d.data() as Map<String, dynamic>)).toList();
  }

  Future<void> saveBusiness(Business biz) async =>
      _businesses.doc(biz.id).set(biz.toMap());

  Future<void> deleteBusiness(String bizId) async =>
      _businesses.doc(bizId).delete();

  Future<String?> getActiveBizId() async {
    final doc = await _profileDoc.get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['activeBizId'] as String?;
  }

  Future<void> setActiveBizId(String bizId) async =>
      _profileDoc.set({'activeBizId': bizId}, SetOptions(merge: true));

  // ── Stock ──────────────────────────────────────────────
  Future<List<StockItem>> loadStock(String bizId) async {
    final snap = await _stock(bizId).get();
    return snap.docs.map((d) => StockItem.fromMap(d.data() as Map<String, dynamic>)).toList();
  }
  Future<void> saveStockItem(String bizId, StockItem item) async =>
      _stock(bizId).doc(item.id).set(item.toMap());
  Future<void> deleteStockItem(String bizId, String id) async =>
      _stock(bizId).doc(id).delete();

  // ── Sales ──────────────────────────────────────────────
  Future<List<Sale>> loadSales(String bizId) async {
    final snap = await _sales(bizId).orderBy('date', descending: true).get();
    return snap.docs.map((d) => Sale.fromMap(d.data() as Map<String, dynamic>)).toList();
  }
  Future<void> saveSale(String bizId, Sale sale) async =>
      _sales(bizId).doc(sale.id).set(sale.toMap());
  Future<void> deleteSale(String bizId, String id) async =>
      _sales(bizId).doc(id).delete();

  // ── Expenses ───────────────────────────────────────────
  Future<List<Expense>> loadExpenses(String bizId) async {
    final snap = await _expenses(bizId).orderBy('date', descending: true).get();
    return snap.docs.map((d) => Expense.fromMap(d.data() as Map<String, dynamic>)).toList();
  }
  Future<void> saveExpense(String bizId, Expense expense) async =>
      _expenses(bizId).doc(expense.id).set(expense.toMap());
  Future<void> deleteExpense(String bizId, String id) async =>
      _expenses(bizId).doc(id).delete();

  // ── Debts ──────────────────────────────────────────────
  Future<List<Debt>> loadDebts(String bizId) async {
    final snap = await _debts(bizId).orderBy('date', descending: true).get();
    return snap.docs.map((d) => Debt.fromMap(d.data() as Map<String, dynamic>)).toList();
  }
  Future<void> saveDebt(String bizId, Debt debt) async =>
      _debts(bizId).doc(debt.id).set(debt.toMap());
  Future<void> deleteDebt(String bizId, String id) async =>
      _debts(bizId).doc(id).delete();

  // ── Settings ───────────────────────────────────────────
  Future<AppSettings> loadSettings(String bizId) async {
    final doc = await _settingsDoc(bizId).get();
    if (!doc.exists) return AppSettings();
    return AppSettings.fromMap(doc.data() as Map<String, dynamic>);
  }
  Future<void> saveSettings(String bizId, AppSettings s) async =>
      _settingsDoc(bizId).set(s.toMap());
}