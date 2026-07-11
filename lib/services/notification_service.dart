import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/stock_item.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'bizsplit_stock';
  static const _channelName = 'Low Stock Alerts';
  static const _channelDesc = 'Notifies when stock items are running low';

  // ── Initialize ─────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
    await _createChannel();
    _initialized = true;
  }

  static Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Request permission (Android 13+) ───────────────────
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── Check stock and fire notifications ─────────────────
  static Future<void> checkLowStock({
    required List<StockItem> stock,
    required int threshold,
  }) async {
    await init();

    final lowItems = stock.where((s) => s.quantity <= threshold && s.quantity >= 0).toList();

    if (lowItems.isEmpty) return;

    if (lowItems.length == 1) {
      // Single item notification
      final item = lowItems.first;
      await _show(
        id: item.id.hashCode.abs() % 100000,
        title: '⚠️ Low Stock — ${item.name}',
        body: 'Only ${item.quantity} unit${item.quantity == 1 ? '' : 's'} left. Time to restock.',
      );
    } else {
      // Grouped notification for multiple low items
      final names = lowItems.take(3).map((s) => s.name).join(', ');
      final extra = lowItems.length > 3 ? ' +${lowItems.length - 3} more' : '';
      await _show(
        id: 99999,
        title: '⚠️ ${lowItems.length} items running low',
        body: '$names$extra — tap to check your stock.',
      );
    }
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF1D9E75),
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  // ── Cancel all notifications ───────────────────────────
  static Future<void> cancelAll() async => _plugin.cancelAll();
}