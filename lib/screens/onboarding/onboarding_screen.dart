import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_complete') ?? false);
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _pages = [
    _OnboardPage(
      emoji: '📊',
      title: 'Track every sale',
      subtitle: 'Record what you sell, what it cost, and how much you made — all in one place.',
      accent: AppTheme.revenue,
      bullets: [
        'Add stock items with cost prices',
        'Record sales in seconds',
        'See profit per transaction instantly',
      ],
    ),
    _OnboardPage(
      emoji: '💰',
      title: 'Split your profit smartly',
      subtitle: 'BizSplit automatically divides every profit into business, savings, and spending.',
      accent: AppTheme.teal,
      bullets: [
        'Set your own business vs personal split',
        'Know exactly what to save vs spend',
        'See your true take-home after expenses',
      ],
    ),
    _OnboardPage(
      emoji: '📈',
      title: 'Grow with clarity',
      subtitle: 'Charts, reports, debt tracking, and low stock alerts — everything a serious business needs.',
      accent: AppTheme.biz,
      bullets: [
        'Export PDF reports for any date range',
        'Track what customers owe you',
        'Get notified when stock runs low',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await OnboardingScreen.markComplete();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) {
                  setState(() => _page = i);
                  _fadeCtrl.reset();
                  _fadeCtrl.forward();
                },
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i], fadeAnim: _fadeAnim),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? page.accent : AppTheme.textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 28),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: page.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _next,
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),

                  if (!isLast) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _finish,
                      child: const Text('Already have an account? Sign in', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  final Animation<double> fadeAnim;

  const _PageContent({required this.page, required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji icon
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: page.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: page.accent.withOpacity(0.2), width: 0.5),
              ),
              child: Center(child: Text(page.emoji, style: const TextStyle(fontSize: 48))),
            ),

            const SizedBox(height: 36),

            Text(
              page.title,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 14),

            Text(
              page.subtitle,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Bullet points
            ...page.bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(color: page.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.check, color: page.accent, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(b, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final List<String> bullets;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.bullets,
  });
}