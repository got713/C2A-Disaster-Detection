import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, .6, curve: Curves.easeOut)));
    _scaleAnim = Tween<double>(begin: .5, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, .7, curve: Curves.elasticOut)));
    _ctrl.forward();
    
    // Check auth status while showing splash
    Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      ApiService.loadToken(),
    ]).then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ApiService.isAuthenticated ? const HomeScreen() : const LoginScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(children: [
        // Grid background
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        // Red glow top-left
        Positioned(top: -100, left: -100, child: Container(
          width: 400, height: 400,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [AppTheme.primaryColor.withOpacity(.12), Colors.transparent])),
        )),
        // Cyan glow bottom-right
        Positioned(bottom: -150, right: -100, child: Container(
          width: 500, height: 500,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [AppTheme.accentColor.withOpacity(.08), Colors.transparent])),
        )),
        Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: _fadeAnim.value,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [AppTheme.primaryColor, Color(0xFFFF6B6B)]),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(.5), blurRadius: 40, spreadRadius: 8)],
                    ),
                    child: const Icon(Icons.radar, color: Colors.white, size: 54),
                  ),
                ),
                const SizedBox(height: 32),
                Text('C2A Detect',
                    style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                const SizedBox(height: 8),
                Text('UAV Human Detection System',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15)),
                const SizedBox(height: 48),
                // Loading bar
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _ctrl.value,
                      backgroundColor: AppTheme.darkCard,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _tag('YOLO v9', AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  _tag('C2A Dataset', AppTheme.accentColor),
                  const SizedBox(width: 8),
                  _tag('AI Powered', AppTheme.success),
                ]),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: AnimatedBuilder(
            animation: _fadeAnim,
            builder: (_, __) => Opacity(
              opacity: _fadeAnim.value,
              child: Text('Disaster Response Intelligence',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(.4)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(.025)..strokeWidth = .5;
    for (double x = 0; x < size.width; x += 35) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 35) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
