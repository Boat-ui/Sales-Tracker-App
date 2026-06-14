import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/settings_screen.dart';

Future<void> _exportIcon() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, 1024, 1024));
  _BizSplitIconPainter().paint(canvas, const Size(1024, 1024));
  final img = await recorder.endRecording().toImage(1024, 1024);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final file = File('assets/icon/app_icon.png');
  await file.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint('✓ Icon saved to assets/icon/app_icon.png');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _exportIcon();
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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1D9E75),
        useMaterial3: true,
      ),
      home: const SplashScreen(
        nextScreen: MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1D9E75).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Painter referenced by the export function above
class _BizSplitIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark navy background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.18),
      ),
      Paint()..color = const Color(0xFF0D1F2D),
    );

    final bars = [
      _Bar(x: 0.16, heightFraction: 0.26, opacity: 0.38),
      _Bar(x: 0.34, heightFraction: 0.44, opacity: 0.65),
      _Bar(x: 0.52, heightFraction: 0.60, opacity: 1.0),
      _Bar(x: 0.70, heightFraction: 0.50, opacity: 0.85),
    ];

    const barWidthFraction = 0.13;
    const bottomPad = 0.16;
    const tealBase = Color(0xFF1D9E75);
    final lightTeal = const Color(0xFF5DCAA5);
    final barPaint = Paint()..style = PaintingStyle.fill;
    final radius = Radius.circular(w * 0.03);

    for (final bar in bars) {
      barPaint.color = tealBase.withOpacity(bar.opacity);
      final barH = h * bar.heightFraction;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * bar.x,
            h * (1 - bottomPad) - barH,
            w * barWidthFraction,
            barH,
          ),
          radius,
        ),
        barPaint,
      );
    }

    final linePaint = Paint()
      ..color = lightTeal
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final points = bars.map((bar) => Offset(
          w * bar.x + w * barWidthFraction / 2,
          h * (1 - bottomPad) - h * bar.heightFraction,
        )).toList();

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(
      points.last,
      w * 0.04,
      Paint()..color = const Color(0xFF9FE1CB),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Bar {
  final double x;
  final double heightFraction;
  final double opacity;
  const _Bar({required this.x, required this.heightFraction, required this.opacity});
}