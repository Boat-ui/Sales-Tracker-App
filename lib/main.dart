import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/app_state.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/pin_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const BizSplitApp(),
    ),
  );
}

class BizSplitApp extends StatelessWidget {
  const BizSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizSplit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(nextScreen: AuthGate()),
    );
  }
}

// Decides what screen to show based on auth state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.navy,
            body: Center(child: CircularProgressIndicator(color: AppTheme.teal)),
          );
        }
        // Not logged in
        if (!snapshot.hasData) return const LoginScreen();
        // Logged in — check for PIN
        return FutureBuilder<bool>(
          future: PinScreen.hasPin(),
          builder: (context, pinSnap) {
            if (!pinSnap.hasData) return const Scaffold(backgroundColor: AppTheme.navy, body: Center(child: CircularProgressIndicator(color: AppTheme.teal)));
            if (pinSnap.data == true) {
              return PinScreen(nextScreen: const MainShell());
            }
            // First time — ask to set PIN
            return PinScreen(nextScreen: const MainShell(), isSetup: true);
          },
        );
      },
    );
  }
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
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loaded = context.watch<AppState>().loaded;

    if (!loaded) {
      return const Scaffold(
        backgroundColor: AppTheme.navy,
        body: Center(child: CircularProgressIndicator(color: AppTheme.teal)),
      );
    }

    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}