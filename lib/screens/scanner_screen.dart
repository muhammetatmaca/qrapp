import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qrapp/screens/settings_screen.dart';
import 'package:qrapp/screens/history_screen.dart';
import 'package:qrapp/screens/saved_screen.dart';
import 'package:qrapp/screens/generator_screen.dart';
import 'package:qrapp/services/settings_service.dart';
import 'package:qrapp/services/history_service.dart';
import 'package:qrapp/services/saved_service.dart';
import 'package:flutter/services.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  late AnimationController _animationController;
  bool _isFlashOn = false;
  bool _isScanning = true;
  String _currentMode = "QR Code";
  String _defaultCamera = 'Rear';
  String _flashlightMode = 'Manual';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initCameraWithSettings();
  }

  Future<void> _initCameraWithSettings() async {
    final cameraSettings = await SettingsService.loadCameraSettings();
    _defaultCamera = cameraSettings['defaultCamera']!;
    _flashlightMode = cameraSettings['flashlightMode']!;

    // Determine initial camera facing
    final cameraFacing = _defaultCamera == 'Front' 
        ? CameraFacing.front 
        : CameraFacing.back;

    // Determine initial torch mode
    TorchState initialTorch = TorchState.off;
    if (_flashlightMode == 'Auto') {
      initialTorch = TorchState.auto;
    }

    _controller = MobileScannerController(
      facing: cameraFacing,
      torchEnabled: _flashlightMode == 'Auto',
    );

    setState(() {
      _isFlashOn = _flashlightMode == 'Auto';
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() {
        _isScanning = false;
      });
      
      final settings = await SettingsService.loadSettings();
      
      final String code = barcodes.first.rawValue!;
      final String type = barcodes.first.type.name;

      // Auto-copy if enabled
      if (settings['autoCopy'] == true) {
        await Clipboard.setData(ClipboardData(text: code));
      }

      // Save to history if enabled
      if (settings['saveHistory'] == true) {
        await HistoryService.addToHistory(code, _currentMode);
      }

      _showResultModal(code);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && _controller != null) {
      await _controller!.analyzeImage(image.path);
    }
  }

  void _showResultModal(String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ResultModal(
        code: code,
        onClose: () {
          setState(() {
            _isScanning = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Feed
          if (_isInitialized && _controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF13EC49)),
            ),

          // 2. Vignette/Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // 3. Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    onTap: () {
                      if (_controller != null) {
                        _controller!.toggleTorch();
                        setState(() {
                          _isFlashOn = !_isFlashOn;
                        });
                      }
                    },
                    icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      "Scanner",
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildCircleButton(
                    onTap: _pickImage,
                    icon: Icons.image_outlined,
                  ),
                ],
              ),
            ),
          ),

          // 4. Central Scanning Area
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Flexible(
                    flex: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: _currentMode == "QR Code" ? 250 : 320,
                      height: _currentMode == "QR Code" ? 250 : 180,
                      child: Stack(
                        children: [
                          _buildCorner(Alignment.topLeft),
                          _buildCorner(Alignment.topRight),
                          _buildCorner(Alignment.bottomLeft),
                          _buildCorner(Alignment.bottomRight),
                          _buildAnimatedScanLine(primaryColor),
                          Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Text(
                      "Align $_currentMode within frame to scan",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(flex: 10),
                ],
              ),
            ),
          ),

          // 5. Bottom Navigation
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Container(
                        height: 48, width: 240,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            _buildModeItem("QR Code", primaryColor),
                            _buildModeItem("Barcode", primaryColor),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildNavItem(
                            Icons.history,
                            "History",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistoryScreen(),
                                ),
                              );
                            },
                          ),
                          _buildNavItem(
                            Icons.bookmark_outline,
                            "Saved",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SavedScreen(),
                                ),
                              );
                            },
                          ),
                          _buildShutterButton(primaryColor),
                          _buildNavItem(
                            Icons.add_circle_outline,
                            "Create",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GeneratorScreen(),
                                ),
                              );
                            },
                          ),
                          _buildNavItem(
                            Icons.settings_outlined,
                            "Settings",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required VoidCallback onTap, required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 28),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  double _shutterScale = 1.0;

  Widget _buildShutterButton(Color primaryColor) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _shutterScale = 0.9),
      onTapUp: (_) => setState(() => _shutterScale = 1.0),
      onTapCancel: () => setState(() => _shutterScale = 1.0),
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: AnimatedScale(
        scale: _shutterScale,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
              ),
            ),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 25)],
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeItem(String label, Color primaryColor) {
    final bool isActive = _currentMode == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentMode = label;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? Colors.black : Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    const double size = 32.0;
    const double weight = 4.0;
    const Color color = Color(0xFF13EC49);
    final bool isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final bool isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: color, width: weight) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: color, width: weight) : BorderSide.none,
            left: isLeft ? const BorderSide(color: color, width: weight) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: color, width: weight) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedScanLine(Color primaryColor) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final position = _animationController.value;
        final maxHeight = _currentMode == "QR Code" ? 250.0 : 180.0;
        final scanAreaHeight = maxHeight - 40; // Subtract padding

        return Stack(
          children: [
            // Trail Effect
            Positioned(
              top: 20 + (position * scanAreaHeight) + (position > 0.5 ? -40.0 : 0.0),
              left: 20, right: 20,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: position > 0.5 ? Alignment.bottomCenter : Alignment.topCenter,
                    end: position > 0.5 ? Alignment.topCenter : Alignment.bottomCenter,
                    colors: [primaryColor.withOpacity(0.3), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Laser Line
            Positioned(
              top: 20 + (position * scanAreaHeight),
              left: 15, right: 15,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(color: primaryColor, blurRadius: 10, spreadRadius: 2),
                    BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 20, spreadRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultModal extends StatefulWidget {
  final String code;
  final VoidCallback onClose;

  const _ResultModal({required this.code, required this.onClose});

  @override
  State<_ResultModal> createState() => _ResultModalState();
}

class _ResultModalState extends State<_ResultModal> {
  bool _isSaved = false;

  bool get _isUrl => Uri.tryParse(widget.code)?.hasAbsolutePath ?? false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final isSaved = await SavedService.isSaved(widget.code);
    setState(() {
      _isSaved = isSaved;
    });
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await SavedService.removeFromSaved(widget.code);
    } else {
      await SavedService.addToSaved(widget.code, 'QR Code');
    }
    setState(() {
      _isSaved = !_isSaved;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Saved!' : 'Removed from saved'),
          backgroundColor: const Color(0xFF13EC49),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);

    return Container(
      decoration: const BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text("Scan Result", style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: SelectableText(
              widget.code,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onTap: () async {
                    if (_isUrl) {
                      final uri = Uri.parse(widget.code);
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    } else {
                      await Clipboard.setData(ClipboardData(text: widget.code));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            backgroundColor: primaryColor,
                          ),
                        );
                      }
                    }
                  },
                  icon: _isUrl ? Icons.open_in_browser : Icons.copy,
                  label: _isUrl ? "Open Link" : "Copy",
                  color: primaryColor,
                  textColor: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              _buildSimpleButton(
                onTap: _toggleSave,
                icon: _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                isActive: _isSaved,
              ),
              const SizedBox(width: 12),
              _buildSimpleButton(onTap: () => Share.share(widget.code), icon: Icons.share),
              const SizedBox(width: 12),
              _buildSimpleButton(
                onTap: () {
                  Navigator.pop(context);
                  widget.onClose();
                },
                icon: Icons.close,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButton({required VoidCallback onTap, required IconData icon, required String label, required Color color, required Color textColor}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSimpleButton({required VoidCallback onTap, required IconData icon, bool isActive = false}) {
    const primaryColor = Color(0xFF13EC49);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? primaryColor : Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: isActive ? primaryColor : Colors.white, size: 22),
      ),
    );
  }
}
