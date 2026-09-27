import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _radarLoopController;
  late AnimationController _pulseLoopController;

  // Staggered reveals for found items
  late Animation<double> _keysOpacity;
  late Animation<double> _keysScale;
  late Animation<double> _phoneOpacity;
  late Animation<double> _phoneScale;
  late Animation<double> _walletOpacity;
  late Animation<double> _walletScale;
  late Animation<double> _laptopOpacity;
  late Animation<double> _laptopScale;

  // Logo & Title reveals
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<double> _textOffset;

  @override
  void initState() {
    super.initState();

    // Loop controllers for rotating sweep and expanding ripples
    _radarLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Main controller drives the staggered sequence (3.2 seconds total duration)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Staggered Item 1: Keys (Top-Left) reveals from 10% to 30% of timeline
    _keysOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.3, curve: Curves.easeOut),
      ),
    );
    _keysScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.3, curve: Curves.easeOutBack),
      ),
    );

    // Staggered Item 2: Phone (Top-Right) reveals from 25% to 45% of timeline
    _phoneOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.45, curve: Curves.easeOut),
      ),
    );
    _phoneScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.45, curve: Curves.easeOutBack),
      ),
    );

    // Staggered Item 3: Wallet (Bottom-Left) reveals from 40% to 60% of timeline
    _walletOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
      ),
    );
    _walletScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Staggered Item 4: Laptop (Bottom-Right) reveals from 55% to 75% of timeline
    _laptopOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.75, curve: Curves.easeOut),
      ),
    );
    _laptopScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.75, curve: Curves.easeOutBack),
      ),
    );

    // Logo (Center) reveals from 35% to 70% of timeline
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeIn),
      ),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Text reveals from 65% to 90% of timeline
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 0.9, curve: Curves.easeOut),
      ),
    );
    _textOffset = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Start execution
    _mainController.forward().then((_) {
      // Small pause after animation finishes, then navigate
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigationScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.05, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _radarLoopController.dispose();
    _pulseLoopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background soft subtle radar rings
            Center(
              child: AnimatedBuilder(
                animation: _pulseLoopController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildPulseRing(240 * _pulseLoopController.value, 1.0 - _pulseLoopController.value, const Color(0xFF4F46E5)),
                      _buildPulseRing(160 * _pulseLoopController.value, 1.0 - _pulseLoopController.value, const Color(0xFF4F46E5)),
                      _buildPulseRing(80 * _pulseLoopController.value, 1.0 - _pulseLoopController.value, const Color(0xFF4F46E5)),
                    ],
                  );
                },
              ),
            ),

            // Central Radar sweep custom painting
            Center(
              child: AnimatedBuilder(
                animation: _radarLoopController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RadarSweepPainter(
                      angle: _radarLoopController.value * 2 * math.pi,
                      color: const Color(0xFF7C3AED).withOpacity(0.18),
                    ),
                    size: const Size(280, 280),
                  );
                },
              ),
            ),

            // Found Items staggered popping around the radar scope
            // 1. Keys - Top Left
            Positioned(
              left: size.width / 2 - 100,
              top: size.height / 2 - 100,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _keysOpacity.value,
                    child: Transform.scale(
                      scale: _keysScale.value,
                      child: _buildItemBubble(
                        context,
                        icon: Icons.vpn_key_rounded,
                        color: Colors.amber.shade600,
                        label: 'Keys',
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Phone - Top Right
            Positioned(
              right: size.width / 2 - 100,
              top: size.height / 2 - 100,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _phoneOpacity.value,
                    child: Transform.scale(
                      scale: _phoneScale.value,
                      child: _buildItemBubble(
                        context,
                        icon: Icons.phone_android_rounded,
                        color: Colors.blue.shade600,
                        label: 'Phone',
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Wallet - Bottom Left
            Positioned(
              left: size.width / 2 - 105,
              bottom: size.height / 2 - 105,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _walletOpacity.value,
                    child: Transform.scale(
                      scale: _walletScale.value,
                      child: _buildItemBubble(
                        context,
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.teal.shade600,
                        label: 'Wallet',
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Laptop - Bottom Right
            Positioned(
              right: size.width / 2 - 105,
              bottom: size.height / 2 - 105,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _laptopOpacity.value,
                    child: Transform.scale(
                      scale: _laptopScale.value,
                      child: _buildItemBubble(
                        context,
                        icon: Icons.laptop_chromebook_rounded,
                        color: Colors.indigo.shade600,
                        label: 'Laptop',
                      ),
                    ),
                  );
                },
              ),
            ),

            // Central pulsing Compass / Scan Target icon
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.6), width: 2),
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          color: Color(0xFF7C3AED),
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Text & App Identity branding
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0.0, _textOffset.value),
                      child: Column(
                        children: [
                          const Text(
                            'TecFind',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Locating what matters most',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Soft elegant matching loading dash
                          SizedBox(
                            width: 48,
                            height: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                backgroundColor: const Color(0xFF7C3AED).withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Soft expanding ripple rings builder
  Widget _buildPulseRing(double radius, double opacity, Color color) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(opacity * 0.25),
          width: 1.5,
        ),
      ),
    );
  }

  // Individual found item bubbles
  Widget _buildItemBubble(BuildContext context, {required IconData icon, required Color color, required String label}) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// Radar sweep shader painter
class RadarSweepPainter extends CustomPainter {
  final double angle;
  final Color color;

  RadarSweepPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the radar sweep wedge
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.0),
          color,
        ],
        stops: const [0.75, 1.0],
        transform: GradientRotation(angle - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    // Draw outer boundary ring
    final outlinePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant RadarSweepPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.color != color;
  }
}
