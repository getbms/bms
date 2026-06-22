import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.65, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.25),
            radius: 1.4,
            colors: [Color(0xFF1A3A6B), Color(0xFF0A1628)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle grid pattern overlay
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            // Main content
            Column(
              children: [
                const Spacer(flex: 2),

                // Logo + wordmark
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Column(
                    children: [
                      // Logo icon
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: _LogoBadge(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // App name
                      FadeTransition(
                        opacity: _textOpacity,
                        child: const Text(
                          'BMS',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 8,
                            height: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tagline
                      FadeTransition(
                        opacity: _taglineOpacity,
                        child: const Text(
                          'Business Management System',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF90AAD4),
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Bottom section
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
                  child: AnimatedBuilder(
                    animation: _taglineOpacity,
                    builder: (context, _) => Opacity(
                      opacity: _taglineOpacity.value,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: const LinearProgressIndicator(
                              backgroundColor: Color(0xFF1E3A5F),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4A9EFF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF4A6FA5),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withAlpha(130),
            blurRadius: 48,
            spreadRadius: 10,
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/images/bms_logo.svg',
        width: 110,
        height: 110,
      ),
    );
  }
}

// Subtle dot-grid background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    const dotRadius = 0.8;
    final paint = Paint()..color = const Color(0x0AFFFFFF);

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
