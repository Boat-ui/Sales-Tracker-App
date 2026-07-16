import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stock_item.dart';
import '../models/sale.dart';
import '../models/settings.dart';
import '../models/expense.dart';
import '../models/debt.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _stock    => _db.collection('users').doc(_uid).collection('stock');
  CollectionReference get _sales    => _db.collection('users').doc(_uid).collection('sales');
  CollectionReference get _expenses => _db.collection('users').doc(_uid).collection('expenses');
  CollectionReference get _debts    => _db.collection('users').doc(_uid).collection('debts');
  DocumentReference  get _settingsDoc => _db.collection('users').doc(_uid).collection('meta').doc('settings');

  // ── Stock ──────────────────────────────────────────────
  Future<List<StockItem>> loadStock() async {
    final snap = await _stock.get();
    return snap.docs.map((d) => StockItem.fromMap(d.data() as Map<String, dynamic>)).toList();
  }
  Future<void> saveStockItem(StockItem item) async => _stock.doc(item.id).set(item.toMap());
  Future<void> deleteStockItem(String id) async => _stock.doc(id).delete();

  // ── Sales ──────────────────────────────────────────────
  Future<List<Sale>> loadSales() async {
    final snap = await _sales.orderBy('date', descending: true).get();
    return snap.docs.map((d) => Sale.fromMap(d.data() as Map<String, dynamic>)).toList();
  }
  Future<void> saveSale(Sale sale) async => _sales.doc(sale.id).set(sale.toMap());
  Future<void> deleteSale(String id) async => _sales.doc(id).delete();

  // ── Expenses ───────────────────────────────────────────
  Future<List<Expense>> loadExpenses() async {
    final snap = await _expenses.orderBy('date', descending: true).get();
    return snap.docs.map((d) => Expense.fromMap(d.data() as Map<String, dynamic>)).toList();
  }
  Future<void> saveExpense(Expense expense) async => _expenses.doc(expense.id).set(expense.toMap());
  Future<void> deleteExpense(String id) async => _expenses.doc(id).delete();

  // ── Debts ──────────────────────────────────────────────
  Future<List<Debt>> loadDebts() async {
    final snap = await _debts.orderBy('date', descending: true).get();
    return snap.docs.map((d) => Debt.fromMap(d.data() as Map<String, dynamic>)).toList();
  }
  Future<void> saveDebt(Debt debt) async => _debts.doc(debt.id).set(debt.toMap());
  Future<void> deleteDebt(String id) async => _debts.doc(id).delete();

  // ── Settings ───────────────────────────────────────────
  Future<AppSettings> loadSettings() async {
    final doc = await _settingsDoc.get();
    if (!doc.exists) return AppSettings();
    return AppSettings.fromMap(doc.data() as Map<String, dynamic>);
  }
  Future<void> saveSettings(AppSettings s) async => _settingsDoc.set(s.toMap());
}