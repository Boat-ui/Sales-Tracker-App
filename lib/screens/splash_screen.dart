import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _wordmarkOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _loaderWidth;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _iconScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.55, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.65, curve: Curves.easeOut),
      ),
    );

    _loaderWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => widget.nextScreen,
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F2D),
      body: Stack(
        children: [
          // Ambient rings
          Positioned(
            top: -100,
            left: -60,
            child: _AmbientRing(size: 420),
          ),
          Positioned(
            bottom: -60,
            right: -80,
            child: _AmbientRing(size: 300),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => Opacity(
                    opacity: _iconOpacity.value,
                    child: Transform.scale(
                      scale: _iconScale.value,
                      child: const _BizSplitIcon(size: 80),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Wordmark
                AnimatedBuilder(
                  animation: _wordmarkOpacity,
                  builder: (_, __) => Opacity(
                    opacity: _wordmarkOpacity.value,
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Biz',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Split',
                            style: TextStyle(color: Color(0xFF1D9E75)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                AnimatedBuilder(
                  animation: _taglineOpacity,
                  builder: (_, __) => Opacity(
                    opacity: _taglineOpacity.value,
                    child: const Text(
                      'Smart business tracking',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0x61FFFFFF),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 64),

                // Loader bar
                AnimatedBuilder(
                  animation: _loaderWidth,
                  builder: (_, __) => Container(
                    width: 44,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _loaderWidth.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D9E75),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ambient decorative ring ────────────────────────────────────────────────
class _AmbientRing extends StatelessWidget {
  final double size;
  const _AmbientRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1D9E75).withOpacity(0.10),
          width: 1,
        ),
      ),
    );
  }
}

// ─── BizSplit Icon Mark ──────────────────────────────────────────────────────
class _BizSplitIcon extends StatelessWidget {
  final double size;
  const _BizSplitIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF162A3A),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: CustomPaint(
        painter: _BizSplitIconPainter(),
      ),
    );
  }
}

class _BizSplitIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bar positions (as fractions of icon size)
    // 4 bars: x positions 0.16, 0.34, 0.52, 0.70 of width
    // Heights from bottom: 0.26, 0.44, 0.60, 0.52
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

    // Draw bars
    for (final bar in bars) {
      barPaint.color = tealBase.withOpacity(bar.opacity);
      final barH = h * bar.heightFraction;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * bar.x,
          h * (1 - bottomPad) - barH,
          w * barWidthFraction,
          barH,
        ),
        radius,
      );
      canvas.drawRRect(rect, barPaint);
    }

    // Draw trend line connecting bar tops
    final linePaint = Paint()
      ..color = lightTeal
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final points = bars.map((bar) {
      return Offset(
        w * bar.x + w * barWidthFraction / 2,
        h * (1 - bottomPad) - h * bar.heightFraction,
      );
    }).toList();

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Highlight dot on last (rightmost) peak
    final dotPaint = Paint()
      ..color = const Color(0xFF9FE1CB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(points.last, w * 0.04, dotPaint);
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