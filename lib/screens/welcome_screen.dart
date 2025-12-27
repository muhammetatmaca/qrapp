import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math' as math;
import 'package:qrapp/screens/scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCheckingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    
    if (hasSeenOnboarding && mounted) {
      // Skip onboarding and go directly to scanner
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
    } else {
      setState(() {
        _isCheckingOnboarding = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
    }
  }

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Scan & ",
      highlightedTitle: "Generate",
      description:
          "Instantly decode barcodes or create your own custom QR codes in seconds with lightning-fast detection.",
      topLabel: "WELCOME TO QR SCANNER",
      illustration: const ScannerIllustration(),
    ),
    OnboardingData(
      title: "Fast & Easy ",
      highlightedTitle: "Scanning",
      description:
          "Point your camera at any QR code or barcode to get results instantly. No buttons to press.",
      topLabel: "FAST & EASY",
      illustration: const FastScanIllustration(),
    ),
    OnboardingData(
      title: "Create ",
      highlightedTitle: "Anything.",
      description:
          "Instantly generate QR codes for websites, Wi-Fi networks, text, and more. Customize the look to match your style.",
      topLabel: "CUSTOM QR",
      illustration: const CreateQRIllustration(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);

    // Show loading while checking onboarding status
    if (_isCheckingOnboarding) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF13EC49)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text(
                    _pages[_currentPage].topLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      "Skip",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    data: _pages[index],
                    primaryColor: primaryColor,
                  );
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primaryColor
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _currentPage == index
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 8,
                                  )
                                ]
                              : [],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Complete onboarding and save state
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: bgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? "Get Started"
                                : "Next",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String highlightedTitle;
  final String description;
  final String topLabel;
  final Widget illustration;

  OnboardingData({
    required this.title,
    required this.highlightedTitle,
    required this.description,
    required this.topLabel,
    required this.illustration,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final Color primaryColor;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: data.illustration),
          const SizedBox(height: 48),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
              children: [
                TextSpan(text: data.title),
                TextSpan(
                  text: data.highlightedTitle,
                  style: TextStyle(color: primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// --- Animated Illustrations ---

class ScannerIllustration extends StatefulWidget {
  const ScannerIllustration({super.key});

  @override
  State<ScannerIllustration> createState() => _ScannerIllustrationState();
}

class _ScannerIllustrationState extends State<ScannerIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dashed Border
            Positioned.fill(
              child: CustomPaint(
                painter: DashedRectPainter(
                  color: Colors.white.withOpacity(0.3),
                  strokeWidth: 2,
                  gap: 10,
                ),
              ),
            ),

            // Tilted Phone Silhouette
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(-0.5)
                ..rotateY(0.5)
                ..rotateZ(-0.2),
              alignment: Alignment.center,
              child: Container(
                width: 180,
                height: 320,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            // Floating QR Code
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -20 + (_controller.value * 20)),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF13EC49).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: "https://google.com",
                      version: QrVersions.auto,
                      size: 100.0,
                    ),
                  ),
                );
              },
            ),

            // Scan Line
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  top: 100 + (_controller.value * 200),
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13EC49),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF13EC49).withOpacity(0.8),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Corner Decorations
            ..._buildCorners(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 30.0;
    const color = Color(0xFF13EC49);
    return [
      Positioned(
          top: 40,
          left: 40,
          child: _corner(top: true, left: true, color: color, size: size)),
      Positioned(
          top: 40,
          right: 40,
          child: _corner(top: true, left: false, color: color, size: size)),
      Positioned(
          bottom: 40,
          left: 40,
          child: _corner(top: false, left: true, color: color, size: size)),
      Positioned(
          bottom: 40,
          right: 40,
          child: _corner(top: false, left: false, color: color, size: size)),
    ];
  }

  Widget _corner(
      {required bool top,
      required bool left,
      required Color color,
      required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: 4) : BorderSide.none,
          bottom: !top ? BorderSide(color: color, width: 4) : BorderSide.none,
          left: left ? BorderSide(color: color, width: 4) : BorderSide.none,
          right: !left ? BorderSide(color: color, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}

class FastScanIllustration extends StatefulWidget {
  const FastScanIllustration({super.key});

  @override
  State<FastScanIllustration> createState() => _FastScanIllustrationState();
}

class _FastScanIllustrationState extends State<FastScanIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Camera Grid
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(painter: GridPainter()),
              ),
            ),

            // Viewfinder
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.circular(24),
              ),
            ),

            // Scanning QR Code
            QrImageView(
              data: "scanning...",
              version: QrVersions.auto,
              size: 140.0,
              foregroundColor: Colors.white.withOpacity(0.8),
            ),

            // Pulse Effect
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 140 + (_controller.value * 40),
                  height: 140 + (_controller.value * 40),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF13EC49)
                          .withOpacity(1 - _controller.value),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),

            // Lock Corners
            ..._buildLockCorners(),

            // Status Label
            Positioned(
              bottom: 40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner,
                        color: Color(0xFF13EC49), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Scanning for code...",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLockCorners() {
    return [
      Positioned(top: 85, left: 35, child: _corner(true, true)),
      Positioned(top: 85, right: 35, child: _corner(true, false)),
      Positioned(bottom: 85, left: 35, child: _corner(false, true)),
      Positioned(bottom: 85, right: 35, child: _corner(false, false)),
    ];
  }

  Widget _corner(bool top, bool left) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFF13EC49), width: 3) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFF13EC49), width: 3) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFF13EC49), width: 3) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFF13EC49), width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}

class CreateQRIllustration extends StatefulWidget {
  const CreateQRIllustration({super.key});

  @override
  State<CreateQRIllustration> createState() => _CreateQRIllustrationState();
}

class _CreateQRIllustrationState extends State<CreateQRIllustration>
    with TickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF13EC49);

    return Center(
      child: SizedBox(
        width: 300,
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background stack effect
            Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),

            // Main Card
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: "Create Anything!",
                    version: QrVersions.auto,
                    size: 120.0,
                  ),
                ),
              ),
            ),

            // Floating Icons
            _floatingIcon(
                icon: Icons.wifi,
                top: 35,
                right: 25,
                delay: 0,
                label: "Wi-Fi"),
            _floatingIcon(
                icon: Icons.link,
                top: 130,
                left: 15,
                delay: 1.5,
                label: "URL"),
            _floatingIcon(
                icon: Icons.text_fields,
                bottom: 45,
                right: 30,
                delay: 3,
                label: "Text"),
          ],
        ),
      ),
    );
  }

  Widget _floatingIcon(
      {required IconData icon,
      double? top,
      double? bottom,
      double? left,
      double? right,
      required double delay,
      required String label}) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final val = math.sin((_floatController.value * 2 * math.pi) + delay);
        return Positioned(
          top: top != null ? top + (val * 10) : null,
          bottom: bottom != null ? bottom + (val * 10) : null,
          left: left,
          right: right,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF25352A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF13EC49).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFF13EC49), size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Custom Painters ---

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter(
      {required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(20)));

    canvas.drawPath(_dashPath(path, gap), paint);
  }

  Path _dashPath(Path source, double gap) {
    final path = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        path.addPath(
            metric.extractPath(distance, distance + gap), Offset.zero);
        distance += gap * 2;
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (var i = 0.0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
