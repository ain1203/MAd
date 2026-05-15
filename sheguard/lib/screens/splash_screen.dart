import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'home_screen.dart';

/// SafeHer Splash Screen — StatefulWidget
///
/// Background : deep violet (#4A148C) → warm magenta/rose (#C2185B) top→bottom
/// Logo       : white shield with glowing BoxShadow + purple location pin inside
/// Typography : 'SafeHer' bold 32 px + faded subtitle
/// Footer     : LinearProgressIndicator (pink) + monospaced 'SECURE CONNECTING…'

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  // ── Brand palette (Static so _Footer can access them) ──────────────────────
  static const Color _deepViolet   = Color(0xFF4A148C);
  static const Color _warmMagenta  = Color(0xFFC2185B);
  static const Color _progressPink = Color(0xFFF48FB1);
  static const Color _progressBg   = Color(0x44C2185B);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ── NAVIGATION TIMER (3 Seconds) ─────────────────────────────────────────
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Navigate to AuthWrapper which will decide between Home and Login
        Navigator.pushReplacementNamed(context, '/auth-wrapper');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // ── Gradient background ──────────────────────────────────────────────
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: [SplashScreen._deepViolet, SplashScreen._warmMagenta],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // ── Logo section ─────────────────────────────────────────────
              const _GlowingShieldLogo(),

              const SizedBox(height: 36),

              // ── Title ────────────────────────────────────────────────────
              const Text(
                'SafeHer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              // ── Subtitle ─────────────────────────────────────────────────
              Text(
                'Stay Safe. Stay Connected.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(flex: 3),

              // ── Footer ───────────────────────────────────────────────────
              const _Footer(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shield logo with soft glow and centred location pin
// ─────────────────────────────────────────────────────────────────────────────

class _GlowingShieldLogo extends StatelessWidget {
  const _GlowingShieldLogo();

  static const double _size = 130;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  _size,
      height: _size,
      decoration: BoxDecoration(
        // Soft white glow behind the shield
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.25),
            blurRadius: 48,
            spreadRadius: 12,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.10),
            blurRadius: 80,
            spreadRadius: 24,
          ),
        ],
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // White shield drawn with CustomPainter
          CustomPaint(
            size: const Size(_size, _size),
            painter: _ShieldPainter(),
          ),
          // Purple location pin centred inside the shield
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Icon(
              Icons.location_on,
              color: Color(0xFF7B1FA2),
              size: _size * 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter — draws a classic heraldic shield in white
// ─────────────────────────────────────────────────────────────────────────────

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shield fill
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Shield path: flat top, straight sides, curved lower halves → pointed tip
    final path = Path()
      ..moveTo(w * 0.15, h * 0.12)
      ..lineTo(w * 0.85, h * 0.12)
      ..lineTo(w * 0.85, h * 0.55)
      ..quadraticBezierTo(w * 0.85, h * 0.82, w * 0.50, h * 0.92)
      ..quadraticBezierTo(w * 0.15, h * 0.82, w * 0.15, h * 0.55)
      ..close();

    canvas.drawPath(path, fillPaint);

    // Subtle inner bevel stroke for depth
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer: animated progress bar + monospaced label
// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator — indeterminate (animated automatically)
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            backgroundColor: SplashScreen._progressBg,
            valueColor: const AlwaysStoppedAnimation<Color>(
              SplashScreen._progressPink,
            ),
            minHeight: 3,
          ),
        ),

        const SizedBox(height: 14),

        // Monospaced connecting label
        Text(
          'SECURE CONNECTING...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.80),
            fontSize: 11,
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Courier New', 'Courier'],
            letterSpacing: 2.8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}