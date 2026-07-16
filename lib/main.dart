import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/pin_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/debts/debts_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  await NotificationService.requestPermission();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const BizSplitApp(),
    ),
  );
}

class BizSplitApp extends StatelessWidget {
  const BizSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'BizSplit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(nextScreen: AuthGate()),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _loadedForUid;
  bool _pinUnlocked = false;
  bool? _hasPin;

  Future<void> _checkPin() async {
    final has = await PinScreen.hasPin();
    if (mounted) setState(() => _hasPin = has);
  }

  void _onUnlocked() => setState(() => _pinUnlocked = true);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _Loading();

        final user = snapshot.data;

        if (user == null) {
          if (_loadedForUid != null) {
            _loadedForUid = null;
            _pinUnlocked  = false;
            _hasPin       = null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AppState>().reset();
              rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            });
          }
          return const LoginScreen();
        }

        if (_loadedForUid != user.uid) {
          _loadedForUid = user.uid;
          _pinUnlocked  = false;
          _hasPin       = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AppState>().init();
            _checkPin();
          });
          return const _Loading();
        }

        if (_hasPin == null) return const _Loading();

        if (!_pinUnlocked) {
          return PinScreen(isSetup: _hasPin == false, onUnlocked: _onUnlocked);
        }

        return const MainShell();
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppTheme.navy,
    body: Center(child: CircularProgressIndicator(color: AppTheme.teal)),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    StockScreen(),
    SalesScreen(),
    ExpensesScreen(),
    DebtsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loaded = context.watch<AppState>().loaded;
    if (!loaded) return const _Loading();

    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Debts'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}